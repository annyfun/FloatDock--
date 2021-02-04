//
//  DataSavePath.m
//  FMDB-iOS
//
//  Created by apple on 2020/1/10.
//

#import "DataSavePath.h"

@implementation DataSavePath

+ (instancetype)share {
    static dispatch_once_t once;
    static DataSavePath * instance;
    dispatch_once(&once, ^{
        instance = [self new];
        [instance initPath];
    });
    return instance;
}

- (void)initPath {
    self.DBFileName = DBFileNameDefault;
    NSArray * pathsToDocuments = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.projectPath = pathsToDocuments.firstObject;
    // UI系列
#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH
    self.cachesPath = self.projectPath;
    // NS系列
#elif TARGET_OS_MAC
    self.cachesPath = [NSString stringWithFormat:@"%@/%@", self.projectPath, [self getBundleID]];
#endif
    
    self.DBPath = [NSString stringWithFormat:@"%@/%@", self.cachesPath, self.DBFileName];
    
    NSLog(@"PoporFMDB cachesPath:\n%@", self.cachesPath);
    NSLog(@"PoporFMDB mainDBPath:\n%@", self.DBPath);
}

//获取BundleID
- (NSString*)getBundleID {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

@end
