//
//  RCMediaCaptureView.m
//  PhotoAndVIdeo
//
//  Created by Roy on 2017/3/3.
//  Copyright © 2017年 Roy CHANG. All rights reserved.
//

#import "RCMediaCaptureView.h"
#import <AVFoundation/AVFoundation.h>
#import "RCMediaFocusView.h"
#import "RCMediaToolbar.h"
#import "RCMediaConstant.h"
#import "RCMediaPreview.h"
#import "RCSimpleHUD.h"

const CGFloat g_Custom_MaxScaleAndCropFactor = 10.f;

typedef NS_ENUM(NSInteger, RCExportMP4Status)
{
    RCExportMP4StatusNormal,
    RCExportMP4StatusProcessing,
    RCExportMP4StatusComplete,
    RCExportMP4StatusFail
    
};

///convert degress to radians e.g. 180° = PI(3.1415926...)
NS_INLINE CGFloat rc_degressToRadians(CGFloat degress)
{
    return degress * M_PI / 180;
}

@interface UIImage (RCImageRotation)

- (UIImage *)rc_imageRotatedByDegress:(CGFloat)degress;

@end

@interface CALayer (RCScaleAnimation)

///default duration is .02f;
- (void)rc_animationWithScale:(CGFloat)scale;

@end

@interface RCMediaCaptureView ()
{
    @private
    
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_audioInput;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureMovieFileOutput *_videoOutput;
    AVCaptureStillImageOutput *_imageOutput;
    AVCaptureVideoPreviewLayer *_captureLayer;
    AVCaptureDevicePosition _devicePosition;
    
    RCMediaFocusView *_focusView;
    RCMediaToolbar *_toolbar;
    RCMediaPreview *_preview;
    
    UIButton *_switchPosition;
    UIButton *_torch;
    UISwitch *_exportMP4;
    
    CGFloat _beginScale;
    CGFloat _finalScale;
    
    NSURL *_videoPath;
    NSURL *_exportMP4Path;
    
    RCExportMP4Status _exportStatus;
    
    RCSimpleHUD *_hud;
}

@end

@implementation RCMediaCaptureView

@synthesize maxScaleAndCropFactor = _maxScaleAndCropFactor;

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [self rc_captureConfigure];
        [self rc_otherConfigure];
        [self rc_addNotifications];
    }
    
    return self;
}

- (void)dealloc
{
    [self rc_release];
    
    NSLog(@"\n%s", __func__);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - property override

- (void)setMaxScaleAndCropFactor:(CGFloat)maxScaleAndCropFactor
{
    _maxScaleAndCropFactor = MAX(1.f, MIN(maxScaleAndCropFactor, _maxScaleAndCropFactor));
}

#pragma mark - configure

- (void)rc_otherConfigure
{
    self.layer.masksToBounds = YES;
    _beginScale = 1.f;
    _finalScale = 1.f;
    _maxScaleAndCropFactor = g_Custom_MaxScaleAndCropFactor;
    
    CGFloat w = CGRectGetWidth(self.bounds);
    _focusView = [[RCMediaFocusView alloc] initWithFrame:CGRectMake(0, 0, w * .25f, w * .25f)];
    [self addSubview:_focusView];
    
    _switchPosition = [UIButton buttonWithType:UIButtonTypeSystem];
    _switchPosition.frame = CGRectMake(w - 60 - 10, 20, 60, 40);
    _switchPosition.tintColor = [UIColor whiteColor];
    _switchPosition.layer.cornerRadius = 8.0f;
    _switchPosition.layer.borderColor = [[UIColor whiteColor] CGColor];
    _switchPosition.layer.borderWidth = 1.0;
    _switchPosition.layer.masksToBounds = YES;
    [_switchPosition setTitle:@"front" forState:UIControlStateNormal];
    [_switchPosition addTarget:self action:@selector(rc_switchPositionCameraEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_switchPosition];
    
    _torch = [UIButton buttonWithType:UIButtonTypeSystem];
    _torch.frame = CGRectMake(w - 60 - 10, 70, 60, 40);
    _torch.tintColor = [UIColor whiteColor];
    _torch.layer.cornerRadius = 8.0f;
    _torch.layer.borderColor = [[UIColor whiteColor] CGColor];
    _torch.layer.borderWidth = 1.0;
    _torch.layer.masksToBounds = YES;
    [_torch.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [_torch setTitle:@"TorchOff" forState:UIControlStateNormal];
    [_torch addTarget:self action:@selector(rc_torchEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_torch];
    
    _exportMP4 = [[UISwitch alloc] initWithFrame:CGRectMake(w - 60 - 10, 120, 60, 40)];
    [self addSubview:_exportMP4];
    UILabel *_exportLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60 - 10, CGRectGetMaxY(_exportMP4.frame) + 5, 60, 20)];
    _exportLabel.font = [UIFont systemFontOfSize:12];
    _exportLabel.textColor = [UIColor greenColor];
    _exportLabel.adjustsFontSizeToFitWidth = YES;
    _exportLabel.text = @"转换MP4";
    [self addSubview:_exportLabel];
    
    _preview = [[RCMediaPreview alloc] initWithFrame:self.bounds];
    _preview.hidden = YES;
    [self addSubview:_preview];
    
    CGFloat h = 80;
    CGSize superSize = self.bounds.size;
    _toolbar = [[RCMediaToolbar alloc] initWithFrame:CGRectMake(0, superSize.height - h - 20, superSize.width, h)];
    _toolbar.delegate = (id<RCMediaToolbarDelegate>)self;
    _toolbar.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.f];
    [self addSubview:_toolbar];
    
    _videoPath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"video_rc_tmp.mov"]];
    _exportMP4Path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"video_rc_tmp.mp4"]];
    
    _exportStatus = RCExportMP4StatusNormal;
    
    _hud = [[RCSimpleHUD alloc] initWithFrame:self.bounds];
    [self addSubview:_hud];
}

- (void)rc_captureConfigure
{
    _session = [[AVCaptureSession alloc] init];
    if([_session canSetSessionPreset:AVCaptureSessionPresetHigh])
    {
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    
    _devicePosition = AVCaptureDevicePositionBack;
    _device = [self rc_deviceWithPosition:AVCaptureDevicePositionBack];
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    if([_session canAddInput:_videoInput])
    {
        [_session addInput:_videoInput];
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    if([_session canAddInput:_audioInput])
    {
        [_session addInput:_audioInput];
    }
    
    _imageOutput = [[AVCaptureStillImageOutput alloc] init];
    [_imageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
    if([_session canAddOutput:_imageOutput])
    {
        [_session addOutput:_imageOutput];
        
        AVCaptureConnection *videoConnection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
        videoConnection.videoScaleAndCropFactor = videoConnection.videoMaxScaleAndCropFactor;
    }
    
    _videoOutput = [[AVCaptureMovieFileOutput alloc] init];
    if([_session canAddOutput:_videoOutput])
    {
        [_session addOutput:_videoOutput];
        
        AVCaptureConnection *videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
        videoConnection.videoScaleAndCropFactor = videoConnection.videoMaxScaleAndCropFactor;
        if(videoConnection.isVideoStabilizationSupported)
        {
            if(RC_iOS_7_Max < NSFoundationVersionNumber)
            {
                videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            else
            {
                if(videoConnection.isVideoStabilizationEnabled)
                {
                    videoConnection.enablesVideoStabilizationWhenAvailable = YES;
                }
            }
        }
    }
    
    _captureLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _captureLayer.frame = self.bounds;
    _captureLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer addSublayer:_captureLayer];
    
    //tap for focus and pin for scale
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rc_focusGestureRecognizer:)];
    [self addGestureRecognizer:tap];
    
    UIPinchGestureRecognizer *pin = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(rc_scaleCropGestureRecognizer:)];
    [self addGestureRecognizer:pin];
}

#pragma mark - Switch Camera

- (void)rc_switchPositionCameraEvent:(UIButton *)btn
{
    if(_device)
    {
        BOOL bSwitch = NO;
        switch(_device.position)
        {
            case AVCaptureDevicePositionBack:
            {
                bSwitch = YES;
                _devicePosition = AVCaptureDevicePositionFront;
                [btn setTitle:@"back" forState:UIControlStateNormal];
                [_torch setTitle:@"TorchOn" forState:UIControlStateNormal];
            }
                break;
                
            case AVCaptureDevicePositionFront:
            {
                bSwitch = YES;
                _devicePosition = AVCaptureDevicePositionBack;
                [btn setTitle:@"front" forState:UIControlStateNormal];
            }
                break;
                
            default:break;
        }
        
        if(bSwitch)
        {
            self.userInteractionEnabled = NO;
            [self rc_freezeScreen:YES];
            AVCaptureDevice *new_device = [self rc_deviceWithPosition:_devicePosition];
            AVCaptureDeviceInput *new_VideoInput = [AVCaptureDeviceInput deviceInputWithDevice:new_device error:nil];
            [_session beginConfiguration];
            [_session removeInput:_videoInput];
            [_session addInput:new_VideoInput];
            [_session commitConfiguration];
            
            _device = new_device;
            _videoInput = new_VideoInput;
            [self rc_freezeScreen:NO];
            self.userInteractionEnabled = YES;
        }
    }
}

- (void)rc_torchEvent:(UIButton *)btn
{
    if(_device && _device.hasTorch)
    {
        AVCaptureTorchMode torchMode = AVCaptureTorchModeOn;
        NSString *title = @"TorchOff";
        if(_device.isTorchActive)
        {
            torchMode = AVCaptureTorchModeOff;
            title = @"TorchOn";
        }
        
        if([_device isTorchModeSupported:torchMode])
        {
            [_device lockForConfiguration:nil];
            [_device setTorchMode:torchMode];
            [_device unlockForConfiguration];
        }
        
        [btn setTitle:title forState:UIControlStateNormal];
    }
}

#pragma mark - notifications

- (void)rc_addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rc_inputportChanged:) name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rc_didStartRunning:) name:AVCaptureSessionDidStartRunningNotification object:nil];
}

- (void)rc_removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:nil];
}

- (void)rc_inputportChanged:(NSNotification *)notify
{
    /*//这歌是默认最大值 适用于 iamgestilloutput
    AVCaptureConnection *imgConnection = [self rc_connectionFromDeviceOutput:_imageOutput];
    _maxScaleAndCropFactor = imgConnection.videoMaxScaleAndCropFactor;//*/
    NSLog(@"\nMaxScaleAndCropFactor: %f", [self rc_connectionFromDeviceOutput:_videoOutput].videoMaxScaleAndCropFactor);
}

- (void)rc_didStartRunning:(NSNotification *)nofity
{
    if(AVCaptureDevicePositionBack == _devicePosition)
    {
        [_focusView rc_focusAtPoint:self.center onView:self];
        [_toolbar rc_showTipWithText:@"轻点拍照长按录视频"];
    }
}

#pragma mark - freeze screen 

- (void)rc_freezeScreen:(BOOL)freeze
{
    [_captureLayer.connection setEnabled:!freeze];
}

#pragma - mark device from device position

- (AVCaptureDevice *)rc_deviceWithPosition:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *device_result = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for(AVCaptureDevice *device in  devices)
    {
        if(position == device.position)
        {
            device_result = device;
            break;
        }
    }
    
    return device_result;
}

#pragma mark - connection from device output

- (AVCaptureConnection *)rc_connectionFromDeviceOutput:(AVCaptureOutput *)output
{
    if(!output)
    {
        return nil;
    }
    
    AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
    return connection;
}

#pragma mark - capture orientation from device orientation

- (AVCaptureVideoOrientation)rc_orientattinFromDeviceOrientation:(UIDeviceOrientation)orientation
{
    AVCaptureVideoOrientation captureOrientatin = (AVCaptureVideoOrientation)orientation;
    switch(orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
        {
            captureOrientatin = AVCaptureVideoOrientationLandscapeRight;
        }
            break;
            
        case UIDeviceOrientationLandscapeRight:
        {
            captureOrientatin = AVCaptureVideoOrientationLandscapeLeft;
        }
            break;
        default:break;
    }
    
    return captureOrientatin;
}

#pragma mark - focus

- (void)rc_focusAtTouchPoint:(CGPoint)point
{
    if(_device && [_device isFocusPointOfInterestSupported])
    {
        CGPoint interestPoint = [_captureLayer captureDevicePointOfInterestForPoint:point];
        [_device lockForConfiguration:nil];
        [_device setFocusPointOfInterest:interestPoint];
        if([_device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
        {
            [_device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        [_device unlockForConfiguration];
    }
}

#pragma mark - UITapGestureRecognizer

- (void)rc_focusGestureRecognizer:(UITapGestureRecognizer *)tap
{
    CGFloat boundaryY = CGRectGetMinY(_toolbar.frame) - CGRectGetHeight(_focusView.frame) * 0.5;
    CGPoint point = [tap locationInView:self];
    if(boundaryY < point.y)
    {
        return;
    }
    
    if(AVCaptureDevicePositionBack == _devicePosition)
    {
        [self rc_focusAtTouchPoint:point];
        [_focusView rc_focusAtPoint:point onView:self];
    }
}

#pragma mark - UIPinchGestureRecognizer

- (void)rc_scaleCropGestureRecognizer:(UIPinchGestureRecognizer *)pin
{
    switch(pin.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            _beginScale = _finalScale;
            NSLog(@"\n**Begin Scale: %f.", _beginScale);
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            _finalScale = MAX(1.f, MIN(_maxScaleAndCropFactor, _beginScale * pin.scale));
            /*[_device lockForConfiguration:nil];
            [_device rampToVideoZoomFactor:_finalScale withRate:1.f];
            [_device unlockForConfiguration];//*/
            [_captureLayer rc_animationWithScale:_finalScale];
        }
            break;
            
        default:;break;
    }
}

#pragma mark - RCMediaToolbarDelegate

///开始拍照或录视频
- (void)rc_toolbar:(RCMediaToolbar *)toolbar didBeginWithMediaOperation:(RCMediaOperation)operation
{
    NSLog(@"\n%d", (int)[UIDevice currentDevice].orientation);
    
    switch(operation)
    {
        case RCMediaOperationPhoto:
        {
            if(_imageOutput.isCapturingStillImage)
            {
                return;
            }
            
            AVCaptureConnection *connection  = [self rc_connectionFromDeviceOutput:_imageOutput];
            if(!connection)
            {
                return;
            }
            
            connection.videoOrientation = [self rc_orientattinFromDeviceOrientation:[UIDevice currentDevice].orientation];
            connection.videoScaleAndCropFactor = _finalScale;
            
            [_imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                
                /*//写入相册信息
                CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                            imageDataSampleBuffer,
                                                                            kCMAttachmentMode_ShouldPropagate);//*/
                NSData *jpgData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [UIImage imageWithData:jpgData];
                image = [image rc_imageRotatedByDegress:90];
                
                [_toolbar rc_endWithMediaOperation:operation];
                
                [self rc_freezeScreen:YES];
                [self rc_stopCaptture];
                
                RCMediaInfo *mediaInfo = [[RCMediaInfo alloc] init];
                mediaInfo.mediaData = image;
                mediaInfo.mediaType = RCMediaTypeImage;
                [_preview rc_previewWithMediaInfo:mediaInfo];
            }];
        }
            break;
            
        case RCMediaOperationVideo:
        {
            AVCaptureConnection *connection = [self rc_connectionFromDeviceOutput:_videoOutput];
            if(!connection)
            {
                return;
            }
            
            _exportStatus = RCExportMP4StatusNormal;
            connection.videoOrientation = [self rc_orientattinFromDeviceOrientation:[UIDevice currentDevice].orientation];
            
            [_videoOutput startRecordingToOutputFileURL:_videoPath recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)self];
        }
            break;
    }
    
    NSLog(@"\nDid Begin With Operation %d.", (int)operation);
}

///完成拍照或录视频
- (void)rc_toolbar:(RCMediaToolbar *)toolbar didFinishWithMediaOperation:(RCMediaOperation)operation
{
    switch(operation)
    {
        case RCMediaOperationPhoto:
        {
            
        }
            break;
            
        case RCMediaOperationVideo:
        {
            [_videoOutput stopRecording];
            [_toolbar rc_endWithMediaOperation:operation];
        }
            break;
    }
    NSLog(@"\nDid Finish With Operation %d.", (int)operation);
}

///使用
- (void)rc_toolbarDidFinish:(RCMediaToolbar *)toolbar
{
    if(_captureDelegate && [_captureDelegate respondsToSelector:@selector(rc_captureView:didFinishPickingMediaWithInfo:)])
    {
        __block NSDictionary *info = nil;
        RCMediaType type = _preview.mediaInfo.mediaType;
        id data = _preview.mediaInfo.mediaData;
        switch(toolbar.lastOperation)
        {
            case RCMediaOperationPhoto:
            {
                if(RCMediaTypeImage == type && data && [data isKindOfClass:[UIImage class]])
                {
                    info = @{RCMediaImageInfo : data};
                }
                
                [_preview rc_endPreview];
                [_captureDelegate rc_captureView:self didFinishPickingMediaWithInfo:info];
            }
                break;
                
            case RCMediaOperationVideo:
            {
                if(_exportMP4.isOn)
                {
                    if(RCMediaTypeVideo == type && data && [data isKindOfClass:[NSURL class]])
                    {
                        [_hud rc_activityWithMessage:@"正在转换MP4...\n(转换失败默认用原始'MOV'格式)"];
                        
                        [self rc_exportMP4FromMOVURL:data withCompletion:^(RCExportMP4Status status) {
                            
                            [_hud rc_hide];
                            if(RCExportMP4StatusComplete == status)
                            {
                                info = @{RCMediaVideoInfo : _exportMP4Path};
                                [_preview rc_endPreview];
                                [[NSFileManager defaultManager] removeItemAtURL:_videoPath error:nil];
                                [_captureDelegate rc_captureView:self didFinishPickingMediaWithInfo:info];
                            }
                            else
                            {// original mov path
                                info = @{RCMediaVideoInfo : data};
                                [_preview rc_endPreview];
                                [_captureDelegate rc_captureView:self didFinishPickingMediaWithInfo:info];
                            }
                        }];
                    }
                    else
                    {
                        [_preview rc_endPreview];
                        [_captureDelegate rc_captureView:self didFinishPickingMediaWithInfo:info];
                    }
                }
                else
                {
                    if(RCMediaTypeVideo == type && data && [data isKindOfClass:[NSURL class]])
                    {
                        info = @{RCMediaVideoInfo : data};
                    }
                    
                    [_preview rc_endPreview];
                    [_captureDelegate rc_captureView:self didFinishPickingMediaWithInfo:info];
                }
            }
                break;
        }
    }
    else
    {
        [_preview rc_endPreview];
    }
}

///取消，最后要手动调用handler
- (void)rc_toolbarDidCancel:(RCMediaToolbar *)toolbar completionHandler:(RCMediaCommonHandler)completionHandler
{
    _finalScale = 1.f;
    [_captureLayer rc_animationWithScale:1.f];
    [self rc_startCapture];
    [self rc_freezeScreen:NO];
    [_preview rc_endPreview];
    
    if(completionHandler)
    {
        completionHandler();
    }
}

///关闭
- (void)rc_toolbarDidClose:(RCMediaToolbar *)toolbar
{
    if(_captureDelegate && [_captureDelegate respondsToSelector:@selector(rc_captureViewDidCancel:)])
    {
        [_captureDelegate rc_captureViewDidCancel:self];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"\nVideo Final URL: %@.", outputFileURL.description);
    
    [self rc_freezeScreen:YES];
    [self rc_stopCaptture];
    
    if(RCMediaOperationPhoto == _toolbar.lastOperation)
    {
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        NSLog(@"\nCancel Video Recording.");
        return;
    }
    
    RCMediaInfo *mediaInfo = [[RCMediaInfo alloc] init];
    mediaInfo.mediaData = outputFileURL;
    mediaInfo.mediaType = RCMediaTypeVideo;
    [_preview rc_previewWithMediaInfo:mediaInfo];
}

#pragma mark - private convert to mp4

- (void)rc_exportMP4FromMOVURL:(NSURL *)url withCompletion:(void (^)(RCExportMP4Status status))complete
{
    if(!url)
    {
        _exportStatus = RCExportMP4StatusFail;
        //goto RC_EXPORTSTATUS_END;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(complete)
            {
                complete(RCExportMP4StatusFail);
            }
        });
        
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    NSString *preset = AVAssetExportPresetMediumQuality;
    if([presets containsObject:AVAssetExportPreset640x480])
    {
        preset = AVAssetExportPreset640x480;
    }
    else if(![presets containsObject:AVAssetExportPresetMediumQuality])
    {
        _exportStatus = RCExportMP4StatusFail;
        asset = nil;
        presets = nil;
        preset = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(complete)
            {
                complete(RCExportMP4StatusFail);
            }
        });
        return;
    }
    AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:asset presetName:preset];
    export.outputURL = _exportMP4Path;
    export.shouldOptimizeForNetworkUse = YES;
    NSArray *fileTypes = [export supportedFileTypes];
    if(![fileTypes containsObject:AVFileTypeMPEG4])
    {
        _exportStatus = RCExportMP4StatusFail;
        export = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(complete)
            {
                complete(RCExportMP4StatusFail);
            }
        });
        return;
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:_exportMP4Path.path])
    {
        BOOL deleted = [[NSFileManager defaultManager] removeItemAtURL:_exportMP4Path error:nil];
        NSLog(@"\nDelete Existed MP4 File %@.", deleted ? @"Success" : @"Fail");
    }
    export.outputFileType = AVFileTypeMPEG4;
    _exportStatus = RCExportMP4StatusProcessing;
    NSLog(@"\nprivate begin export.");
    [export exportAsynchronouslyWithCompletionHandler:^{
        
        switch(export.status)
        {
            case AVAssetExportSessionStatusCompleted:_exportStatus = RCExportMP4StatusComplete;break;
            case AVAssetExportSessionStatusExporting:_exportStatus = RCExportMP4StatusProcessing;break;
            default:_exportStatus = RCExportMP4StatusFail;break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(complete)
            {
                complete(_exportStatus);
            }
        });
        
        NSLog(@"\nprivate end export.");
    }];
}

#pragma mark - public method

- (void)rc_startCapture
{
    if([_session isRunning])
    {
        return;
    }
    
    [_session startRunning];
}

- (void)rc_stopCaptture
{
    if(![_session isRunning])
    {
        return;
    }
    
    [_session stopRunning];
}

- (void)rc_release
{
    [self rc_removeNotifications];
    if([_session isRunning])
    {
        [_session stopRunning];
    }
    
    [_session removeInput:_audioInput];
    [_session removeInput:_videoInput];
    [_session removeOutput:_imageOutput];
    [_session removeOutput:_videoOutput];
    [_captureLayer removeFromSuperlayer];
    
    _audioInput = nil;
    _videoInput = nil;
    _imageOutput = nil;
    _videoOutput = nil;
    _captureLayer = nil;
    _session = nil;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _captureDelegate = nil;
}

@end

@implementation RCMediaInfo

- (void)dealloc
{
    NSLog(@"\n%s", __FUNCTION__);
}

+ (NSString *)rc_mediaTypeString:(RCMediaType)type
{
    NSString *result = @"Unknown";
    switch(type)
    {
        case RCMediaTypeVideo:
        {
            result = @"RCMediaTypeVideo";
        }
            break;
            
        case RCMediaTypeImage:
        {
            result = @"RCMediaTypeImage";
        }
            break;
    }
    
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, RCMediaType: %@, RCMediaData: %@>", NSStringFromClass(self.class), self, [self.class rc_mediaTypeString:self.mediaType], [self.mediaData description]];
}

@end

@implementation UIImage (RCImageRotation)

- (UIImage *)rc_imageRotatedByDegress:(CGFloat)degress
{
    CGSize oldSize = CGSizeMake(CGImageGetWidth([self CGImage]), CGImageGetHeight([self CGImage]));
    CGFloat radians = rc_degressToRadians(degress);
    UIView *rotated_box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, oldSize.width, oldSize.height)];
    rotated_box.transform = CGAffineTransformMakeRotation(radians);
    CGSize rotatedSize = rotated_box.frame.size;
    rotated_box = nil;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotatedSize.width * 0.5, rotatedSize.height * 0.5);
    CGContextRotateCTM(context, radians);
    CGContextScaleCTM(context, 1.f, -1.f);
    CGContextDrawImage(context, CGRectMake(-oldSize.width * 0.5, -oldSize.height * 0.5, oldSize.width, oldSize.height), [self CGImage]);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

@implementation CALayer (RCScaleAnimation)

- (void)rc_animationWithScale:(CGFloat)scale
{
    [self rc_animationWithScale:scale duration:0.02f];
}

- (void)rc_animationWithScale:(CGFloat)scale duration:(CFTimeInterval)duration
{
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    [self setAffineTransform:CGAffineTransformMakeScale(scale, scale)];
    [CATransaction commit];
}

@end
