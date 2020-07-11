//
//  ZFPlayerPersentInteractiveTransition.m
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

#import "ZFPlayerPersentInteractiveTransition.h"

@interface ZFPlayerPersentInteractiveTransition () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, weak) UIViewController *vc;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, assign) CGPoint transitionImgViewCenter;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) CGFloat scrollViewZoomScale;
@property (nonatomic, assign) CGSize scrollViewContentSize;
@property (nonatomic, assign) CGPoint scrollViewContentOffset;
@property (nonatomic, assign) CGRect conentInitialFrame;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) BOOL atFirstPan;

@end

@implementation ZFPlayerPersentInteractiveTransition

- (void)addPanGestureForViewController:(UIViewController *)viewController
                           contentView:(UIView *)contenView
                         containerView:(UIView *)containerView {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    self.panGesture.delegate = self;
    self.vc = viewController;
    self.contentView = contenView;
    self.containerView = containerView;
    self.conentInitialFrame = self.contentView.frame;
    [viewController.view addGestureRecognizer:self.panGesture];
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
    [viewController.view addGestureRecognizer:self.tapGesture];
    self.tapGesture.enabled = self.enablePortraitGesture;
    self.panGesture.enabled = self.enablePortraitGesture;
}

- (void)setEnablePortraitGesture:(BOOL)enablePortraitGesture {
    _enablePortraitGesture = enablePortraitGesture;
    self.tapGesture.enabled = enablePortraitGesture;
    self.panGesture.enabled = enablePortraitGesture;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:[UICollectionView class]]) {
        return NO;
    }
    if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
        if (scrollView.contentOffset.y <= 0 &&
            !scrollView.zooming && self.atFirstPan) {
            return YES;
        }
    }
    return NO;
}

- (void)tapGestureAction {
    [self.vc dismissViewControllerAnimated:YES completion:nil];
    self.interation = NO;
    [self cancelInteractiveTransition];
    [self interPercentFinish];
}

- (void)gestureRecognizeDidUpdate:(UIPanGestureRecognizer *)gestureRecognizer {
    CGFloat scale = 0;
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    CGFloat transitionY = translation.y;
    scale = transitionY / ((gestureRecognizer.view.frame.size.height - 50) / 2);
    if (scale > 1.f) {
        scale = 1.f;
    }
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (scale < 0) {
                [self.vc.view removeGestureRecognizer:self.panGesture];
                [self.vc.view addGestureRecognizer:self.panGesture];
                return;
            }
            self.interation = YES;
            [self.vc dismissViewControllerAnimated:YES completion:nil];
        } break;
        case UIGestureRecognizerStateChanged:
            if (self.interation) {
                if (scale < 0.f) {
                    scale = 0.f;
                }
                CGFloat imageViewScale = 1 - scale * 0.5;
                if (imageViewScale < 0.4) {
                    imageViewScale = 0.4;
                }
                NSLog(@"%f",imageViewScale);

                self.contentView.center = CGPointMake(self.transitionImgViewCenter.x + translation.x, self.transitionImgViewCenter.y + translation.y);
                self.contentView.transform = CGAffineTransformMakeScale(imageViewScale, imageViewScale);
                
                [self updateInterPercent:1 - scale * scale];
                
                [self updateInteractiveTransition:scale];
            }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            if (self.interation) {
                if (scale < 0.f) {
                    scale = 0.f;
                }
                self.interation = NO;
                if (scale < 0.15f){
                    [self cancelInteractiveTransition];
                    [self interPercentCancel];
                } else {
                    [self finishInteractiveTransition];
                    [self interPercentFinish];
                }
            }
            break;
        default:
            if (self.interation) {
                self.interation = NO;
                [self cancelInteractiveTransition];
                [self interPercentCancel];
            }
            break;
    }
}

- (void)beginInterPercent {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
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
    
    UIView *containerView = [transitionContext containerView];
    CGRect tempImageViewFrame = [fromVC.view convertRect:self.contentView.frame toView:toVC.view];
    
    self.bgView = [[UIView alloc] initWithFrame:containerView.bounds];
    self.contentView.frame = tempImageViewFrame;
    self.transitionImgViewCenter = self.contentView.center;
    
    [containerView addSubview:self.bgView];
    [containerView addSubview:self.contentView];
    [containerView addSubview:fromVC.view];
    
    self.bgView.backgroundColor = [UIColor blackColor];
    fromVC.view.backgroundColor = [UIColor clearColor];
}

- (void)updateInterPercent:(CGFloat)scale {
    UIViewController *fromVC = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    fromVC.view.alpha = scale;
    self.bgView.alpha = scale;
}

- (void)interPercentCancel {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [UIView animateWithDuration:0.2f animations:^{
        fromVC.view.alpha = 1;
        self.contentView.transform = CGAffineTransformIdentity;
        self.contentView.center = self.transitionImgViewCenter;
        self.bgView.alpha = 1;
    } completion:^(BOOL finished) {
        fromVC.view.backgroundColor = [UIColor blackColor];
//        self.contentView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
        self.contentView.frame = self.conentInitialFrame;
        if (self.scrollViewContentOffset.y < 0) {
            self.scrollViewContentOffset = CGPointMake(self.scrollViewContentOffset.x, 0);
        }
        [self.vc.view addSubview:self.contentView];
        [self.bgView removeFromSuperview];
        self.bgView = nil;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)interPercentFinish {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
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
    CGRect tempImageViewFrame = self.contentView.frame;
//    self.contentView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    self.contentView.transform = CGAffineTransformIdentity;
    self.contentView.frame = tempImageViewFrame;
    
    CGRect toRect = [self.containerView convertRect:self.containerView.bounds toView:self.containerView.window];
    [self.delagate zf_orientationWillChange:NO];
    [UIView animateWithDuration:0.3f animations:^{
        self.contentView.frame = toRect;
        fromVC.view.alpha = 0;
        self.bgView.alpha = 0;
        toVC.navigationController.navigationBar.alpha = 1;
        [self.contentView layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.delagate zf_orientationDidChanged:NO];
        [self.containerView addSubview:self.contentView];
        self.contentView.frame = self.containerView.bounds;
        [self.bgView removeFromSuperview];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext;
    [self beginInterPercent];
}

@end
