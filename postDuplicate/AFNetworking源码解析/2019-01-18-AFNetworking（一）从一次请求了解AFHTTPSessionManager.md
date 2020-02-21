AFNetworking 的核心类是 AFHTTPSessionManager，负责各种 HTTP 请求的发起和处理，它继承自 AFURLSessionManager，是各种请求的直接执行者。

## 1. AFHTTPSessionManager的初始化

初始化方法主要接收 baseURL 和 sessionConfiguration 两个参数。

其中对于 baseURL，初始化方法进行了如下判断

```objectivec
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
```

这样判断的原因是，对于一个形如 "https://www.baidu.com/foo" 格式的 baseURL，如果末尾不带正斜杠，则当调用 URLWithString:relativeToURL: 方法，对诸如 "text" 的 path 添加完整路径时，会得到 ""https://www.baidu.com/text" 的结果，所以需要调用 ```URLByAppendingPathComponent ```，这个方法的说明讲到了如果原始 url 非空字符串且末尾不带正斜杠，而新的 url 开头也不带正斜杠，则方法会在中间插入正斜杠。

> If the original URL does not end with a forward slash and pathComponent does not begin with a forward slash, a forward slash is inserted between the two parts of the returned URL, unless the original URL is the empty string.

对于 configuration，AFHTTPSessionManager 交给了父类 AFURLSessionManager 执行，具体操作包含如下

```objectivec
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    self = [super init];
    if (!self) {
        return nil;
    }

    if (!configuration) {
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }

    self.sessionConfiguration = configuration;

    // 初始化操作队列，并设置为串行队列
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;

    // 默认的响应序列化器为 JSON 序列化器
    self.responseSerializer = [AFJSONResponseSerializer serializer];

    // 初始化 SSL 所需的 securityPolicy
    self.securityPolicy = [AFSecurityPolicy defaultPolicy];

#if !TARGET_OS_WATCH
    self.reachabilityManager = [AFNetworkReachabilityManager sharedManager];
#endif

    // task 的 id 作为 key，代理对象作为 value
    self.mutableTaskDelegatesKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];

    self.lock = [[NSLock alloc] init];
    self.lock.name = AFURLSessionManagerLockName;

    __weak typeof(self) weakSelf = self;
    // 获取所有的 task，设置一遍 delegate
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        for (NSURLSessionDataTask *task in dataTasks) {
            [strongSelf addDelegateForDataTask:task uploadProgress:nil downloadProgress:nil completionHandler:nil];
        }

        for (NSURLSessionUploadTask *uploadTask in uploadTasks) {
            [strongSelf addDelegateForUploadTask:uploadTask progress:nil completionHandler:nil];
        }

        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            [strongSelf addDelegateForDownloadTask:downloadTask progress:nil destination:nil completionHandler:nil];
        }
    }];

    return self;
}
```

对于序列化器，AFHTTPSessionManager 初始化方法里也指定了默认对象。

```objectivec
// 请求序列化器用 AFHTTPRequestSerializer，响应序列化器用 AFJSONResponseSerializer
    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.responseSerializer = [AFJSONResponseSerializer serializer];
```

## 2 一次完整的请求与响应过程

这里以 GET 为例，发起一次 GET 请求的具体过程可以分为发起请求和处理响应两步，下面详细说明。

### 2.1 发起请求

AFHTTPSessionManager 支持创建 GET、HEAD、POST、PUT、PATCH、DELETE 等请求，其中 GET 请求支持以下方法发起

```objectivec
- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(nullable id)parameters
                      success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                      failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure DEPRECATED_ATTRIBUTE;

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable id)parameters
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure DEPRECATED_ATTRIBUTE;

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable id)parameters
                               headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;
```

最终调用到的方法都是第三个方法，在这个方法里 HTTPSessionManager 创建了一个 HTTP 类型的 dataTask，并发起请求。

```objectivec
- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(id)parameters
                      headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                     progress:(void (^)(NSProgress * _Nonnull))downloadProgress
                      success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                      failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"GET"
                                                        URLString:URLString
                                                       parameters:parameters
                                                          headers:headers
                                                   uploadProgress:nil
                                                 downloadProgress:downloadProgress
                                                          success:success
                                                          failure:failure];
    
    [dataTask resume];
    
    return dataTask;
}
```

而在 dataTaskWithHTTPMethod 方法里，则做了以下事情

```objectivec
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                         headers:(NSDictionary <NSString *, NSString *> *)headers
                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *serializationError = nil;
    // 1. 设置 request 属性以及参数
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
    // 2. 设置 header
    for (NSString *headerField in headers.keyEnumerator) {
        [request addValue:headers[headerField] forHTTPHeaderField:headerField];
    }
    // 3. 序列化失败回调
    if (serializationError) {
        if (failure) {
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
        }
        
        return nil;
    }
    
    // 4. 传给 URLSessionManager 创建 dataTask
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest:request
                          uploadProgress:uploadProgress
                        downloadProgress:downloadProgress
                       completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                       }];
    
    return dataTask;
}
```

#### 2.1.1 设置 request 属性以及参数

```requestWithMethod:URLString:parameters:error:``` 方法主要做了创建和配置 Request 的工作，具体来说包括

* 利用 url 创建 NSMutableURLRequest
* 设置 HTTPMethod
* 设置 request 的 allowsCellularAccess、cachePolicy、HTTPShouldHandleCookies、HTTPShouldUsePipelining、networkServiceType、timeoutInterval等属性
* 对参数编码后加入到 url 或者 body 中

其中能设置的 request 具体作用如下

* allowsCellularAccess 是否允许使用服务商蜂窝网络
* cachePolicy 缓存策略枚举
  * NSURLRequestUseProtocolCachePolicy = 0 默认的缓存策略， 如果缓存不存在，直接从服务端获取。如果缓存存在，会根据 response 中的 Cache-Control 字段判断下一步操作，如: Cache-Control 字段为 must-revalidata, 则询问服务端该数据是否有更新，无更新的话直接返回给用户缓存数据，若已更新，则请求服务端
  * NSURLRequestReloadIgnoringLocalCacheData = 1 忽略本地缓存数据，直接请求服务端
  * NSURLRequestReloadIgnoringLocalAndRemoteCacheData = 4 __未实现__，忽略本地缓存，代理服务器以及其他中介，直接请求源服务端
  * NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData 忽略本地缓存数据，直接请求服务端
  * NSURLRequestReturnCacheDataElseLoad = 2 有缓存就使用，不管其有效性(即忽略 Cache-Control 字段), 无则请求服务端
  * NSURLRequestReturnCacheDataDontLoad = 3 只加载本地缓存. 没有就失败(确定当前无网络时使用)
  * NSURLRequestReloadRevalidatingCacheData = 5 __未实现__，缓存数据必须得得到服务端确认有效才使用
* HTTPShouldHandleCookies 设置发送请求时是否发送cookie数据
* HTTPShouldUsePipelining 设置请求时是否按顺序收发 默认禁用 在某些服务器中设为YES可以提高网络性能 
* networkServiceType 网络请求的服务类型
  * NSURLNetworkServiceTypeDefault = 0 普通网络传输，默认使用这个
  * NSURLNetworkServiceTypeVoIP = 1 网络语音通信传输，只能在VoIP使用
  * NSURLNetworkServiceTypeVideo = 2 影像传输
  * NSURLNetworkServiceTypeBackground = 3 网络后台传输，优先级不高时可使用。对用户不需要的网络操作可使用
  * NSURLNetworkServiceTypeVoice = 4 语音传输
* timeoutInterval 请求超时时间

具体到 AFNetworking 中，是利用了 KVO 特性，将一系列 set 方法手动触发 KVO，然后对于触发过设置方法的属性，均加入到了mutableObservedChangedKeyPaths 集合中，创建 request 时会针对设置过的属性，设置相对应的属性

```objectivec
    for (NSString *keyPath in AFHTTPRequestSerializerObservedKeyPaths()) {
        // 只有设置过此属性，才会触发 KVO，mutableObservedChangedKeyPaths 这个 set 里才有此属性
        if ([self.mutableObservedChangedKeyPaths containsObject:keyPath]) {
            [mutableRequest setValue:[self valueForKeyPath:keyPath] forKey:keyPath];
        }
    }
```

#### 2.1.2 对参数编码

编码参数用到了 AFURLRequestSerialization 协议类的 ```requestBySerializingRequest:withParameters:error:``` 方法，而 HTTPSessionManager 用到的 AFHTTPRequestSerializer 则实现了此方法，主要做了几件事

* 没有设置过相关必要的 header 字段，则设置成默认值
* 编码 query 参数
* 针对 HTTPMethod，将参数放入到 url 或 body 里

首先是设置一些默认 header，目前包含以下两个键值对

```objectivec
{
    "Accept-Language" = "en;q=1";
    "User-Agent" = "iOS Example/1.0 (iPhone; iOS 11.3; Scale/3.00)";
}
```

其次是编码 query，AFNetworking 接受的字典类型的参数作为编码 query 的数据，编码过程如下

```objectivec
NSString *query = nil;
    if (parameters) {
        if (self.queryStringSerialization) {
            NSError *serializationError;
            query = self.queryStringSerialization(request, parameters, &serializationError);

            if (serializationError) {
                if (error) {
                    *error = serializationError;
                }

                return nil;
            }
        } else {
            switch (self.queryStringSerializationStyle) {
                case AFHTTPRequestQueryStringDefaultStyle:
                    // 序列化 query 参数
                    query = AFQueryStringFromParameters(parameters);
                    break;
            }
        }
    }
```

可以看到这里提供了一个 block 参数 queryStringSerialization，它可以支持外部设置，从而将编码序列化工作交给外部处理。AFNetworking 内部则使用了 AFQueryStringFromParameters 方法来编码参数，下面是它的实现

```objectivec
NSString * AFQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
        // 将字典参数打平成一层AFQueryStringPair，进行url编码后，放入数组
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    // 按照 description 正序排序
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                // 字典类型的参数，需要转为 dicName[key] = value 形式
                [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            // 数组类型的参数，需要转为 arrayName[] = value 形式
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            // 集合类型的参数，直接取出元素添加到 query
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        // 最终遍历到字符串类型参数截止
        [mutableQueryStringComponents addObject:[[AFQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}
```

通过深度优先遍历，将字典内所有元素均转化为 AFQueryStringPair 对象后，每个对象调用自身的 URLEncodedStringValue 方法，实现编码

```objectivec
- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return AFPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", AFPercentEscapedStringFromString([self.field description]), AFPercentEscapedStringFromString([self.value description])];
    }
}
```

而这里具体编码工作是由 AFPercentEscapedStringFromString 方法完成，在这个方法里，AFNetworking 首先将系统提供的 URLQueryAllowedCharacterSet 集合中的 #[] 三个字符去除了，意味着这三个字符也需要参与编码。然后以每 50 个字符为一个单元，调用 stringByAddingPercentEncodingWithAllowedCharacters 方法进行编码处理。

为了避免对完整的 emoji 进行错误的截断，这里还用到了 rangeOfComposedCharacterSequencesForRange 方法获取完整的子字符串，而不是 substringToIndex 方法获取字符串。

编码后的字符，通过 & 字符连接起来后，就将被加入到 request 中，其中对于 GET、HEAD、DELETE 方法，也就是 HTTPMethodsEncodingParametersInURI 属性包含的方法，需要将参数补到 url 末尾，而对于其他方法，则直接加入到 body 中

```objectivec
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        if (query && query.length > 0) {
            // url 有 query 和无 query 时需要区别处理
            mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", query]];
        }
    } else {
        // #2864: an empty string is a valid x-www-form-urlencoded payload
        if (!query) {
            query = @"";
        }
        // request 没设置 Content-Type 时，设置为默认的 application/x-www-form-urlencoded
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        }
        [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
    }
```

#### 2.1.3 设置 header

设置 header 就是遍历传入的 headers 字典，加入到 request 的 headerField 中即可。

#### 2.1.4 序列化失败回调

对于序列化过程中出现的错误，实际上就是 queryStringSerialization 外部编码出现的错误可以走 failure 回调，结束此次请求。

#### 2.1.5 传给 URLSessionManager 创建 dataTask

URLSessionManager 持有了创建 dataTask 所需的 NSURLSession 对象，因此需要最后由 URLSessionManager 创建对应的 task，它所做的工作如下

```objectivec
    __block NSURLSessionDataTask *dataTask = nil;
    url_session_manager_create_task_safely(^{
        // 利用 request 创建一个 dataTask
        dataTask = [self.session dataTaskWithRequest:request];
    });

    [self addDelegateForDataTask:dataTask uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];

    return dataTask;
```

除了创建 task 以外，URLSessionManager 需要对每一个 task 设置它的代理对象，具体在 addDelegateForDataTask 方法里，这个方法的实现如下

```objectivec
    // 创建代理对象
    AFURLSessionManagerTaskDelegate *delegate = [[AFURLSessionManagerTaskDelegate alloc] initWithTask:dataTask];
    delegate.manager = self;
    // 传入回调
    delegate.completionHandler = completionHandler;

    dataTask.taskDescription = self.taskDescriptionForSessionTasks;
    // 将 task 与其代理对象的键值对加入到 mutableTaskDelegatesKeyedByTaskIdentifier
    // 并监听 task 启动和挂起通知
    [self setDelegate:delegate forTask:dataTask];

    // 设置进度回调
    delegate.uploadProgressBlock = uploadProgressBlock;
    delegate.downloadProgressBlock = downloadProgressBlock;
```

可以看到 URLSessionManager 对象其实并未细致到每一个 task 进行控制和处理，更多是对 task 的汇聚和管理，具体的回调、更新、异常处理都在每一个 task 对应的代理对象中实现。

### 2.2 处理响应

AFNetworking 3.0 内部使用的网络 API 是 URLSession，它有一系列的回调方法，涵盖 SSL 建立、发送数据、收到响应行、收到响应实体、异常处理和结束请求等关键过程，具体又分为以下几个协议类

* NSURLSessionDelegate : session-level 的代理方法
* NSURLSessionTaskDelegate : task-level 面向 all 的代理方法
* NSURLSessionDataDelegate : task-level 面向 data 和 upload 的代理方法
* NSURLSessionDownloadDelegate : task-level 面向 download 的代理方法
* NSURLSessionStreamDelegate : task-level 面向 stream 的代理方法

#### 2.2.1 接收数据

GET 请求主要关注 NSURLSessionDataDelegate 方法，当收到数据时，系统会回调 URLSessionManager 的 ```URLSession:dataTask:didReceiveData:``` 方法，原因是初始化 URLSessionManager 时，session 的代理对象设置的就是 URLSessionManager。

这个方法的实现很简单，主要做了以下工作

* 回调此事件给 task 的代理对象
* 回调 dataTaskDidReceiveData block

具体如下

```objectivec
{
    // 查找 task 对应的 delegate
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:dataTask];
    // 回调给代理对象同名方法
    [delegate URLSession:session dataTask:dataTask didReceiveData:data];

    // manager 类统一回调
    if (self.dataTaskDidReceiveData) {
        self.dataTaskDidReceiveData(session, dataTask, data);
    }
}
```

而对于每一个 task 的代理对象 AFURLSessionManagerTaskDelegate 类，也要实现一个同名方法，这个方法具体做的事情是将收到的数据汇聚到一个 NSData 中

```objectvec
{
    self.downloadProgress.totalUnitCount = dataTask.countOfBytesExpectedToReceive;
    self.downloadProgress.completedUnitCount = dataTask.countOfBytesReceived;

    [self.mutableData appendData:data];
}
```

#### 2.2.2 完成响应

这里就有两个问题了，其一是每一个 task 总会结束，结束后它的代理对象也就没有意义需要销毁，其二是，数据何时才能结束添加并最终回调给调用者。其实这些都在 NSURLSessionTaskDelegate 协议的 ```URLSession:task:didCompleteWithError:``` 中，仍然像上面一样，首先系统会回调到 URLSessionManager 中，在这里 Manager 找到 task 的代理对象，调用它的同名方法

```objectivec
{
    // 获取代理对象
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];

    // delegate may be nil when completing a task in the background
    if (delegate) {
        // 回调同名方法
        [delegate URLSession:session task:task didCompleteWithError:error];

        // 从 mutableTaskDelegatesKeyedByTaskIdentifier 移除task的代理对象，同时销毁对 task 的监听
        [self removeDelegateForTask:task];
    }

    // 统一回调
    if (self.taskDidComplete) {
        self.taskDidComplete(session, task, error);
    }
}
```

而在 AFURLSessionManagerTaskDelegate 的同名方法里则完成了数据的解析、序列化和回调，主要来说有以下工作

* 对系统回调返回的 error 走异常处理，此时 responseObject 为 nil
* 对响应中的二进制数据进行序列化操作，默认通过 AFJSONResponseSerializer 进行序列化
* 回调到网络请求方

#### 2.2.3 序列化操作

这里主要看一下序列化 response 的操作，AFHTTPSessionManager 默认使用的序列化类是 AFJSONResponseSerializer，除此之外还有 AFHTTPResponseSerializer、AFXMLParserResponseSerializer、AFXMLDocumentResponseSerializer、AFPropertyListResponseSerializer、AFImageResponseSerializer 等序列化器。

下面分析几个主要的序列化器的内部逻辑。

##### 2.2.3.1 AFJSONResponseSerializer

序列化的核心方法是 ```responseObjectForResponse:data:error:``` ，这个方法由 AFURLResponseSerialization 协议类定义，AFJSONResponseSerializer 的实现做了如下工作

* 验证合法性
* 调用 NSJSONSerialization 转化为 JSON 对象
* 去除值为 NSNULL 的情况（可选）

验证合法性这一步，AFJSONResponseSerializer 用到了它的父类 AFHTTPResponseSerializer 定义的 ```validateResponse:data:error:``` 方法，这个方法主要检查

* MIMEType 是否在 AFHTTPResponseSerializer 定义的 acceptableContentTypes 中，不同的序列化器包含了不同的 MTMEType，对于 AFJSONResponseSerializer，包含以下类型application/json、text/json、text/javascript
* 状态码在 acceptableStatusCodes 中，即 200-299

验证合法性结束后就调用 NSJSONSerialization 的 ```+ (nullable id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error;``` 方法，将数据转为 JSON 对象，可能是字典或者数组。如果外部设置了 removesKeysWithNullValues，即代表需要将 value 为 NSNULL 的键值对去除，这一步操作在 AFJSONObjectByRemovingKeysWithNullValues 方法中实现。

##### 2.2.3.2 AFHTTPResponseSerializer

作为父类，AFHTTPResponseSerializer 的序列化操作仅仅检查了合法性就直接返回数据了

```objectivec
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    [self validateResponse:(NSHTTPURLResponse *)response data:data error:error];

    return data;
}
```

同时，它的 acceptableContentTypes 为 nil。

##### 2.2.3.3 AFXMLParserResponseSerializer 

AFXMLParserResponseSerializer 接受 "application/xml" 及 "text/xml" 类型的 MIMEType，它的序列化过程主要调用如下方法

```objectivec
[[NSXMLParser alloc] initWithData:data];
```

##### 2.2.3.4 AFXMLDocumentResponseSerializer

AFXMLDocumentResponseSerializer 接受 "application/xml" 及 "text/xml" 类型的 MIMEType，它的序列化过程主要调用如下方法

```objectivec
    NSError *serializationError = nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:self.options error:&serializationError];
```

##### 2.2.3.5 AFPropertyListResponseSerializer

AFPropertyListResponseSerializer 接受 "application/x-plist" 类型的 MIMEType，它的序列化过程主要调用如下方法

```objectivec
    NSError *serializationError = nil;
    
    id responseObject = [NSPropertyListSerialization propertyListWithData:data options:self.readOptions format:NULL error:&serializationError];
```

##### 2.2.3.6 AFImageResponseSerializer

AFImageResponseSerializer 定义了许多与图片相关 MIMEType，包括 "image/tiff", "image/jpeg", "image/gif", "image/png", "image/ico", "image/x-icon", "image/bmp", "image/x-bmp", "image/x-xbitmap", "image/x-win-bitmap" 等等。

图片序列化的过程如果细分会很复杂，这里简单概括一下如下

* 验证合法性
* 是否自动解码，需要自动解码则通过 CGContextDrawImage 解码图片
* 返回图片

##### 2.2.3.7 AFCompoundResponseSerializer

AFCompoundResponseSerializer 是一个混合序列化器，它接受一系列的序列化器，当收到 response 时，一个一个去尝试能否解析出最终结果，如果都无法解析，则会调用到 AFHTTPResponseSerializer 的默认实现。