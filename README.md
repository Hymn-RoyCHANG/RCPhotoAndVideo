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
    
![Photo](https://github.com/Hymn-RoyCHANG/RCPhotoAndVideo/raw/master/screenshots/1.jpeg "拍照界面")
![Photo](https://github.com/Hymn-RoyCHANG/RCPhotoAndVideo/raw/master/screenshots/2.jpeg "录视频界面")

# MIT License

Copyright (c) 2017 Roy CHANG

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
