//
//  RCMediaPreview.m
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/3/5.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import "RCMediaPreview.h"
#import <AVFoundation/AVFoundation.h>

NSString *const RCMeidaPlayStatus = @"status";

@interface RCMediaPreview ()
{
    @private
    AVPlayer *_prePlayer;
    AVPlayerItem *_preItem;
    AVPlayerLayer *_preLayer;
}

@end

@implementation RCMediaPreview

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


#pragma mark - public method

- (void)rc_previewWithMediaInfo:(RCMediaInfo *)mediaInfo;
{
    if(!mediaInfo || !mediaInfo.mediaData)
    {
        return;
    }
    
    _mediaInfo = mediaInfo;
    self.hidden = YES;
    
    switch(_mediaInfo.mediaType)
    {
        case RCMediaTypeImage:
        {
            if([_mediaInfo.mediaData isKindOfClass:[UIImage class]])
            {
                self.layer.contentsGravity = kCAGravityResizeAspectFill;
                self.layer.contents = (id)[((UIImage*)_mediaInfo.mediaData) CGImage];
                self.hidden = NO;
            }
        }
            break;
            
        case RCMediaTypeVideo:
        {
            if([_mediaInfo.mediaData isKindOfClass:[NSURL class]])
            {
                _preItem = [AVPlayerItem playerItemWithURL:_mediaInfo.mediaData];
                _prePlayer = [AVPlayer playerWithPlayerItem:_preItem];
                _preLayer = [AVPlayerLayer playerLayerWithPlayer:_prePlayer];
                _preLayer.frame = self.bounds;
                _preLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                [self.layer addSublayer:_preLayer];
                [self rc_addKVOAndNotifications];
            }
        }
            break;
    }
}

- (void)rc_endPreview
{
    
    switch(_mediaInfo.mediaType)
    {
        case RCMediaTypeImage:
        {
            self.hidden = YES;
            self.layer.contents = nil;
        }
            break;
            
        case RCMediaTypeVideo:
        {
            self.hidden = YES;
            [_prePlayer pause];
            [self rc_removeKVOAndNotifications];
            [_preLayer removeFromSuperlayer];
            _preLayer = nil;
            _preItem = nil;
            _prePlayer = nil;
        }
            break;
    }
    
    _mediaInfo = nil;
}

#pragma mark - kvo and notifications

- (void)rc_addKVOAndNotifications
{
    [_preItem addObserver:self forKeyPath:RCMeidaPlayStatus options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rc_didPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)rc_removeKVOAndNotifications
{
    [_preItem removeObserver:self forKeyPath:RCMeidaPlayStatus];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)rc_didPlayToEnd:(NSNotification *)notify
{
    [_prePlayer seekToTime:CMTimeMakeWithSeconds(0.f, 600) completionHandler:^(BOOL finished) {
        
        [_prePlayer play];
    }];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
{
    if([keyPath isEqualToString:RCMeidaPlayStatus])
    {
        AVPlayerItem *item = (AVPlayerItem*)object;
        switch(item.status)
        {
            case AVPlayerItemStatusReadyToPlay:
            {
                [_prePlayer play];
                self.hidden = NO;
            }
                break;
            default:NSLog(@"\nCan not play for url: %@.", _mediaInfo.mediaData);break;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
