# AutoLayout指南·AutoLayout Cookbook

## StackView

下面的指南将会向你展示如何使用 StackView 来创建比较复杂的布局。StackView 是一个非常有用的工具，它可以方便快捷地设计出你的用户界面。它的属性允许你很高程度地控制它对子视图的布局设置。你可以通过一些附加的自定义约束来增强这些设置，但是这样也会增加布局的复杂度。

查看此指南的源码请查阅 [Auto Layout Cookbook](https://developer.apple.com/sample-code/xcode/downloads/Auto-Layout-Cookbook.zip)

### 简单的 StackView

这里我们用一个垂直的 StackView 来布局一个 label、一个 imageview、一个 button。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Simple_Stack_View_Screenshot_2x.png" width=500>

#### 视图和约束

在 Interface Builder 中，首先拖进一个垂直的 StackView，然后添加一个 flower label，一个 imageview，一个编辑的 button，然后将它们的约束配置成下图

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/simple_stack_2x.png" width=500>

```
Stack View.Leading = Superview.LeadingMargin
Stack View.Trailing = Superview.TrailingMargin
Stack View.Top = Top Layout Guide.Bottom + Standard
Bottom Layout Guide.Top = Stack View.Bottom + Standard
```

#### 属性

在属性检查器中，需要设置下列 StackView 属性

|Stack|Axis|Alignment|Distribution|Spacing|
|---|---|---|---|---|
|StackView|Vertical|Fill|Fill|8|

然后将 imageview 属性设置如下

|View|Attribute|Value|
|---|---|---|
|ImageView|Image|一个花朵的图片|
|ImageView|Mode|Aspect Fit|

最后在属性检查器中将 imageview 的 content-hugging 和 compression-resistance（CHCR）优先级设置如下

|Name|Horizontal hugging|Verticle hugging|Horizontal resistance|Vertical resistance|
|---|---|---|---|---|
|Imageview|250|249|750|749|

#### 讨论

你必须将 StackView 加到父 view 上，否则 StackView 就会因为缺少参考约束而无法设置整个布局。

在这里我们将 StackView 填充父 view，并设置了一个很小的标准边距。而 StackView 的子视图将会重新设置尺寸以填充 StackView 的内部区域。水平方向上，所有的 view 都会被拉伸以匹配 StackView 的宽度。竖直方向上，view 会按照它们的 CHCR 优先级而被拉伸。由于 Imageview 要始终保持填满可填充区域，所以它的 Vertical content-hugging 和 compression-resistance 优先级要低于 label 和 button 的默认优先级。

最后我们设置了 Imageview 的展示模式为 Aspect Fit。这个设置强制使 imageView 调整自身 image，让图片以不改变宽高比的方式适应进 imageView 中。这样可以保证在 StackView 任意改变 Imageview 的尺寸时不会让它上面的 image 改变自身宽高比而导致图片扭曲变形。

### 嵌套 StackView

这里我们将用嵌套 StackView 的方式实现一个比较复杂的多层布局。但是在示例中仅凭 StackView 是不能完成效果的，还要借助一些约束来更好的配置布局。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Nested_Stack_Views_Screenshot_2x.png" width=500>

我们会在构建完视图层级后，在下一节 [Views and Constraints](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/LayoutUsingStackViews.html#//apple_ref/doc/uid/TP40010853-CH11-SW12) 添加额外的约束。

#### 视图和约束

当使用内嵌的 stackView 时，从内向外布局是最容易的。首先将姓名行放置在 IB 中，然后将 label 和 textfield 放置在正确的位置，选中它们然后点击 Editor->Embed In->Stack View 选项，这样就创建了一个水平的 StackView 来装载这一行。

然后将这些行水平放置好，选中所有姓名行，再次点击 Editor->Embed In->Stack View。这样就创建了一个水平 StackView 来装载所有姓名行。依据下图继续创建界面。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/nested_stack_views_2x.png" width=500>

```
Root Stack View.Leading = Superview.LeadingMargin
Root Stack View.Trailing = Superview.TrailingMargin
Root Stack View.Top = Top Layout Guide.Bottom + 20.0
Bottom Layout Guide.Top = Root Stack View.Bottom + 20.0
Image View.Height = Image View.Width
First Name Text Field.Width = Middle Name Text Field.Width
First Name Text Field.Width = Last Name Text Field.Width
```

#### 属性

每一个 StackView 都有其自己的属性集合，这些属性定义了 StackView 如何布局它的子视图。在属性检查器中设置这些属性

|Stack|Axis|Alignment|Distribution|Spacing|
|---|---|---|---|---|
|First Name|Horizontal|First Baseline|Fill|8
|Middle Name|Horizontal|First Baseline|Fill|8
|Last Name|Horizontal|First Baseline|Fill|8
|NameRows|Vertical|Fill|Fill|8
|Upper|Horizontal|Fill|Fill|8
|Button|horizontal|First Baseline|Fill Equally|8
|Root|Vertical|Fill|Fill|8

另外，对 textView，需要设置一个亮灰色背景颜色，从而可以看出当设备旋转时 textview 是如何重新计算尺寸的。

|View|Attribute|Value|
|textView|Background|Light Gray Color|

最后在属性检查器中设置 view 的 CHCR 优先级

|Name|Horizontal hugging|Verticle hugging|Horizontal resistance|Vertical resistance|
|---|---|---|---|---|
|ImageView|250|250|48|48|
|TextView|250|249|250|250|
|First,Middle,Last Name Label|251|251|750|750|
|First,Middle,Last Name textfield|48|250|749|750|

#### 讨论

在这里，我们用多个 StackView 创建了大部分的布局，但是并不能完全依靠 StackView 来实现所有想要的效果。例如我们想让图片在 imageview 改变尺寸时保持自己的长宽比，就无法使用 [Simple Stack View](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/LayoutUsingStackViews.html#//apple_ref/doc/uid/TP40010853-CH11-SW2) 中的技术来实现了。这个布局需要紧贴图片的边线，而使用 Aspect Fit 模式会在横向或纵向的某个维度上添加额外的空白。幸运的是，在这个例子中我们用到的图片都是正方形的，所以你可以确保图片一定能完美地紧贴边线，同时将图片的长宽比约束为 1：1。

> 注意
> 
> 在 IB 中一个长宽比约束代表一个 view 的长宽之间的约束，IB 还可以用一些方法来设置长宽比约束的乘数因子，一般来说 IB 会将约束表达为一个比率，例如一个表示宽高相等的约束可以表达为 1：1.

另外，所有的 textfield 都要等宽度，不幸的是这些 textfield 都在不同的 StackView 中，所以这几个 StackView 无法实现自动让 textfield 等宽，因此，你必须显式地为这些 textfield 添加等宽约束。

同时就像示例中一样，你需要修改一些 CHCR 优先级，从而定义当父视图的区域变化时，view 如何伸缩。

垂直方向上，你想要 textView 扩展自己从而填满 upper Stack 和 button Stack 之间的空白区域，所以 textView 的 Vertical content-hugging 优先级就必须小于其他两个 Stackview 的 Vertical content-hugging 优先级。

水平方向上，label 需要按照其 intrinsic content size 来展示，而 textfield 要伸缩自己从而填满可填充区域。默认的 CHCR 优先级对于 label 来说可以实现这样的效果，因为 IB 已经将所有 label 的 content-hugging 设置为 251，保证其大于 textfield 的 content-hugging。但是你还是应该使 textfield 的 Horizontal content-hugging 和 Horizontal content-hugging 尽量小。

imageview 应当伸缩自身以保证其高度和包含三行 name 的 StackView 一致，然而 StackView 自身的 content-hugging 优先级是小于其子视图的，所以为了避免 StackView 被拉伸，而保证 imageview 被压缩来适应 StackView 的内部区域，需要将 imageview 的 Vertical compression resistance 设置非常低。另外，imageview 的长宽比使得布局变得较为复杂，因为长宽比使得水平约束与竖直约束互相之间发生了影响。这意味着 textfield 的 Horizontal content-hugging 必须非常小，或阻止 image view 压缩。考虑上述情况，需要将 textfield 的 Horizontal content-hugging 设置为小于 48 的值。__此处有疑问__

### 动态 StackView

这里演示了如何在运行时动态向一个 StackView 添加和移除元素，并且所有发生在 StackView 的变化都有动画效果。另外还将 StackView 放进了一个 ScrollView 中，从而保证当列表中的元素过多时可以滑动查看。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Dynamic_Stack_View_Screenshot_2x.png" width=500>

> 注意
> 
> 这里只是故意演示如何用 StackView 动态地实现布局效果，以及如何将 StackView 放进 scrollView 中使用。在一个需要实际上线的 app 中应当使用 UITableView 代替这种方式。一般来说，你不应当只是使用动态 StackView 来实现一个粗糙简陋的 TableView，而是应当将其用于实现一些其他技术无法方便实现的用户界面。

#### 视图和约束

初始界面很简单，你需要放置一个 scrollView 在 IB 的场景中，然后设置它的大小铺满整个场景，再把一个 StackView 放进 scrollView 中，并在 StackView 中加入一个添加元素的按钮。当所有元素都添加完毕后，将约束设置如下

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/dynamic_stack_view_2x.png" width=500>

```
Scroll View.Leading = Superview.LeadingMargin

Scroll View.Trailing = Superview.TrailingMargin

Scroll View.Top = Superview.TopMargin

Bottom Layout Guide.Top = Scroll View.Bottom + 20.0

Stack View.Leading = Scroll View.Leading

Stack View.Trailing = Scroll View.Trailing

Stack View.Top = Scroll View.Top

Stack View.Bottom = Scroll View.Bottom

Stack View.Width = Scroll View.Width
```

#### 属性

在属性检查器中，设置 StackView 的属性如下

|Stack|Axis|Alignment|Distribution|Spacing|
|---|---|---|---|---|
|StackView|Vertical|Fill|Equal Spacing|0|

#### 代码

这里需要一些代码来实现向 StackView 添加和移除元素，所以为你的场景创建 ViewController，并添加 scrollView 和 StackView 的 outlet。

```swift
class DynamicStackViewController: UIViewController {
    
    @IBOutlet weak private var scrollView: UIScrollView!
    @IBOutlet weak private var stackView: UIStackView!
    
    // Method implementations will go here...
    
}
```

接下来覆写 viewDidLoad 函数，设置 scrollView 的初始位置在状态栏下面。

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup scrollview
    let insets = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)
    scrollView.contentInset = insets
    scrollView.scrollIndicatorInsets = insets
    
}
```

然后给添加元素的按钮设置一个 action

```swift
// MARK: Action Methods
 
@IBAction func addEntry(sender: AnyObject) {
    
    let stack = stackView
    let index = stack.arrangedSubviews.count - 1
    let addView = stack.arrangedSubviews[index]
    
    let scroll = scrollView
    let offset = CGPoint(x: scroll.contentOffset.x,
                         y: scroll.contentOffset.y + addView.frame.size.height)
    
    let newView = createEntry()
    newView.hidden = true
    stack.insertArrangedSubview(newView, atIndex: index)
    
    UIView.animateWithDuration(0.25) { () -> Void in
        newView.hidden = false
        scroll.contentOffset = offset
    }
}
```

这个方法为 scrollView 计算了一个新的 offset 值，然后创建了一个新的实体视图并添加到 StackView 中，这个视图是隐藏的。隐藏的 view 不会影响到 StackView 的布局或界面。然后在动画代码块中，视图会被显示出来，scroll offset 也会被更新，同时伴随 view 的显示动画。

添加一个类似的方法用于删除实体。删除实体的方法不像 addEntity，这个方法不会与 IB 的任何控制器相连，app 将会在创建 view 时用代码配置每一个实体 view 与这个方法相连。

```swift
func deleteStackView(sender: UIButton) {
    if let view = sender.superview {
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            view.hidden = true
        }, completion: { (success) -> Void in
            view.removeFromSuperview()
        })
    }
}
```

这个方法在动画代码块中隐藏了一个 view，动画结束后将这个 view 从视图层级中移除，同时也会自动从 StackView 的子视图列表中删除这个视图。

尽管实体 view 可以是任何 view，但我们在这里会将一个日期 label、一个显示随机十六进制数字的 label、一个删除按钮放进 StackView。

```swift
// MARK: - Private Methods
private func createEntry() -> UIView {
    let date = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .NoStyle)
    let number = "\(randomHexQuad())-\(randomHexQuad())-\(randomHexQuad())-\(randomHexQuad())"
    
    let stack = UIStackView()
    stack.axis = .Horizontal
    stack.alignment = .FirstBaseline
    stack.distribution = .Fill
    stack.spacing = 8
    
    let dateLabel = UILabel()
    dateLabel.text = date
    dateLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    
    let numberLabel = UILabel()
    numberLabel.text = number
    numberLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
    
    let deleteButton = UIButton(type: .RoundedRect)
    deleteButton.setTitle("Delete", forState: .Normal)
    deleteButton.addTarget(self, action: "deleteStackView:", forControlEvents: .TouchUpInside)
    
    stack.addArrangedSubview(dateLabel)
    stack.addArrangedSubview(numberLabel)
    stack.addArrangedSubview(deleteButton)
    
    return stack
}
 
private func randomHexQuad() -> String {
    return NSString(format: "%X%X%X%X",
                    arc4random() % 16,
                    arc4random() % 16,
                    arc4random() % 16,
                    arc4random() % 16
        ) as String
}
}
```

#### 讨论

正如本节所演示的，视图可以在运行时被添加到或移除出 StackView，StackView 的布局会自动适应其子视图列表的变化。但是这里仍然有一些需要注意的点

* 隐藏的视图仍然会被加入到 StackView 的子视图列表中，但是不会被显示也不会对其他子视图的布局产生影响
* 向 StackView 添加一个视图会自动将其加入到视图层级中
* 从 StackView 的子视图列表中移除一个视图不会将其移除出视图层级，但是将视图从视图层级移除时会自动从 StackView 的子视图列表中移除
* 在 iOS 中，view 的隐藏属性正常来说不会有动画效果，但是一旦将其放入到 StackView 的子视图列表中，隐藏属性就会带有动画效果了。真正的动画动作是由 StackView 而非 view 自身完成的，所以可以使用 hidden 属性实现添加删除 view 时的动画效果

这一节也介绍了如何将 AutoLayout 与 scrollView 放在一起使用，这里利用了 StackView 与 scrollView 之间的约束来设置 scrollView 的内容区尺寸。垂直方向上，内容区尺寸会基于 StackView 的适应尺寸而变化。StackView 会因为内容区的元素增加而变长，scrollView 的滑动性会由于内容区元素超出一屏的内容而自动激活。

查看更多信息请看 [Working with Scroll Views](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/WorkingwithScrollViews.html#//apple_ref/doc/uid/TP40010853-CH24-SW1)