## 1. 播放视频综述

AVFoundation 对于播放封装了主要的三个类 AVPlay、AVPlayerLayer 和 AVPlayerItem。

* AVPlayer

AVPlayer 是一个用于播放基于时间的试听媒体的控制器对象，可以播放本地、分布下载以及 HTTP Live Streaming 协议得到的流媒体。

> HTTP Live Streaming（缩写是HLS）是一个由苹果公司提出的基于HTTP的流媒体网络传输协议。是苹果公司QuickTime X和iPhone软件系统的一部分。它的工作原理是把整个流分成一个个小的基于HTTP的文件来下载，每次只下载一些。当媒体流正在播放时，客户端可以选择从许多不同的备用源中以不同的速率下载同样的资源，允许流媒体会话适应不同的数据速率。在开始一个流媒体会话时，客户端会下载一个包含元数据的extended M3U (m3u8)playlist文件，用于寻找可用的媒体流。
> 
> HLS只请求基本的HTTP报文，与实时传输协议（RTP)不同，HLS可以穿过任何允许HTTP数据通过的防火墙或者代理服务器。它也很容易使用内容分发网络来传输媒体流。
> 
> 苹果公司把HLS协议作为一个互联网草案（逐步提交），在第一阶段中已作为一个非正式的标准提交到IETF。但是，即使苹果偶尔地提交一些小的更新，IETF却没有关于制定此标准的有关进一步的动作。

AVPlayer 只管理一个单独资源的播放，其子类 AVQueuePlayer 可以管理资源队列。

* AVPlayerLayer

AVPlayerLayer 构建于 Core Animation 之上，扩展了 Core Animation 的 CALayer 类，不提供除内容渲染面以外的任何可视化控件，支持的自定义属性只有 video gravity，可以选择 AVLayerVideoGravityResizeAspect、AVLayerVideoGravityResizeAspectFill、AVLayerVideoGravityResize 三个值，分别是等比例完全展示，等比例完全铺满，和不等比例完全铺满。

* AVPlayerItem

AVAsset 只包含媒体资源的静态信息，AVPlayerItem 可以建立媒体资源动态视角的数据模型，并保存 AVPlayer 播放状态。

## 2. 播放视频

从一个待播放的 AVAsset 开始，需要做以下初始化操作

```objectivec
        self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.targetAVAsset];
        self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
        self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        [self.layer addSublayer:self.avPlayerLayer];
```

依次创建 AVPlayerItem、AVPlayer 和 AVPlayerLayer 三个对象，最终将 AVPlaterLayer 加入到待展示内容的 view 上。但是此时不能立即播放，AVPlayerItem 有一个 status 状态，用于标识当前视频是否准备好被播放，需要监听这一个属性。

```objectivec
        [RACObserve(self.avPlayerItem, status) subscribeNext:^(id x) {
            @strongify(self);
            if (self.avPlayerItem.status == AVPlayerItemStatusReadyToPlay) {
                // 视频准备就绪
                if (self.autoPlayMode) {
                    self.playerButton.hidden = YES;
                    [self beginPlay];
                } else {
                    self.playerButton.enabled = YES;
                    self.playerButton.hidden = NO;
                }
            }else if (self.avPlayerItem.status == AVPlayerItemStatusFailed){
                NSLog(@"failed");
            }
        }];
```

## 3. 处理时间

使用浮点型数据类型来表示时间在视频播放时会由于数据不精确、多时间计算累加导致时间明显偏移，是的数据流无法同步，且不能做到自我描述，在不同的时间轴进行比较和运算时比较困难。所以 AVFoundation 使用 CMTime 数据结构来表示时间。

```objectivec
typedef struct
{
	CMTimeValue	value;
	CMTimeScale	timescale;
	CMTimeFlags	flags;
	CMTimeEpoch	epoch;		/* CMTime 结构体的纪元数量通常设置为 0，但是你可以用它来区分不相关的时间轴。例如，纪元可以通过使用演示循环每个周期递增，区分循环0中的时间 N与循环1中的时间 N。*/
} CMTime;
```

CMTime 对时间的描述就是 time = value/timescale。

## 4. 实践

### 4.1 创建视频视图

UIView 寄宿在 CALayer 实例之上，可以继承 UIView 覆写其类方法 ```+ (Class)layerClass``` 返回特定类型的 CALayer，这样 UIView 在初始化时就会选择此类型来创建宿主 Layer。

```objectivec
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
```

接下来在自定义初始化方法里直接传入一个 AVPlayer 对象就可以对 UIView 的根 layer 设置 AVPlayer 属性了。

```objectivec
- (id)initWithPlayer:(AVPlayer *)player {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        [(AVPlayerLayer *) [self layer] setPlayer:player];
    }
    return self;
}
```

可以在加载 AVPlayerItem 时选择一些元数据 key 值进行加载，形式如下

```objectivec
    NSArray *keys = @[
        @"tracks",
        @"duration",
        @"commonMetadata",
        @"availableMediaCharacteristicsWithMediaSelectionOptions"
    ];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset
                           automaticallyLoadedAssetKeys:keys];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerView = [[THPlayerView alloc] initWithPlayer:self.player];
```

这样可以在加载 AVPlayerItem 时同时加载音轨、时长、common 元数据和备用。

### 4.2 监听状态

初始化 AVPlayerItem 之后需要等待其状态变为 AVPlayerItemStatusReadyToPlay，因此需要进行监听

```objectivec
        [RACObserve(self.avPlayerItem, status) subscribeNext:^(id x) {
            @strongify(self);
            if (self.avPlayerItem.status == AVPlayerItemStatusReadyToPlay) {
                // 视频准备就绪
                CMTime duration = self.playerItem.duration;
                [self.player play];
            } else if (self.avPlayerItem.status == AVPlayerItemStatusFailed){
                // 视频无法播放
            }
        }];
```

### 4.3 监听时间

对于播放时间的监听，AVPlayer 提供了两个方法

* 定期监听

```objectivec
        self.intervalObserver =  [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 2) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            NSLog(@"%f", CMTimeGetSeconds(time));
        }];
```

这个方法以一定时间间隔，发送消息到指定队列，这里要求队列必须是串行队列，回调 block 的参数是一个用 CMTime 表示的播放器的当前时间。

* 边界时间监听

```objectivec
        self.intervalObserver = [self.avPlayer addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:CMTimeMake(1, 2)], [NSValue valueWithCMTime:CMTimeMake(2, 2)]] queue:dispatch_get_main_queue() usingBlock:^{
            NSLog(@"..");
        }];
```

这个方法接受一个 CMTime 组成的数组，当到达数组包含的边界点时触发回调 block，但 block 不提供当前的 CMTime 值。

同时要注意对监听的释放

```objectivec
        if (self.intervalObserver){
            [self.avPlayer removeTimeObserver:self.intervalObserver];
        }
```

### 4.4 监听播放结束

视频播放结束时会发出 AVPlayerItemDidPlayToEndTimeNotification 通知，可以注册此通知来获知视频已经播放结束

```objectivec
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayerItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"did play to end");
    }];
```

还有一种办法是监听 AVPlayer 的速度 rate，当速度降为 0 时，判断当前时间与总时长的关系

```objectivec
        @weakify(self);
        [RACObserve(self.avPlayer, rate) subscribeNext:^(id x) {
            @strongify(self);
            float currentTime = CMTimeGetSeconds(self.avPlayerItem.currentTime);
            float durationTime = CMTimeGetSeconds(self.avPlayerItem.duration);
            if (self.avPlayer.rate == 0 && currentTime >= durationTime) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self endPlayer];
                });
            }
        }];
```

### 4.5 控制播放进度

我们用一个 UISlider 来控制视频播放,UISlider 有三个事件可以加入 selector，分别是

* 点按开始 UIControlEventTouchDown
* 滑动中 UIControlEventValueChanged
* 点按结束 UIControlEventTouchUpInside

```objectivec
        _scrubberSlider = [[UISlider alloc] init];
        [_scrubberSlider addTarget:self action:@selector(sliderValueChange) forControlEvents:UIControlEventValueChanged];
        [_scrubberSlider addTarget:self action:@selector(sliderStop) forControlEvents:UIControlEventTouchUpInside];
        [_scrubberSlider addTarget:self action:@selector(sliderBegin) forControlEvents:UIControlEventTouchDown];
```

同时获取到视频大小后可以设置 slider 的 value 属性

```objectivec
        self.scrubberSlider.minimumValue = 0.0;
        self.scrubberSlider.maximumValue = CMTimeGetSeconds(self.avPlayerItem.duration);
```

接下来是三个 selector 的实现

```objectivec
- (void)sliderBegin
{
    [self pausePlayer];
}

- (void)sliderValueChange
{
    [self.avPlayerItem cancelPendingSeeks];
    [self.avPlayerItem seekToTime:CMTimeMakeWithSeconds(self.scrubberSlider.value, NSEC_PER_SEC)];
}

- (void)sliderStop
{
    [self beginPlay];
}
```

其中当滑动开始时要暂时停止视频播放，滑动过程中出于性能考虑，调用 cancelPendingSeeks 方法，它能取消之前所有的 seekTime 操作，然后再根据 slider 的 value 值去进行 seekToTime 操作，最后滑动结束后恢复播放。

### 4.6 获取图片序列

AVAssetImageGenerator 可以用来生成一个视频的固定时间点的图片序列集合，其具体使用如下。

首先初始化一个 AVAssetImageGenerator 对象

```objectivec
        self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:targetAVAsset];
        self.imageGenerator.maximumSize = CGSizeMake(400.0f, 0.0f);
        [self.imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
        [self.imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
```

setRequestedTimeToleranceBefore 和 setRequestedTimeToleranceAfter 方法可以设置获取的帧时值偏移程度，越精确对性能要求越高。

然后生成一串时值数组

```objectivec
        CMTime duration = self.targetAVAsset.duration;
        NSMutableArray *times = [NSMutableArray array];
        CMTimeValue increment = duration.value / 20;
        CMTimeValue currentValue = 2.0 * duration.timescale;
        while (currentValue <= duration.value) {
            CMTime time = CMTimeMake(currentValue, duration.timescale);
            [times addObject:[NSValue valueWithCMTime:time]];
            currentValue += increment;
        }
        __block NSUInteger imageCount = times.count;
        __block NSMutableArray *images = [NSMutableArray array];
```

最后调用方法生成图片

```objectivec
        [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable imageref, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
            if (result == AVAssetImageGeneratorSucceeded) {
                UIImage *image = [UIImage imageWithCGImage:imageref];
                [images addObject:image];
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
            
            if (--imageCount == 0) {
                
            }
        }];
```

### 4.7 显示字幕

AVMediaSelectionOption 用于标识 AVAsset 的备用媒体呈现方式，包含备用音频、视频或文本轨道，这些轨道可能是特定语言的音频轨道、备用相机角度或字幕。

首先通过 AVAsset 的 availableMediaCharacteristicsWithMediaSelectionOptions 属性来获取当前视频的所有备用轨道，返回的字符串可能是 AVMediaCharacteristicVisual（备用视频轨道）、AVMediaCharacteristicAudible（备用音频轨道）、AVMediaCharacteristicLegible（字幕）等。

获取到此数组后，通过 mediaSelectionGroupForMediaCharacteristic 获取到对应类型轨道包含的所有轨道的组合 AVMediaSelectionGroup，然后遍历 AVMediaSelectionGroup 的 options 属性可以获取到所有的 AVMediaSelectionOption 对象。得到 AVMediaSelectionOption 对象后就可以进行 AVPlayerItem 的属性设置了。

```objectivec
    NSString *mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group = [self.asset mediaSelectionGroupForMediaCharacteristic:mc];
    if (group) {
        NSMutableArray *subtitles = [NSMutableArray array];
        for (AVMediaSelectionOption *option in group.options) {
            [subtitles addObject:option.displayName];
        }
        // 获取到所有支持的字幕名称
    } else {
    }
   
   
    NSString *mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group = [self.asset mediaSelectionGroupForMediaCharacteristic:mc]; 
    BOOL selected = NO;
    for (AVMediaSelectionOption *option in group.options) {
        if ([option.displayName isEqualToString:subtitle]) {
            [self.playerItem selectMediaOption:option inMediaSelectionGroup:group];
            // 匹配后设置字幕属性
        }
    }
    
    
    [self.playerItem selectMediaOption:nil inMediaSelectionGroup:group];// 设置为 nil 可以取消字幕
```

