//
//  AcceptDragFileView.h
//  FloatDock
//
//  Created by 王凯庆 on 2020/4/25.
//  Copyright © 2020 王凯庆. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// 1.Demo 源码
// 原文链接：https://blog.csdn.net/chenghxc/article/details/8608547

// 2. 获取 path 方法
// https://stackoverflow.com/questions/31320947/nsurl-returns-files-id-instead-of-files-path

typedef void(^DragViewBlockPString) (NSArray * array);

@interface AcceptDragFileView : NSView

// demo
// dragAppBlock = ^(NSArray * array) {
//     @strongify(self);
//
//     for (int i = 0; i<array.count; i++) {
//         NSString * path = [array[i] path];
//         path = [NSString stringWithFormat:@"file://%@/", path];
//
//         [self.appInfoEntity.appPathArray addObject:path];
//     }
//
//     [self updateWindowFrame];
//     [AppInfoTool updateEntity];
// };
//
@property (nonatomic, copy  ) DragViewBlockPString dragAppBlock;

@end

NS_ASSUME_NONNULL_END
