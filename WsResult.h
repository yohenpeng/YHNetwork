//
//  WsResult.h
//  ticket
//
//  Created by ken on 14-2-20.
//  Copyright (c) 2014年 ken. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *SessionExpiredNotification;

@interface WsResult : NSObject
-(id)initWithDictionary:(NSDictionary*)dic;

@property(nonatomic,readonly) BOOL isFromServer;
@property(nonatomic,readonly) BOOL isRight;
@property(nonatomic,readonly) NSInteger code;
@property(nonatomic,readonly,copy) NSString *method;
@property(nonatomic,readonly,copy) NSString *version;
@property(nonatomic,readonly,copy) NSArray *arrayData;
@property(nonatomic,readonly,copy) NSDictionary *mapData;
@property(nonatomic,readonly,copy) id rawData;
@property(nonatomic,readonly,copy) NSString *msg;
@property(nonatomic,readonly,strong) NSError *error;

extern NSString *SessionExpiredNotification;

extern NSInteger const WsResultUserCancelErrorCode;
@end
