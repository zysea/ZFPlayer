//
//  ZFPlayerPresentTransition.m
//  ZFPlayer
//
// Copyright (c) 2020年 任子丰 ( http://github.com/renzifeng )
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

#import "ZFPlayerPresentTransition.h"
#import "ZFPlayer.h"

@interface ZFPlayerPresentTransition ()

@property (strong, nonatomic) ZFPlayerView *contentView;
@property (assign, nonatomic) ZFPresentTransitionType type;
@property (nonatomic, strong) UIView *containerView;

@end

@implementation ZFPlayerPresentTransition

+ (instancetype)transitionWithTransitionType:(ZFPresentTransitionType)type
                                 contentView:(ZFPlayerView *)contentView
                               containerView:(UIView *)containerView {
    return [[self alloc] initWithTransitionType:type contentView:contentView containerView:containerView];
}

- (instancetype)initWithTransitionType:(ZFPresentTransitionType)type
                           contentView:(ZFPlayerView *)contentView
                         containerView:(UIView *)containerView {
    self = [super init];
    if (self) {
        self.type = type;
        self.contentView = contentView;
        self.containerView = containerView;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    if (self.type == ZFPresentTransitionTypePresent) {
        return 0.45f;
    } else {
        return 0.25f;
    }
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
    switch (self.type) {
        case ZFPresentTransitionTypePresent:
            [self presentAnimation:transitionContext];
            break;
            
        case ZFPresentTransitionTypeDismiss:
            [self dismissAnimation:transitionContext];
            break;
    }
}

/**
 *  实现present动画
 */
- (void)presentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    if ([fromVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)fromVC;
        fromVC = nav.viewControllers.lastObject;
    } else if ([fromVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBar = (UITabBarController *)fromVC;
        if ([tabBar.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)tabBar.selectedViewController;
            fromVC = nav.viewControllers.lastObject;
        } else {
            fromVC = tabBar.selectedViewController;
        }
    }
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    [toVC.view insertSubview:self.contentView atIndex:0];
    CGRect originRect = [self.containerView convertRect:self.contentView.frame toView:toVC.view];
    self.contentView.frame = originRect;
    
    CGFloat videoWidth = self.contentView.scaleSize.width;
    CGFloat videoHeight = self.contentView.scaleSize.height;
    
    
    UIColor *tempColor = toVC.view.backgroundColor;
    toVC.view.backgroundColor = [tempColor colorWithAlphaComponent:0];
    
    [UIView animateWithDuration:0.2 animations:^{
        toVC.view.backgroundColor = [tempColor colorWithAlphaComponent:1.f];
    }];
  [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      self.contentView.frame = CGRectMake((ZFPlayerScreenWidth - videoWidth) / 2, (ZFPlayerScreenHeight - videoHeight) / 2, videoWidth, videoHeight);
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

/**
 *  实现dimiss动画
 */
- (void)dismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if ([toVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)toVC;
        toVC = nav.viewControllers.lastObject;
    } else if ([toVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBar = (UITabBarController *)toVC;
        if ([tabBar.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)tabBar.selectedViewController;
            toVC = nav.viewControllers.lastObject;
        } else {
            toVC = tabBar.selectedViewController;
        }
    }
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    fromVC.view.frame = containerView.bounds;
    [containerView addSubview:fromVC.view];
    [containerView addSubview:self.contentView];
    CGRect originRect = [fromVC.view convertRect:self.contentView.frame toView:toVC.view];
    self.contentView.frame = originRect;
    
    CGRect toRect = [fromVC.view convertRect:self.containerView.frame toView:toVC.view];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromVC.view.alpha = 0;
        self.contentView.frame = toRect;
    } completion:^(BOOL finished) {
        [self.containerView addSubview:self.contentView];
        self.contentView.frame = self.containerView.bounds;
        [transitionContext completeTransition:YES];
    }];
}
@end
