# PhotoAndVIdeo
    简单模仿微信轻点拍照／长按录视频
# 使用
## RCMediaViewController
    实际就是添加了一层‘RCMediaCaptureView’，使用方式上和‘UIImagePickerController‘差不多。
```Objective-C
@protocol RCMediaViewControllerDelegate <NSObject>

- (void)rc_mediaController:(RCMediaViewController *)media didFinishPickingMediaWithInfo:(NSDictionary *)info;

- (void)rc_mediaControlelrDidCancel:(RCMediaViewController *)media;
    
@end
```
    
## RCMediaCaptureView
    对拍照和录视频的封装，可以抽出来添加到’其它‘地方,但是尺寸的问题要注意一下...
```Objective-C
~~代理方法
@protocol RCMediaCaptureViewDelegate <NSObject>

- (void)rc_captureView:(RCMediaCaptureView *)capture didFinishPickingMediaWithInfo:(NSDictionary *)info;

- (void)rc_captureViewDidCancel:(RCMediaCaptureView *)capture;
@end

~~实例方法
///开启
- (void)rc_startCapture;
///关闭
- (void)rc_stopCaptture;
```
    
![Photo](https://github.com/Hymn-RoyCHANG/PhotoAndVIdeo/edit/master/images/1.jpeg "拍照界面")
![Photo](https://github.com/Hymn-RoyCHANG/PhotoAndVIdeo/edit/master/images/2.jpeg "录视频界面")
