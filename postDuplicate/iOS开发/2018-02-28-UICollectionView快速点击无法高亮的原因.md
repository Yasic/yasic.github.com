在 MTBCYAlbumKit 中有一个用于切换相册的 view，使用 collectionview 展示系统相册列表和用户相册列表，点击列表元素实现相册切换功能，其中 UI 要求点击时元素背景颜色变深，点击结束后恢复颜色。

collectionview 自身有两个代理方法可以实现此效果。

```objectivec
- (void)collectionView : (UICollectionView *)collectionView didHighlightItemAtIndexPath : (NSIndexPath *)indexPath
{
    [collectionView cellForItemAtIndexPath:indexPath].contentView.backgroundColor = HEXCOLOR(0xF5F5F5);
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath : (NSIndexPath *)indexPath
{
    [collectionView cellForItemAtIndexPath:indexPath].contentView.backgroundColor = IMERCHANT_WHITE;
}
```

但是在使用中发现有如下问题：快速点击列表内元素时不会出现高亮效果，只有按住一小段时间才会出现高亮效果。网上给出的解决方法是将 collectionview 的 delaysContentTouches 属性设置为 NO，下面阐述调研后的具体原因。

### delaysContentTouches 属性

delaysContentTouches 其实是 UIScrollView 的属性，它的含义如下

> A Boolean value that determines whether the scroll view delays the handling of touch-down gestures.
> 
> 一个布尔值，用于确定滚动视图是否延迟触摸手势的处理。

这里涉及到 UIScrollView 对于手势的处理逻辑，当手指开始 touch 屏幕时，scrollview 会启动一个短时间的定时器，在此期间，如果检测到手势有明显滑动，则 scrollView 发生滚动，并且不会将事件下发到 cell。如果此期间没有明显滑动，则触发 cell 的 touchBegin 事件，但同时如果之后手指发生滑动了，scrollView 就会传递 touchCancelled 事件给 cell。

而如果将默认值为 YES 的 delaysContentTouches 属性设置为 NO，则不会启动此定时器，直接触发 cell 的 touchBegin 事件。

### 高亮效果

但是高亮效果是由 UICollectionView 确定的，为什么不设置 delaysContentTouches 为 NO 就不能出现高亮效果呢。

我对 UICollectionView 一些关键的代理方法做了埋点打印处理，具体如下

```objectivec
- (void)collectionView : (UICollectionView *)collectionView didHighlightItemAtIndexPath : (NSIndexPath *)indexPath
{
    NSLog(@"didHighlight");
    [collectionView cellForItemAtIndexPath:indexPath].contentView.backgroundColor = HEXCOLOR(0xF5F5F5);
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath : (NSIndexPath *)indexPath
{
    NSLog(@"didUnHighlight");
    [collectionView cellForItemAtIndexPath:indexPath].contentView.backgroundColor = IMERCHANT_WHITE;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectItemAtIndexPath");
    ···
}
```

同时对 cell 的手势处理方法进行了覆写

```objectivec
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    NSLog(@"touchesBegan");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesEnded1");
    [super touchesEnded:touches withEvent:event];
    NSLog(@"touchesEnded2");
}
```

分别对 delaysContentTouches 为 NO 和 YES 的情况进行五次点击测试后，得出如下数据

* delaysContentTouches = NO，快速点击变色

```
2018-02-28 09:12:39.942214+0800 MTBCYAlbumKit[22929:9571394] didHighlight
2018-02-28 09:12:39.942469+0800 MTBCYAlbumKit[22929:9571394] touchesBegan
2018-02-28 09:12:39.986804+0800 MTBCYAlbumKit[22929:9571394] touchesEnded1
2018-02-28 09:12:39.987212+0800 MTBCYAlbumKit[22929:9571394] didUnHighlight
2018-02-28 09:12:39.987573+0800 MTBCYAlbumKit[22929:9571394] didSelectItemAtIndexPath
2018-02-28 09:12:39.987737+0800 MTBCYAlbumKit[22929:9571394] touchesEnded2


2018-02-28 09:17:48.398848+0800 MTBCYAlbumKit[22936:9574330] didHighlight
2018-02-28 09:17:48.399059+0800 MTBCYAlbumKit[22936:9574330] touchesBegan
2018-02-28 09:17:48.443024+0800 MTBCYAlbumKit[22936:9574330] touchesEnded1
2018-02-28 09:17:48.443397+0800 MTBCYAlbumKit[22936:9574330] didUnHighlight
2018-02-28 09:17:48.443793+0800 MTBCYAlbumKit[22936:9574330] didSelectItemAtIndexPath
2018-02-28 09:17:48.444018+0800 MTBCYAlbumKit[22936:9574330] touchesEnded2

2018-02-28 09:17:57.665995+0800 MTBCYAlbumKit[22936:9574330] didHighlight
2018-02-28 09:17:57.666365+0800 MTBCYAlbumKit[22936:9574330] touchesBegan
2018-02-28 09:17:57.727243+0800 MTBCYAlbumKit[22936:9574330] touchesEnded1
2018-02-28 09:17:57.727588+0800 MTBCYAlbumKit[22936:9574330] didUnHighlight
2018-02-28 09:17:57.727932+0800 MTBCYAlbumKit[22936:9574330] didSelectItemAtIndexPath
2018-02-28 09:17:57.728064+0800 MTBCYAlbumKit[22936:9574330] touchesEnded2

2018-02-28 09:18:08.884289+0800 MTBCYAlbumKit[22936:9574330] didHighlight
2018-02-28 09:18:08.884659+0800 MTBCYAlbumKit[22936:9574330] touchesBegan
2018-02-28 09:18:08.945185+0800 MTBCYAlbumKit[22936:9574330] touchesEnded1
2018-02-28 09:18:08.945578+0800 MTBCYAlbumKit[22936:9574330] didUnHighlight
2018-02-28 09:18:08.946008+0800 MTBCYAlbumKit[22936:9574330] didSelectItemAtIndexPath
2018-02-28 09:18:08.946153+0800 MTBCYAlbumKit[22936:9574330] touchesEnded2

2018-02-28 09:18:28.736691+0800 MTBCYAlbumKit[22936:9574330] didHighlight
2018-02-28 09:18:28.737061+0800 MTBCYAlbumKit[22936:9574330] touchesBegan
2018-02-28 09:18:28.781248+0800 MTBCYAlbumKit[22936:9574330] touchesEnded1
2018-02-28 09:18:28.781590+0800 MTBCYAlbumKit[22936:9574330] didUnHighlight
2018-02-28 09:18:28.782002+0800 MTBCYAlbumKit[22936:9574330] didSelectItemAtIndexPath
2018-02-28 09:18:28.782147+0800 MTBCYAlbumKit[22936:9574330] touchesEnded2
```

* delaysContentTouches = YES，快速点击不变色

```
2018-02-28 09:13:25.126845+0800 MTBCYAlbumKit[22932:9572093] didHighlight
2018-02-28 09:13:25.127143+0800 MTBCYAlbumKit[22932:9572093] touchesBegan
2018-02-28 09:13:25.127362+0800 MTBCYAlbumKit[22932:9572093] touchesEnded1
2018-02-28 09:13:25.127587+0800 MTBCYAlbumKit[22932:9572093] didUnHighlight
2018-02-28 09:13:25.127891+0800 MTBCYAlbumKit[22932:9572093] didSelectItemAtIndexPath
2018-02-28 09:13:25.128023+0800 MTBCYAlbumKit[22932:9572093] touchesEnded2

2018-02-28 09:15:33.459640+0800 MTBCYAlbumKit[22932:9572093] didHighlight
2018-02-28 09:15:33.459983+0800 MTBCYAlbumKit[22932:9572093] touchesBegan
2018-02-28 09:15:33.460154+0800 MTBCYAlbumKit[22932:9572093] touchesEnded1
2018-02-28 09:15:33.460321+0800 MTBCYAlbumKit[22932:9572093] didUnHighlight
2018-02-28 09:15:33.460587+0800 MTBCYAlbumKit[22932:9572093] didSelectItemAtIndexPath
2018-02-28 09:15:33.460714+0800 MTBCYAlbumKit[22932:9572093] touchesEnded2

2018-02-28 09:16:33.733329+0800 MTBCYAlbumKit[22932:9572093] didHighlight
2018-02-28 09:16:33.733524+0800 MTBCYAlbumKit[22932:9572093] touchesBegan
2018-02-28 09:16:33.733674+0800 MTBCYAlbumKit[22932:9572093] touchesEnded1
2018-02-28 09:16:33.733760+0800 MTBCYAlbumKit[22932:9572093] didUnHighlight
2018-02-28 09:16:33.733864+0800 MTBCYAlbumKit[22932:9572093] didSelectItemAtIndexPath
2018-02-28 09:16:33.733975+0800 MTBCYAlbumKit[22932:9572093] touchesEnded2

2018-02-28 09:17:01.455392+0800 MTBCYAlbumKit[22932:9572093] didHighlight
2018-02-28 09:17:01.455700+0800 MTBCYAlbumKit[22932:9572093] touchesBegan
2018-02-28 09:17:01.455874+0800 MTBCYAlbumKit[22932:9572093] touchesEnded1
2018-02-28 09:17:01.456044+0800 MTBCYAlbumKit[22932:9572093] didUnHighlight
2018-02-28 09:17:01.456308+0800 MTBCYAlbumKit[22932:9572093] didSelectItemAtIndexPath
2018-02-28 09:17:01.456486+0800 MTBCYAlbumKit[22932:9572093] touchesEnded2

2018-02-28 09:17:14.455519+0800 MTBCYAlbumKit[22932:9572093] didHighlight
2018-02-28 09:17:14.455864+0800 MTBCYAlbumKit[22932:9572093] touchesBegan
2018-02-28 09:17:14.456056+0800 MTBCYAlbumKit[22932:9572093] touchesEnded1
2018-02-28 09:17:14.456232+0800 MTBCYAlbumKit[22932:9572093] didUnHighlight
2018-02-28 09:17:14.456488+0800 MTBCYAlbumKit[22932:9572093] didSelectItemAtIndexPath
2018-02-28 09:17:14.456613+0800 MTBCYAlbumKit[22932:9572093] touchesEnded2
```

最终统计 didHighlight 和 didUnHighlight 之间的时间间隔，得到数据如下，时间单位为秒。

|序号|delaysContentTouches = NO|delaysContentTouches = YES|
|---|---|---|
|1|0.044998|0.000742|
|2|0.044935|0.000681|
|3|0.061593|0.000431|
|4|0.061289|0.000652|
|5|0.044899|0.000713|
|平均值|0.0515428|0.0006438|

可以看出当 delaysContentTouches = YES 时，highlight 和 unhighlight 之间间隔比 delaysContentTouches = NO 时小了两个数量级，所以推测出 delaysContentTouches = YES 时不变色的 __可能原因__ 是变色过快，不能被肉眼察觉。另外值得注意的是，大量耗时过程发生在 touchesBegan 与 touchesEnd 之间。

进一步对 ```- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event``` 方法进行埋点打印，多次测试后发现如下数据

* delaysContentTouches = YES 时不会触发 touchesMoved 事件
* delaysContentTouches = NO 时可能触发 touchesMoved 事件

```
delaysContentTouches = NO

2018-02-28 09:39:33.278930+0800 MTBCYAlbumKit[22948:9583284] didHighlight
2018-02-28 09:39:33.279310+0800 MTBCYAlbumKit[22948:9583284] touchesBegan
2018-02-28 09:39:33.292573+0800 MTBCYAlbumKit[22948:9583284] touchMoved
2018-02-28 09:39:33.308281+0800 MTBCYAlbumKit[22948:9583284] touchMoved
2018-02-28 09:39:33.340444+0800 MTBCYAlbumKit[22948:9583284] touchesEnded1
2018-02-28 09:39:33.340753+0800 MTBCYAlbumKit[22948:9583284] didUnHighlight
2018-02-28 09:39:33.341192+0800 MTBCYAlbumKit[22948:9583284] didSelectItemAtIndexPath
2018-02-28 09:39:33.341400+0800 MTBCYAlbumKit[22948:9583284] touchesEnded2

delaysContentTouches = YES

2018-02-28 09:37:12.255610+0800 MTBCYAlbumKit[22945:9582286] didHighlight
2018-02-28 09:37:12.255807+0800 MTBCYAlbumKit[22945:9582286] touchesBegan
2018-02-28 09:37:12.256025+0800 MTBCYAlbumKit[22945:9582286] touchesEnded1
2018-02-28 09:37:12.256137+0800 MTBCYAlbumKit[22945:9582286] didUnHighlight
2018-02-28 09:37:12.256255+0800 MTBCYAlbumKit[22945:9582286] didSelectItemAtIndexPath
2018-02-28 09:37:12.256366+0800 MTBCYAlbumKit[22945:9582286] touchesEnded2
```

所以 delaysContentTouches = NO 时大部分间隔发生在 touchBegin 和 touchEnd 之间，推测 __可能原因__ 是 cell 进行 touchesMoved 检测导致的时间消耗。

而网上对于实现 collectionView 点击高亮的补充说明通常如下

> 然而如果你实现了 本文介绍的 这个两个方法改变选中颜色，你会发现只有长按时才会看到设置的颜色。
> 
> 原因：长按没有松手的时候，触发的是高亮方法，松手触发的是取消高亮的方法。轻触点击的时候会很快速的响应 高亮和取消高亮的方法，所以看不到颜色的改变。此时，需要设置delaysContentTouches属性为NO，此时当点击的时候会立刻调用点击事件的begin方法，率先变成高亮状态。

其实真正耗时的操作并不是 begin 之前，而是在 begin 之后，end 之前。

### canCancelContentTouches

与 delaysContentTouches 相关的属性还有一个 canCancelContentTouches 属性，它的含义如下

> A Boolean value that controls whether touches in the content view always lead to tracking.
> 
> If the value of this property is YES and a view in the content has begun tracking a finger touching it, and if the user drags the finger enough to initiate a scroll, the view receives a touchesCancelled:withEvent: message and the scroll view handles the touch as a scroll. If the value of this property is NO, the scroll view does not scroll regardless of finger movement once the content view starts tracking.

也就是可以控制当一个子控件开始跟踪触摸事件后，能否接收 touchesCancelled 事件从而取消事件处理过程。