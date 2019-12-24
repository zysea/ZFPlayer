//
//  UINavigationController+ZFNavigationBar.m
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2019/12/24.
//  Copyright © 2019 紫枫. All rights reserved.
//

#import "UINavigationController+ZFNavigationBar.h"
#import <objc/runtime.h>
#import "ZFUtilities.h"

@implementation UINavigationController (ZFNavigationBar)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            @selector(viewDidLoad)
        };
        
        for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
            SEL originalSelector = selectors[index];
            SEL swizzledSelector = NSSelectorFromString([@"zf_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
            Method originalMethod = class_getInstanceMethod(self, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
            if (class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    });
}


- (void)zf_viewDidLoad {
    [self zf_viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)didRotate:(NSNotification *)noti {
    CGRect windowFrame = UIScreen.mainScreen.applicationFrame;
    self.navigationBar.frame = CGRectMake(0, iPhoneX?44:20, windowFrame.size.width, 44);
}

@end
