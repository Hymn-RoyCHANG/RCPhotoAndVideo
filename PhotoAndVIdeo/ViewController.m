//
//  ViewController.m
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/2/28.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import "ViewController.h"
#import "RCSimpleHUD.h"
#import "RCMediaViewController.h"

@interface ViewController (){

    UIView *_panView;
}
@property (weak, nonatomic) IBOutlet UIButton *hudBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _panView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
    _panView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:_panView];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rc_pan:)];
    [self.view addGestureRecognizer:pan];
}

- (void)rc_pan:(UIPanGestureRecognizer *)pan
{
    switch(pan.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            //[_hud rc_hide];
            CGPoint point = [pan locationInView:self.view];
            _panView.center = point;
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [pan locationInView:self.view];
            _panView.center = point;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGPoint point = [pan locationInView:self.view];
            CGPoint velocity = [pan velocityInView:self.view];
            CGFloat half_x = 0.5 * 320;
            CGFloat half_y = 0.5 * 568;
            CGFloat x = 0;
            CGFloat y = 0;
            if(velocity.x > 1000 || point.x > half_x)
            {
                x = 288;
            }
            else
            {
                x = 32;
            }
            
            if(velocity.y > 1000 || point.y > half_y)
            {
                y = MIN(536, MAX(32, point.y + point.y * velocity.y * 0.00005));
            }
            else
            {
                y = MAX(32, point.y + point.y * velocity.y * 0.00005);
            }
            
            [UIView animateWithDuration:.25f animations:^{
                
                _panView.center = CGPointMake(x, y);
            }];
        }
            break;
            
        default:break;
    }
    
    [pan setTranslation:CGPointZero inView:self.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.hidden = YES;
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    RCMediaViewController *media = (RCMediaViewController*)segue.destinationViewController;
    media.mediaDelegate = (id<RCMediaViewControllerDelegate>)self;
}

- (void)rc_mediaController:(RCMediaViewController *)media didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"\nInfo: %@.", info.description);
}

- (void)rc_mediaControlelrDidCancel:(RCMediaViewController *)media
{
    NSLog(@"\nCancel...");
}

@end
