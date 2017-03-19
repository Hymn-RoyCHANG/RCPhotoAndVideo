//
//  RCMediaPreview.h
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/3/5.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import <UIKit/UIKit.h>

///media data type enum
typedef NS_ENUM(NSInteger, RCMediaType)
{
    ///image instance
    RCMediaTypeImage = 1,
    ///NSURL instance
    RCMediaTypeVideo
};

@interface RCMediaInfo : NSObject

@property (nonatomic, strong) id mediaData;

@property (nonatomic, assign) RCMediaType mediaType;

@end

@interface RCMediaPreview : UIView

@property (nonatomic, readonly) RCMediaInfo *mediaInfo;

- (void)rc_previewWithMediaInfo:(RCMediaInfo *)mediaInfo;

- (void)rc_endPreview;

@end
