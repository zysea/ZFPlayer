//
//  ZFDouYinCell.h
//  ZFPlayer_Example
//
//  Created by 紫枫 on 2018/6/4.
//  Copyright © 2018年 紫枫. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZFTableData.h"

@protocol ZFDouYinCellDelegate <NSObject>

- (void)zf_douyinRotation;

@end

@interface ZFDouYinCell : UITableViewCell 

@property (nonatomic, strong) ZFTableData *data;

@property (nonatomic, weak) id<ZFDouYinCellDelegate> delegate;

@end
