//
//  RCSimpleHUD.h
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/3/11.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, RCSimpleHUDMode)
{
    RCSimpleHUDModeActivity,
    RCSimpleHUDModeText,
};

@interface RCSimpleHUD : UIView

@property (nonatomic, readonly, getter = isVisible) BOOL visible;

@property (nonatomic, readonly) RCSimpleHUDMode currentMode;

- (void)rc_activityWithMessage:(NSString *)msg;

- (void)rc_showMessage:(NSString *)msg;

- (void)rc_hide;

@end
