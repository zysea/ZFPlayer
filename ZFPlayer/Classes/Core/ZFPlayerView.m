//
//  ZFPlayerView.m
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

#import "ZFPlayerView.h"
#import "ZFPlayer.h"

@interface ZFPlayerView ()

@property (nonatomic, weak) UIView *fitView;
@end

@implementation ZFPlayerView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)setPlayerView:(UIView *)playerView {
    if (_playerView) [_playerView removeFromSuperview];
    _playerView = playerView;
    if (playerView != nil) [self addSubview:playerView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerView.frame = self.bounds;
}

- (CGSize)presentationSize {
    if (CGSizeEqualToSize(_presentationSize, CGSizeZero)) {
        _presentationSize = self.frame.size;
    }
    return _presentationSize;
}

- (CGSize)scaleSize {
    CGFloat videoWidth = self.presentationSize.width;
    CGFloat videoHeight = self.presentationSize.height;
    CGFloat screenScale = (CGFloat)(ZFPlayerScreenWidth/ZFPlayerScreenHeight);
    CGFloat videoScale = (CGFloat)(videoWidth/videoHeight);
    if (screenScale > videoScale) {
        CGFloat height = ZFPlayerScreenHeight;
        CGFloat width = (CGFloat)(height * videoScale);
        _scaleSize = CGSizeMake(width, height);
    } else {
        CGFloat width = ZFPlayerScreenWidth;
        CGFloat height = (CGFloat)(width / videoScale);
        _scaleSize = CGSizeMake(width, height);
    }
    
    return _scaleSize;
}

@end
