//
//  YHWebServiceFormData.m
//  YHNetwork
//
//  Created by pengehan on 2017/2/23.
//  Copyright © 2017年 pengehan. All rights reserved.
//

#import "YHWebServiceFormData.h"

@interface YHWebServiceFormData ()
{
    NSMutableArray* _modelArray;
    
}
@property(nonatomic,strong,readwrite)NSDictionary *dic;
@property(nonatomic,copy,readwrite)AFConstructingBlock constructingBlock;

@end

@implementation YHWebServiceFormData

-(instancetype)init{
    self = [super init];
    if (self) {
        _modelArray = [NSMutableArray new];
    }
    return self;
}

-(void)addFormDataModel:(YHFormDataModel *)model{
    [_modelArray addObject:model];
}

-(void)addFormDataModelArray:(NSArray<YHFormDataModel *> *)array{
    [_modelArray addObjectsFromArray:array];

}


-(NSDictionary *)dic{
    
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    for (YHFormDataModel *model in _modelArray) {
        if (model.value) {
            dictionary[model.formKey] = model.value;
        }
    }
    
    _dic = dictionary;
    return _dic;
}

- (AFConstructingBlock)constructingBlock {
    
    NSMutableArray* __weak weakModelArray = _modelArray;
    _constructingBlock = ^(id<AFMultipartFormData> formData){
        for (YHFormDataModel *model in weakModelArray) {
            if (model.data) {
                [formData appendPartWithFileData:model.data name:model.formKey fileName:model.fileName mimeType:model.mimeType];
            }
        }
    };
    return _constructingBlock;
    
}

@end


@implementation YHFormDataModel

+(instancetype)modelWithFormKey:(NSString *)formKey fileName:(NSString *)fileName data:(NSData *)data mimeType:(NSString *)type{
    YHFormDataModel *model = [YHFormDataModel new];
    model.formKey = formKey;
    model.fileName = fileName;
    model.data = data;
    model.mimeType = type;
    return model;
}

+(instancetype)imageModelWithFormKey:(NSString *)formKey fileName:(NSString *)fileName data:(NSData *)data{
    return [YHFormDataModel modelWithFormKey:formKey fileName:fileName data:data mimeType:@"image/jpeg"];
}

+(instancetype)modelWithFormKey:(NSString *)formKey value:(id)value{
    YHFormDataModel *model = [YHFormDataModel new];
    model.formKey = formKey;
    model.value = value;
    return model;
}

@end
