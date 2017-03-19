//
//  RCMediaToolbar.h
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/2/28.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCMediaToolbar;

///回调块
typedef void (^RCMediaCommonHandler)();

typedef NS_ENUM(NSInteger, RCMediaOperation)
{
    ///take picture
    RCMediaOperationPhoto = 10010,
    ///record video
    RCMediaOperationVideo = 10086
};

typedef NS_ENUM(NSInteger, RCToolbarActionType)
{
    ///close
    RCToolbarActionTypeClose,
    ///cancel
    RCToolbarActionTypeCancel,
    ///done
    RCToolbarActionTypeDone,
};

@protocol RCMediaToolbarDelegate <NSObject>

///开始拍照或录视频
- (void)rc_toolbar:(RCMediaToolbar *)toolbar didBeginWithMediaOperation:(RCMediaOperation)operation;

///完成拍照或录视频(拍照一般不调用...)
- (void)rc_toolbar:(RCMediaToolbar *)toolbar didFinishWithMediaOperation:(RCMediaOperation)operation;

///取消，最后要手动调用handler
- (void)rc_toolbarDidCancel:(RCMediaToolbar *)toolbar completionHandler:(RCMediaCommonHandler)completionHandler;

///使用
- (void)rc_toolbarDidFinish:(RCMediaToolbar *)toolbar;

///关闭
- (void)rc_toolbarDidClose:(RCMediaToolbar *)toolbar;

@end

/*!
 * @brief media toolbar class
 * @author Roy CHANG
 */
@interface RCMediaToolbar : UIView

///代理
@property (nonatomic, weak) id<RCMediaToolbarDelegate> delegate;

///最后一次操作
@property (nonatomic, readonly) RCMediaOperation lastOperation;

///根据动作类型获取触发该动作的视图
- (void)rc_viewWithActionType:(RCToolbarActionType)type configureBlock:(void (^)(UIView *view))block;

///拍照或摄像开始UI处理
- (void)rc_beginWithMediaOperation:(RCMediaOperation)operation;

///拍照或摄像结束UI处理
- (void)rc_endWithMediaOperation:(RCMediaOperation)operation;

///显示操作处理
- (void)rc_showTipWithText:(NSString *)text;

@end
