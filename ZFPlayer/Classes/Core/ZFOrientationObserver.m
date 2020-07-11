
//  ZFOrentationObserver.m
//  ZFPlayer
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZFOrientationObserver.h"
#import "ZFLandscapeWindow.h"
#import "ZFPortraitViewController.h"
#import "ZFPlayerConst.h"

@interface UIWindow (CurrentViewController)

/*!
 @method currentViewController
 @return Returns the topViewController in stack of topMostController.
 */
+ (UIViewController*)zf_currentViewController;

@end

@implementation UIWindow (CurrentViewController)

+ (UIViewController*)zf_currentViewController; {
    __block UIWindow *window;
    if (@available(iOS 13, *)) {
        [[UIApplication sharedApplication].connectedScenes enumerateObjectsUsingBlock:^(UIScene * _Nonnull scene, BOOL * _Nonnull scenesStop) {
            if ([scene isKindOfClass: [UIWindowScene class]]) {
                UIWindowScene * windowScene = (UIWindowScene *)scene;
                [windowScene.windows enumerateObjectsUsingBlock:^(UIWindow * _Nonnull windowTemp, NSUInteger idx, BOOL * _Nonnull windowStop) {
                    if ([windowTemp isKeyWindow]) {
                        window = windowTemp;
                        *windowStop = true;
                        *scenesStop = true;
                    }
                }];
            }
        }];
    } else {
        window = [[UIApplication sharedApplication].delegate window];
    }
    UIViewController *topViewController = [window rootViewController];
    while (true) {
        if (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        } else if ([topViewController isKindOfClass:[UINavigationController class]] && [(UINavigationController *)topViewController topViewController]) {
            topViewController = [(UINavigationController *)topViewController topViewController];
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    return topViewController;
}

@end

@interface ZFOrientationObserver () <ZFLandscapeViewControllerDelegate>

@property (nonatomic, weak) ZFPlayerView *view;

@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

@property (nonatomic, strong) UIView *cell;

@property (nonatomic, assign) NSInteger playerViewTag;

@property (nonatomic, assign) ZFRotateType roateType;

@property (nonatomic, strong) UIWindow *previousKeyWindow;

@property (nonatomic, strong) ZFLandscapeWindow *window;

@property (nonatomic, readonly, getter=isRotating) BOOL rotating;
/// current device orientation observer is activie.
@property (nonatomic, assign) BOOL activeDeviceObserver;

@property (nonatomic, strong) ZFPortraitViewController *portraitViewController;

@end

@implementation ZFOrientationObserver

- (instancetype)init {
    self = [super init];
    if (self) {
        _duration = 0.30;
        _fullScreenMode = ZFFullScreenModeLandscape;
        _supportInterfaceOrientation = ZFInterfaceOrientationMaskAllButUpsideDown;
        _allowOrentitaionRotation = YES;
        _roateType = ZFRotateTypeNormal;
        _currentOrientation = UIInterfaceOrientationPortrait;
    }
    return self;
}

- (void)updateRotateView:(ZFPlayerView *)rotateView
           containerView:(UIView *)containerView {
    self.view = rotateView;
    self.containerView = containerView;
}

- (void)cellModelRotateView:(ZFPlayerView *)rotateView rotateViewAtCell:(UIView *)cell playerViewTag:(NSInteger)playerViewTag {
    self.roateType = ZFRotateTypeCell;
    self.view = rotateView;
    self.cell = cell;
    self.playerViewTag = playerViewTag;
}

- (void)cellOtherModelRotateView:(ZFPlayerView *)rotateView containerView:(UIView *)containerView {
    self.roateType = ZFRotateTypeCellOther;
    self.view = rotateView;
    self.containerView = containerView;
}

- (void)dealloc {
    [self removeDeviceOrientationObserver];
}

- (void)addDeviceOrientationObserver {
    self.activeDeviceObserver = YES;
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)removeDeviceOrientationObserver {
    self.activeDeviceObserver = NO;
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)handleDeviceOrientationChange {
    if (self.fullScreenMode == ZFFullScreenModePortrait || !self.allowOrentitaionRotation) return;
    UIInterfaceOrientation currentOrientation = UIInterfaceOrientationUnknown;
    if (UIDeviceOrientationIsValidInterfaceOrientation([UIDevice currentDevice].orientation)) {
        currentOrientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    } else {
        return;
    }

    // Determine that if the current direction is the same as the direction you want to rotate, do nothing
    if (currentOrientation == _currentOrientation && !self.forceDeviceOrientation) return;
    
    switch (currentOrientation) {
        case UIInterfaceOrientationPortrait: {
            if ([self isSupportedPortrait]) {
                [self enterLandscapeFullScreen:UIInterfaceOrientationPortrait animated:YES];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
            if ([self isSupportedLandscapeLeft]) {
                [self enterLandscapeFullScreen:UIInterfaceOrientationLandscapeLeft animated:YES];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeRight: {
            if ([self isSupportedLandscapeRight]) {
                [self enterLandscapeFullScreen:UIInterfaceOrientationLandscapeRight animated:YES];
            }
        }
            break;
        default: break;
    }
}

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        UIInterfaceOrientation val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

#pragma mark - public

- (void)enterLandscapeFullScreen:(UIInterfaceOrientation)orientation animated:(BOOL)animated {
    if (self.fullScreenMode == ZFFullScreenModePortrait) return;
    _currentOrientation = orientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        if (!self.fullScreen) {
            UIView *containerView = nil;
            if (self.roateType == ZFRotateTypeCell) {
                containerView = [self.cell viewWithTag:self.playerViewTag];
            } else {
                containerView = self.containerView;
            }
            CGRect targetRect = [self.view convertRect:self.view.frame toView:containerView.window];
            self.window.landscapeViewController.targetRect = targetRect;
            self.window.landscapeViewController.rotateView = self.view;
            self.window.landscapeViewController.containerView = self.containerView;
            self.fullScreen = YES;
        }
        if (self.orientationWillChange) self.orientationWillChange(self, self.isFullScreen);
    } else {
        self.fullScreen = NO;
    }
    [UIDevice.currentDevice setValue:@(UIDeviceOrientationUnknown) forKey:@"orientation"];
    [UIDevice.currentDevice setValue:@(orientation) forKey:@"orientation"];
}

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
    self.fullScreen = fullScreen;
    if (fullScreen) {
        self.portraitViewController.contentView = self.view;
        self.portraitViewController.containerView = self.containerView;
        [[UIWindow zf_currentViewController] presentViewController:self.portraitViewController animated:YES completion:nil];
    } else {
        [self.portraitViewController dismissViewControllerAnimated:YES completion:^{
        }];
    }
}

- (void)exitFullScreenWithAnimated:(BOOL)animated {
    if (self.fullScreenMode == ZFFullScreenModeLandscape) {
        [self enterLandscapeFullScreen:UIInterfaceOrientationPortrait animated:animated];
    } else if (self.fullScreenMode == ZFFullScreenModePortrait) {
        [self enterPortraitFullScreen:NO animated:animated];
    }
}

#pragma mark - private

/// is support portrait
- (BOOL)isSupportedPortrait {
    return self.supportInterfaceOrientation & ZFInterfaceOrientationMaskPortrait;
}

/// is support landscapeLeft
- (BOOL)isSupportedLandscapeLeft {
    return self.supportInterfaceOrientation & ZFInterfaceOrientationMaskLandscapeLeft;
}

/// is support landscapeRight
- (BOOL)isSupportedLandscapeRight {
    return self.supportInterfaceOrientation & ZFInterfaceOrientationMaskLandscapeRight;
}

- (void)_fixNavigationBarLayout {
    UINavigationController *nav = [self _lookupResponderForClass:UINavigationController.class];
    [nav viewDidAppear:NO];
    [nav.navigationBar layoutSubviews];
}

/// 寻找响应者
- (__kindof UIResponder *_Nullable)_lookupResponderForClass:(Class)cls {
    __kindof UIResponder *_Nullable next = self.containerView.nextResponder;
    while ( next != nil && [next isKindOfClass:cls] == NO ) {
        next = next.nextResponder;
    }
    return next;
}

#pragma mark - ZFLandscapeViewControllerDelegate

- (BOOL)ls_shouldAutorotate {
    if (!self.activeDeviceObserver) {
        return NO;
    }
    if (self.fullScreenMode == ZFFullScreenModePortrait || !self.allowOrentitaionRotation) {
        return NO;
    }
    
    UIDeviceOrientation orientation = UIDevice.currentDevice.orientation;
    if (UIDeviceOrientationIsLandscape(orientation)) {
        UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
        if (keyWindow != self.window && self.previousKeyWindow != keyWindow) {
            self.previousKeyWindow = UIApplication.sharedApplication.keyWindow;
        }
        if (!self.window.isKeyWindow) {
            self.window.hidden = NO;
            [self.window makeKeyAndVisible];
        }
    }
    return YES;
}

- (void)ls_willRotateToOrientation:(UIInterfaceOrientation)orientation {
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        [self performSelector:@selector(_fixNavigationBarLayout) onThread:NSThread.mainThread withObject:@(NO) waitUntilDone:NO];
    }
    self.fullScreen = UIInterfaceOrientationIsLandscape(orientation);
    if (self.orientationWillChange) self.orientationWillChange(self, self.isFullScreen);
}

- (void)ls_didRotateFromOrientation:(UIInterfaceOrientation)orientation {
    if (self.orientationDidChanged) self.orientationDidChanged(self, self.isFullScreen);
    if (!self.isFullScreen) {
        UIView *containerView = nil;
        if (self.roateType == ZFRotateTypeCell) {
            containerView = [self.cell viewWithTag:self.playerViewTag];
        } else {
            containerView = self.containerView;
        }
        [containerView addSubview:self.view];
        self.view.frame = containerView.bounds;
        UIWindow *previousKeyWindow = self.previousKeyWindow ?: UIApplication.sharedApplication.windows.firstObject;
        [previousKeyWindow makeKeyAndVisible];
        self.previousKeyWindow = nil;
        self.window.hidden = YES;
    }
}

#pragma mark - getter

- (ZFLandscapeWindow *)window {
    if (!_window) {
        _window = [ZFLandscapeWindow new];
        _window.landscapeViewController.delegate = self;
        if (@available(iOS 9.0, *)) {
            [_window.rootViewController loadViewIfNeeded];
        } else {
            [_window.rootViewController view];
        }
    }
    return _window;
}

- (ZFPortraitViewController *)portraitViewController {
    if (!_portraitViewController) {
        @weakify(self)
        _portraitViewController = [[ZFPortraitViewController alloc] init];
        if (@available(iOS 9.0, *)) {
            [_portraitViewController loadViewIfNeeded];
        } else {
            [_portraitViewController view];
        }
        _portraitViewController.orientationWillChange = ^(BOOL isFullScreen) {
            @strongify(self)
            self.fullScreen = isFullScreen;
            if (self.orientationWillChange) self.orientationWillChange(self, isFullScreen);
        };
        _portraitViewController.orientationDidChanged = ^(BOOL isFullScreen) {
            @strongify(self)
            self.fullScreen = isFullScreen;
            if (self.orientationDidChanged) self.orientationDidChanged(self, isFullScreen);
        };
    }
    return _portraitViewController;;
}

#pragma mark - setter

- (void)setLockedScreen:(BOOL)lockedScreen {
    _lockedScreen = lockedScreen;
    if (lockedScreen) {
        [self removeDeviceOrientationObserver];
    } else {
        [self addDeviceOrientationObserver];
    }
}

- (UIView *)fullScreenContainerView {
    if (!_fullScreenContainerView) {
        _fullScreenContainerView = [UIApplication sharedApplication].keyWindow;
    }
    return _fullScreenContainerView;
}

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    [self.window.landscapeViewController setNeedsStatusBarAppearanceUpdate];
    [UIViewController attemptRotationToDeviceOrientation];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    _statusBarHidden = statusBarHidden;
    if (self.fullScreenMode == ZFFullScreenModePortrait) {
        self.portraitViewController.statusBarHidden = statusBarHidden;
        [self.portraitViewController setNeedsStatusBarAppearanceUpdate];
    } else if (self.fullScreenMode == ZFFullScreenModeLandscape) {
        self.window.landscapeViewController.statusBarHidden = statusBarHidden;
        [self.window.landscapeViewController setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)setFullScreenStatusBarStyle:(UIStatusBarStyle)fullScreenStatusBarStyle {
    _fullScreenStatusBarStyle = fullScreenStatusBarStyle;
    if (self.fullScreenMode == ZFFullScreenModePortrait) {
        self.portraitViewController.statusBarStyle = fullScreenStatusBarStyle;
        [self.portraitViewController setNeedsStatusBarAppearanceUpdate];
    } else if (self.fullScreenMode == ZFFullScreenModeLandscape) {
        self.window.landscapeViewController.statusBarStyle = fullScreenStatusBarStyle;
        [self.window.landscapeViewController setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)setFullScreenStatusBarAnimation:(UIStatusBarAnimation)fullScreenStatusBarAnimation {
    _fullScreenStatusBarAnimation = fullScreenStatusBarAnimation;
    if (self.fullScreenMode == ZFFullScreenModePortrait) {
        self.portraitViewController.statusBarAnimation = fullScreenStatusBarAnimation;
        [self.portraitViewController setNeedsStatusBarAppearanceUpdate];
    } else if (self.fullScreenMode == ZFFullScreenModeLandscape) {
        self.window.landscapeViewController.statusBarAnimation = fullScreenStatusBarAnimation;
        [self.window.landscapeViewController setNeedsStatusBarAppearanceUpdate];
    }
}

@end
