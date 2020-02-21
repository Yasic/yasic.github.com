# 012-Autolayout指南·AutoLayout 高级指南

## 编程创建约束

尽可能通过 IB 来创建你的约束。IB 能提供很多工具来可视化、编辑、管理和调试你的约束。IB 也可以通过分析你的约束，在设计期就发现很多常见的错误，使你能够在 app 运行之前找到并修复你的问题。

IB 能够管理不断增长的任务。你可以在 IB 中直接创建出几乎任何类型的约束（查看 [在 IB 中使用 约束](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/WorkingwithConstraintsinInterfaceBuidler.html#//apple_ref/doc/uid/TP40010853-CH10-SW1)）。你也可以指定基于特定 size-class 的约束（查看 [调试 AutoLayout](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/TypesofErrors.html#//apple_ref/doc/uid/TP40010853-CH22-SW1)），你甚至可以利用像 stackview 这样的新工具在运行时动态添加或移除 view（查看 [Dynamic Stack View](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/LayoutUsingStackViews.html#//apple_ref/doc/uid/TP40010853-CH11-SW19)）。然后，一些动态改变可能只能用代码来管理。

你有三种选择来通过编程创建约束：你可以使用 layout anchor、 NSLayoutConstraint 类，以及 VFL 语言。

### Layout Anchor

NSLayoutAnchor 类为创建约束提供了一个流畅的界面。要使用 API，你只需要访问你需要约束的元素的 anchor 属性。例如，ViewController 的顶部和底部 layoutGuide 有 topAnchor、bottomAnchor 和 heightAnchor 属性。另一方面 view 则将锚点暴露在其边缘，中心，大小和基线上。

> 注意：
> 
> 在 iOS 中，view 同样有 layoutMarginsGuide 和 readableContentGuide 属性，这些属性暴露了一个 UILayoutGuide 对象，这个对象分别表示了 view 的边界和可读的内容边界。这些 guide 反过来暴露了 Anchor 的边缘，中心和大小。
> 
> 在用编程创建边界和可读内容边界约束时可以使用这些 guide。

LayoutAnchor 能够使你用一种便于阅读和紧凑的格式来创建约束。正如下面展示的，它们暴露了一系列方法来创建不同类型的约束

```objectivec
// Get the superview's layout
let margins = view.layoutMarginsGuide
 
// Pin the leading edge of myView to the margin's leading edge
myView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
 
// Pin the trailing edge of myView to the margin's trailing edge
myView.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
 
// Give myView a 1:2 aspect ratio
myView.heightAnchor.constraint(equalTo: myView.widthAnchor, multiplier: 2.0).isActive = true
```

如同 [详解约束](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW1) 所描述的，一个约束就是一个线性等式

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/view_formula_2x.png" width=500>

LayoutAnchor 有许多不同的方法来创建约束。每一个方法都包含等式中一些影响到布局的元素的参数。所以在下面这行代码里

```objectivec
myView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
```

这些符号对应于等式里的这些部分

|等式|符号|
|---|---|
|Item 1|myView|
|Attribute 1|LeadingAnch|
|Relationship|constraintEqualToAnchor|
|Multiplier|None (defaults to 1.0)|
|Item 2|margins|
|Attribute 2|leadingAnchor|
|Constant|None (defaults to 0.0)|

LayoutAnchor 也提供了额外的类型安全属性。NSLayoutAnchor 类有很多子类，这些子类为创建约束加入了类型信息和子类方法。这帮助我们防止发生非法约束的创建。例如，你只能将水平 Anchor （LeadingAnchor 或 TrailingAnchor）与其他水平 Anchor 相互约束。类似的，你只能为尺寸约束提供乘数因子。

> 注意：
> 
> 这些规则并不是 NSLayoutConstraint API 所强制的，如果你创建了一个非法的约束，那么约束就会在运行时抛出异常。因此 LayoutAnchor 能够将运行时错误转换为编译期错误。

了解更多信息请查看 [NSLayoutAnchor 类参考](https://developer.apple.com/documentation/appkit/nslayoutanchor)。

### NSLayoutConstraint 类

你也可以直接用 NSLayoutConstraint 类的 constraintWithItem:attribute:relatedBy:toItem:attribute:multiplier:constant: 方法来创建约束。这个方法显式地将约束关系式转换成了代码。每一个参数都对应于等式的一个部分（查看 [约束关系式](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW2)）。

不像 LayoutAnchor API 的方法，你必须为每一个参数确定一个值，即使这个参数不会影响到布局。最终的结果就是一大堆样板代码，而且一般很难阅读。例如，下面这段代码就和上一节的那句代码有一样的效果。

```objectivec
NSLayoutConstraint(item: myView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leadingMargin, multiplier: 1.0, constant: 0.0).isActive = true
 
NSLayoutConstraint(item: myView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailingMargin, multiplier: 1.0, constant: 0.0).isActive = true
 
NSLayoutConstraint(item: myView, attribute: .height, relatedBy: .equal, toItem: myView, attribute:.width, multiplier: 2.0, constant:0.0).isActive = true
```

> 注意：
> 
> 在 iOS 中，NSLayoutAttribute 包含了表示一个 view 的边距的枚举值。这意味着你不需要通过 layoutMarginsGuide 属性就可以为边距创建约束。但是你仍然需要使用 readableContentGuide 来创建可阅读内容 guide 的约束。

不像 LayoutAnchor API，NSLayoutConstraint 方法不能高亮一个特定约束的重要特性。因此，在浏览代码时很容易就会遗留一些重要的细节。此外，编译器不会对约束执行任何静态检查。你可以自由地创建非法约束，这些约束会在运行时抛出异常。所以除非你需要支持 iOS 8 或者 OS X v10.10 之前的版本，否则你应当考虑将代码迁移到更新的 LayoutAnchor API 上。

了解更多信息请查阅 [NSLayoutConstraint 类参考](https://developer.apple.com/documentation/appkit/nslayoutconstraint)

### 视觉格式语言 VFL

VFL 使你可以使用类似 ASCII 中的字符串来定义约束。这提供了一种对于约束的可视化描述性表达。VFL 有以下优点和不足：

* AutoLayout 向控制台打印约束时用的是 VFL，所以使用 VFL 创建的代码会和调试信息非常类似
* VFL 能允许你利用一种非常紧凑的格式，一次创建非常多的约束
* VFL 能保证你创建的一定是合法约束
* VFL 强调完整性的良好可视化,因此，使用 VFL 不能创建一些约束（例如，宽高比）
* 编译器没有任何办法验证这些字符串。你只能在运行时测试和发现你的错误

下面就是一个用 VFL 创建的约束，它的效果与上面两节实现的效果一样

```objectivec
let views = ["myView" : myView]
let formatString = "|-[myView]-|"
 
let constraints = NSLayoutConstraint.constraints(withVisualFormat: formatString, options: .alignAllTop, metrics: nil, views: views)
 
NSLayoutConstraint.activate(constraints)
```

示例代码创建和激活了头部和尾部的约束。VFL 语言在使用默认空白时总是为父视图的边距创建 0pt 的约束，所以这些约束与前面两节的示例效果相同。但是 VFL 不能创建长宽比的约束。

如果你在一行里用很多元素创建了一个更加复杂的 view，VFL 会指定竖直和水平方向上的空白间距。正如示例所写的那样，"Align All Top" 选项不会影响布局，因为该示例只有一个视图（不包括父视图）。

为了利用 VFL 创建约束，你应当

* 创建 view 字典。这个字典必须以字符串作为键，以视图对象（或其他可以在“自动布局”中约束的元素，例如 LayoutGuide）作为值，使用键来识别字符串对应的视图。

> 注意：
> 
> 当使用 objective-c 时，可以使用 NSDictionaryOfVariableBindings 宏命令来创建 view 字典。在 Swift 里则需要你手动创建字典。

* （可选）创建度量字典。这个字典必须以字符串作为键，NSNumber 对象作为值。使用键来表示字符串对应的约束值
* 通过放置一行或一列元素来创建格式化字符串
* 调用  NSLayoutConstraint 类的 constraintsWithVisualFormat:options:metrics:views: 方法，这个方法能返回一个数组，其中包含所有约束
* 通过调用 NSLayoutConstraint 类的 activateConstraints: 方法来激活约束

了解更多信息请查阅附录的 [视觉格式语言](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/VisualFormatLanguage.html#//apple_ref/doc/uid/TP40010853-CH27-SW1)