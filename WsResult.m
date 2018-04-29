//
//  WsResult.m
//  ticket
//
//  Created by ken on 14-2-20.
//  Copyright (c) 2014年 ken. All rights reserved.
//

#import "WsResult.h"

//action：接口名称
//code：返回状态码
//reason：提示信息
//v：接口版本号
//data：返回数据

#define WebServiceActionKey @"action"
#define WebServicePayLoadKey @"data"
#define WebServiceMessageKey @"reason"
#define WebServiceVersionKey @"v"
#define WebServiceReturnCodeKey @"code"


#define failCode 4000
#define successCode 4001
#define timeoutCode 4002
#define sessionExpired 4003

NSString *SessionExpiredNotification = @"SessionExpiredNotification";
NSString *const WebserviceErrorDomain = @"WebserviceErrorDomain";
NSInteger const WsResultUserCancelErrorCode = NSURLErrorCancelled; //4 for asi

@implementation WsResult

- (void)preprocessData
{
    if([_rawData isKindOfClass:[NSArray class]])
    {
        _arrayData = [self prepareArrayData:_rawData];
    }
    else if([_rawData isKindOfClass:[NSDictionary class]])
    {
        _mapData = _rawData;
    }
}


-(id)initWithDictionary:(NSDictionary*)dic
{
    
    self = [super init];
    if(self)
    {
        _version = [dic objectForKey:@"version"];
        _method = [dic objectForKey:WebServiceActionKey];
        _rawData = [dic objectForKey:WebServicePayLoadKey];
        _msg = [dic objectForKey:WebServiceMessageKey];
        if([self checkResultReturnCode:dic])
            _isRight = YES;
        else
            _isRight = NO;
        if(_isRight)
        {
            [self preprocessData];
        }else if(_code == sessionExpired){
            [[NSNotificationCenter defaultCenter] postNotificationName:SessionExpiredNotification object:_msg];
            _error = [NSError errorWithDomain:WebserviceErrorDomain code:[[dic objectForKey:WebServiceReturnCodeKey] integerValue] userInfo:nil];
        }
        else{
            _error = [NSError errorWithDomain:WebserviceErrorDomain code:[[dic objectForKey:WebServiceReturnCodeKey] integerValue] userInfo:@{NSLocalizedFailureReasonErrorKey:_msg}];
        }
    }
    return self;
}

-(Class)mapMethodToModel
{
    static NSDictionary *dic;
    if(dic == nil)
    {
        dic = @{};
    }
    NSString *className = [dic objectForKey:self.method];
    if(className)
        return NSClassFromString(className);
    else
        return Nil;
}

-(NSArray*)prepareArrayData:(NSArray*)data
{
    NSMutableArray *resultArray = [NSMutableArray new];
    Class itemClass = [self mapMethodToModel];
    if([itemClass instancesRespondToSelector:@selector(initWithDictionary:)])
    {
        for (NSDictionary *item in data) {
            id instance = [[itemClass alloc] initWithDictionary:item];
            [resultArray addObject:instance];
        }
        return [resultArray copy];
    }
    else
        return data;
}


-(BOOL)checkResultReturnCode:(NSDictionary*)dic
{
    _code = [[dic objectForKey:WebServiceReturnCodeKey] integerValue];
    if(_code == successCode)
        return YES;
    else
        return NO;
}

@end
