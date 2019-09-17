//
//  PLPlayerManager.m
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2019/8/7.
//  Copyright © 2019 紫枫. All rights reserved.
//

#import "PLPlayerManager.h"
#import <ZFPlayer/ZFPlayerView.h>
#import <ZFPlayer/ZFPlayer.h>
#if __has_include(<PLPlayerKit/PLPlayerKit.h>)

@interface PLPlayerManager () <PLPlayerDelegate>

@property (nonatomic, strong) PLPlayer *player;
@property (nonatomic, strong) PLPlayerOption *options;
@property (nonatomic, assign) BOOL isReadyToPlay;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) void (^seekCompletionHandler)(BOOL finished);

@end

@implementation PLPlayerManager
@synthesize view                           = _view;
@synthesize currentTime                    = _currentTime;
@synthesize totalTime                      = _totalTime;
@synthesize playerPlayTimeChanged          = _playerPlayTimeChanged;
@synthesize playerBufferTimeChanged        = _playerBufferTimeChanged;
@synthesize playerDidToEnd                 = _playerDidToEnd;
@synthesize bufferTime                     = _bufferTime;
@synthesize playState                      = _playState;
@synthesize loadState                      = _loadState;
@synthesize assetURL                       = _assetURL;
@synthesize playerPrepareToPlay            = _playerPrepareToPlay;
@synthesize playerReadyToPlay              = _playerReadyToPlay;
@synthesize playerPlayStateChanged         = _playerPlayStateChanged;
@synthesize playerLoadStateChanged         = _playerLoadStateChanged;
@synthesize seekTime                       = _seekTime;
@synthesize muted                          = _muted;
@synthesize volume                         = _volume;
@synthesize presentationSize               = _presentationSize;
@synthesize isPlaying                      = _isPlaying;
@synthesize rate                           = _rate;
@synthesize isPreparedToPlay               = _isPreparedToPlay;
@synthesize shouldAutoPlay                 = _shouldAutoPlay;
@synthesize scalingMode                    = _scalingMode;
@synthesize playerPlayFailed               = _playerPlayFailed;
@synthesize presentationSizeChanged        = _presentationSizeChanged;

- (void)dealloc {
    [self stop];
}

- (void)destory {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _isPlaying = NO;
    _isPreparedToPlay = NO;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _scalingMode = ZFPlayerScalingModeAspectFit;
        _shouldAutoPlay = YES;
    }
    return self;
}

- (void)prepareToPlay {
    if (!_assetURL) return;
    _isPreparedToPlay = YES;
    [self initializePlayer];
    if (self.shouldAutoPlay) {
        [self play];
    }
}

- (void)play {
    if (!_isPreparedToPlay) {
        [self prepareToPlay];
    } else {
        if (self.playState == ZFPlayerPlayStatePaused || self.playState == ZFPlayerPlayStatePlaying) {
            [self.player resume];
        } else {
            [self.player play];
        }
        _isPlaying = YES;
        self.player.playSpeed = self.rate;
        self.playState = ZFPlayerPlayStatePlaying;
    }
}

- (void)pause {
    [self.player pause];
    _isPlaying = NO;
    self.playState = ZFPlayerPlayStatePaused;
}

- (void)stop {
    [self.player stop];
    [self.player.playerView removeFromSuperview];
    [self destory];
    self.player = nil;
    self->_currentTime = 0;
    self->_totalTime = 0;
    self->_bufferTime = 0;
    self.isReadyToPlay = NO;
    [self.timer invalidate];
    self.timer = nil;
    self.playState = ZFPlayerPlayStatePlayStopped;
}

- (void)replay {
    @weakify(self)
    [self seekToTime:0 completionHandler:^(BOOL finished) {
        @strongify(self)
        [self play];
    }];
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler {
    if (self.currentTime > 0) {
        CMTime seekTime = CMTimeMake(time, 1);
        [self.player seekTo:seekTime];
        self.seekCompletionHandler = completionHandler;
    } else {
        self.seekTime = time;
    }
}

- (void)thumbnailImageAtCurrentTimeCompletionHandler:(void (^ __nullable)(UIImage * _Nullable image))completionHandler {
    [self.player getScreenShotWithCompletionHandler:^(UIImage * _Nullable image) {
        if (completionHandler) completionHandler(image);
    }];
}

- (void)reloadPlayer {
    self.seekTime = self.currentTime;
    [self prepareToPlay];
}

- (void)initializePlayer {
    if (self.player) [self.player stop];
    
    PLPlayFormat format = kPLPLAY_FORMAT_UnKnown;
    NSString *urlString = _assetURL.absoluteString.lowercaseString;
    if ([urlString hasSuffix:@"mp4"]) {
        format = kPLPLAY_FORMAT_MP4;
    } else if ([urlString hasPrefix:@"rtmp:"]) {
        format = kPLPLAY_FORMAT_FLV;
    } else if ([urlString hasSuffix:@".mp3"]) {
        format = kPLPLAY_FORMAT_MP3;
    } else if ([urlString hasSuffix:@".m3u8"]) {
        format = kPLPLAY_FORMAT_M3U8;
    }
    [self.options setOptionValue:@(format) forKey:PLPlayerOptionKeyVideoPreferFormat];
    self.player = [[PLPlayer alloc] initWithURL:_assetURL option:self.options];
    [self.view insertSubview:self.player.playerView atIndex:2];
    self.player.playerView.backgroundColor = [UIColor clearColor];
    self.player.playerView.frame = self.view.bounds;
    self.player.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.player.delegateQueue = dispatch_get_main_queue();
    self.player.delegate = self;
    self.scalingMode = _scalingMode;
}

- (void)timerUpdate {
    if (CMTimeGetSeconds(self.player.currentTime) > 0 && !self.isReadyToPlay) {
        self.isReadyToPlay = YES;
        self.loadState = ZFPlayerLoadStatePlaythroughOK;
    }
    if (self.isPlaying) {
        self->_currentTime = CMTimeGetSeconds(self.player.currentTime) > 0 ? CMTimeGetSeconds(self.player.currentTime) : 0;
        self->_totalTime = CMTimeGetSeconds(self.player.totalDuration);
        if (self.playerPlayTimeChanged) self.playerPlayTimeChanged(self, self->_currentTime, self->_totalTime);
        if (self.playerBufferTimeChanged) self.playerBufferTimeChanged(self, self->_bufferTime);
    }
}

#pragma mark - PLPlayerDelegate

/**
 告知代理对象 PLPlayer 即将开始进入后台播放任务
 
 @param player 调用该代理方法的 PLPlayer 对象
 
 @since v1.0.0
 */
- (void)playerWillBeginBackgroundTask:(nonnull PLPlayer *)player {
    
}

/**
 告知代理对象 PLPlayer 即将结束后台播放状态任务
 
 @param player 调用该方法的 PLPlayer 对象
 
 @since v2.1.1
 */
- (void)playerWillEndBackgroundTask:(nonnull PLPlayer *)player {
    
}

/**
 告知代理对象播放器状态变更
 
 @param player 调用该方法的 PLPlayer 对象
 @param state  变更之后的 PLPlayer 状态
 
 @since v1.0.0
 */
- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state {
    switch (state) {
        case PLPlayerStatusUnknow: {
            self.loadState = ZFPlayerLoadStateUnknown;
        }
            break;
        case PLPlayerStatusPreparing: {
            self.loadState = ZFPlayerLoadStatePrepare;
            if (self.playerPrepareToPlay) self.playerPrepareToPlay(self, self.assetURL);
        }
            break;
        case PLPlayerStatusReady: {
            // 视频开始播放的时候开启计时器
            if (!self.timer) {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeRefreshInterval > 0 ? self.timeRefreshInterval : 0.1 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
                self.player.mute = self.muted;
                if (self.seekTime > 0) {
                    CMTime seekTime = CMTimeMake(self.seekTime, 1);
                    [self.player preStartPosTime:seekTime];
                    self.seekTime = 0; // 滞空, 防止下次播放出错
                }
                [self play];
                if (self.playerReadyToPlay) self.playerReadyToPlay(self, self.assetURL);
            }
        }
            break;
        case PLPlayerStatusCaching: {
            self.loadState = ZFPlayerLoadStateStalled;
            ZFPlayerLog(@"player start caching");
        }
            break;
        case PLPlayerStatusPlaying: {
            self.loadState = ZFPlayerLoadStatePlayable;
        }
            break;
        case PLPlayerStatusCompleted: {
            self.playState = ZFPlayerPlayStatePlayStopped;
            if (self.playerDidToEnd) self.playerDidToEnd(self);
        }
            break;
            
        default:
            break;
    }
}

/**
 告知代理对象播放器因错误停止播放
 
 @param player 调用该方法的 PLPlayer 对象
 @param error  携带播放器停止播放错误信息的 NSError 对象
 
 @since v1.0.0
 */
- (void)player:(nonnull PLPlayer *)player stoppedWithError:(nullable NSError *)error {
    self.playState = ZFPlayerPlayStatePlayFailed;
    ZFPlayerLog(@"player Error : %@", error);
    if (self.playerPlayFailed) self.playerPlayFailed(self, error);
}

/**
 点播已缓冲区域
 
 @param player 调用该方法的 PLPlayer 对象
 @param timeRange  CMTime , 表示从0时开始至当前缓冲区域，单位秒。
 
 @warning 仅对点播有效
 
 @since v2.4.1
 */
- (void)player:(nonnull PLPlayer *)player loadedTimeRange:(CMTime)timeRange {
    NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange);
    self->_bufferTime = durationSeconds;
    if (self.playerBufferTimeChanged) self.playerBufferTimeChanged(self, durationSeconds);
}

/**
 音视频渲染首帧回调通知
 
 @param player 调用该方法的 PLPlayer 对象
 @param firstRenderType 音视频首帧回调通知类型
 
 @since v3.2.1
 */
- (void)player:(nonnull PLPlayer *)player firstRender:(PLPlayerFirstRenderType)firstRenderType {
    
}

/**
 视频宽高数据回调通知
 
 @param player 调用该方法的 PLPlayer 对象
 @param width 视频流宽
 @param height 视频流高
 
 @since v3.3.0
 */
- (void)player:(nonnull PLPlayer *)player width:(int)width height:(int)height {
    self->_presentationSize = CGSizeMake(width, height);
    if (self.presentationSizeChanged) {
        self.presentationSizeChanged(self, self->_presentationSize);
    }
}

/**
 seekTo 完成的回调通知
 
 @param player 调用该方法的 PLPlayer 对象
 
 @since v3.3.0
 */
- (void)player:(nonnull PLPlayer *)player seekToCompleted:(BOOL)isCompleted {
    if (self.seekCompletionHandler) self.seekCompletionHandler(isCompleted);
}

#pragma mark - getter

- (PLPlayerOption *)options {
    if (!_options) {
        _options = [PLPlayerOption defaultOption];
        [_options setOptionValue:@(kPLLogWarning) forKey:PLPlayerOptionKeyLogLevel];
        [_options setOptionValue:@3000 forKey:PLPlayerOptionKeyMaxL1BufferDuration];
        [_options setOptionValue:@1000 forKey:PLPlayerOptionKeyMaxL2BufferDuration];
    }
    return _options;
}

- (ZFPlayerView *)view {
    if (!_view) {
        _view = [[ZFPlayerView alloc] init];
    }
    return _view;
}

- (float)rate {
    return _rate == 0 ?1:_rate;
}

#pragma mark - setter

- (void)setPlayState:(ZFPlayerPlaybackState)playState {
    _playState = playState;
    if (self.playerPlayStateChanged) self.playerPlayStateChanged(self, playState);
}

- (void)setLoadState:(ZFPlayerLoadState)loadState {
    _loadState = loadState;
    if (self.playerLoadStateChanged) self.playerLoadStateChanged(self, loadState);
}

- (void)setAssetURL:(NSURL *)assetURL {
    if (self.player) [self stop];
    _assetURL = assetURL;
    [self prepareToPlay];
}

- (void)setRate:(float)rate {
    _rate = rate;
    self.player.playSpeed = rate;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    self.player.mute = muted;
}

- (void)setVolume:(float)volume {
    _volume = MIN(MAX(0, volume), 3);
    [self.player setVolume:_volume];
}

- (void)setScalingMode:(ZFPlayerScalingMode)scalingMode {
    _scalingMode = scalingMode;
    switch (scalingMode) {
        case ZFPlayerScalingModeNone:
            self.player.playerView.contentMode = UIViewContentModeScaleToFill;
            break;
        case ZFPlayerScalingModeAspectFit:
            self.player.playerView.contentMode = UIViewContentModeScaleAspectFit;
            break;
        case ZFPlayerScalingModeAspectFill:
            self.player.playerView.contentMode = UIViewContentModeScaleAspectFill;
            break;
        case ZFPlayerScalingModeFill:
            self.player.playerView.contentMode = UIViewContentModeScaleToFill;
            break;
        default:
            break;
    }
}

@end

#endif
