## 1. 捕捉功能综述

* 捕捉会话

AVCaptureSession 用于连接输入和输出的资源，从物理设备如摄像头和麦克风等获取数据流，输出到一个或多个目的地。AVCaptureSession 可以额外配置一个会话预设值（session preset），用于控制捕捉数据的格式和质量，预设值默认值为 AVCaptureSessionPresetHigh。

* 捕捉设备

AVCaptureDevice 为物理设备定义统一接口，以及大量控制方法，获取指定类型的默认设备方法如下

```objectivec
    self.activeVideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
```

* 捕捉设备的输入

不能直接将 AVCaptureDevice 加入到 AVCaptureSession 中，需要封装为 AVCaptureDeviceInput。

```objectivec
    self.captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.activeVideoDevice error:&videoError];
    if (self.captureVideoInput) {
        if ([self.captureSession canAddInput:self.captureVideoInput]){
            [self.captureSession addInput:self.captureVideoInput];
        }
    } else if (videoError) {
        [MTBProgressHUD showErrorWithStatus:@"视频输入接口配置失败，请检查摄像头功能是否正常"];
    }
```

* 捕捉输出

AVCaptureOutput 作为抽象基类提供了捕捉会话数据流的输出目的地，同时定义了此抽象类的高级扩展类。

* AVCaptureStillImageOutput - 静态照片
* AVCaptureMovieFileOutput - 视频
* AVCaptureAudioFileOutput - 音频
* AVCaptureAudioDataOutput - 音频底层数字样本
* AVCaptureVideoDataOutput - 视频底层数字样本

* 捕捉连接

AVCaptureConnection 用于确定哪些输入产生视频，哪些输入产生音频，能够禁用特定连接或访问单独的音频轨道。

* 捕捉预览

AVCaptureVideoPreviewLayer 是一个 CALayer 的子类，可以对捕捉视频数据进行实时预览。

## 2. 实践

### 2.1 创建预览视图

可以直接向一个 view 的 layer 中加入一个 AVCaptureVideoPreviewLayer 对象

```objectivec
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] init];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.previewLayer setSession:self.cameraHelper.captureSession];
    self.previewLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 50);
    [self.previewImageView.layer addSublayer:self.previewLayer];
```

也可以通过 view 的类方法直接换掉 view 的 clayer 实例

```objectivec
+ (Class)layerClass {
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession*)session {
	return [(AVCaptureVideoPreviewLayer*)self.layer session];
}

- (void)setSession:(AVCaptureSession *)session {
	[(AVCaptureVideoPreviewLayer*)self.layer setSession:session];
}
```

#### 2.1.1 坐标转换

AVCaptureVideoPreviewLayer 定义了两个方法用于在屏幕坐标系和设备坐标系之间转换，设备坐标系规定左上角为 （0，0），右下角为（1，1）。

* (CGPoint)captureDevicePointOfInterestForPoint:(CGPoint)pointInLayer 从屏幕坐标系的点转换为设备坐标系
* (CGPoint)pointForCaptureDevicePointOfInterest:(CGPoint)captureDevicePointOfInterest 从设备坐标系的点转换为屏幕坐标系

### 2.2 设置捕捉会话

首先是初始化捕捉会话

```objectivec
    self.captureSession = [[AVCaptureSession alloc]init];
    [self.captureSession setSessionPreset:(self.isVideoMode)?AVCaptureSessionPreset1280x720:AVCaptureSessionPresetPhoto];
```

根据拍摄视频还是拍摄照片选择不同的预设值，然后设置会话输入。

```objectivec
- (void)configSessionInput
{
    // 摄像头输入
    NSError *videoError = [[NSError alloc] init];
    self.activeVideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.flashMode = self.activeVideoDevice.flashMode;
    self.captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.activeVideoDevice error:&videoError];
    if (self.captureVideoInput) {
        if ([self.captureSession canAddInput:self.captureVideoInput]){
            [self.captureSession addInput:self.captureVideoInput];
        }
    } else if (videoError) {
        [MTBProgressHUD showErrorWithStatus:@"视频输入接口配置失败，请检查摄像头功能是否正常"];
    }
    
    if (self.isVideoMode) {
        // 麦克风输入
        NSError *audioError = [[NSError alloc] init];
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&audioError];
        if (audioInput) {
            if ([self.captureSession canAddInput:audioInput]) {
                [self.captureSession addInput:audioInput];
            }
        } else if (audioError) {
            [MTBProgressHUD showErrorWithStatus:@"音频输入接口配置失败，请检查麦克风功能是否正常"];
        }
    }
}
```

对摄像头和麦克风设备均封装为 AVCaptureDeviceInput 后加入到会话中。

然后配置会话输出。

```objectivec
- (void)configSessionOutput
{
    if (self.isVideoMode) {
        // 视频输出
        self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([self.captureSession canAddOutput:self.movieFileOutput]) {
            [self.captureSession addOutput:self.movieFileOutput];
        }
    } else {
        // 图片输出
        self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
        self.imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};// 配置 outputSetting 属性，表示希望捕捉 JPEG 格式的图片
        if ([self.captureSession canAddOutput:self.imageOutput]) {
            [self.captureSession addOutput:self.imageOutput];
        }
    }
}
```

### 2.3 启动和停止会话

可以在一个 VC 的生命周期内启动和停止会话

```objectivec
- (void)startSession {
	if (![self.captureSession isRunning]) {                                 // 1
		dispatch_async([self globalQueue], ^{
			[self.captureSession startRunning];
		});
	}
}

- (void)stopSession {
	if ([self.captureSession isRunning]) {                                  // 2
		dispatch_async([self globalQueue], ^{
			[self.captureSession stopRunning];
		});
	}
}
```

由于这个操作是比较耗时的同步操作，因此建议在异步线程里执行此方法。

### 2.4 权限请求

如果没有获取到相机和麦克风权限，在设置 captureVideoInput 时就会出错。

```objectivec
/// 检测 AVAuthorization 权限
/// 传入待检查的 AVMediaType，AVMediaTypeVideo or AVMediaTypeAudio
/// 返回是否权限可用
- (BOOL)ifAVAuthorizationValid:(NSString *)targetAVMediaType grantedCallback:(void (^)())grantedCallback
{
    NSString *mediaType = targetAVMediaType;
    BOOL result = NO;
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
        switch (authStatus) {
            case AVAuthorizationStatusNotDetermined: { // 尚未请求授权
                [AVCaptureDevice requestAccessForMediaType:targetAVMediaType completionHandler:^(BOOL granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (granted) {
                            grantedCallback();
                        }
                    });
                }];
                break;
            }
            case AVAuthorizationStatusDenied: { // 明确拒绝
                if ([mediaType isEqualToString:AVMediaTypeVideo]) {
                    [METSettingPermissionAlertView showAlertViewWithPermissionType:METSettingPermissionTypeCamera];// 申请相机权限
                } else if ([mediaType isEqualToString:AVMediaTypeAudio]) {
                    [METSettingPermissionAlertView showAlertViewWithPermissionType:METSettingPermissionTypeMicrophone];// 申请麦克风权限
                }
                break;
            }
            case AVAuthorizationStatusRestricted: { // 限制权限更改
                [MTBToastMarker makeToast:[NSString stringWithFormat:@"无法获取%@权限，请检查\"设置->通用->访问限制\"是否禁止了%@的权限更改，并重启应用程序", [mediaType isEqualToString:AVMediaTypeVideo] ? @"相机":@"麦克风", [mediaType isEqualToString:AVMediaTypeVideo] ? @"相机":@"麦克风"]];
                break;
            }
            case AVAuthorizationStatusAuthorized: { // 已授权
                result = YES;
                break;
            }
            default: // 兜底
                break;
        }
    }
    return result;
}
```

可以用这个方法对各种情况进行相应逻辑处理，避免没有权限导致的应用异常，同时由于用户随时可以在后台更改权限设置，应该每次启动相机前进行权限判断。

### 2.5 切换摄像头

大多数 ios 设备都有前后两个摄像头，标识前后摄像头需要用到 AVCaptureDevicePosition 枚举类

```objectivec
typedef NS_ENUM(NSInteger, AVCaptureDevicePosition) {
    AVCaptureDevicePositionUnspecified = 0, // 未知
    AVCaptureDevicePositionBack        = 1, // 后置摄像头
    AVCaptureDevicePositionFront       = 2, // 前置摄像头
}
```

切换摄像头前首先要判断能否切换

```objectivec
- (BOOL)canSwitchCameras {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1;
}
```

接下来获取当前活跃的设备

```objectivec
- (AVCaptureDevice *)activeCamera {
    return self.activeVideoInput.device;
}
```

从 AVCaptureDeviceInput 就可以获取到当前活跃的 device，然后找到与其相对的设备

```objectivec
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position { // 1
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {                              // 2
		if (device.position == position) {
			return device;
		}
	}
	return nil;
}
```

获取到对应的 device 后就可以封装为 AVCaptureInput 对象，然后进行配置

```objectivec
            [self.captureSession beginConfiguration];// 开始配置新的视频输入
            [self.captureSession removeInput:self.captureVideoInput]; // 首先移除旧的 input，才能加入新的 input
            if ([self.captureSession canAddInput:newInput]) {
                [self.captureSession addInput:newInput];
                self.activeVideoDevice = newActiveDevice;
                self.captureVideoInput = newInput;
            } else {
                [self.captureSession addInput:self.captureVideoInput];
            }
            [self.captureSession commitConfiguration];
```

这里 beginConfiguration 和 commitConfiguration 可以使修改操作成为原子性操作，保证设备运行安全。

### 2.6 调整焦距和曝光

这里主要关注对于设置操作的测试以及对设置过程的加锁解锁。

* 对焦

```objectivec
- (BOOL)cameraSupportsTapToFocus {
    return [self.activeVideoInput.device isFocusPointOfInterestSupported];
}

- (void)focusAtPoint:(CGPoint)point {
    AVCaptureDevice *device = self.activeVideoInput.device;
    if (device.isFocusPointOfInterestSupported &&
        [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        } else {
        }
    }
}
```

isFocusPointOfInterestSupported 用于判断设备是否支持兴趣点对焦，isFocusModeSupported 判断是否支持某种对焦模式，AVCaptureFocusModeAutoFocus 即自动对焦，然后进行对焦设置。

* 曝光

曝光与对焦非常类似，核心方法如下

```objectivec
[self.activeVideoDevice setExposurePointOfInterest:focusPoint];
[self.activeVideoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
```

### 2.7 调整闪光灯和手电筒模式

闪光灯（flash）和手电筒（torch）是两个不同的模式，分别定义如下

```objectievc
typedef NS_ENUM(NSInteger, AVCaptureFlashMode) {
    AVCaptureFlashModeOff  = 0,
    AVCaptureFlashModeOn   = 1,
    AVCaptureFlashModeAuto = 2,
}

typedef NS_ENUM(NSInteger, AVCaptureTorchMode) {
    AVCaptureTorchModeOff  = 0,
    AVCaptureTorchModeOn   = 1,
    AVCaptureTorchModeAuto = 2,
}
```

通常在拍照时需要设置闪光灯，而拍视频时需要设置手电筒。具体配置模式代码如下

```objectivec
- (BOOL)cameraHasFlash {
    return [[self activeCamera] hasFlash];
}

- (AVCaptureFlashMode)flashMode {
    return [[self activeCamera] flashMode];
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    AVCaptureDevice *device = [self activeCamera];
    if (device.flashMode != flashMode &&
        [device isFlashModeSupported:flashMode]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        } else {
            // 错误处理
        }
    }
}

- (BOOL)cameraHasTorch {
    return [[self activeCamera] hasTorch];
}

- (AVCaptureTorchMode)torchMode {
    return [[self activeCamera] torchMode];
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode {
    AVCaptureDevice *device = [self activeCamera];
    if (device.torchMode != torchMode &&
        [device isTorchModeSupported:torchMode]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.torchMode = torchMode;
            [device unlockForConfiguration];
        } else {
            // 错误处理
        }
    }
}
```

### 2.8 拍摄静态图片

设置捕捉会话时我们将 AVCaptureStillImageOutput 实例加入到会话中，这个会话可以用来拍摄静态图片。

```objectivec
    AVCaptureConnection *connection = [self.cameraHelper.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection isVideoOrientationSupported]) {
        [connection setVideoOrientation:self.cameraHelper.videoOrientation];
    }
    if (!connection.enabled || !connection.isActive) { // connection 不可用
        // 处理非法情况
        return;
    }
```

这里从 AVCaptureStillImageOutput 实例类中获取到一个 AVCaptureConnection 对象后，需要设置此 connection 的 orientation 值，有两种方法可以获取。

* 通过监听重力感应器修改 orientation

```objectivec
    // 监测重力感应器并调整 orientation
    CMMotionManager *motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 1/15.0;
    if (motionManager.deviceMotionAvailable) {
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler: ^(CMDeviceMotion *motion, NSError *error){
                                               double x = motion.gravity.x;
                                               double y = motion.gravity.y;
                                               if (fabs(y) >= fabs(x)) { // y 轴分量大于 x 轴
                                                   if (y >= 0) { // 顶部向下
                                                       self.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown; // UIDeviceOrientationPortraitUpsideDown;
                                                   } else { // 顶部向上
                                                       self.videoOrientation = AVCaptureVideoOrientationPortrait; // UIDeviceOrientationPortrait;
                                                   }
                                               } else {
                                                   if (x >= 0) { // 顶部向右
                                                       self.videoOrientation = AVCaptureVideoOrientationLandscapeLeft; // UIDeviceOrientationLandscapeRight;
                                                   } else { // 顶部向左
                                                       self.videoOrientation = AVCaptureVideoOrientationLandscapeRight; // UIDeviceOrientationLandscapeLeft;
                                                   }
                                               }
                                           }];
        self.motionManager = motionManager;
    } else {
        self.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
```

要注意这里一些枚举量的名称，AVCaptureVideoOrientationLandscapeLeft 表示 home 键在左，AVCaptureVideoOrientationLandscapeRight 表示 home 键在右。

* 通过 UIDevice 获取

```objectivec
    AVCaptureVideoOrientation orientation;

    switch ([UIDevice currentDevice].orientation) {                         // 3
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
    }

    return orientation;
```

这里也要注意，UIDeviceOrientationLandscapeRight 表示 home 键在左，UIDeviceOrientationLandscapeLeft 表示 home 键在右。

最终调用方法来获取 CMSampleBufferRef,CMSampleBufferRef 是一个 Core Media 定义的 Core Foundation 对象，可以通过 AVCaptureStillImageOutput 的 jpegStillImageNSDataRepresentation 类方法将其转化为 NSData 类型。

```objectivec
    @weakify(self)
    [self.cameraHelper.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        @strongify(self)
        if (!error && imageDataSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            if (!imageData) {return;}
            UIImage *image = [UIImage imageWithData:imageData];
            if (!image) {return;}
    }];
```

### 2.9 保存图片

《AVFoundation 开发秘籍》介绍的 Assets Library 在 ios 8 以后已经被 Photo Library 替代，这里用 Photo Library 实现保存图片的功能。

```objectivec
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *changeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:targetImage];
        NSString *imageIdentifier = changeRequest.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^( BOOL success, NSError * _Nullable error ) {
    }];
```

可以通过保存时返回的 imageIdentifier 从相册里找到这个图片。

### 2.10 视频捕捉

QuickTime 格式的影片，元数据处于影片文件的开头位置，这样可以帮助视频播放器快速读取头文件来确定文件内容、结构和样本位置，但是录制时需要等所有样本捕捉完成才能创建头数据并将其附在文件结尾处。这样一来，如果录制时发生崩溃或中断就会导致无法创建影片头，从而在磁盘生成一个不可读的文件。

因此 AVFoundation 的 AVCaptureMovieFileOutput 类就提供了分段捕捉能力，录制开始时生成最小化的头信息，录制进行中，片段间隔一定周期再次创建头信息，从而逐步完成创建。默认状态下每 10s 写入一个片段，可以通过 movieFragmentInterval 属性来修改。

首先是开启视频拍摄

```objectivec
    AVCaptureConnection *videoConnection = [self.cameraHelper.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:self.cameraHelper.videoOrientation];
    }
    
    if ([videoConnection isVideoStabilizationSupported]) {
        [videoConnection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
    }
    
    [videoConnection setVideoScaleAndCropFactor:1.0];
    if (![self.cameraHelper.movieFileOutput isRecording] && videoConnection.isActive && videoConnection.isEnabled) {
        // 判断视频连接是否可用
        self.countTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshTimeLabel) userInfo:nil repeats:YES];
        NSString *urlString = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%.0f.mov", [[NSDate date] timeIntervalSince1970] * 1000]];
        NSURL *url = [NSURL fileURLWithPath:urlString];
        [self.cameraHelper.movieFileOutput startRecordingToOutputFileURL:url recordingDelegate:self];
        [self.captureButton setTitle:@"结束" forState:UIControlStateNormal];
    } else {
        [MTBProgressHUD showErrorWithStatus:@"视频连接不可用"];
    }
```

设置 PreferredVideoStabilizationMode 可以支持视频拍摄时的稳定性和拍摄质量，但是这一稳定效果只会在拍摄的视频中感受到，预览视频时无法感知。

我们将视频文件临时写入到临时文件中，等待拍摄结束时会调用 AVCaptureFileOutputRecordingDelegate 的 ```(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error``` 方法。此时可以进行保存视频和生成视频缩略图的操作。

```objectivec
- (void)saveVideo:(NSURL *)videoURL
{
    __block NSString *imageIdentifier;
    @weakify(self)
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // 保存视频
        PHAssetChangeRequest *changeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
        imageIdentifier = changeRequest.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^( BOOL success, NSError * _Nullable error ) {
        @strongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self)
            [MTBProgressHUD dismiss];
            [self resetTimeCounter];
            if (!success) {
                // 错误处理
            } else {
                PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[imageIdentifier] options:nil].firstObject;
                if (asset && asset.mediaType == PHAssetMediaTypeVideo) {
                    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                    options.version = PHImageRequestOptionsVersionCurrent;
                    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable obj, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                        @strongify(self)
                        [self resolveAVAsset:obj identifier:asset.localIdentifier];
                    }];
                }
            }
        });
    }];
}
    
- (void)resolveAVAsset:(AVAsset *)asset identifier:(NSString *)identifier
{
    if (!asset) {
        return;
    }
    if (![asset isKindOfClass:[AVURLAsset class]]) {
        return;
    }
    AVURLAsset *urlAsset = (AVURLAsset *)asset;
    NSURL *url = urlAsset.URL;
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES; //捕捉缩略图时考虑视频 orientation 变化，避免错误的缩略图方向
    CMTime snaptime = kCMTimeZero;
    CGImageRef cgImageRef = [generator copyCGImageAtTime:snaptime actualTime:NULL error:nil];
    UIImage *assetImage = [UIImage imageWithCGImage:cgImageRef];
    CGImageRelease(cgImageRef);
}
```