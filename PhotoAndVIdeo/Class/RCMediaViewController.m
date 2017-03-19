//
//  RCMediaViewController.m
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/2/28.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import "RCMediaViewController.h"
#import "RCMediaCaptureView.h"

@interface RCMediaViewController ()
{
    RCMediaCaptureView *_captureView;
}

@end

@implementation RCMediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //[self rc_initToolbar];
    
//    _focus = [[RCMediaFocusView alloc] initWithFrame:CGRectMake(100, 100, 80, 80)];
//    [self.view addSubview:_focus];
    
    _captureView = [[RCMediaCaptureView alloc] initWithFrame:self.view.bounds];
    _captureView.captureDelegate = (id<RCMediaCaptureViewDelegate>)self;
    [self.view addSubview:_captureView];
    
    [_captureView rc_startCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if(self.isMovingFromParentViewController)
    {
        [_captureView rc_stopCaptture];
        [_captureView removeFromSuperview];
    }
}

- (void)rc_captureView:(RCMediaCaptureView *)capture didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if([_mediaDelegate respondsToSelector:@selector(rc_mediaController:didFinishPickingMediaWithInfo:)])
    {
        [_mediaDelegate rc_mediaController:self didFinishPickingMediaWithInfo:info];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rc_captureViewDidCancel:(RCMediaCaptureView *)capture
{
    if([_mediaDelegate respondsToSelector:@selector(rc_mediaControlelrDidCancel:)])
    {
        [_mediaDelegate rc_mediaControlelrDidCancel:self];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
