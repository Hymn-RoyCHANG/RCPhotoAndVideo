//
//  RCSimpleHUD.m
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/3/11.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import "RCSimpleHUD.h"

#define RC_DEFAULT_TXT  @"帅气的烦恼"
#define RC_ANIMATION_KEY @"RCOpacityAnimation"


@interface UIView (RCLayerOpacityAnimaion)

- (void)rc_animationPause;

- (void)rc_animationResume;

///暂时固定属性
- (void)rc_opacityAnimation;

@end

@interface RCSimpleHUD ()
{
    NSTimer *_timer;
    UILabel *_label;
    CGSize _maxTxtSize;
    RCSimpleHUDMode _mode;
}

@end

@implementation RCSimpleHUD

//@synthesize iMode = _iMode;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];//[UIColor colorWithWhite:0 alpha:.4];
        
        _mode = NSNotFound;
        _label = [[UILabel alloc] init];
        _label.backgroundColor = [UIColor blackColor];
        _label.center = self.center;
        _label.bounds = CGRectZero;
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:15];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 0;
        _label.layer.cornerRadius = 8.0f;
        _label.layer.masksToBounds = YES;
        [self addSubview:_label];
        
        self.hidden = YES;
        
        [self rc_addOrRemoveNotifications:YES];
    }
    
    return self;
}

- (void)dealloc
{
    [self rc_addOrRemoveNotifications:NO];
}

#pragma mark - notifications

- (void)rc_addOrRemoveNotifications:(BOOL)operation
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if(operation)
    {
        [center addObserver:self selector:@selector(rc_appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [center addObserver:self selector:@selector(rc_appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    else
    {
        [center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
        [center removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

- (void)rc_appDidEnterBackground:(NSNotification *)notify
{
    [_label.layer removeAnimationForKey:RC_ANIMATION_KEY];
}

- (void)rc_appDidEnterForeground:(NSNotification *)notify
{
    [_label rc_opacityAnimation];
}

- (BOOL)isVisible
{
    return (!self.hidden && self.alpha == 1);
}

- (RCSimpleHUDMode)currentMode
{
    return _mode;
}

#pragma mark - calculate text size

- (CGSize)rc_sizeForMessage:(NSString *)message
{
    CGFloat size_w = CGRectGetWidth(self.bounds) - 80;
    CGSize maxSize = CGSizeMake(size_w, size_w * 0.75);
    NSDictionary *dic = @{NSFontAttributeName : _label.font};
    CGRect txtRect = [message boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:dic context:nil];
    txtRect = CGRectIntegral(txtRect);
    return CGSizeMake(txtRect.size.width + 10, txtRect.size.height + 10);
}

- (void)rc_configureWithMessage:(NSString *)msg mode:(RCSimpleHUDMode)mode
{
    if(!self.hidden && _mode == mode)
    {
        NSLog(@"\nConfigure Invalid.");
        return;
    }
    
    _mode = mode;
    self.userInteractionEnabled = RCSimpleHUDModeActivity == mode;
    NSString *message = 0 == msg.length ? RC_DEFAULT_TXT : msg;
    CGSize txtSize = [self rc_sizeForMessage:message];
    CGRect txtBound = _label.bounds;
    txtBound.size = txtSize;
    _label.bounds = txtBound;
    _label.text = message;
    
    if(_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    self.alpha = 0.f;
    self.transform = CGAffineTransformMakeScale(2., 2.);
    self.hidden = NO;
    [UIView animateWithDuration:.3 animations:^{
        
        self.alpha = 1.f;
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
        if(RCSimpleHUDModeText == mode)
        {
            _timer = [NSTimer scheduledTimerWithTimeInterval:2.f target:self selector:@selector(rc_autoDismiss:) userInfo:nil repeats:NO];
        }
        
        [_label rc_opacityAnimation];
    }];
}

- (void)rc_autoDismiss:(NSTimer *)timer
{
    [self rc_hide];
}

- (void)rc_activityWithMessage:(NSString *)msg
{
    [self rc_configureWithMessage:msg mode:RCSimpleHUDModeActivity];
}

- (void)rc_showMessage:(NSString *)msg
{
    [self rc_configureWithMessage:msg mode:RCSimpleHUDModeText];
}

- (void)rc_hide
{
    if(_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    [UIView animateWithDuration:.25 animations:^{
        
        self.alpha = 0.f;
        self.transform = CGAffineTransformMakeScale(1.5, 1.5);
    } completion:^(BOOL finished) {
        
        self.hidden = YES;
        self.alpha = 1.f;
        self.transform = CGAffineTransformIdentity;
    }];
}

@end



@implementation UIView (RCLayerOpacityAnimaion)

- (void)rc_animationPause
{
    CFTimeInterval timeOffset = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.layer.speed = 0.f;
    self.layer.timeOffset = timeOffset;
    
    NSLog(@"\nLayer Animation Pause.");
}

- (void)rc_animationResume
{
    CFTimeInterval timeOffset = [self.layer timeOffset];
    self.layer.speed = 1.f;
    self.layer.timeOffset = 0.f;
    self.layer.beginTime = 0.f;
    CFTimeInterval interval = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil] - timeOffset;
    self.layer.beginTime = interval;
    
    NSLog(@"\nLayer Animation Resume.");
}

-(void)rc_opacityAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    animation.repeatCount = HUGE_VALF;
    animation.duration = 0.8;
    animation.autoreverses = YES;
    animation.fromValue = @(0.2);
    animation.toValue = @(1);
    [self.layer addAnimation:animation forKey:RC_ANIMATION_KEY];
}

@end
