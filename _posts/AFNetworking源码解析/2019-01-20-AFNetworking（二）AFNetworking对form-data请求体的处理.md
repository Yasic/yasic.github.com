---
category: AFNetworking源码解析
description: "AFNetworking 发送 GET、POST 等请求时可以直接将参数按照字典结构传入，最终编码到 url 中或者是 body 实体中，同时也支持按照 multipart/form-data 格式，将多种不同的数据合入到 body 中进行发送，而这些就涉及到 AFNetworking 的请求序列化类，也就是 AFURLRequestSerialization。"
---

AFNetworking 发送 GET、POST 等请求时可以直接将参数按照字典结构传入，最终编码到 url 中或者是 body 实体中，同时也支持按照 multipart/form-data 格式，将多种不同的数据合入到 body 中进行发送，而这些就涉及到 AFNetworking 的请求序列化类，也就是 AFURLRequestSerialization。

AFURLRequestSerialization 是一个协议，它定义了一个方法用于序列化参数到 NSURLRequest 中，AFHTTPRequestSerializer 实现了这个协议，并实现了相应的方法。它不仅提供了普通的参数编码方法，也提供了 form-data 格式的 request 构建方法，也就是下面的方法

```objective_c
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError *__autoreleasing *)error
```

## 1. form-data

首先简单介绍一下 form-data，multipart/form-data 主要用于 POST方法中传递多种格式和含义的数据，在 body 中引入 boundary 的概念，用分割线将多部分数据融合到一个 body 中发送给服务端。那么对于一个简单的 form-data，它发送的 body 内容可能如下

```
--Boundary+FD2E180F039993ED

Content-Disposition: form-data; name="myArray[]"



v1

--Boundary+FD2E180F039993ED

Content-Disposition: form-data; name="myArray[]"



v2

--Boundary+FD2E180F039993ED

Content-Disposition: form-data; name="myArray[]"



v3

--Boundary+FD2E180F039993ED

Content-Disposition: form-data; name="mydic[key1]"



value1

--Boundary+FD2E180F039993ED

Content-Disposition: form-data; name="mydic[key2]"



value2

--Boundary+FD2E180F039993ED

header: headerkey



BodyData

--Boundary+FD2E180F039993ED--

```

它的特点是
* 每一部分都可以包含 header，一般默认必须包含的标识 header 是 Content-Disposition
* 头部和每一部分需要以 --Boundary+{XXX} 格式分割
* 末尾以 --Boundary+{XXX}-- 结束
* 请求头中，要设置 Content-Type: multipart/form-data; boundary=Boundary+{XXX}
* 请求头要设置 Content-Length 为 body 总长度

## 2. 一个 form-data 类型的 POST 请求

在 AFNetworking 中，要发送 form-data，可以通过如下方式发送

```objective_c
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 100;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html",@"application/json", @"text/json" ,@"text/javascript", nil];;
    [manager POST:@"https://www.baidu.com" parameters:@{@"mydic":@{@"key1":@"value1",@"key2":@"value2"},
                                                          @"myArray":@[@"v1", @"v2", @"v3"]
                                                          } headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                                              [formData appendPartWithFileData:[@"Data" dataUsingEncoding:NSUTF8StringEncoding]
                                                                                          name:@"DataName"
                                                                                      fileName:@"DataFileName"
                                                                                      mimeType:@"data"];
                                                          } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

                                                          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

                                                          }];
```

主要用到 AFHTTPSessionManager 定义的如下方法

```objective_c
- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
                                headers:(nullable NSDictionary <NSString *, NSString *> *)headers
              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;
```

它的内部实现，主要做了这几件事

* 通过 requestSerializer 的 multipartFormRequestWithMethod 方法构建 NSMutableURLRequest 对象
* 设置头部
* 通过 AFURLSessionManager 创建 NSURLSessionUploadTask 对象

从中可以看出，请求序列化主要发生在 multipartFormRequestWithMethod 方法中，而 AFHttpSessionManager 默认的 requestSerializer 是 AFHTTPAFHTTPRequestSerializer。

## 3. 请求序列化

AFHTTPAFHTTPRequestSerializer 对于 form-data 提供了如下方法进行序列化

```objective_c
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError *__autoreleasing *)error
```

在方法实现里主要做了以下事情

* 与普通的 urlencode 请求类似，先设置 request 相关参数，仍然是通过 KVO 记录需要设置的参数，其他都走默认逻辑
* 构造 AFStreamingMultipartFormData 对象，将传入的参数深度遍历后一一通过 ```appendPartWithFormData: name:``` 方法添加到 AFStreamingMultipartFormData 中
* 提供外部 block，对 AFStreamingMultipartFormData 对象进一步添加数据
* 通过 AFStreamingMultipartFormData 的  ```requestByFinalizingMultipartFormData``` 方法构建 request

那么 AFStreamingMultipartFormData 是一个什么类呢。

## 4. 构造 form-data 数据

AFNetworking 定义的 AFStreamingMultipartFormData 类用于表征一个 form-data 格式 body 的数据，它遵循 AFMultipartFormData 协议，能管理 boundary 字符串、用于向 request 传输数据的 NSInputStream 对象。

其中对于 form-data 的每一个 part，AFNetworking 定义了一个 AFHTTPBodyPart 类，其中包含如下信息

* 这个 part 的头部 header
* 分割字符串 boundary
* 内容区长度
* id 类型的 body
* 数据流 inputStream

AFStreamingMultipartFormData 所包含的 NSInputStream 类，实质上是继承自 NSInputStream 的子类 AFMultipartBodyStream，AFMultipartBodyStream 有一个 HTTPBodyParts 属性，是一个 AFHTTPBodyPart 类型的数组，所有 append 到 AFStreamingMultipartFormData 的 part，最后都转化为一个 AFHTTPBodyPart 对象加入到了 AFMultipartBodyStream 的 HTTPBodyParts 中。

具体来说，AFMultipartFormData 协议（也就是 AFStreamingMultipartFormData 类）定义了如下一些 append 方法

* ```appendPartWithFileURL: name: error:``` 添加文件路径内的文件内容到 form-data
* ```appendPartWithFileURL: name: fileName: mimeType: error:``` 添加文件路径内的文件内容到 form-data，指定文件名和 mimeType
* ```appendPartWithInputStream: name: fileName: length: mimeType:``` 添加 inputStream 到 form-data
* ```appendPartWithFileData: name: fileName: mimeType:``` 添加 NSData 到 form-data
* ```appendPartWithFormData: name:``` 添加 NSData 到 form-data
* ```appendPartWithHeaders: body:``` 添加自定义 header 和 body 到 form-data

下面以 appendPartWithFormData 为例看下具体实现

```objective_c
- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name
{
    NSParameterAssert(name);

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    // 每一块数据，默认带上 Content-Disposition 作为头部
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];

    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    NSParameterAssert(body);

    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = headers;
    // 复用一个 boundary
    bodyPart.boundary = self.boundary;
    // body 长度
    bodyPart.bodyContentLength = [body length];
    bodyPart.body = body;
    // 添加到 stream 中
    [self.bodyStream appendHTTPBodyPart:bodyPart];
}
```

可以看到，就是根据数据构造一个 AFHTTPBodyPart 对象添加到 bodyStream 属性中；至于文件和 inputStream，则是直接将文件 url 和 inputStream 对象赋值给 id 类型的 body。

这样将所有数据都 append 到了 AFStreamingMultipartFormData 中以后，再调用 AFStreamingMultipartFormData 的 requestByFinalizingMultipartFormData 方法就可以构造一个 NSMutableURLRequest 对象了，而在 requestByFinalizingMultipartFormData 方法中，主要做了如下工作

* 将构造出来的 NSMutableURLRequest 的 HTTPBodyStream 属性设置为 AFStreamingMultipartFormData 的 bodyStream 对象，也就是 AFMultipartBodyStream 作为 NSMutableURLRequest 的 body 数据源
* 设置 Content-Type 

```objective_c
    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary] forHTTPHeaderField:@"Content-Type"];
```

* 设置 Content-Length

```objective_c
    [self.request setValue:[NSString stringWithFormat:@"%llu", [self.bodyStream contentLength]] forHTTPHeaderField:@"Content-Length"];
```

## 5. 从 bodyStream 读取数据

AFMultipartBodyStream 直接继承自 NSInputStream，它维护一个 包含全部 AFHTTPBodyPart 的数组，当通过 request 发起一个 NSURLSessionUploadTask 以后，由于设置了 request 的 HTTPBodyStream，则系统会尝试从 AFMultipartBodyStream 读取 body 数据，这里就涉及到了 AFMultipartBodyStream 的 ```read: maxLength:``` 方法，它从流中读取数据到 buffer 中，并返回实际读取的数据长度（该长度最大为 len）。而实际上 AFMultipartBodyStream 的 numberOfBytesInPacket 属性就可以限制读取数据的最大长度。

```objective_c
{
    if ([self streamStatus] == NSStreamStatusClosed) {
        // 流已关闭，返回长度 0
        return 0;
    }

    NSInteger totalNumberOfBytesRead = 0;
    // 一直从 HTTPBodyParts 读取到字节数达到 length 为止
    while ((NSUInteger)totalNumberOfBytesRead < MIN(length, self.numberOfBytesInPacket)) {
        // 如果还未开始读取，或者当前 part 已经读取结束，则进入下一个
        if (!self.currentHTTPBodyPart || ![self.currentHTTPBodyPart hasBytesAvailable]) {
            if (!(self.currentHTTPBodyPart = [self.HTTPBodyPartEnumerator nextObject])) {
                break;
            }
        } else {
            NSUInteger maxLength = MIN(length, self.numberOfBytesInPacket) - (NSUInteger)totalNumberOfBytesRead;
            // 从 part 中读取数据
            NSInteger numberOfBytesRead = [self.currentHTTPBodyPart read:&buffer[totalNumberOfBytesRead] maxLength:maxLength];
            if (numberOfBytesRead == -1) {
                // 读取出错
                self.streamError = self.currentHTTPBodyPart.inputStream.streamError;
                break;
            } else {
                // 更新总读取字节数
                totalNumberOfBytesRead += numberOfBytesRead;

                if (self.delay > 0.0f) {
                    [NSThread sleepForTimeInterval:self.delay];
                }
            }
        }
    }

    return totalNumberOfBytesRead;
}
```

这里通过一个 currentHTTPBodyPart 对象对 AFMultipartBodyStream 维护的 AFHTTPBodyPart 数组进行遍历，读取其中每一个 AFHTTPBodyPart 对象的数据到 buffer 中。AFHTTPBodyPart 类也实现了同名的 read 方法，在这个方法里，按照如下顺序，读取相应部分的数据

* AFEncapsulationBoundaryPhase 顶部边界
* AFHeaderPhase 头部数据
* AFBodyPhase 实体
* AFFinalBoundaryPhase 底部边界

例如读取顶部边界数据如下

```objective_c
        NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AFMultipartFormInitialBoundary(self.boundary) : AFMultipartFormEncapsulationBoundary(self.boundary)) dataUsingEncoding:self.stringEncoding];
        totalNumberOfBytesRead += [self readData:encapsulationBoundaryData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
```

但是当读取到 body 部分时要注意，由于 body 是一个 id 类型，外界主要设置的可能值有 NSData、NSURL、NSInputStream 等，AFNetworking 在这里统一将 body 的读取归一化为 inputStream 流方式读取，按照如下规则构建 inputStream

```objective_c
- (NSInputStream *)inputStream {
    // inputStream 根据 body 的类别返回不同的数据源
    if (!_inputStream) {
        if ([self.body isKindOfClass:[NSData class]]) {
            _inputStream = [NSInputStream inputStreamWithData:self.body];
        } else if ([self.body isKindOfClass:[NSURL class]]) {
            _inputStream = [NSInputStream inputStreamWithURL:self.body];
        } else if ([self.body isKindOfClass:[NSInputStream class]]) {
            _inputStream = self.body;
        } else {
            _inputStream = [NSInputStream inputStreamWithData:[NSData data]];
        }
    }

    return _inputStream;
}
```

读取到 body 部分时则启动 stream，读取完 body 以后关闭 stream

```objective_c
// 这里是根据当前 phase 切换到下一端 phase 的逻辑
        case AFHeaderPhase:
            // header -> body
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [self.inputStream open];
            _phase = AFBodyPhase;
            break;
        case AFBodyPhase:
            // body -> 底部边界
            [self.inputStream close];
            _phase = AFFinalBoundaryPhase;
            break;
```

以上就是 AFNetworking 对于 form-data 请求的完整处理，基于 inputStream，将多种不同类型的 form-data 用统一的代码模型处理，对外暴露的方法简洁一致，因而便于使用和理解。