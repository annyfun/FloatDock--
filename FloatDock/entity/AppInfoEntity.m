//
//  AppInfoEntity.m
//  FloatDock
//
//  Created by 王凯庆 on 2020/4/24.
//  Copyright © 2020 王凯庆. All rights reserved.
//

#import "AppInfoEntity.h"
#import "DataSavePath.h"

@implementation AppInfoEntity

- (id)init {
    if (self = [super init]) {
        _appPathArray = [NSMutableArray<NSString *> new];
    }
    return self;
}
// 允许参数为空
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation AppInfoArrayEntity

- (id)init {
    if (self = [super init]) {
        _windowArray = [NSMutableArray<AppInfoEntity> new];
    }
    return self;
}
// 允许参数为空
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation AppInfoTool

+ (instancetype)share {
    static dispatch_once_t once;
    static AppInfoTool * instance;
    dispatch_once(&once, ^{
        instance = [self new];
        instance.appInfoArrayEntity = [AppInfoTool getAppInfoArrayEntity];
    });
    return instance;
}

+ (AppInfoArrayEntity *)getAppInfoArrayEntity {
    DataSavePath * path = [DataSavePath share];
    NSData * data = [NSData dataWithContentsOfFile:path.DBPath];
    if (data) {
        AppInfoArrayEntity * entity = [[AppInfoArrayEntity alloc] initWithData:data error:nil];
        if (entity) {
            return entity;
        } else {
            return [AppInfoArrayEntity new];
        }
    } else {
        return [AppInfoArrayEntity new];
    }
}

+ (void)updateEntity {
    [AppInfoTool saveAppInfoArrayEntity:[AppInfoTool share].appInfoArrayEntity];
}

+ (void)saveAppInfoArrayEntity:(AppInfoArrayEntity *)entity {
    if (entity) {
        DataSavePath * path = [DataSavePath share];
        [[NSFileManager defaultManager] createDirectoryAtPath:path.cachesPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        [entity.toJSONData writeToFile:path.DBPath atomically:YES];
    }
}


@end
