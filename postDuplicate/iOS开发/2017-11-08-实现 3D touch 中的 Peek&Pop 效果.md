3D touch 是苹果定义的新一代多点触控技术，支持 3D touch 的屏幕可以感应不同的压力触控，做出不同的响应动作，自 iOS 9 开始支持，并提供了下列四类 API

* Home Screen Quick Action，也就是在桌面状态下按压 App 的 Icon 图标时可以弹出一个选择对话框
* UIKit Peek & Pop，允许用户通过短时间按压屏幕弹出预览内容，继续按压弹出详细内容
* WebView Peek & Pop 在网页中实现 3D touch 效果
* UITouch Force Properties 允许应用通过检测交互的力度做出不同响应

这里简单介绍下 UIKit Peek & Pop 的实现。Peek & Pop 效果大致可以分为三个阶段，这里以系统相册为例

* 第一阶段，交互控件突出显示，其他控件模糊处理

<img src="https://wiki.sankuai.com/download/attachments/1160111064/image2017-10-31%2011%3A27%3A34.png?version=1&modificationDate=1509427205000&api=v2" width=500>

* 第二阶段，弹出预览视图

<img src="https://wiki.sankuai.com/download/attachments/1160111064/image2017-10-31%2011%3A27%3A54.png?version=1&modificationDate=1509427205000&api=v2" width=500>

这一阶段还可以选择是否支持上滑手势呼出一个选择栏

<img src="https://wiki.sankuai.com/download/attachments/1160111064/image2017-10-31%2011%3A29%3A30.png?version=1&modificationDate=1509427205000&api=v2" width=500>

* 第三阶段，弹出详细视图

<img src="https://wiki.sankuai.com/download/attachments/1160111064/image2017-10-31%2011%3A27%3A13.png?version=1&modificationDate=1509427205000&api=v2" width=500>

实际上，这些阶段的动画效果都由系统来处理，开发者只需要将交互控件、预览视图、详细视图及选择栏定义好就可以了。在实现 3D touch 之前，还需要检测设备是否支持 3D touch

```objectivec
        if (IOS9_OR_LATER) {
            if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                // 3D touch 可用
            } else {
                // 3D touch 不可用
            }
        }
```

系统定义了三种权限状态

```objectivec
    UIForceTouchCapabilityUnknown = 0, // 检测失败
    UIForceTouchCapabilityUnavailable = 1, // 不可用
    UIForceTouchCapabilityAvailable = 2 // 可用
```

同时在应用运行中，也可以检测到用户是否修改了 3D touch 功能，只需要在 VC 中实现下面的方法

```objectivec
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	//do something
}
```

检测有权限后就可以注册交互控件 sourceView 了

```objectivec
[self registerForPreviewingWithDelegate:self sourceView:_imageCollectionView];
```

这样 imageCollectionView 就可以响应 3D touch 了。

接下来是对 Peek 和 Pop 效果的实现，需要实现 UIViewControllerPreviewingDelegate 协议中的两个方法

```objectivec
- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location NS_AVAILABLE_IOS(9_0);
- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit NS_AVAILABLE_IOS(9_0);
```

第一个方法返回一个 VC 用于预览视图，第二个方法里实现逻辑来呈现详细视图，比如进行页面跳转或者 present 出另一个视图。

而在第一个方法中可以定义第一阶段中突出显示的区域和模糊的区域，这里实现将 collectionView 中一个 cell 的区域作为突出显示区域的效果

```
- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [self.imageCollectionView indexPathForItemAtPoint:location];    
    MTBCYSingleImageCell *cell = (MTBCYSingleImageCell *)[self.imageCollectionView cellForItemAtIndexPath:indexPath];
    CGRect rect = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
    previewingContext.sourceRect = rect;
    
    ···生成 VC···
    return peekTouchVC;
}
```

可以看到，通过 location 可以获取对应的 cell，将 previewingContext.sourceRect 赋值为 cell 的 frame 值就可以实现突出显示 cell 的区域。

而如果要在 Peak 状态下上滑呼出一个选择对话框，则只需要实现 previewActionItems 的 getter 方法。

```objectivec
- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    
    // 生成UIPreviewAction
    UIPreviewAction *action1 = [UIPreviewAction actionWithTitle:@"Action 1" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        NSLog(@"Action 1 selected");
    }];
    
    UIPreviewAction *action2 = [UIPreviewAction actionWithTitle:@"Action 2" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        NSLog(@"Action 2 selected");
    }];
    
    UIPreviewAction *action3 = [UIPreviewAction actionWithTitle:@"Action 3" style:UIPreviewActionStyleSelected handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        NSLog(@"Action 3 selected");
    }];
    
    UIPreviewAction *tap1 = [UIPreviewAction actionWithTitle:@"tap 1" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        NSLog(@"tap 1 selected");
    }];
    
    UIPreviewAction *tap2 = [UIPreviewAction actionWithTitle:@"tap 2" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        NSLog(@"tap 2 selected");
    }];
    
    UIPreviewAction *tap3 = [UIPreviewAction actionWithTitle:@"tap 3" style:UIPreviewActionStyleSelected handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        NSLog(@"tap 3 selected");
    }];
    
    //添加到到UIPreviewActionGroup中
    NSArray *actions = @[action1, action2, action3];
    NSArray *taps = @[tap1, tap2, tap3];
    UIPreviewActionGroup *group1 = [UIPreviewActionGroup actionGroupWithTitle:@"Action Group" style:UIPreviewActionStyleDefault actions:actions];
    UIPreviewActionGroup *group2 = [UIPreviewActionGroup actionGroupWithTitle:@"Tap Group" style:UIPreviewActionStyleDefault actions:taps];
    NSArray *group = @[group1, group2];
    
    return group;
}
``` 