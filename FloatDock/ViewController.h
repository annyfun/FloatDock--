//
//  ViewController.h
//  FloatDock
//
//  Created by 王凯庆 on 2020/4/24.
//  Copyright © 2020 王凯庆. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppInfoEntity.h"

static CGFloat VcHeight = 70;

@interface ViewController : NSViewController

@property (nonatomic, weak  ) AppInfoEntity * appInfoEntity;

@end

