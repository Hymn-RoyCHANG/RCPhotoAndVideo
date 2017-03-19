//
//  RCMediaFocusView.m
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/3/3.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import "RCMediaFocusVIew.h"

@interface RCMediaFocusView ()

@property (nonatomic, weak) UIView *cSuperView;

@end

@implementation RCMediaFocusView

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
        self.backgroundColor = [UIColor clearColor];
        
        UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:8];
        
        CAShapeLayer *border = [CAShapeLayer layer];
        border.fillColor = [[UIColor clearColor] CGColor];
        border.strokeColor = [[UIColor greenColor] CGColor];
        border.lineWidth = 3.0f;
        border.strokeStart = 0.f;
        border.strokeEnd = 1.f;
        border.path = [borderPath CGPath];
        [self.layer addSublayer:border];
        
        self.hidden = YES;
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"\n%s", __FUNCTION__);
}

- (void)rc_focusAtPoint:(CGPoint)point onView:(UIView *)theView
{
    self.center = point;
    self.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
    self.hidden = NO;
    
    self.cSuperView = theView;
    theView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:.3f animations:^{
        
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
        CALayer *layer = self.layer.sublayers[0];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.fromValue = @(.1f);
        animation.toValue = @(1.f);
        animation.duration = 0.09f;
        animation.repeatCount = 4.f;
        animation.autoreverses = YES;
        animation.delegate = (id<CAAnimationDelegate>)self;
        [layer addAnimation:animation forKey:nil];
    }];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    self.hidden = YES;
    self.cSuperView.userInteractionEnabled = YES;
}

@end
