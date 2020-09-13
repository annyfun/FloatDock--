//
//  HotKeyTool.m
//  FloatDock
//
//  Created by 王凯庆 on 2020/4/29.
//  Copyright © 2020 王凯庆. All rights reserved.
//

#import "HotKeyTool.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import "FavoriteAppEntity.h"

#import "DataSavePath.h"
#import "NSParameterName.h"
#import "KeyboardConvert.h"


static NSString * FavoriteDBPath = @"favority";

@interface HotKeyTool ()

@property (nonatomic, strong) NSEvent * localEvent1;
@property (nonatomic, strong) NSEvent * localEvent2;
@property (nonatomic, strong) NSEvent * localEvent3;

@property (nonatomic, strong) NSEvent * globalEvent1;
@property (nonatomic, strong) NSEvent * globalEvent2;
@property (nonatomic, strong) NSEvent * globalEvent3;

@end

@implementation HotKeyTool

+ (instancetype)share {
    static dispatch_once_t once;
    static HotKeyTool * instance;
    dispatch_once(&once, ^{
        instance = [self new];
        [instance alertUserGetSystemKeyboardPermission];
        [instance racBindEvent];
        
        instance.favoriteAppArrayEntity = [instance getFavoriteAppArrayEntity];
        instance.favoriteAppsSigleArray = [NSMutableArray<FavoriteAppEntity> new];
        instance.favoriteHotkeyDic      = [NSMutableDictionary new];
        [instance updateHotkeyDic];
        [instance racUpdateFavoriteAppsSigleArray];
        
    });
    return instance;
}

/**
 // 全局监听事件 链接：https://blog.csdn.net/ZhangWangYang/article/details/95952046
 */
- (void)localMonitorKeyboard:(BOOL)enable {
    if (!enable) {
        if (self.localEvent1) {
            [NSEvent removeMonitor:self.localEvent1];
            [NSEvent removeMonitor:self.localEvent2];
            [NSEvent removeMonitor:self.localEvent3];
            
            self.localEvent1 = nil;
            self.localEvent2 = nil;
            self.localEvent3 = nil;
        }
    } else {
        if (self.localEvent1) {
            return;
        }
        @weakify(self);
        // 本地 修饰符
        self.localEvent1 = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
            @strongify(self);
            self.localFlags = event.modifierFlags;
            return event;
        }];
        
        // 本地 键盘
        self.localEvent2 = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
            @strongify(self);
            NSString * key = [KeyboardConvert convertKeyboard:event.keyCode];
            self.localKey = key ? [NSString stringWithFormat:@"%@%@", key, HotKeyEnd] : @"";
            //NSLog(@"设置字符: %@", event.charactersIgnoringModifiers);
            //NSLog(@"设置字符: %@", self.characters);
            return event;
        }];
        
        self.localEvent3 = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyUp handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
            @strongify(self);
            self.localKey = @"";
            return event;
        }];
    }
}

- (void)globalMonitorKeyboard:(BOOL)enable {
    if (!enable) {
        if (self.globalEvent1) {
            [NSEvent removeMonitor:self.globalEvent1];
            [NSEvent removeMonitor:self.globalEvent2];
            [NSEvent removeMonitor:self.globalEvent3];
            
            self.globalEvent1 = nil;
            self.globalEvent2 = nil;
            self.globalEvent3 = nil;
        }
    } else {
        if (self.globalEvent1) {
            return;
        }
        @weakify(self);
        // 全局
        self.globalEvent1 = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^(NSEvent * event) {
            @strongify(self);
            //NSLog(@"event: %@\n\n", event);
            //NSLog(@"全局 修饰符 event: %li", event.modifierFlags);
            
            self.globalFlags = event.modifierFlags;
        }];
        
        self.globalEvent2 = [NSEvent addGlobalMonitorForEventsMatchingMask: NSEventMaskKeyDown handler:^(NSEvent *event){
            //NSLog(@"全局 键盘 event: %@", event.characters);
            @strongify(self);
            
            self.globalKey = [KeyboardConvert convertKeyboard:event.keyCode];
            //NSLog(@"设置字符: %@", event.charactersIgnoringModifiers);
            //NSLog(@"设置字符: %@", self.characters);
        }];
        self.globalEvent3 = [NSEvent addGlobalMonitorForEventsMatchingMask: NSEventMaskKeyUp handler:^(NSEvent *event){
            //NSLog(@"全局 键盘 event: %@", event.characters);
            @strongify(self);
            self.globalKey = @"";
            
        }];
    }
}

// MARK: 监听收集到的键盘事件
- (void)racBindEvent {
    
    @weakify(self);
    // 全局
    RACSignal * signalGlobal = [RACSignal combineLatest:@[RACObserve(self, globalFlags), RACObserve(self, globalKey)] reduce:^id (id flags, NSString * key){
        //@strongify(self);
        NSString * flagText = [KeyboardConvert convertFlag:[flags integerValue]];
        //NSLog(@"全局RAC结果 %@:%@ - %@", flags, flagText, key);
        //NSLog(@"全局RAC结果:%@-%@", flagText, key);
        if (flagText.length > 0 && key.length>0) {
            return [NSString stringWithFormat:@"%@%@", flagText, key];
        } else {
            return nil;
        }
    }];
    [[signalGlobal distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        //NSLog(@"全局监测结果 : %@", x);
        if (x) {
            NSMutableArray * array = self.favoriteHotkeyDic[x];
            for (NSInteger i = 0; i<array.count; i++) {
                FavoriteAppEntity * entity = array[i];
                //NSLog(@"name: %@", entity.name);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self openAppWindows:entity.path];
                });
            }
            //NSLog(@"全局监测结果 : %@ ---------2 \n", x);
        }
    }];
    
    // 本地
    RAC(self, localFlagsKey) = [RACSignal combineLatest:@[RACObserve(self, localFlags), RACObserve(self, localKey)] reduce:^id (id flags, NSString * key){
        //@strongify(self);
        return [NSString stringWithFormat:@"%@%@", [KeyboardConvert convertFlag:[flags integerValue]], key];
        //NSLog(@"本地 %@ - %@", flags, characters);
        //NSString * hotKey = [NSString stringWithFormat:@"%@%@", [self convertFlag:[flags integerValue]], key];
        //return hotKey;
    }];
}

// MARK: 打开APP
- (void)openAppWindows:(NSString * _Nullable)appPath {
    if (!appPath) {
        return;
    }
    appPath                           = appPath.stringByRemovingPercentEncoding;
    NSURL                * url        = [NSURL URLWithString:[appPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
    NSRunningApplication * runningApp = self.runningAppsDic[appPath];
    
    // 显示APP窗口
    if (url) {
        if (@available(macOS 10.15, *)) {
            // 2. 如果没有运行APP, 则打开最后一个窗口
            NSWorkspaceOpenConfiguration * config = [NSWorkspaceOpenConfiguration configuration];
            config.activates = YES;
            [[NSWorkspace sharedWorkspace] openApplicationAtURL:url configuration:config completionHandler:nil];
            
            // 通过某个APP打开某个文件.
            // [[NSWorkspace sharedWorkspace] openFile:@"/Myfiles/README" withApplication:@"TextEdit"];
        } else {
            // 2. 如果没有运行APP, 则打开最后一个窗口
            [[NSWorkspace sharedWorkspace] openURL:url];
        }
    }
    
    // 1. 假如有多个窗口, 则打开所有窗口, 全局运行的需要调换下顺序.
    if (runningApp) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [runningApp unhide];
        });
    }
    
    //    if (runningApp && !runningApp.hidden) { // 隐藏APP窗口
    //        [runningApp hide];
    //    } else {
    //    }
}

- (void)javaScriptDemo {
    //    BOOL scriptSuccess = YES;
    //    {   // 执行 脚本语言, 这个可以设置打开隐藏, 但是还不能拦截系统按键.
    //        NSString * appName = [appPath lastPathComponent];//.stringByRemovingPercentEncoding
    //        if ([appName hasSuffix:@".app"]) {
    //            appName = [appName substringToIndex:appName.length -4];
    //
    //            NSString * script =
    //            [NSString stringWithFormat:@"\n\
    //             tell application \"System Events\" to tell process \"%@\" \n\
    //             if visible is true then \n\
    //             set visible to false \n\
    //             else \n\
    //             tell application \"%@\" to activate \n\
    //             end if \n\
    //             end tell", appName, appName];
    //            NSLog(@"%@", script);
    //
    //            NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:script];
    //
    //            NSDictionary * errorDic;
    //            NSAppleEventDescriptor * returnDescriptor = [scriptObject executeAndReturnError:&errorDic];
    //
    //            if (errorDic) {
    //                scriptSuccess = NO;
    //            }
    //            if (returnDescriptor != NULL) {
    //                // successful execution
    //                if (kAENullEvent != [returnDescriptor descriptorType]) {
    //                    // script returned an AppleScript result
    //                    if (cAEList == [returnDescriptor descriptorType]) {
    //                        // result is a list of other descriptors
    //                    } else {
    //                        // coerce the result to the appropriate ObjC typeŒ
    //                    }
    //                }
    //            } else {
    //                // no script result, handle error here
    //                scriptSuccess = NO;
    //            }
    //
    //        } else {
    //
    //        }
    //    }
    //    //return;
}

// 一个设置快捷键的方法, 好像是APP内部的.
// https://blog.csdn.net/zz110731/article/details/52712372
//#import <Carbon/Carbon.h>
//OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
//
//    EventHotKeyID hotKeyRef;
//
//    GetEventParameter(anEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyRef), NULL, &hotKeyRef);
//
//    unsigned int hotKeyId = hotKeyRef.id;
//
//    switch (hotKeyId) {
//        case 4:
//            // do something
//            NSLog(@"%d", hotKeyId);
//            break;
//        default:
//            break;
//    }
//    return noErr;
//}
//
//// 注册快捷键
//- (void)costomHotKey {
//
//    // 1、声明相关参数
//    EventHotKeyRef myHotKeyRef;
//    EventHotKeyID myHotKeyID;
//    EventTypeSpec myEvenType;
//    myEvenType.eventClass = kEventClassKeyboard;    // 键盘类型
//    myEvenType.eventKind = kEventHotKeyPressed;     // 按压事件
//
//    // 2、定义快捷键
//    myHotKeyID.signature = 'yuus';  // 自定义签名
//    myHotKeyID.id = 4;              // 快捷键ID
//
//    // 3、注册快捷键
//    // 参数一：keyCode; 如18代表1，19代表2，21代表4，49代表空格键，36代表回车键
//    // 快捷键：command+4
//    RegisterEventHotKey(21, cmdKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
//
//    // 快捷键：command+option+4
//    //    RegisterEventHotKey(21, cmdKey + optionKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
//
//    // 5、注册回调函数，响应快捷键
//    InstallApplicationEventHandler(&hotKeyHandler, 1, &myEvenType, NULL, NULL);
//}


// MARK: TOOLS

/**
 1. 如果没有系统权限, 是无法获得全局点击键盘功能的.
 2. 除此之外, mac app 还需打开 app > target > Signing & Capabilities > Signing Certificate.
 3. 要想用下面的代码自动在 [系统设置][安全与隐私][隐私][辅助功能] 中包含本APP,需要关闭SandBox.
 */
/**
 沙盒其他相关
 https://www.jianshu.com/p/c8785cb864e9 macOS-Cocoa开发之沙盒机制及访问Sandbox之外的文件
 */
- (void)alertUserGetSystemKeyboardPermission {
    // MacOS获取辅助功能权限控制鼠标点击事件
    // https://blog.csdn.net/cocos2der/article/details/53393026
    //    let opts = NSDictionary(object: kCFBooleanTrue,
    //                            forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    //                ) as CFDictionary
    //
    //    guard AXIsProcessTrustedWithOptions(opts) == true else { return }
    
    
    NSDictionary *options = @{(__bridge id) kAXTrustedCheckOptionPrompt : (id)kCFBooleanTrue};
    //NSDictionary *options = @{(__bridge id) kAXTrustedCheckOptionPrompt : (id)kCFBooleanFalse};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) options);
    NSLog(@"获取APP读取系统权限 acc : %i", accessibilityEnabled);
    
    if (!accessibilityEnabled) {
        // 打开辅助功能
        NSString *urlString = @"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
    }
    
}


// MARK: 收藏APP数据

- (FavoriteAppArrayEntity *)getFavoriteAppArrayEntity {
    //DataSavePath * path = [DataSavePath share];
    //NSData * data = [NSData dataWithContentsOfFile:path.DBPath];
    NSString * txt = [NSString stringWithContentsOfFile:[self savePath] encoding:NSUTF8StringEncoding error:nil];
    if (txt) {
        //NSString * txt = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //AppInfoArrayEntity * entity = [[AppInfoArrayEntity alloc] initWithData:data error:nil];
        FavoriteAppArrayEntity * entity = [[FavoriteAppArrayEntity alloc] initWithString:txt error:nil];
        if (entity) {
            return entity;
        } else {
            return [FavoriteAppArrayEntity new];
        }
    } else {
        return [FavoriteAppArrayEntity new];
    }
}

- (void)updateEntitySaveJson {
    [self saveAppInfoArrayEntity:self.favoriteAppArrayEntity];
    [self updateHotkeyDic];
}

- (void)updateHotkeyDic {
    [self.favoriteHotkeyDic removeAllObjects];
    for (FavoriteAppEntity * app in self.favoriteAppArrayEntity.array) {
        if (app.hotKey.length > 0 && app.enable) {
            NSMutableArray * array = [self.favoriteHotkeyDic objectForKey:app.hotKey];
            if (array) {
                [array addObject:app];
            } else {
                array = [NSMutableArray new];
                [array addObject:app];
                [self.favoriteHotkeyDic setObject:array forKey:app.hotKey];
            }
            
        }
    }
    
    [self globalMonitorKeyboard:self.favoriteHotkeyDic.count > 0 ? YES:NO ];
}

- (void)saveAppInfoArrayEntity:(FavoriteAppArrayEntity *)entity {
    if (entity) {
        [entity.toJSONString writeToFile:[self savePath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        //[[NSFileManager defaultManager] createDirectoryAtPath:path.cachesPath withIntermediateDirectories:YES attributes:nil error:nil]; // 放在单例中执行
    }
}

- (NSString *)savePath {
    DataSavePath * path = [DataSavePath share];
#if DEBUG
    return [NSString stringWithFormat:@"%@/%@Debug.txt", path.cachesPath, FavoriteDBPath];
#else
    return [NSString stringWithFormat:@"%@/%@.txt", path.cachesPath, FavoriteDBPath];
#endif
}

// 新增APP, 需要顺带更新favoriteAppsSigleArray
- (void)racAddFavoriteAppEntity:(FavoriteAppEntity *)entity {
    static NSString * mKey;
    if (!mKey) {
        mKey = [NSParameterName entity:self.favoriteAppArrayEntity equalTo:self.favoriteAppArrayEntity.array];
    }
    
    [[self.favoriteAppArrayEntity mutableArrayValueForKey:mKey] addObject:entity];
    
    [self updateEntitySaveJson];
    [self racUpdateFavoriteAppsSigleArray];
}

// 删除APP, 需要顺带更新favoriteAppsSigleArray
- (void)racRemoveFavoriteAppEntity:(FavoriteAppEntity *)entity {
    static NSString * mKey;
    if (!mKey) {
        mKey = [NSParameterName entity:self.favoriteAppArrayEntity equalTo:self.favoriteAppArrayEntity.array];
    }
    
    [[self.favoriteAppArrayEntity mutableArrayValueForKey:mKey] removeObject:entity];
    
    [self updateEntitySaveJson];
    [self racUpdateFavoriteAppsSigleArray];
}

- (void)racUpdateFavoriteAppsSigleArray {
    static NSString * mKey;
    if (!mKey) {
        mKey = [NSParameterName entity:self equalTo:self.favoriteAppsSigleArray];
    }
    
    //NSMutableArray * array = [NSMutableArray<FavoriteAppEntity> new];
    [self.favoriteAppsSigleArray removeAllObjects];
    NSMutableSet * set = [NSMutableSet new];
    for (FavoriteAppEntity * app in self.favoriteAppArrayEntity.array) {
        if (![set containsObject:app.name]) {
            [set addObject:app.name];
            //[array addObject:app];
            [[self mutableArrayValueForKey:mKey] addObject:app];
        }
    }
    
}

@end
