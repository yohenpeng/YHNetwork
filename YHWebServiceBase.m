//
//  YHWebServiceBase.m
//  YHNetwork
//
//  Created by pengehan on 2017/2/22.
//  Copyright © 2017年 pengehan. All rights reserved.
//

#import "YHWebServiceBase.h"
#import "WsResult.h"
#import "YHWebServiceFormData.h"


static NSString* const completeBlockKey = @"ServiceBase.CompleteBlockKey";
static NSString* const RequestCompleteSuccessNotification = @"ServiceBase.RequestCompleteSuccessNotification";
static NSString* const RequestRetryNotification = @"ServiceBase.RequestRetryNotification";
static NSString* const RequestCompleteFailureNotification = @"ServiceBase.RequestCompleteFailureNotification";

@interface YHWebServiceBase(){
    NSInteger _retryCount;
    NSTimeInterval _timeoutInterval;
    
}
@property(nonatomic,copy)NSString *baseUrlString;

@property(nonatomic,strong)AFHTTPSessionManager *httpSessionManager;

@property(nonatomic,strong)AFURLSessionManager *urlSessionManager;

@property(nonatomic,strong)AFNetworkReachabilityManager *reachabilityManager;
@property(nonatomic,copy)void (^reachStatusChangeBlock)(AFNetworkReachabilityStatus staus);
//任务id和任务的对应表
@property(nonatomic,strong)NSMutableDictionary<NSString *,NSURLSessionDataTask*> *currentTaskForIdentify;
//旧的任务id和当前最新的任务id对应表
@property(nonatomic,strong)NSMutableDictionary<NSString *,NSString *> *oldMapToNewDic;

@end

@implementation YHWebServiceBase

-(instancetype)initWithBaseUrlString:(NSString *)baseUrlString{
    self = [self init];
    if (self) {
        _baseUrlString = baseUrlString;
    }
    return self;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        _retryCount = 3;
        _timeoutInterval = 20;
        _currentTaskForIdentify = [NSMutableDictionary new];
        _oldMapToNewDic = [NSMutableDictionary new];
        [self initNotification];
    }
    return self;
}

-(void)initNotification{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(requestSuccessOrFailure:) name:RequestCompleteSuccessNotification object:self];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(requestRetry:) name:RequestRetryNotification object:self];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(requestSuccessOrFailure:) name:RequestCompleteFailureNotification object:self];
}

-(NSString *)taskIdString:(NSURLSessionDataTask*)task{
    return [NSString stringWithFormat:@"%ld",task.taskIdentifier];
}

-(void)requestRetry:(NSNotification *)notification{
    NSDictionary *dic = notification.userInfo;
    NSURLSessionDataTask *oldTask = [dic objectForKey:@"oldTask"];
    NSURLSessionDataTask *currentTask = [dic objectForKey:@"currentTask"];
    
    __block NSString *oldTaskId;
    
    
    [_oldMapToNewDic.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([_oldMapToNewDic[obj] isEqualToString:[self taskIdString:oldTask]]) {
            oldTaskId = obj;
            *stop = YES;
        }
    }];
    
    
    if (!oldTaskId) {
        oldTaskId = [self taskIdString:oldTask];
    }else{  //有的话删除旧的task
        @synchronized (_currentTaskForIdentify) {
            [_currentTaskForIdentify removeObjectForKey:[self taskIdString:oldTask]];
        }
    }
    
    @synchronized (_oldMapToNewDic) {
        _oldMapToNewDic[oldTaskId] = [self taskIdString:currentTask];
    }
    
    
    
}

-(void)requestSuccessOrFailure:(NSNotification*)notification{
    NSURLSessionDataTask *task = notification.userInfo[@"task"];
    NSString* currentTaskId = [self taskIdString:task];
    
    
    __block NSString *oldTaskId;
    [_oldMapToNewDic.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([_oldMapToNewDic[obj] isEqualToString:currentTaskId]) {
            oldTaskId = obj;
            *stop = YES;
        }
    }];
    
    @synchronized (_currentTaskForIdentify) {
        [_currentTaskForIdentify removeObjectForKey:currentTaskId];
        if (oldTaskId) {
            [_currentTaskForIdentify removeObjectForKey:oldTaskId];
        }
    }
    
    @synchronized (_oldMapToNewDic) {
        if (oldTaskId) {
            [_oldMapToNewDic removeObjectForKey:oldTaskId];
        }
        
    }
    
}


-(NSURLSessionDataTask *)currentSessionTaskByBefore:(NSURLSessionDataTask *)task{
    
    NSString *currentTaskId = _oldMapToNewDic[[self taskIdString:task]];
    if (currentTaskId == nil) {
        return _currentTaskForIdentify[[self taskIdString:task]];
    }else{
        return _currentTaskForIdentify[currentTaskId];
    }
}


-(void)cancelSingleTask:(NSURLSessionDataTask *)task{
    NSURLSessionDataTask *currentTask = [self currentSessionTaskByBefore:task];
    [currentTask cancel];
}

#pragma mark ---- httpSessionManager
-(AFHTTPSessionManager *)httpSessionManager{
    if (!_httpSessionManager) {
        _httpSessionManager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:_baseUrlString] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _httpSessionManager.requestSerializer = self.httpRequestSerializer;
        _httpSessionManager.responseSerializer = self.httpResponseSerializer;
    }
    
    return _httpSessionManager;
}

-(AFHTTPRequestSerializer *)httpRequestSerializer{
    if (!_httpRequestSerializer) {
        _httpRequestSerializer = [AFJSONRequestSerializer new]; //默认是json
        [_httpRequestSerializer setValue:@"text/html" forHTTPHeaderField:@"Accept"];  //请求接受文本
        [_httpRequestSerializer setTimeoutInterval:_timeoutInterval];
    }
    return _httpRequestSerializer;
}

-(AFHTTPResponseSerializer *)httpResponseSerializer{
    if (!_httpResponseSerializer) {
        _httpResponseSerializer = [AFJSONResponseSerializer new]; //默认是json
        _httpResponseSerializer.acceptableContentTypes = [_httpResponseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    }
    return _httpResponseSerializer;
}


#pragma mark ---- urlSessionManager
-(AFURLSessionManager *)urlSessionManager{
    if (!_urlSessionManager) {
        _urlSessionManager = [[AFURLSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _urlSessionManager.responseSerializer = self.urlResponseSerializer;
    }
    return _urlSessionManager;
}


-(AFHTTPResponseSerializer *)urlResponseSerializer{
    if (!_urlResponseSerializer) {
        _urlResponseSerializer = [AFJSONResponseSerializer new]; //默认是json
    }
    return _urlResponseSerializer;
}


-(AFNetworkReachabilityManager *)reachabilityManager{
    if (!_reachabilityManager) {
        _reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    }
    return _reachabilityManager;
}

#pragma mark ----
-(void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus))block{
    
    self.reachStatusChangeBlock = block;
    
    typeof(self) __weak weakSelf = self;
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable) {
            [weakSelf cancelAllTask];
        }else{
            [weakSelf resumeAllTask];
        }
        weakSelf.reachStatusChangeBlock(status);
    }];
    
}


-(NSURLSessionDataTask*)webservice:(NSString*)method withParams:(NSDictionary*)dic finish:(void(^)(WsResult* result))result{
    
    NSURLSessionDataTask *task = [self webservice:method withParams:dic complete:^(NSDictionary *dic) {
        if(result)
        {
            result([[WsResult alloc]initWithDictionary:dic]);
        }
    }];
    
    return task;
}

-(NSURLSessionDataTask*)webservice:(NSString*)method withParams:(NSDictionary*)dic complete:(void(^)(NSDictionary *dic))block{
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:block forKey:completeBlockKey];
    return [self addRequestToManager:method withParms:dic WithUserInfo:userInfo retryCount:_retryCount];
}



-(NSURLSessionDataTask *)addRequestToManager:(NSString *)method withParms:(NSDictionary *)dic WithUserInfo:(NSDictionary *)userInfo retryCount:(NSInteger)count{
    
    NSLog(@"尝试了一次");
    
    NSURLSessionDataTask *dataTask = [self.httpSessionManager POST:method parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //成功
        [[NSNotificationCenter defaultCenter]postNotificationName:RequestCompleteSuccessNotification object:self userInfo:@{@"task":task}];
        
        void (^completeBlock)(NSDictionary *) = [userInfo objectForKey:completeBlockKey];
        if (completeBlock) {
            completeBlock([self preProcessResponse:responseObject]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (count > 0) {
            //如果是超时
            if (error.code == NSURLErrorTimedOut) {
                
                NSURLSessionDataTask *currentTask = [self addRequestToManager:method withParms:dic WithUserInfo:userInfo retryCount:count - 1];
                [[NSNotificationCenter defaultCenter]postNotificationName:RequestRetryNotification object:self userInfo:@{@"oldTask":task,@"currentTask":currentTask}];
                
            }else{
                //非超时错误
                [[NSNotificationCenter defaultCenter]postNotificationName:RequestCompleteFailureNotification object:self userInfo:@{@"task":task}];
                void (^completeBlock)(NSDictionary *) = [userInfo objectForKey:completeBlockKey];
                if (completeBlock) {
                    completeBlock([self preProcessResponse:error]);
                }
            }
            
        }else{
            
            //失败
            [[NSNotificationCenter defaultCenter]postNotificationName:RequestCompleteFailureNotification object:self userInfo:@{@"task":task}];
            void (^completeBlock)(NSDictionary *) = [userInfo objectForKey:completeBlockKey];
            if (completeBlock) {
                completeBlock([self preProcessResponse:error]);
            }
        }
    }];
    
    @synchronized (_currentTaskForIdentify) {
        _currentTaskForIdentify[[self taskIdString:dataTask]] = dataTask;
    }
    
    return dataTask;
}

-(NSURLSessionDataTask*)formDataWebService:(NSString*)method withFormData:(YHWebServiceFormData*)formData finish:(void(^)(WsResult* result))result{
    
    NSURLSessionDataTask *task = [self formDataWebService:method withFormData:formData complete:^(NSDictionary *dic) {
        if (result) {
            result([[WsResult alloc]initWithDictionary:dic]);
        }
    }];
    
    return task;
}


-(NSURLSessionDataTask*)formDataWebService:(NSString*)method withFormData:(YHWebServiceFormData*)formData complete:(void(^)(NSDictionary *dic))block{
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:block forKey:completeBlockKey];
    return [self addRequestToManager:method withFormData:formData WithUserInfo:userInfo retryCount:_retryCount];
    
}


-(NSURLSessionDataTask*)addRequestToManager:(NSString *)method withFormData:(YHWebServiceFormData*)formData WithUserInfo:(NSDictionary *)userInfo retryCount:(NSInteger)retryCount{
    
    NSURLSessionDataTask *task = [self.httpSessionManager POST:method parameters:formData.dic constructingBodyWithBlock:formData.constructingBlock progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        void (^completeBlock)(NSDictionary *) = [userInfo objectForKey:completeBlockKey];
        if (completeBlock) {
            
            @synchronized (_currentTaskForIdentify) {
                [_currentTaskForIdentify removeObjectForKey:[NSString stringWithFormat:@"%ld",task.taskIdentifier]];
            }
            completeBlock([self preProcessResponse:responseObject]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        void (^completeBlock)(NSDictionary *) = [userInfo objectForKey:completeBlockKey];
        if (completeBlock) {
            @synchronized (_currentTaskForIdentify) {
                [_currentTaskForIdentify removeObjectForKey:[NSString stringWithFormat:@"%ld",task.taskIdentifier]];
            }
            completeBlock([self preProcessResponse:error]);
        }
        
    }];
    
    @synchronized (_currentTaskForIdentify) {
        _currentTaskForIdentify[[NSString stringWithFormat:@"%ld",task.taskIdentifier]] = task;
    }
    
    return task;
}


-(NSDictionary*)preProcessResponse:(id)responseObject
{
    
    NSError *error;
    NSDictionary *jsonDic;
    if ([responseObject isKindOfClass:[NSError class]]) {
        error = responseObject;
    }else if ([responseObject isKindOfClass:[NSDictionary class]]){
        jsonDic = responseObject;
    }
    if(error)
    {
        jsonDic = [self createReturnDataFromError:error];
    }
    return jsonDic;
}

-(NSDictionary*)createReturnDataFromError:(NSError *)error
{
    if(error){
        if (error.code == NSURLErrorCancelled) {
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)NSURLErrorCancelled],@"code",@"用户中途取消",@"reason",@YES,@"notReach", nil];
        }else if (error.code == NSURLErrorUserCancelledAuthentication){
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)NSURLErrorUserCancelledAuthentication],@"code",@"网络繁忙,请稍后再试",@"reason",@YES,@"notReach", nil];
        }else if (error.code == NSURLErrorTimedOut){
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)NSURLErrorTimedOut],@"code",@"网络不给力啊",@"reason",@YES,@"notReach", nil];
        }
        else{
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)error.code],@"code",error.userInfo[NSLocalizedDescriptionKey],@"reason",@YES,@"notReach", nil];
        }
    }else{
        return [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"code",@"未知网络错误",@"reason",@YES,@"notReach", nil];
    }
}


#pragma mark ---- 取消 挂起 唤醒
-(void)cancelAllTask{
    for (id task in self.httpSessionManager.tasks) {
        [((NSURLSessionTask *)task) cancel];
    }
    for (id task in self.urlSessionManager.tasks) {
        [((NSURLSessionTask *)task) cancel];
    }
}


-(void)resumeAllTask{
    for (id task in self.httpSessionManager.tasks) {
        [((NSURLSessionTask *)task) resume];
    }
    for (id task in self.urlSessionManager.tasks) {
        [((NSURLSessionTask *)task) resume];
    }
}




@end
