iOS 中常见传感器如下所示

|类型|作用|
|---|---|
|环境光传感器|感应光照强度|
|距离传感器|感应靠近设备屏幕的物体|
|磁力计传感器|感应周边磁场|
|内部温度传感器|感应设备内部温度（非公开）|
|湿度传感器|感应设备是否进水（非微电子传感器）|
|陀螺仪|感应持握方式|
|加速计|感应设备运动|

其中陀螺仪、加速计和磁力计的数据获取均依赖于 CMMotionManager。

## CMMotionManager

CMMotionManager 是 Core Motion 库的核心类，负责获取和处理手机的运动信息，它可以获取的数据有

* 加速度，标识设备在三维空间中的瞬时加速度
* 陀螺仪，标识设备在三个主轴上的瞬时旋转
* 磁场信息，标识设备相对于地球磁场的方位
* 设备运动数据，标识关键的运动相关属性，包括设备用户引起的加速度、姿态、旋转速率、相对于校准磁场的方位以及相对于重力的方位等，这些数据均来自于 Core Motion 的传感器融合算法，从这一个数据接口即可获取以上三种数据，因此使用较为广泛

CMMotionManager 有 “push” 和 “pull” 两种方式获取数据，push 方式实时获取数据，采样频率高，pull 方式仅在需要数据时采集数据，Apple 更加推荐这种方式获取数据。

### push 方式

将 CMMotionManager 采集频率 interval 设置好以后，CMMotionManager 会在一个操作队列里从特定的 block 返回实时数据更新，这里以设备运动数据 DeviceMotion 为例，代码如下

```objectivec
    CMMotionManager *motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 1/15.0;
    if (motionManager.deviceMotionAvailable) {
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler: ^(CMDeviceMotion *motion, NSError *error){
                                               double x = motion.gravity.x;
                                               double y = motion.gravity.y;
                                               double z = motion.gravity.z;
                                               //NSLog(@"roll:%f, pitch:%f, yew:%f", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw);
                                               NSLog(@"x:%f, y:%f, z:%f", x, y, z);
                                           }];
    }
```

首先要注意尽可能在 app 中只创建一个 CMMotionManager 对象，多个 CMMotionManager 对象会影响从加速计和陀螺仪接受数据的速率。其次，在启动接收设备传感器信息前要检查传感器是否硬件可达，可以用
deviceMotionAvailable 检测硬件是否正常，用 deviceMotionActive 检测当前 CMMotionManager 是否正在提供数据更新。

暂停更新也很容易，直接调用 stopXXXUpdates 即可。

### pull 方式

仍以 DevideMotion 为例，pull 方式代码如下

```objectivec
    CMMotionManager *motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 1/15.0;
    if (motionManager.deviceMotionAvailable) {
        [motionManager startDeviceMotionUpdates];
        double x = motionManager.deviceMotion.gravity.x;
        double y = motionManager.deviceMotion.gravity.y;
        double z = motionManager.deviceMotion.gravity.z;
        NSLog(@"x:%f, y:%f, z:%f", x, y, z);
    }
```

但是这样的方式获取的数据实时性不高，第一次获取可能没有数据，同时要注意不能过于频繁的获取，否则可能引起崩溃。

下面是 CMMotionManager 监听的各类运动信息的简单描述。首先需要明确，iOS 设备的运动传感器使用了如下的坐标系

<img src="http://blog.denivip.ru/wp-content/uploads/2013/07/CoreMotionAxes.png" width=500>

而 DeviceMotion 信息具体对应 iOS 中的 CMDeviceMotion 类，它包含的数据有

#### 1. attitude

attitude 用于标识空间位置的欧拉角（roll、yaw、pitch）和四元数（quaternion）

<img src="http://blog.denivip.ru/wp-content/uploads/2013/07/CoreMotionRotationAxes.png" width=500>

其中绕 x 轴运动称作 pitch（俯仰），绕 y 轴运动称作 roll（滚转），绕 z 轴运动称作 yaw（偏航）。

当设备正面向上、顶部指向正北、水平放置时，pitch、yaw 和 roll 值均为 0，其他变化如下

* 设备顶部上扬，pitch 由 0 递增 pi/2，顶部下沉，由 0 递减 pi/2
* 设备顶部左偏 180 度范围内，yaw 由 0 递增 pi，右偏递减
* 设备左部上旋，roll 由 0 递增 pi，左部下旋，roll 由 0 递减

#### 2. rotationRate

rotationRate 标识设备旋转速率，具体变化如下

* pitch 增加，x > 0，pictch 减少，x < 0
* roll 增加，y > 0，row 减少，y < 0
* yaw 增加，z > 0，yaw 减少，z < 0

#### 3. gravity

gravity 用于标识重力在设备各个方向的分量，具体值的变化遵循如下规律：重力方向始终指向地球，而在设备的三个方向上有不同分量，最大可达 1.0，最小是 0.0。

其中设备顶部向上时 y 轴分量为负数，向下为正数。设备顶部向右时 x 轴分量为正数，向左时 x 轴分量为负数。

#### 4. userAcceleration

userAcceleration 用于标识设备各个方向上的加速度，注意是加速度值，可以标识当前设备正在当前方向上减速 or 加速。

#### 5. magneticField & heading

magneticField 用于标识设备周围的磁场范围和精度，heading 用于标识北极方向。但是要注意，这两个值的检测需要指定 ReferenceFrame，它是一个 CMAttitudeReferenceFrame 的枚举，有四个值

* CMAttitudeReferenceFrameXArbitraryZVertical
* CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
* CMAttitudeReferenceFrameXMagneticNorthZVertical
* CMAttitudeReferenceFrameXTrueNorthZVertical

其中前两个 frame 下磁性返回非法负值，只有选择了 CMAttitudeReferenceFrameXMagneticNorthZVertical 或 CMAttitudeReferenceFrameXTrueNorthZVertical 才有有效值，这两个枚举分别指代磁性北极和地理北极。

## 距离传感器

距离传感器可以检测有物理在靠近或者远离屏幕，使用如下

```objectivec
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateDidChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    
- (void)proximityStateDidChange:(NSNotification *)note
{
    if ([UIDevice currentDevice].proximityState) {
        NSLog(@"Coming");
    } else {
        NSLog(@"Leaving");
    }
}
```

## 环境光传感器

目前没有找到相应的 API，可以采取的思路是通过摄像头获取每一帧，进行光线强度检测

```objectivec
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
            NSDictionary *metadata = [[NSDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
            CFRelease(metadataDict);
            NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *) kCGImagePropertyExifDictionary] mutableCopy];
            float brightnessValue = [[exifMetadata  objectForKey:(NSString *) kCGImagePropertyExifBrightnessValue] floatValue];
            NSLog(@"%f",brightnessValue);
```