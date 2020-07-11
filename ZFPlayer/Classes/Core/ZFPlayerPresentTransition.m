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

- (void)transitionWithTransitionType:(ZFPresentTransitionType)type
                         contentView:(ZFPlayerView *)contentView
                       containerView:(UIView *)containerView {
    
    self.type = type;
    self.contentView = contentView;
    self.containerView = containerView;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    switch (self.type) {
        case ZFPresentTransitionTypePresent: {
            [self presentAnimation:transitionContext];
        }
            break;
        case ZFPresentTransitionTypeDismiss: {
            [self dismissAnimation:transitionContext];
        }
            break;
    }
}

/**
 *  实现present动画
 */
- (void)presentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
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
    
    UIColor *tempColor = toVC.view.backgroundColor;
    toVC.view.backgroundColor = [tempColor colorWithAlphaComponent:0];
    toVC.view.alpha = 1;
    [self.delagate zf_orientationWillChange:YES];
    
    CGFloat videoWidth = self.contentView.scaleSize.width;
    CGFloat videoHeight = self.contentView.scaleSize.height;
    CGRect toRect = CGRectMake((ZFPlayerScreenWidth - videoWidth) / 2, (ZFPlayerScreenHeight - videoHeight) / 2, videoWidth, videoHeight);

    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        self.contentView.frame = toRect;
        [self.contentView layoutIfNeeded];
        toVC.view.backgroundColor = [tempColor colorWithAlphaComponent:1.f];
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
        [self.delagate zf_orientationDidChanged:YES];
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
    CGRect toRect = [self.containerView convertRect:self.containerView.bounds toView:toVC.view];
    [fromVC.view convertRect:self.contentView.bounds toView:self.containerView.window];
    [self.delagate zf_orientationWillChange:NO];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromVC.view.alpha = 0;
        self.contentView.frame = toRect;
        [self.contentView layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.containerView addSubview:self.contentView];
        self.contentView.frame = self.containerView.bounds;
        [transitionContext completeTransition:YES];
        [self.delagate zf_orientationDidChanged:NO];
    }];
}

@end
