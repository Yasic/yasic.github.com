---
category: AutoLayout
description: "接下来的话题是关于如何收集和组织你的布局的信息的技术，以及一些你可能会遇到的奇葩的布局表现。你可能并不需要在每一个布局上都使用这些技术，但是它们能帮助你即使遇到最困难的问题也能顺利完成布局工作。"
---

# 011-Autolayout指南·调试 AutoLayout

## 调试技巧

接下来的话题是关于如何收集和组织你的布局的信息的技术，以及一些你可能会遇到的奇葩的布局表现。你可能并不需要在每一个布局上都使用这些技术，但是它们能帮助你即使遇到最困难的问题也能顺利完成布局工作。

### 理解日志

有关视图的信息都可以被打印到控制台，无论是由于无法满足的布局，还是因为你调用 constraintsAffectingLayoutForAxis: 或者 constraintsAffectingLayoutForOrientation: 等调试函数显式地打印这些约束。

总之，你可以在这些日志里找到很多有用的信息，这里有一份有关无法满足的约束的示例输出：

```
2015-08-26 14:27:54.790 Auto Layout Cookbook[10040:1906606] Unable to simultaneously satisfy constraints.
    Probably at least one of the constraints in the following list is one you don't want. Try this: (1) look at each constraint and try to figure out which you don't expect; (2) find the code that added the unwanted constraint or constraints and fix it. (Note: If you're seeing NSAutoresizingMaskLayoutConstraints that you don't understand, refer to the documentation for the UIView property translatesAutoresizingMaskIntoConstraints) 
(
    "<NSLayoutConstraint:0x7a87b000 H:[UILabel:0x7a8724b0'Name'(>=400)]>",
    "<NSLayoutConstraint:0x7a895e30 UILabel:0x7a8724b0'Name'.leading == UIView:0x7a887ee0.leadingMargin>",
    "<NSLayoutConstraint:0x7a886d20 H:[UILabel:0x7a8724b0'Name']-(NSSpace(8))-[UITextField:0x7a88cff0]>",
    "<NSLayoutConstraint:0x7a87b2e0 UITextField:0x7a88cff0.trailing == UIView:0x7a887ee0.trailingMargin>",
    "<NSLayoutConstraint:0x7ac7c430 'UIView-Encapsulated-Layout-Width' H:[UIView:0x7a887ee0(320)]>"
)
 
Will attempt to recover by breaking constraint
<NSLayoutConstraint:0x7a87b000 H:[UILabel:0x7a8724b0'Name'(>=400)]>
 
Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKit/UIView.h> may also be helpful.
```

这条错误信息展示了五条冲突约束，并不是所有约束都能同时成立，你需要移除其中一个，或者是将其转为一个可选的约束。

幸运的是，视图层级相对比较简单，你有一个包含一个 label 和 一个 textfield 的父视图，冲突约束设置了下面这一系列的关系：

* label 的宽度大于等于 400pt
* label 的头部边线等于父视图的头部
* Label 与 textfield 间距为 8pt
* textfield 的尾部边线等于父视图的尾部
* 父视图的宽度为 320 pt

系统会尝试打破 label 的宽度以修复冲突

> 注意：
> 
> 约束采用了视觉格式语言 VFL （Visual Format Language）打印到控制台，即使你从未使用过 VFL 来创建约束，你也一定能够读懂它，从而有效调试你的 AutoLayout 问题。关于 VFL 更多信息请查阅 [Visual Format Language](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/VisualFormatLanguage.html#//apple_ref/doc/uid/TP40010853-CH27-SW1)

在这些约束中，最后一个约束是由系统创建的。你不能修改这条约束，另外，它还和第一条约束产生了一个明显的冲突。如果你的父视图宽度只有 320pt，那么你永远不能有一个 400pt 宽度的 label。幸运的是，你并不需要去除第一条约束，如果您将其优先级降至 999，那么系统仍然会尝试提供你所选择的宽度 - 它会尽可能接近，同时仍然满足其他约束。

基于 view 的 view’s autoresizing mask 创建的约束（例如当 translatesAutoresizingMaskIntoConstraints 为 YES 时就会创建约束）会有额外的信息。在约束的地址后面，日志分别展示了一个 "h=" 和 一个 "v="，后面各跟着三个字符。这三个字符如果是"-" 连字符则表示一个固定的值，是 "&" 符号则表示一个变化的值。对于水平 mask 值（h=），三个字符分别代表左边距、宽度和右边距，对于垂直 mask 值（v=），三个字符分别表示上边距、高度和下边距。

例如，考虑下面这条日志信息：

```
<NSAutoresizingMaskLayoutConstraint:0x7ff28252e480 h=--& v=--& H:[UIView:0x7ff282617cc0(50)]>"
```

这条信息包含了以下几部分：

* NSAutoresizingMaskLayoutConstraint:0x7ff28252e480: 这条约束的类和地址，这里的类告诉我们这是一条基于 view 的 autoresizing mask 创建的约束。
* h=--& v=—&: view 的 autoresizing mask 值，在这里它是默认值。水平方向上有一个固定的左边距和宽度，一个变化的右边距。竖直方向上有一个固定的上边距和高度，一个变化的下边距。也就是说，这个 view 的左上角和尺寸不会随着父视图的尺寸变化而变化。
* H:[UIView:0x7ff282617cc0(50)]: 这条约束的 VFL 表达。在这个例子中，它定义了一个有 50pt 宽度 的 view，表达中同样包含了这条约束影响到的视图的类和地址。

### 向日志添加标识

前面的示例还比较容易理解，但是随着约束列表变长，很快就会难以追踪和理解日志的含义。你可以向每一个 view 和约束提供一个可理解的标识来使日志更易于阅读。

如果 view 有一个明显的文本组件，Xcode 会使用这个组件来作为标识。例如，Xcode 会使用一个 lable 的文案，一个 button 的标题，或者一个 textfield 的占位文案来标识这些 view。否则，就需要在标识检查器里设置 view 的 Xcode 标签。IB 会在整个接口中使用这些标识符，控制台日志中也会展示这些标识。

对于约束，可以通过编程或者使用属性检查器来设置它们的 identifier 属性。Autolayout 之后会使用这些标识在控制台中打印约束信息。

例如，这里有一个同样无法满足的约束错误，它有一个标识集合：

```
2015-08-26 14:29:32.870 Auto Layout Cookbook[10208:1918826] Unable to simultaneously satisfy constraints.
    Probably at least one of the constraints in the following list is one you don't want. Try this: (1) look at each constraint and try to figure out which you don't expect; (2) find the code that added the unwanted constraint or constraints and fix it. (Note: If you're seeing NSAutoresizingMaskLayoutConstraints that you don't understand, refer to the documentation for the UIView property translatesAutoresizingMaskIntoConstraints) 
(
    "<NSLayoutConstraint:0x7b58bac0 'Label Leading' UILabel:0x7b58b040'Name'.leading == UIView:0x7b590790.leadingMargin>",
    "<NSLayoutConstraint:0x7b56d020 'Label Width' H:[UILabel:0x7b58b040'Name'(>=400)]>",
    "<NSLayoutConstraint:0x7b58baf0 'Space Between Controls' H:[UILabel:0x7b58b040'Name']-(NSSpace(8))-[UITextField:0x7b589490]>",
    "<NSLayoutConstraint:0x7b51cb10 'Text Field Trailing' UITextField:0x7b589490.trailing == UIView:0x7b590790.trailingMargin>",
    "<NSLayoutConstraint:0x7b0758c0 'UIView-Encapsulated-Layout-Width' H:[UIView:0x7b590790(320)]>"
)
 
Will attempt to recover by breaking constraint
<NSLayoutConstraint:0x7b56d020 'Label Width' H:[UILabel:0x7b58b040'Name'(>=400)]>
 
Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKit/UIView.h> may also be helpful.
```

正如你所看到的，标识能允许你快速便捷地在日志中识别出你的约束。

### 可视化 view 和 约束

Xcode 提供了工具来帮助你可视化你的视图层级中的 view 和约束。

在模拟器中进行如下操作即可看到 view：

* 在模拟器中运行 app
* 切换回 Xcode
* 选择 Debug > View Debugging > Show Alignment Rectangles。这个设置能显示出你的 view 的轮廓

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Show_Alignment_Rectangles_2x.png" width=500>

alignment rectangles 对齐是 AutoLayout 所使用的 view 的边线，开启这个选项能够使你快速定位尺寸不对的 alignment rectangles。

如果你需要更多信息，你可以点击 Xcode 调试条上的 Debug View Hierarchy 按钮。Xcode 会展示一个 View 互动调试器，提供给你一些工具来探索视图层级并与之进行交互。当你在调试 AutoLayout 问题时，"Show clipped content" 和 "Show constraints" 通常会非常有用。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Debug_View_Hierarchy_2x.png" width=500>

选中 "Show clipped content" 选项会展示一些已经放置到屏幕外面的 view。选中 "Show constraints" 选项会展示所有影响到当前选中 view 的约束。当布局变得很奇怪时，两个选项提供了一个便捷而明智的检查方式。

了解更多信息请查阅 [调试区帮助](http://help.apple.com/xcode)。

### 理解边界情况

这里有一些会引起 AutoLayout 布局发生异常的边界情况：

* AutoLayout 是基于 alignment rectangles 来定位 view 的，而不是 view 的 frame，在大多数时候这两者是完全一样的。但是一些 view 可能会设置一个自己的 alignment rectangles 从而在布局计算中去除掉自己的部分 view（例如边界线）。

了解更多信息，可以查看 [UIView类参考](https://developer.apple.com/documentation/uikit/uiview) 的 "与自动布局对齐视图" 一节。

* 在 iOS 上，你可以使用一个 view 的 transform 属性来重新设置 view 的尺寸、对 viw 旋转、移动等，但是这些变换无法影响 AutoLayout 的计算。AutoLayout 会基于 view 未变换时的 frame 来计算它的 alignment rectangles。
* 一个 view 展示超出其边界的内容。大多数时候 view 会正常展示并限制内容在它们的边界内。但是，出于性能方面的考虑，这不是由图形引擎强制执行的。这意味着 view (尤其是有自定义绘图的 view) 可能会被按照一个与其 frame 所不同的尺寸来绘制。

你可以通过设置 view 的 clipsToBounds 属性为 YES 或者检查 view 的 frame 尺寸来识别出这些 bug。

* 只有当 view 都被按照其 intrinsic content height 来展示时 NSLayoutAttributeBaseline, NSLayoutAttributeFirstBaseline, and NSLayoutAttributeLastBaseline 属性才能正确对齐文案。如果其中一个 view 在竖直方向上被压缩或延展了，那么它的文案就可能被展示在错误的位置。
* 约束优先级在视图层级中充当了全局属性。你常常可以通过将 view 分组到一个 StackView 、一个 layoutguide、或者一个 dummy view 中来简化布局。但是这种方式并不能封装所包含 view 的优先级。AutoLayout 仍会继续比较组内和组外的优先级（甚至是其他组内的优先级）（疑惑？）
* 长宽比约束会将水平与竖直约束联系起来。一般来说竖直和水平约束都是分开计算的。但是如果你约束了一个 view 的高度相对于其宽度而变化，那么你就创建了竖直与水平约束之间的联系。它们互相之间可以影响甚至产生冲突。这种联系会极大增加布局复杂性，也会在你的布局的一些没有关联的部分之间引起无法预期的冲突。