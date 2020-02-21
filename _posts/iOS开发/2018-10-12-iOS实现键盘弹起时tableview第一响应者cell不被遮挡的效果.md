---
category: iOS开发
description: "近期在调研 XLForm 框架，一个集成多种表单常见功能的框架，其中对于 UITableView 中的输入框与键盘弹出隐藏逻辑进行了相关处理以避免输入区域被遮挡。"
---

近期在调研 XLForm 框架，一个集成多种表单常见功能的框架，其中对于 UITableView 中的输入框与键盘弹出隐藏逻辑进行了相关处理以避免输入区域被遮挡。

下面是我的实现

首先实现一个 cell，其中包含一个 UITextField，用于获取第一响应者，弹出键盘

```objective_c
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self){
        [self addViews];
    }
    return self;
}

- (void)addViews
{
    [self addSubview:self.textInput];
}

- (UITextField *)textInput
{
    if (!_textInput) {
        _textInput = [[UITextField alloc] initWithFrame:CGRectMake(0, 44, 100, 44)];
    }
    return _textInput;
}
```

其次对键盘事件进行监听，包括 UIKeyboardWillShowNotification 和 UIKeyboardWillHideNotification

```objective_c
    // 添加键盘弹出事件监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    // 添加键盘隐藏事件监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
```

这里主要关注了键盘弹出事件，实现原理是通过弹出事件获取到键盘高度以及动画时间等信息，然后对 tableview 也做一个动画，将它的 contentInset 的 bottom 值设置为键盘区域顶部，这样做的目的是改变 tableView 的可滑动区域，再结合 scrollToRowAtIndexPath 方法，保证 UITextField 所在的 cell 完全展示不被遮挡。这里存在一些问题，稍后解释。

下面是具体的代码

```objective_c
- (void)keyboardWillShow:(NSNotification *)notification
{
    // 取出当前第一响应者
    UIView *firstResponderView = [self.inputTableView findFirstResponder];
    // 取出第一响应者所在的 cell
    UITableViewCell *cell = [firstResponderView findAttachedCell];
    if (!cell) {
        return;
    }
    
    // 取出 userInfo，其中包含一些与键盘相关的信息，如
    // UIKeyboardFrameEndUserInfoKey 键盘在屏幕坐标系中最终展示的矩形 frame 尺寸
    // UIKeyboardAnimationDurationUserInfoKey 键盘弹出动画时长
    // UIKeyboardAnimationCurveUserInfoKey 键盘弹出动画曲线
    NSDictionary *keyboardInfo = [notification userInfo];
    // 将键盘 frame 转换到 tableView 上
    CGRect keyboardFrame = [self.inputTableView.window convertRect:[keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:self.inputTableView.superview];
    // 计算出 tableview 底部被键盘遮挡的区域
    CGFloat newBottomInset = self.inputTableView.frame.origin.y + self.inputTableView.frame.size.height - keyboardFrame.origin.y;
    UIEdgeInsets tableContentInset = self.inputTableView.contentInset;
    NSNumber *currentBottomTableContentInset = @(tableContentInset.bottom);
    if (newBottomInset > [currentBottomTableContentInset floatValue]) { // 的确遮挡了 tableview
        tableContentInset.bottom = newBottomInset;
        // 启动动画
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:[keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[keyboardInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];
        // 改变 tableView 的 contentInset
        self.inputTableView.contentInset = tableContentInset;
        // 滚动到第一响应者所在的 cell，UITableViewScrollPositionNone 保证以最小的滚动完全展示 cell
        NSIndexPath *selectedRow = [self.inputTableView indexPathForCell:cell];
        [self.inputTableView scrollToRowAtIndexPath:selectedRow atScrollPosition:UITableViewScrollPositionNone animated:NO];
        [UIView commitAnimations];
    }
}
```

注释基本解释清楚了整个过程，但仍然存在一个问题，即为什么必须要修改 contentInset。

实际上大概是 iOS4 版本以后（“大概是”表示消息来源不可靠），UITextField 就有一个特性，如果在 UITableView 中展示的 UITextField 被遮挡了，即使仅遮挡一部分，UITextField 也会滚动整个 tableview，以确保自身被完全展示出来。

单纯考虑这一条，我尝试去除了所有代码，不设置 contentInset，也不滚动到 cell，结果发现键盘弹出时并不会将 UITextField 展示出来，其判断是否自身被“遮挡”，即“不可见”并不是依赖于键盘遮挡这种情况，甚至就算放一个 view 到 tableview 上挡住这个 UITextField，也不会被 UITextField 认为是遮挡。UITextField 是按照自己是否在 UItableView 的“可视区域”来判断是否遮挡，而可视区域是根据 UITableView 的 frame，去除 contentInset 以后得到的区域来确定的。

所以这里如果不设置 contentInset，即使调用了 scrollToRowAtIndexPath 也没有用，UITableViewScrollPositionNone 仍然是按照“可视区域”来决定是否 cell 已经完全展示的。

> UITableViewScrollPositionNone
> 
> The table view scrolls the row of interest to be fully visible with a minimum of movement. If the row is already fully visible, no scrolling occurs. For example, if the row is above the visible area, the behavior is identical to that specified by UITableViewScrollPositionTop. This is the default.

所以当设置了 contentInset 的 bottom 间距刚好为键盘高度时，就可以实现获取第一响应者的 UITextField 自动滑动到屏幕可视范围了，scrollToRowAtIndexPath 也能正常滚动了。