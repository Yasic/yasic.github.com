---
category: AVFoundation
description: "AVAsset 是一个抽象类和不可变类，它定义了媒体资源混合呈现的方式，将媒体资源的静态属性模块化为一个整体，包括标题、时长和元数据。AVAsset 提供了基本媒体格式的层抽象，隐藏了资源的位置信息。"
---

AVAsset 是一个抽象类和不可变类，它定义了媒体资源混合呈现的方式，将媒体资源的静态属性模块化为一个整体，包括标题、时长和元数据。AVAsset 提供了基本媒体格式的层抽象，隐藏了资源的位置信息。

## 1. 创建资源

通过 URL 创建一个 AVAsset

```objective_c
NSURL *assetUrl = // url
AVAsset *asset  =[AVAsset assetWithURL:assetUrl];
```

assetWithURL 方法生成的实际类是 AVAsset 的子类 AVURLAsset，它允许通过 options 字典来调整创建方式。

### 获取方式

常见的获取 AVAsset 的途径有

* iOS Asset 库，即相册资源 —— Photo Framework
* iOS iPod 库 —— MediaPlayer
* MAC iTunes 库 —— iTunesLibrary 框架

这里只举 Photo Framework 的例子

```objective_c
                [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable obj, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    @strongify(self)
                    AVURLAsset *urlAsset = (AVURLAsset *)obj;
                    NSURL *url = urlAsset.URL;
                    NSData *data = [NSData dataWithContentsOfURL:url];
                }];
```

## 2. 异步加载

AVAsset 对资源属性实现了延迟加载特性，仅在请求时才载入，这样如果是同步请求属性，就可能因为属性没有预先载入而阻塞主线程，因此应采用异步加载属性的方法。

AVAsset 和 AVAssetTrack 都遵循了 AVAsynchronousKeyValueLoading 协议，此协议有两个方法

```objective_c
- (AVKeyValueStatus)statusOfValueForKey:(NSString *)key error:(NSError * _Nullable * _Nullable)outError;
- (void)loadValuesAsynchronouslyForKeys:(NSArray<NSString *> *)keys completionHandler:(nullable void (^)(void))handler;
```

第一个方法用于确定当前属性是预先加载好了、尚未加载还是加载出错了，而第二个方法则是异步加载属性的方法。

```objective_c
        [self.targetAVAsset loadValuesAsynchronouslyForKeys:@[@"trackss"] completionHandler:^{
            NSError *error = nil;
            AVKeyValueStatus status = [self.targetAVAsset statusOfValueForKey:@"tracks" error:nil];
            switch (status) {
                case AVKeyValueStatusLoaded: {
                    NSLog(@"AVKeyValueStatusLoaded");
                    break;
                }
                case AVKeyValueStatusFailed: {
                    NSLog(@"AVKeyValueStatusFailed");
                    break;
                }
                case AVKeyValueStatusUnknown: {
                    NSLog(@"AVKeyValueStatusUnknown");
                    break;
                }
                case AVKeyValueStatusCancelled: {
                    NSLog(@"AVKeyValueStatusCancelled");
                    break;
                }
                default:
                    break;
            }
        }];
```

这里请求的参数可以是多个，但是当请求多个参数时，异步请求的回调只会调用一次，此时需要分别对各个属性调用 statusOfValueForKey 方法来判断是否加载完成。

## 3. 媒体元数据

### 3.1 元数据格式

在 Apple 环境下，最常见四种媒体类型，分别是 QuickTime（mov）、MPEG-4 video（mp4 和 m4v）、MPEG-4 audio（m4a）和 MPEG-Layer III Audio（mp3）。

QuickTime 是苹果公司开发的一种跨平台媒体架构，由一种称为 atoms 的数据结构组成，一个 atom 可以包含元数据，也可以包含其他 atom，但不能两者都包含。

MPEG-4 Part 14 定义了 MP4 文件格式的规范，MP4 直接派生于 QuickTime 文件格式，结构类似。要注意，MP4 有多种文件拓展名。.mp4 是标准扩展名，.m4v 是带有苹果公司针对 FairPlay 加密及 AC3-audio 扩展的 MPEG-4 视频格式，而 .m4a 针对音频，m4p 针对较旧的 itunes 音频格式，m4b 针对有声读物。

MP3 不是容器格式，使用编码音频数据，使用 ID3v2 格式保存元数据。由于专利限制，AVFoundation 只支持读取 MP3，不支持编码 MP3。

## 4. 使用元数据

AVFoundation 使用键空间作为将相关键组合在一起的方法，可以实现对 AVMetaDataItem 实例集合的筛选。Common 键空间用于定义所有支持的媒体类型的键，包括曲名、歌手、插图信息等。开发者可以通过查询资源或曲目的 commonMetadata 属性从 common 键空间获取元数据，这个属性会返回一个包含所有可用元数据的数组。

访问指定格式的元数据，需要对 AVAsset 对象调用 metadataForFormat 方法，此方法包含一个用于定义元数据格式的 NSString 对象并返回一个包含所有相关元数据信息的 NSArray。一个 AVAsset 所支持的资源格式可以通过 availableMetadataFormats 属性来获取。

```objective_c
        [self.targetAVAsset loadValuesAsynchronouslyForKeys:@[@"availableMetadataFormats"] completionHandler:^{
            NSError *error = nil;
            AVKeyValueStatus status = [self.targetAVAsset statusOfValueForKey:@"availableMetadataFormats" error:nil];
            switch (status) {
                case AVKeyValueStatusLoaded: {
                    for (NSString *format in self.targetAVAsset.availableMetadataFormats) {
                        NSLog(@"%@", format);
                        NSLog(@"%@", [self.targetAVAsset metadataForFormat:format]);
                    }
                    break;
                }
                case AVKeyValueStatusFailed: {
                    NSLog(@"AVKeyValueStatusFailed");
                    break;
                }
                case AVKeyValueStatusUnknown: {
                    NSLog(@"AVKeyValueStatusUnknown");
                    break;
                }
                case AVKeyValueStatusCancelled: {
                    NSLog(@"AVKeyValueStatusCancelled");
                    break;
                }
                default:
                    break;
            }
        }];
```

示例输出如下

```objective_c
com.apple.quicktime.mdta
(

    "<AVMetadataItem: 0x1c801f230, identifier=mdta/com.apple.quicktime.software, keySpace=mdta, key class = __NSCFString, key=com.apple.quicktime.software, commonKey=software, extendedLanguageTag=(null), dataType=com.apple.metadata.datatype.UTF-8, time={INVALID}, duration={INVALID}, startDate=(null), extras={\n    dataType = 1;\n    dataTypeNamespace = \"com.apple.quicktime.mdta\";\n}, value class=__NSCFString, value=video.vue.ios.280>",

    "<AVMetadataItem: 0x1c42004d0, identifier=mdta/com.apple.quicktime.description, keySpace=mdta, key class = __NSCFString, key=com.apple.quicktime.description, commonKey=description, extendedLanguageTag=(null), dataType=com.apple.metadata.datatype.UTF-8, time={INVALID}, duration={INVALID}, startDate=(null), extras={\n    dataType = 1;\n    dataTypeNamespace = \"com.apple.quicktime.mdta\";\n}, value class=__NSCFString, value=ewogICJzc2Z3IiA6IFsKICAgICIiCiAgXSwKICAic2RldiIgOiBbCiAgICAiIgogIF0sCiAgInNjIiA6IDEsCiAgInNsb2MiIDogWwogICAgIiIKICBdLAogICJzdWIiIDogWwogICAgIiIKICBdLAogICJ0cnMiIDogWwogICAgMCwKICAgIDAKICBdLAogICJzZHVyIiA6IFsKICAgIDEwCiAgXSwKICAiY2FwIiA6ICIgIiwKICAiZiIgOiBbCiAgICAiMSIKICBdCn0=>"

)
```

## 5. 实践

### 5.1 对 AVAsset 进行封装

通过 url 我们可以实例化一个 AVAsset，也可以获取到其中一些有效的元数据信息

```objective_c
        _url = url;
        _asset = [AVAsset assetWithURL:url];
        _filename = [url lastPathComponent];
        _filetype = [self fileTypeForURL:url];                              
        _editable = ![_filetype isEqualToString:AVFileTypeMPEGLayer3];
```

lastPathComponent 从 URL （例如 "file:///Users/yasic/Library/Application%20Support/MetaManager/01%20Demo%20AAC.m4a"）的最后一个路径取出文件名，fileTypeForURL 具体实现如下

```objective_c
- (NSString *)fileTypeForURL:(NSURL *)url {
    NSString *ext = [[self.url lastPathComponent] pathExtension];
    NSString *type = nil;
    if ([ext isEqualToString:@"m4a"]) {
        type = AVFileTypeAppleM4A;
    } else if ([ext isEqualToString:@"m4v"]) {
        type = AVFileTypeAppleM4V;
    } else if ([ext isEqualToString:@"mov"]) {
        type = AVFileTypeQuickTimeMovie;
    } else if ([ext isEqualToString:@"mp4"]) {
        type = AVFileTypeMPEG4;
    } else {
        type = AVFileTypeMPEGLayer3;
    }
    return type;
}
```

### 5.2 获取元数据

对于通用键空间，可以通过 commonMetadata 属性获取到元数据对应的 AVMetadataItem 对象。

```objective_c
    NSArray *keys = @[COMMON_META_KEY];
    [self.asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        AVKeyValueStatus commonStatus =
            [self.asset statusOfValueForKey:COMMON_META_KEY error:nil];
        self.prepared = (commonStatus == AVKeyValueStatusLoaded);

        if (self.prepared) {
            for (AVMetadataItem *item in self.asset.commonMetadata) {
                //NSLog(@"%@: %@", item.keyString, item.value);
                [self.metadata addMetadataItem:item withKey:item.commonKey];
            }
        }
    }];
```

对于其他格式的元数据，先获取到可用格式的数组，然后分别进行元数据获取

```objective_c
    NSArray *keys = @[AVAILABLE_META_KEY];
    [self.asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        AVKeyValueStatus formatsStatus = [self.asset statusOfValueForKey:AVAILABLE_META_KEY error:nil];
        self.prepared = (formatsStatus == AVKeyValueStatusLoaded);

        if (self.prepared) {
            for (id format in self.asset.availableMetadataFormats) {        // 5
                if ([self.acceptedFormats containsObject:format]) {
                    NSArray *items = [self.asset metadataForFormat:format];
                    for (AVMetadataItem *item in items) {
                        //NSLog(@"%@: %@", item.keyString, item.value);
                        [self.metadata addMetadataItem:item
                                               withKey:item.keyString];
                    }
                }
            }
        }
    }];
```

获取到的元数据有些是可以直接阅读的，有些则不够语义化，需要进行不同方式的转化，包括 Artwork、注释、音轨数据、唱片数据、风格数据等类型的数据，这里不再赘述。

### 5.3 保存元数据

对于元数据的修改不能直接操作原 AVAsset，需要使用 AVAssetExportSession 导出一个新的资源副本来覆盖原本的资源对象。

```objective_c
    NSString *presetName = AVAssetExportPresetPassthrough;
    AVAssetExportSession *session =
        [[AVAssetExportSession alloc] initWithAsset:self.asset
                                         presetName:presetName];
```

AVAssetExportSession 的初始化需要一个待修改的 AVAsset 对象，以及一个预设值，AVAssetExportPresetPassthrough 预设值能够在不重新编码媒体的前提下实现写入元数据功能，但不能添加新的元数据。

```objective_c
    NSURL *outputURL = [self tempURL];
    session.outputURL = outputURL;
    session.outputFileType = self.filetype;
    session.metadata = [self.metadata metadataItems];
```

指定导出副本的存储位置，配置到 session 上。

```objective_c
    [session exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = session.status;
        BOOL success = (status == AVAssetExportSessionStatusCompleted);
        if (success) {
            NSURL *sourceURL = self.url;
            NSFileManager *manager = [NSFileManager defaultManager];
            [manager removeItemAtURL:sourceURL error:nil];
            [manager moveItemAtURL:outputURL toURL:sourceURL error:nil];
        }
    }];
```

导出需要用到 exportAsynchronouslyWithCompletionHandler 方法，完成后对状态进行判断，获知导出是否成功，然后通过 NSFileManager 的 moveItemAtURL 方法来覆盖原始的媒体资源