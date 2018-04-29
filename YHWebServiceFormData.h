//
//  YHWebServiceFormData.h
//  YHNetwork
//
//  Created by pengehan on 2017/2/23.
//  Copyright © 2017年 pengehan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@class YHFormDataModel;

typedef void(^AFConstructingBlock)(id<AFMultipartFormData> formData);

@interface YHWebServiceFormData : NSObject

-(void)addFormDataModel:(YHFormDataModel *)model;
-(void)addFormDataModelArray:(NSArray<YHFormDataModel *> *)array;

@property(nonatomic,strong,readonly)NSDictionary *dic;
@property(nonatomic,copy,readonly)AFConstructingBlock constructingBlock;

@end


@interface YHFormDataModel : NSObject

@property(nonatomic,strong)NSObject *value;
@property(nonatomic,strong)NSData *data;
@property(nonatomic,copy)NSString *formKey;
@property(nonatomic,copy)NSString *fileName;
@property(nonatomic,copy)NSString *mimeType;  //默认是图片

+(instancetype)modelWithFormKey:(NSString *)formKey fileName:(NSString *)fileName data:(NSData *)data mimeType:(NSString *)type;
+(instancetype)imageModelWithFormKey:(NSString *)formKey fileName:(NSString *)fileName data:(NSData *)data;
//普通json字符串
+(instancetype)modelWithFormKey:(NSString *)formKey value:(id)value;

@end
