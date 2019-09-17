//
//  PLPlayerManager.h
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2019/8/7.
//  Copyright © 2019 紫枫. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZFPlayer/ZFPlayerMediaPlayback.h>
#if __has_include(<PLPlayerKit/PLPlayerKit.h>)
#import <PLPlayerKit/PLPlayerKit.h>

@interface PLPlayerManager : NSObject<ZFPlayerMediaPlayback>

@property (nonatomic, strong, readonly) PLPlayer *player;
@property (nonatomic, strong, readonly) PLPlayerOption *options;
@property (nonatomic, assign) NSTimeInterval timeRefreshInterval;

@end

#endif
