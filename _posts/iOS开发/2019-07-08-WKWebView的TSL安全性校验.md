---
category: iOS开发
description: "WKWebView 允许 native 介入到 HTTP 的验证流程，类似于 URLSession 一样对 Challenge 进行校验，具体代码如下"
---

WKWebView 允许 native 介入到 HTTP 的验证流程，类似于 URLSession 一样对 Challenge 进行校验，具体代码如下

```objective_c
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) { // 非服务端校验流程，走默认
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    SecTrustResultType result;
    int err = SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result); // 用系统证书进行服务端证书校验
    if (err) {
        // 证书校验失败
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }
    if (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed) {
        // 校验通过
        // kSecTrustResultProceed：验证成功，且该验证得到了用户认可(例如在弹出的是否信任的alert框中选择always trust)
        // kSecTrustResultUnspecified：验证成功，此证书也被暗中信任了，但是用户并没有显示地决定信任该证书
        NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
        return;
    } else {
        // 证书校验失败
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }
}
```

参考链接

[iOS中HTTP/HTTPS授权访问(二)](https://www.jianshu.com/p/ebee00c785bd)

[URL加载系统之四：认证与TLS链验证](http://southpeak.github.io/2014/07/16/url-load-system-4/)