//
//  YHWebServiceBase.h
//  YHNetwork
//
//  Created by pengehan on 2017/2/22.
//  Copyright © 2017年 pengehan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@class WsResult;
@class YHWebServiceFormData;
@class NSURLSessionDataTask;

@interface YHWebServiceBase : NSObject

@property(nonatomic,strong)AFHTTPRequestSerializer *httpRequestSerializer;
@property(nonatomic,strong)AFHTTPResponseSerializer *httpResponseSerializer;

@property(nonatomic,strong)AFHTTPResponseSerializer *urlResponseSerializer;

-(instancetype)initWithBaseUrlString:(NSString *)baseUrlString;

#pragma mark ---- json
-(NSURLSessionDataTask*)webservice:(NSString*)method withParams:(NSDictionary*)dic finish:(void(^)(WsResult* result))result;

-(NSURLSessionDataTask*)webservice:(NSString*)method withParams:(NSDictionary*)dic complete:(void(^)(NSDictionary *dic))block;

#pragma mark ---- formdata 
-(NSURLSessionDataTask*)formDataWebService:(NSString*)method withFormData:(YHWebServiceFormData*)formData finish:(void(^)(WsResult* result))result;

-(NSURLSessionDataTask*)formDataWebService:(NSString*)method withFormData:(YHWebServiceFormData*)formData complete:(void(^)(NSDictionary *dic))block;

//单独取消某个接口
-(void)cancelSingleTask:(NSURLSessionDataTask *)task;

-(NSURLSessionDataTask *)currentSessionTaskByBefore:(NSURLSessionDataTask *)task;

-(void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus staus))block;

-(void)cancelAllTask;
-(void)resumeAllTask;

@end


