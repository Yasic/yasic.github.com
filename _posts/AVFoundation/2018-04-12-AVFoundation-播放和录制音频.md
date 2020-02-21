---
category: AVFoundation
description: "iOS 利用音频会话（audio session）实现可管理的音频环境，音频会话提供简单实用的方法使 OS 得知应用程序应该如何与 iOS 音频环境进行交互。AVFoundation 定义了 7 种分类来描述音频行为"
---

## 1 音频会话

### 1.1 分类 category

iOS 利用音频会话（audio session）实现可管理的音频环境，音频会话提供简单实用的方法使 OS 得知应用程序应该如何与 iOS 音频环境进行交互。AVFoundation 定义了 7 种分类来描述音频行为

|分类|作用|是否允许混音|音频输入输出模式|是否支持后台|是否遵循静音切换|
|---|---|---|---|---|---|
|Ambient|游戏、效率应用程序|支持|O|不支持|不支持|遵循|
|Solo Ambient（default）|游戏、效率应用程序|不支持|O|不支持|遵循|
|Playback|音频和视频播放器|可选|O|支持|不遵循|
|Record|录音机、音频捕捉|不支持|I|支持|不遵循|
|Play and Record|VoIP、语音聊天|可选|I/O|支持|不遵循|
|Audio Processing|离线会话和处理|F|不能播放和录制||不遵循|
|Multi-Route|使用外部硬件的高级 A/V 应用程序|F|I/O||不遵循|

同时可以用 options 和 modes 进一步自定义开发。

#### 1.1.1 options

options 有以下选项

* AVAudioSessionCategoryOptionMixWithOthers

支持 AVAudioSessionCategoryPlayAndRecord, AVAudioSessionCategoryPlayback, 和 AVAudioSessionCategoryMultiRoute，AVAudioSessionCategoryAmbient 自动设置了此选项，AVAudioSessionCategoryOptionDuckOthers 和AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers 也自动设置了此选项。如果使用这个选项激活会话，应用程序的音频不会中断从其他应用程序（如音乐应用程序）的音频，否则激活会话会打断其他音频会话。

* AVAudioSessionCategoryOptionDuckOthers

支持 AVAudioSessionCategoryAmbient，AVAudioSessionCategoryPlayAndRecord, AVAudioSessionCategoryPlayback, 和 AVAudioSessionCategoryMultiRoute。设置此选项能够在播放音频时低音量听到后台播放的其他音频。整个选项周期与会话激活周期一致。

* AVAudioSessionCategoryOptionAllowBluetooth

支持 AVAudioSessionCategoryRecord，AVAudioSessionCategoryPlayAndRecord；允许蓝牙免提设备启用。当应用使用 setPreferredInput:error: 方法选择了蓝牙无线设备作为输入时，也会自动选择相应的蓝牙设备作为输出，使用 MPVolumeView 对象将蓝牙设备作为输出时，输入也会相应改变。

* AVAudioSessionCategoryOptionDefaultToSpeaker

支持 AVAudioSessionCategoryPlayAndRecord；在没有其他的音频路径（如耳机）可以使用的情况下设置这个选项，会议音频将通过设备的内置扬声器播放。当不设置此选项，并且没有其他的音频输出可用或选择时，音频将通过接收器播放。只有 iPhone 设备都配备有一个接收器; iPad 和 iPod touch 设备，此选项没有任何效果

当你的 iPhone 接有多个外接音频设备时（耳塞，蓝牙耳机等），AudioSession 将遵循 last-in wins 的原则来选择外接设备，即声音将被导向最后接入的设备。

当没有接入任何音频设备时，一般情况下声音会默认从扬声器出来，但有一个例外的情况：在 PlayAndRecord 这个 category 下，听筒会成为默认的输出设备。如果你想要改变这个行为，可以提供 MPVolumeView 来让用户切换到扬声器，也可通过 overrideOutputAudioPort 方法来 programmingly 切换到扬声器，也可以修改 category option 为AVAudioSessionCategoryOptionDefaultToSpeaker。

* AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers

支持 AVAudioSessionCategoryPlayAndRecord, AVAudioSessionCategoryPlayback, and AVAudioSessionCategoryMultiRoute，设置此选项能使应用程序的音频会话与其他会话混合，但是会中断使用了 AVAudioSessionModeSpokenAudio 模式的会话。其他应用的音频会在此会话启动后暂停，并在此会话关闭后重新恢复。

在用到 AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers 选项时，中断了其他应用的音频后，自己的应用音频结束播放时，若想恢复其他应用的音频，需要在关闭音频会话的时候设置AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation 选项

```objective_c
[session setActive:NO
       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
             error:<#Your error object, or nil for testing#>];
```

* AVAudioSessionCategoryOptionAllowAirPlay

支持 AVAudioSessionCategoryPlayAndRecord，允许会话在 AirPlay 设备上执行。

#### 1.1.2 mode

mode 用于定制化 audio sessions，如果将分类的 mode 设置不合理会执行默认的模式行为，如将 AVAudioSessionCategoryMultiRoute 类别设置 AVAudioSessionModeGameChat 模式。

* AVAudioSessionModeDefault 默认音频会话模式

* AVAudioSessionModeVoiceChat 如果应用需要执行例如 VoIP 类型的双向语音通信则选择此模式

* AVAudioSessionModeVideoChat 如果应用正在进行在线视频会议，请指定此模式

* AVAudioSessionModeGameChat 该模式由Game Kit 提供给使用 Game Kit 的语音聊天服务的应用程序设置

* AVAudioSessionModeVideoRecording 如果应用正在录制电影，则选此模式

* AVAudioSessionModeMeasurement 如果您的应用正在执行音频输入或输出的测量，请指定此模式

* AVAudioSessionModeMoviePlayback 如果您的应用正在播放电影内容，请指定此模式

* AVAudioSessionModeSpokenAudio 当需要持续播放语音，同时希望在其他程序播放短语音时暂停播放此应用语音，选取此模式

### 1.2 配置音频会话

首先获得指向 AVAudioSession 的单例指针，设置合适的分类，最后激活会话。

```objective_c
    AVAudioSession *session = [AVAudioSession sharedInstance];

    NSError *error;
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error]) {
        NSLog(@"Category Error: %@", [error localizedDescription]);
    }

    if (![session setActive:YES error:&error]) {
        NSLog(@"Activation Error: %@", [error localizedDescription]);
    }
```

## 2. 播放音频

AVAudioPlayer 构建于 Core Audio 的 C-based Audio Queue Services 最顶层，局限性在于无法从网络流播放音频，不能访问原始音频样本，不能满足非常低的时延。

### 2.1 创建 AVAudioPlayer

可以通过 NSData 或本地音频文件的 NSURL 两种方式创建 AVAudioPlayer。

```objective_c
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"rock" withExtension:@"mp3"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:nil];
    if (self.player) {
        [self.player prepareToPlay];
    }
```

创建出 AVAudioPlayer 后建议调用 prepareToPlay 方法，这个方法会取得需要的音频硬件并预加载 Audio Queue 的缓冲区，当然如果不主动调用，执行 play 方法时也会默认调用，但是会造成轻微播放的延时。

### 2.2 对播放进行控制

AVAudioPlayer 的 play 可以播放音频，stop 和 pause 都可以暂停播放，但是 stop 会撤销调用 prepareToPlay 所做的设置。

* 修改播放器的音量：播放器音量独立于系统音量，音量或播放增益定义为 0.0（静音）到 1.0（最大音量）之间的浮点值
* 修改播放器的 pan 值：允许使用立体声播放声音，pan 值从 -1.0（极左）到 1.0（极右），默认值 0.0（居中）
* 调整播放率：0.5（半速）到 2.0（2 倍速）
* 设置 numberOfLoops 实现无缝循环：-1 表示无限循环（音频循环可以是未压缩的线性 PCM 音频，也可以是 AAC 之类的压缩格式音频，MP3 格式不推荐循环）
* 音频计量：当播放发生时从播放器读取音量力度的平均值和峰值

### 2.3 实践

#### 2.3.1 播放音频

```objective_c
        NSTimeInterval delayTime = [self.players[0] deviceCurrentTime] + 0.01;
        for (AVAudioPlayer *player in self.players) {
            [player playAtTime:delayTime];
        }
        self.playing = YES;
```

对于多个需要播放的音频，如果希望同步播放效果，则需要捕捉当前设备时间并添加一个小延时，从而具有一个从开始播放时间计算的参照时间。deviveCurrentTime 是一个独立于系统事件的音频设备的时间值，当有多于 audioPlayer 处于 play 或者 pause 状态时 deviveCurrentTime 会单调增加，没有时置位为 0。playAtTime 的参数 time 要求必须是基于 deviveCurrentTime 且大于等于 deviveCurrentTime 的时间。

#### 2.3.2 暂停播放

```objective_c
        for (AVAudioPlayer *player in self.players) {
            [player stop];
            player.currentTime = 0.0f;
        }
```

暂停时需要将 audioPlayer 的 currentTime 值设置为 0.0，当音频正在播放时，这个值用于标识当前播放位置的偏移，不播放音频时标识重新播放音频的起始偏移。

#### 2.3.4 修改音量、pan值、播放速率和循环

```objective_c
player.enableRate = YES;
player.rate = rate;
player.volume = volume;
player.pan = pan;
player.numberOfLoops = -1;
```

### 2.4 配置音频会话

如果希望应用程序播放音频时屏蔽静音切换动作，需要设置会话分类为 AVAudioSessionCategoryPlayback，但是如果希望按下锁屏后还可以播放，就需要在 plist 里加入一个 Required background modes 类型的数组，在其中添加 App plays audio or streams audio/video using AirPlay。

### 2.5 处理中断事件

中断事件是指电话呼入、闹钟响起、弹出 FaceTime 等，中断事件发生时系统会调用 AVAudioPlayer 的 AVAudioPlayerDelegate 类型的 delegate 的下列方法

```objective_c
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player NS_DEPRECATED_IOS(2_2, 8_0);
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags NS_DEPRECATED_IOS(6_0, 8_0);
```

中断结束调用的方法会带入一个 options 参数，如果是 AVAudioSessionInterruptionOptionShouldResume 则表明可以恢复播放音频了。

### 2.6 处理线路改变

在 iOS 设备上添加或移除音频输入、输出线路时会引发线路改变，最佳实践是，插入耳机时播放动作不改动，拔出耳机时应当暂停播放。

首先需要监听通知

```objective_c
        NSNotificationCenter *nsnc = [NSNotificationCenter defaultCenter];
        [nsnc addObserver:self
                 selector:@selector(handleRouteChange:)
                     name:AVAudioSessionRouteChangeNotification
                   object:[AVAudioSession sharedInstance]];
```

然后判断是旧设备不可达事件，进一步取出旧设备的描述，判断旧设备是否是耳机，再做暂停播放处理。

```objective_c
- (void)handleRouteChange:(NSNotification *)notification {

    NSDictionary *info = notification.userInfo;

    AVAudioSessionRouteChangeReason reason =
        [info[AVAudioSessionRouteChangeReasonKey] unsignedIntValue];

    if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {

        AVAudioSessionRouteDescription *previousRoute =
            info[AVAudioSessionRouteChangePreviousRouteKey];

        AVAudioSessionPortDescription *previousOutput = previousRoute.outputs[0];
        NSString *portType = previousOutput.portType;

        if ([portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [self stop];
            [self.delegate playbackStopped];
        }
    }
}
```

这里 AVAudioSessionPortHeadphones 只包含了有线耳机，无线蓝牙耳机需要判断 AVAudioSessionPortBluetoothA2DP 值。

## 3. 录制音频

AVAudioRecorder 用于负责录制音频。

### 3.1 创建 AVAudioRecorder

创建 AVAudioRecorder 需要以下信息

* 用于写入音频的本地文件 URL
* 用于配置录音会话键值信息的字典
* 用于捕捉错误的 NSError

```objective_c
        NSString *tmpDir = NSTemporaryDirectory();
        NSString *filePath = [tmpDir stringByAppendingPathComponent:@"memo.caf"];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];

        NSDictionary *settings = @{
                                   AVFormatIDKey : @(kAudioFormatAppleIMA4),
                                   AVSampleRateKey : @44100.0f,
                                   AVNumberOfChannelsKey : @1,
                                   AVEncoderBitDepthHintKey : @16,
                                   AVEncoderAudioQualityKey : @(AVAudioQualityMedium)
                                   };

        NSError *error;
        self.recorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:settings error:&error];
        if (self.recorder) {
            self.recorder.delegate = self;
            self.recorder.meteringEnabled = YES;
            [self.recorder prepareToRecord];
        } else {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
```

prepareToRecord 方法执行底层 Audio Queue 初始化必要过程，并在指定位置创建文件。

### 3.2 通用设置参数

* 音频格式

AVFormatIDKey 键对应写入内容的音频格式，它有以下可选值

```objective_c
kAudioFormatLinearPCM
kAudioFormatMPEG4AAC
kAudioFormatAppleLossless
kAudioFormatAppleIMA4
kAudioFormatiLBC
kAudioFormatULaw
```

kAudioFormatLinearPCM 会将未压缩的音频流写入文件，文件体积大。kAudioFormatMPEG4AAC 和 kAudioFormatAppleIMA4 的压缩格式会显著缩小文件，并保证高质量音频内容。但是要注意，制定的音频格式与文件类型应该兼容，例如 wav 格式对应 kAudioFormatLinearPCM 值。

* 采样率

AVSampleRateKey 指示采样率，即对输入的模拟音频信号每一秒内的采样数。常用值 8000，16000，22050，44100。

* 通道数

AVNumberOfChannelsKey 指示定义记录音频内容的通道数，除非使用外部硬件录制，否则通常选择单声道。

* 编码位元深度

AVEncoderBitDepthHintKey 指示编码位元深度，从 8 到 32。

* 音频质量

AVEncoderAudioQualityKey 指示音频质量，可选值有 AVAudioQualityMin, AVAudioQualityLow, AVAudioQualityMedium, AVAudioQualityHigh, AVAudioQualityMax。

### 3.3 实践

#### 3.3.1 配置音频会话

录音和播放应用应当使用 AVAudioSessionCategoryPlayAndRecord 分类来配置会话。

```objective_c
    AVAudioSession *session = [AVAudioSession sharedInstance];

    NSError *error;
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error]) {
        NSLog(@"Category Error: %@", [error localizedDescription]);
    }

    if (![session setActive:YES error:&error]) {
        NSLog(@"Activation Error: %@", [error localizedDescription]);
    }
```

注意录音前需要申请麦克风权限。

#### 3.3.2 录音控制

对录音过程的控制如下

```objective_c
[self.recorder record];
[self.recorder pause];
[self.recorder stop];
```

其中选择了 stop 录音即停止，此时 AVAudioRecorder 会调用其遵循 AVAudioRecorderDelegate 协议的代理的 ```- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag``` 方法。

#### 3.3.3 录音保存

在初始化 AVAudioRecorder 时指定了临时文件目录作为存储音频的位置，音频录制结束时需要保存到 Document 目录下

```objective_c
    NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
    NSString *filename = [NSString stringWithFormat:@"%@-%f.m4a", name, timestamp];

    NSString *docsDir = [self documentsDirectory];
    NSString *destPath = [docsDir stringByAppendingPathComponent:filename];

    NSURL *srcURL = self.recorder.url;
    NSURL *destURL = [NSURL fileURLWithPath:destPath];

    NSError *error;
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:srcURL toURL:destURL error:&error];
    if (success) {
        handler(YES, [THMemo memoWithTitle:name url:destURL]);
        [self.recorder prepareToRecord];
    } else {
        handler(NO, error);
    }
```

这里调用了 NSFileManager 的 copyItemAtURL 方法将文件内容拷贝到 Document 目录下。

#### 3.3.4 展示时间

记录音频时需要展示时间提示用户当前录制时间，AVAudioRecorder 的 currentTime 属性可以获知当前时间，将其格式化后即可进行展示

```objective_c
- (NSString *)formattedCurrentTime {
    NSUInteger time = (NSUInteger)self.recorder.currentTime;
    NSInteger hours = (time / 3600);
    NSInteger minutes = (time / 60) % 60;
    NSInteger seconds = time % 60;

    NSString *format = @"%02i:%02i:%02i";
    return [NSString stringWithFormat:format, hours, minutes, seconds];
}
```

但是需要实时展示时间的话，不能通过 KVO 来解决，只能加入到 NSTimer 中，每 0.5s 执行一次。

```objective_c
    [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(updateTimeDisplay)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
```

#### 3.3.5 可视化音频信号

AVAudioRecorder 和 AVAudioPlayer 都有两个方法获取当前音频的平均分贝和峰值分贝数据。

```objective_c
- (float)averagePowerForChannel:(NSUInteger)channelNumber; /* returns average power in decibels for a given channel */
- (float)peakPowerForChannel:(NSUInteger)channelNumber; /* returns peak power in decibels for a given channel */
```

返回值从 -160dB（静音） 到 0dB（最大分贝）。

获取值之前要在初始化播放器或记录器时设置 meteringEnabled 为 YES。

首先需要将 -160 到 0 的分贝值转为 0 到 1 范围内，需要用到下面这个类

```objective_c
@implementation THMeterTable {
    float _scaleFactor;
    NSMutableArray *_meterTable;
}

- (id)init {
    self = [super init];
    if (self) {
        float dbResolution = MIN_DB / (TABLE_SIZE - 1);

        _meterTable = [NSMutableArray arrayWithCapacity:TABLE_SIZE];
        _scaleFactor = 1.0f / dbResolution;

        float minAmp = dbToAmp(MIN_DB);
        float ampRange = 1.0 - minAmp;
        float invAmpRange = 1.0 / ampRange;

        for (int i = 0; i < TABLE_SIZE; i++) {
            float decibels = i * dbResolution;
            float amp = dbToAmp(decibels);
            float adjAmp = (amp - minAmp) * invAmpRange;
            _meterTable[i] = @(adjAmp);
        }
    }
    return self;
}

float dbToAmp(float dB) {
    return powf(10.0f, 0.05f * dB);
}

- (float)valueForPower:(float)power {
    if (power < MIN_DB) {
        return 0.0f;
    } else if (power >= 0.0f) {
        return 1.0f;
    } else {
        int index = (int) (power * _scaleFactor);
        return [_meterTable[index] floatValue];
    }
}

@end
```

接下来可以实时获取到分贝平均值和峰值

```objective_c
- (THLevelPair *)levels {
    [self.recorder updateMeters];
    float avgPower = [self.recorder averagePowerForChannel:0];
    float peakPower = [self.recorder peakPowerForChannel:0];
    float linearLevel = [self.meterTable valueForPower:avgPower];
    float linearPeak = [self.meterTable valueForPower:peakPower];
    return [THLevelPair levelsWithLevel:linearLevel peakLevel:linearPeak];
}
```

可以看到获取峰值和均值前必须调用 updateMeters 方法。
