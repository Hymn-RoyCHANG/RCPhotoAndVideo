//
//  RCMediaToolbar.m
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/2/28.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import "RCMediaToolbar.h"

const CGFloat g_Duration = .2f;
const CGFloat g_Media_Btn_Size_Small = 60.0f;
const CGFloat g_Media_Btn_Size_Big = 80.0f;
const NSUInteger g_Min_Video_Duration = 1;
const CGFloat g_LineWidth_Normal = 5.0f;
const CGFloat g_LineWidth_Thick = 30.0f;
const NSTimeInterval g_Max_Video_Duration = 10.0f;//动画的时长(其实就是停止视频录制的时长,可以弄成属性.)
NSString *const kRCProgressAnimation = @"RCStokeEnd";

@interface RCMediaToolbar ()
{
    UIButton *_closeBtn;
    UIButton *_doneBtn;
    UIButton *_cancelBtn;
    UILabel *_tipLabel;
    UIView *_mediaBtn;
    CAShapeLayer *_bgLayer;
    CAShapeLayer *_progressLayer;
    NSDate *_beginTime;
    NSDate *_pressBeginTime;
    BOOL _videoOperationCanceled;
    
    UILabel *_operationTip;
}

@end

@implementation RCMediaToolbar

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGRect validFrame = CGRectZero;
    CGFloat validWidth = screenSize.width;
    CGFloat validHeight = frame.size.height < 44.0f ? 44.0f : frame.size.height;
    validFrame.origin = frame.origin;
    validFrame.size.height = validHeight;
    validFrame.size.width = validWidth;
    
    if(self = [super initWithFrame:validFrame])
    {
        [self rc_initSubviews];
    }
    
    return self;
}

- (void)dealloc
{
    [self rc_release];
    
    NSLog(@"\n%s", __FUNCTION__);
}

#pragma mark - super method

- (void)layoutSubviews
{
    [super layoutSubviews];
}

#pragma mark - init subviews

- (void)rc_initSubviews
{
    _lastOperation = RCMediaOperationPhoto;
    
    CGRect frame = self.bounds;
    
    CGFloat x,y,w,h;
    
    x = 10.0f;
    w = 60;
    h = 40;
    y = (CGRectGetHeight(frame) - h) * 0.5;
    
    _closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _closeBtn.frame = CGRectMake(x, y, w, h);
    _closeBtn.tintColor = [UIColor whiteColor];
    _closeBtn.layer.cornerRadius = 8.0f;
    _closeBtn.layer.borderColor = [[UIColor whiteColor] CGColor];
    _closeBtn.layer.borderWidth = 1.0;
    _closeBtn.layer.masksToBounds = YES;
    [_closeBtn setTitle:@"close" forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(rc_closeBtnEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_closeBtn];
    
    _mediaBtn = [UIView new];
    _mediaBtn.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    _mediaBtn.bounds = CGRectMake(0, 0, w, w);
    _mediaBtn.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _mediaBtn.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *Tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rc_photoGestureRecognizer:)];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(rc_videoGestureRecognizer:)];
    longPress.minimumPressDuration = 0.3;
    [_mediaBtn addGestureRecognizer:Tap];
    [_mediaBtn addGestureRecognizer:longPress];
    [self addSubview:_mediaBtn];
    
    [self rc_initLayerOnView:_mediaBtn];
    
    CGPoint center = _mediaBtn.center;
    x = center.x - w * 0.5;
    y = center.y - h * 0.5;
    
    _cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _cancelBtn.frame = CGRectMake(x, y, w, h);
    _cancelBtn.tintColor = [UIColor whiteColor];
    _cancelBtn.layer.cornerRadius = g_LineWidth_Normal;
    _cancelBtn.layer.borderColor = [[UIColor whiteColor] CGColor];
    _cancelBtn.layer.borderWidth = 1.0;
    _cancelBtn.layer.masksToBounds = YES;
    _cancelBtn.hidden = YES;
    [_cancelBtn setTitle:@"cancel" forState:UIControlStateNormal];
    [_cancelBtn addTarget:self action:@selector(rc_cancelBtnEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self insertSubview:_cancelBtn belowSubview:_mediaBtn];
    
    _doneBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _doneBtn.frame = CGRectMake(x, y, w, h);
    _doneBtn.tintColor = [UIColor whiteColor];
    _doneBtn.layer.cornerRadius = g_LineWidth_Normal;
    _doneBtn.layer.borderColor = [[UIColor whiteColor] CGColor];
    _doneBtn.layer.borderWidth = 1.0;
    _doneBtn.layer.masksToBounds = YES;
    _doneBtn.hidden = YES;
    [_doneBtn setTitle:@"done" forState:UIControlStateNormal];
    [_doneBtn addTarget:self action:@selector(rc_doneBtnEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self insertSubview:_doneBtn belowSubview:_doneBtn];
    
    _operationTip = [[UILabel alloc] init];
    _operationTip.center = CGPointMake(frame.size.width * 0.5f, -5);
    _operationTip.bounds = CGRectMake(0, 0, 200, 20);
//    _operationTip.layer.masksToBounds = YES;
//    _operationTip.layer.cornerRadius = 10;
    _operationTip.font = [UIFont systemFontOfSize:13.f];
    _operationTip.textColor = [UIColor whiteColor];
    _operationTip.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_operationTip];
}

#pragma mark - init sublayers

- (void)rc_initLayerOnView:(UIView *)theView
{
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:theView.bounds];
    
    _bgLayer = [CAShapeLayer layer];
    _bgLayer.frame = theView.bounds;
    _bgLayer.fillColor = [[UIColor whiteColor] CGColor];
    _bgLayer.strokeColor = [[UIColor grayColor] CGColor];
    _bgLayer.lineCap = kCALineCapRound;
    _bgLayer.lineWidth = g_LineWidth_Normal;
    _bgLayer.strokeStart = 0.f;
    _bgLayer.strokeEnd = 1.f;
    _bgLayer.path = [path CGPath];
    [theView.layer addSublayer:_bgLayer];
    
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.frame = theView.bounds;
    _progressLayer.fillColor = [[UIColor clearColor] CGColor];
    _progressLayer.strokeColor = [[UIColor greenColor] CGColor];
    _progressLayer.lineCap = kCALineCapRound;
    _progressLayer.lineWidth = 5.f;
    _progressLayer.strokeStart = 0.f;
    _progressLayer.strokeEnd = 0.f;
    [_bgLayer addSublayer:_progressLayer];
}

#pragma mark - add progress layer animation

- (void)rc_addingProgressAnimation
{
    CGRect frame = CGRectInset(_bgLayer.frame, -_bgLayer.lineWidth * 0.5, -_bgLayer.lineWidth * 0.5);
    frame = CGRectInset(frame, _progressLayer.lineWidth * 0.5, _progressLayer.lineWidth * 0.5);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:frame];
    _progressLayer.path = nil;
    _progressLayer.path = [path CGPath];
    
    _progressLayer.speed = 1.f;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = g_Max_Video_Duration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fromValue = @(0);
    animation.toValue = @(1);
    animation.delegate = (id<CAAnimationDelegate>)self;
    [_progressLayer addAnimation:animation forKey:kRCProgressAnimation];//*/
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStart:(CAAnimation *)anim
{
    if(_delegate && [_delegate respondsToSelector:@selector(rc_toolbar:didBeginWithMediaOperation:)])
    {
        _beginTime = [NSDate date];
        [_delegate rc_toolbar:self didBeginWithMediaOperation:RCMediaOperationVideo];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if(flag)
    {
        NSLog(@"\nPrivate 10s done.");
    }
    else
    {
        NSLog(@"\nPrivate 10s broken.");
    }
    
    NSDate *endTime = [NSDate date];
    int seconds = [endTime timeIntervalSinceDate:_beginTime];
    if(_delegate && [_delegate respondsToSelector:@selector(rc_toolbar:didFinishWithMediaOperation:)])
    {
        if(g_Min_Video_Duration <= seconds)
        {
            [_delegate rc_toolbar:self didFinishWithMediaOperation:RCMediaOperationVideo];
        }
        else
        {
            _lastOperation = RCMediaOperationPhoto;
            [self rc_beginWithMediaOperation:RCMediaOperationPhoto];
            if(_delegate && [_delegate respondsToSelector:@selector(rc_toolbar:didBeginWithMediaOperation:)])
            {
                [_delegate rc_toolbar:self didBeginWithMediaOperation:RCMediaOperationPhoto];
            }
        }
    }
}

#pragma mark - get special view via action type

- (void)rc_viewWithActionType:(RCToolbarActionType)type configureBlock:(void (^)(UIView *view))block
{
    UIView *theView = nil;
    
    switch(type)
    {
        case RCToolbarActionTypeClose:theView = _closeBtn;break;
        case RCToolbarActionTypeDone:theView = _doneBtn;break;
        case RCToolbarActionTypeCancel:theView = _cancelBtn;break;
    }
    
    if(block)
    {
        block(theView);
    }
}

#pragma mark - UI changed method

- (void)rc_beginWithMediaOperation:(RCMediaOperation)operation
{
    switch(operation)
    {
        case RCMediaOperationPhoto:
        {
            self.userInteractionEnabled = NO;
            _progressLayer.delegate = nil;
            _progressLayer.path = nil;
            _progressLayer.strokeEnd = 0.f;
            [UIView animateWithDuration:g_Duration animations:^{
                
                _closeBtn.alpha = 0.f;
                _bgLayer.lineWidth = g_LineWidth_Normal;
            } completion:^(BOOL finished) {
                
            }];
        }
            break;
            
        case RCMediaOperationVideo:
        {
            [UIView animateWithDuration:g_Duration animations:^{
                
                _closeBtn.alpha = 0.f;
                _bgLayer.lineWidth = g_LineWidth_Thick;
            } completion:^(BOOL finished) {
                
                if(finished && !_videoOperationCanceled)
                {
                    [self rc_addingProgressAnimation];
                }
            }];
        }
            break;
    }
}

- (void)rc_endWithMediaOperation:(RCMediaOperation)operation
{
    CGRect cancelFrame = _cancelBtn.frame;
    cancelFrame.origin.x = 10.0f;
    
    CGRect doneFrame = _doneBtn.frame;
    doneFrame.origin.x = CGRectGetWidth(self.frame) - 10 - CGRectGetWidth(doneFrame);
    
    _cancelBtn.hidden = NO;
    _doneBtn.hidden = NO;
    _mediaBtn.hidden = YES;
    
    [UIView animateWithDuration:g_Duration animations:^{
        
        _cancelBtn.frame = cancelFrame;
        _cancelBtn.alpha = 1.f;
        _doneBtn.frame = doneFrame;
        _doneBtn.alpha = 1.0f;
    } completion:^(BOOL finished) {
        
        self.userInteractionEnabled = YES;
    }];
    
    NSLog(@"\nprivate end with operation: %d.", (int)operation);
}

- (void)rc_resetUI
{
    CGPoint center = _mediaBtn.center;
    CGRect frame = _cancelBtn.frame;
    frame.origin.x = center.x - frame.size.width * 0.5;
    _progressLayer.path = nil;
    
    [UIView animateWithDuration:g_Duration animations:^{
        
        _bgLayer.lineWidth = g_LineWidth_Normal;
        _cancelBtn.frame = frame;
        _cancelBtn.alpha = 0.f;
        _doneBtn.frame = frame;
        _doneBtn.alpha = 0.f;
    } completion:^(BOOL finished) {
        
        _mediaBtn.hidden = NO;
        _cancelBtn.hidden = YES;
        _doneBtn.hidden = YES;
        
        [UIView animateWithDuration:g_Duration animations:^{
            
            _closeBtn.alpha = 1.f;
        }];
    }];
}

- (void)rc_showTipWithText:(NSString *)text
{
    _operationTip.text = text;//if nil ?
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(1.f);
    animation.toValue = @(0.f);
    animation.fillMode = kCAFillModeBoth;
    animation.beginTime = CACurrentMediaTime() + 3.f;
    animation.duration = 1.f;
    animation.removedOnCompletion = NO;
    [_operationTip.layer addAnimation:animation forKey:nil];
}

#pragma mark - close button event

- (void)rc_closeBtnEvent:(UIButton *)btn
{
    if(_delegate && [_delegate respondsToSelector:@selector(rc_toolbarDidClose:)])
    {
        [_delegate rc_toolbarDidClose:self];
    }
}

#pragma mark - cancel button event

- (void)rc_cancelBtnEvent:(UIButton *)btn
{
    if(_delegate && [_delegate respondsToSelector:@selector(rc_toolbarDidCancel:completionHandler:)])
    {
        [_delegate rc_toolbarDidCancel:self completionHandler:^{
            
            [self rc_resetUI];
        }];
    }
}

#pragma mark - done button event

- (void)rc_doneBtnEvent:(UIButton *)btn
{
    if(_delegate && [_delegate respondsToSelector:@selector(rc_toolbarDidClose:)])
    {
        [_delegate rc_toolbarDidFinish:self];
    }
}

#pragma mark - UITapGestureRecognizer event

- (void)rc_photoGestureRecognizer:(UITapGestureRecognizer *)tap
{
    if(_delegate && [_delegate respondsToSelector:@selector(rc_toolbar:didBeginWithMediaOperation:)])
    {
        _lastOperation = RCMediaOperationPhoto;
        [self rc_beginWithMediaOperation:RCMediaOperationPhoto];
        [_delegate rc_toolbar:self didBeginWithMediaOperation:RCMediaOperationPhoto];
    }
}

#pragma mark - UILongPressGestureRecognizer event

- (void)rc_videoGestureRecognizer:(UILongPressGestureRecognizer *)press
{
    switch(press.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            _videoOperationCanceled = NO;
            _pressBeginTime = [NSDate date];
            _lastOperation = RCMediaOperationVideo;
            [self rc_beginWithMediaOperation:RCMediaOperationVideo];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            NSDate *endTime = [NSDate date];
            NSTimeInterval seconds = [endTime timeIntervalSinceDate:_pressBeginTime];
            if(seconds > g_Duration)
            {
                [_progressLayer removeAnimationForKey:kRCProgressAnimation];
            }
            else
            {
                _videoOperationCanceled = YES;
                _lastOperation = RCMediaOperationPhoto;
                [self rc_beginWithMediaOperation:RCMediaOperationPhoto];
                if(_delegate && [_delegate respondsToSelector:@selector(rc_toolbar:didBeginWithMediaOperation:)])
                {
                    [_delegate rc_toolbar:self didBeginWithMediaOperation:RCMediaOperationPhoto];
                }
            }
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            NSLog(@"\nChanged");
        }
            break;
            
        default:break;
    }
}

- (void)rc_release
{
    _delegate = nil;
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _closeBtn = nil;
    _cancelBtn = nil;
    _doneBtn = nil;
    _mediaBtn = nil;
    _beginTime = nil;
    _pressBeginTime = nil;
    _bgLayer.path = nil;
    [_bgLayer removeFromSuperlayer];
    _bgLayer = nil;
    _progressLayer.path = nil;
    [_progressLayer removeFromSuperlayer];
    _progressLayer = nil;
}

@end
