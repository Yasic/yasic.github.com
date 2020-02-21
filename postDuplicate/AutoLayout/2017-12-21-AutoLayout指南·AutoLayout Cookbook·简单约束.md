# AutoLayout指南·AutoLayout Cookbook

## 约束示例

接下来的例子中将使用一些相对简单的例子实现一些常用的布局效果，这些例子可以作为基础构建块用于组建更大更复杂的布局。

查看示例的源码请查阅 [Auto Layout Cookbook](https://developer.apple.com/sample-code/xcode/downloads/Auto-Layout-Cookbook.zip)

### 单一 view

这一节我们将一个红色 view 放进父视图中，并使其四个边线与父 view 保持一定的间距。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Simple_Single_View_Screenshot_2x.png" width=500>

#### 视图和约束

在 IB 中，拖拽一个 view 到你的场景中，然后改变其尺寸以填满场景，使用 Ib 向导选择一个与父视图四条边线相对合适的位置。

> 注意
>
> 你并不需要完全保证 view 放置在正确的像素点位置上，当你设置完约束后，系统会自动帮你计算出正确的尺寸和位置。

放置好 view 后设置如下约束

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/simple_single_view_2x.png" width=500>

```
Red View.Leading = Superview.LeadingMargin

Red View.Trailing = Superview.TrailingMargin

Red View.Top = Top Layout Guide.Bottom + 20.0

Bottom Layout Guide.Top = Red View.Bottom + 20.0
```

#### 属性

为了给 view 配置一个红色背景，需要在属性检查器中设置如下属性

|View|Attribute|Value|
|---|---|---|
|Red View|Background|Red|

#### 讨论

这一节示例中的约束使得红色 view 与父视图的边线保持了一个固定距离，对于左右边线，将 view 与父视图的 margin 相联系，对于上下边线，将 view 与父视图的 Layout guide 相联系。

> 注意
> 
> 系统会自动设置根 view 的边距使得左右边距为 16 或 20 个像素点（根据不同设备），上下边距为 0。这使得你非常容易将内容与不同的 control bar （statusbar，navigationbar，tabbar，toolbar 等）协同布局。
> 
> 但是在这里你需要将内容放置在 bar 下面一点距离，因此你只能设置 view 自身的上下间距相对于 Layout guide 的间距。

IB 默认会将 view 与父视图的边线设置 20 像素点的空白间距，将兄弟 view 之间边线设置 8 像素点空白间距。这意味着你应当在红色 view 的顶部与状态栏的底部使用 8 像素点的间距。但是当 iphone 横屏显示时，状态栏会隐藏，此时 8 像素点会显得比较拥挤。

因此应当总是在 app 中选择效果最好的布局，这里我们用固定 20 像素的间距设置 app 的顶部和底部，这使得约束逻辑尽量简单，同时在横屏和竖屏上的展示效果看起来也很合理，所以其他的布局或许会比默认的固定 8 像素点要好。

如果你需要一个能动态根据 bars 的展示和隐藏而调整自身的布局，你应当看看 [Adaptive Single View](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/WorkingwithSimpleConstraints.html#//apple_ref/doc/uid/TP40010853-CH12-SW4)

### 自适应单一 view

这一节的示例将一个蓝色 view 以固定边距放置在父视图中，并填满父视图。但是不像上一节那样，蓝色 view 的顶部边距会随着 View 的上下文不同情况而变化。当存在状态栏时，view 会与状态栏保持 8 像素点间距，当状态栏不存在时，view 顶部会与父视图边线保持 20 像素点间距。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Adaptive_Single_View_Screenshot_2x.png" width=500>

下面是简单 view 和自适应 view 的比较图

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/SideBySide_2x.png" width=500>

#### 视图和约束

在 IB 中，将一个 view 拖进场景中，设置其尺寸铺满场景，设置约束如下

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/adaptive_single_view_2x.png" width=500>

```
Blue View.Leading = Superview.LeadingMargin

Blue View.Trailing = Superview.TrailingMargin

Blue View.Top = Top Layout Guide.Bottom + Standard (Priority 750)

Blue View.Top >= Superview.Top + 20.0

Bottom Layout Guide.Top = Blue View.Bottom + Standard (Priority 750)

Superview.Bottom >= Blue View.Bottom + 20.0
```

#### 属性

设置 view 背景为蓝色，设置如下属性

|View|Attribute|Value|
|---|---|---|
|Blue View|Background|Blue|

#### 讨论

这一节示例中为蓝色 view 的顶部和底部创建了一个自适应的边距，如果存在 bar，view 的边距就会与 bar 相距 8 像素，如果不存在 bar，view 就会与父视图的边距保持 20 像素。

示例用到了 LayoutGuide 去设置内容正确的位置。系统会基于 bar 的尺寸和是否展示将 LayoutGuide 放置在合适的位置。top LayoutGuide 会被放置在任何顶部 bar (例如 statusbar，navigationbar)的下边线。bottom LayoutGuide 会被放置在任何底部 bar 的上边线(例如 tabbar)。如果没有 bar，系统会将 LayoutGuide 放置在父视图相应的边线上。

示例利用一对约束来实现自适应视图的效果。首先是一个必需的约束，大于等于约束。这个约束保证了蓝色 view 的边线至少与父视图边线有 20 像素点距离。

然后是一个可选的约束，它尝试将 view 与对应的 LayoutGuide 保持 8 像素间距。由于这个约束是可选的，所以当系统无法满足这个约束的时候，会尝试尽量靠近这个约束的效果。所以这个约束像是弹簧一样将蓝色 view 系在 LayoutGuide 上。

如果系统没有展示 bar，则 LayoutGuide 与父视图的边线相等，此时蓝色 view 的边线与父视图边线既不能保持 8 像素间距也不能保持 20 像素间距，因此系统将无法满足可选约束，但它仍会尽量保证间距最小值为 20 像素。

如果 bar 存在，则两个约束都可以满足，因为所有的 bar 都有至少 20 像素的高度。所以如果系统将 view 与 bar 的边线保持 8 像素，也一定能满足 view 与父视图有至少 20 像素点的距离。

使用一对表现得像是相反力的约束在创建自适应布局时是非常常见的技术，当我们在 [Views with Intrinsic Content Size](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW1) 讲到 content-hugging 和 compression-resistance 的优先级时会再次用到它。

### 两个等宽 view

这一节示例将展示两个 view，无论父视图的尺寸如何变化，它们始终保持等宽度。同时两个 view 会填满父视图，与父视图有一个固定间距，两个 view 之间也有一个标准空白间距。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Two_Equal_Width_Views_Screenshot_2x.png" width=500>

#### 视图和约束

在 IB 中拖两个 view 放进场景中，并使它们填满父视图。使用 guideline 设置它们与场景的间距。

不要担心不能使二者完全等宽，稍后可以用约束来精确保证这一效果。

放置好 view 后设置如下约束

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/two_equal_width_views_2x.png" width=500>

```
Yellow View.Leading = Superview.LeadingMargin

Green View.Leading = Yellow View.Trailing + Standard

Green View.Trailing = Superview.TrailingMargin

Yellow View.Top = Top Layout Guide.Bottom + 20.0

Green View.Top = Top Layout Guide.Bottom + 20.0

Bottom Layout Guide.Top = Yellow View.Bottom + 20.0

Bottom Layout Guide.Top = Green View.Bottom + 20.0

Yellow View.Width = Green View.Width
```

#### 属性

在属性检查器中设置两个 view 的背景颜色

|View|Attribute|Value|
|---|---|---|
|Yellow View|Background|Yellow|
|Green View|Background|Green|

#### 讨论

这个布局显式地定义了两个 view 的顶部和底部间距，只要这些间距是相同的，这两个 view 就会有相同的高度。但是这并不唯一可能的实现方式，除了将绿色 view 与父视图的顶部和底部绑定，你也可以设置它与黄色 view 的顶部底部相等。对齐顶部和底部边线会显式地设置这些 view 相同的垂直布局。

即使是像这样一个相对简单的布局也可以用多种约束方式实现，一些会更加清晰，但是大多数都是等价的。每一个方式有其自己的优缺点，示例用到的方式有两个主要的优点。首先也是最重要的一点是，它很容易被理解，其次，这个布局可以最大限度保证其完整性，即使你从中移除一个 view。

从视图层级移除一个 view 的同时也会移除它上面的约束。对于这个例子，移除黄色 view 的同时，约束 1，2，4，6 和 8 也会被移除。但是剩下的三条约束仍可以使绿色 view 在其正确位置上，你只需要加入一条约束来定义绿色 view 左边线的位置就能修复这个布局了。

这个布局最大的缺点是你需要手动确保所有 view 的顶部约束和底部约束是相等的。改变其中一个约束的常数就会使视图展示出错。一般来说，用 IB 设置一个固定常量相对还比较容易，如果用拖拽方式创建约束就可能比较困难了。

当面对复杂而等价的诸多约束方式时，应当根据布局的上下文选择最容易理解和维护的方式。比如如果你需要居中一些不同尺寸的 view 时，最容易的方式是设置它们的 CenterX 属性，而其他布局可能设置 view 的边线或长宽会更容易一些。

更多关于选择最好的约束方式的信息请查阅 [Creating Nonambiguous, Satisfiable Layouts](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW16)

### 两个不同宽度的 view

这个示例与上一节很类似，但是显著的不同在于这个示例中橙色 view 的宽度始终是紫色 view 的两倍。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Two_Different_Sized_Views_2x.png" width=500>

#### 视图和约束

像之前那样，简单向场景拖进两个 view 并放置在大致位置后设置约束如下

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/two_different_sized_views_2x.png" width=500>

```
Purple View.Leading = Superview.LeadingMargin

Orange View.Leading = Purple View.Trailing + Standard

Orange View.Trailing = Superview.TrailingMargin

Purple View.Top = Top Layout Guide.Bottom + 20.0

Orange View.Top = Top Layout Guide.Bottom + 20.0

Bottom Layout Guide.Top = Purple View.Bottom + 20.0

Bottom Layout Guide.Top = Orange View.Bottom + 20.0

Orange View.Width = 2.0 x Purple View.Width
```

#### 属性

在属性检查器中设置 view 的背景颜色

|View|Attribute|Value|
|---|---|---|
|Purple View|Background|Purple|
|Orange View|Background|Orange|

#### 讨论

这个示例在宽度约束中使用了一个乘数因子，乘数因子只能被用在宽高的约束中，它能帮你设置不同 view 的相对尺寸。同时你也可以设置一个 view 的长宽比为一个常数。

IB 能让你用多种形式来表达一个乘数因子，可以是十进制整数、百分数、分数或者一个比值。

### 两个有复杂宽度的 view

这一节示例几乎和两个不同宽度的 view 的示例是一样的，但是这里你需要使用一对约束来定义对 view 的宽度定义一个更加复杂的效果。在一节里，系统将尝试使红色 view 的宽度是蓝色 view 宽度的两倍，而蓝色 view 至少要有 150 像素点的宽度。所以在 iphone 的竖屏模式下两个 view 的宽度几乎一样，但是在横屏模式下红色 view 的宽度很明显比蓝色 view 宽 2 倍。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Two_Views_with_Complex_Widths_Screenshot_2x.png" width=500>

#### 视图和约束

在画布上放上两个 view，然后设置约束如下

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/two_views_with_complex_widths_2x.png" width=500>

```
Blue View.Leading = Superview.LeadingMargin

Red View.Leading = Blue View.Trailing + Standard

Red View.Trailing = Superview.TrailingMargin

Blue View.Top = Top Layout Guide.Bottom + 20.0

Red View.Top = Top Layout Guide.Bottom + 20.0

Bottom Layout Guide.Top = Blue View.Bottom + 20.0

Bottom Layout Guide.Top = Red View.Bottom + 20.0

Red View.Width = 2.0 x Blue View.Width (Priority 750)

Blue View.Width >= 150.0
```

#### 属性

在属性检查器设置 view 的背景颜色

|View|Attribute|Value|
|---|---|---|
|Red View|Background|Red|
|Blue View|Background|Blue|

#### 讨论

示例用到了一对约束来控制 view 的宽度，一个可选的成比例的约束使红色 view 的宽度是蓝色 view 的 2 倍。而必需的大于等于约束则定义了蓝色 view 的最小宽度。

当父视图的左右边线距离大于等于 458（150 + 300 + 8）像素点时，红色 view 的宽度会是蓝色 view 的两倍。而如果父视图的左右间距小于这个值，则会保证蓝色 view 的宽度是 150 像素点，而红色 view 填充剩余的空间，并保持两个 view 之间有 8 个像素点的间距。

你可能已经发现了这种方式就是 [Adaptive Single View](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/WorkingwithSimpleConstraints.html#//apple_ref/doc/uid/TP40010853-CH12-SW4) 一节提到的方法的变种。

你还可以用三个约束关系式拓展这种设计。例如你可以设置一个必需的约束对红色 view 的宽度进行限制，一个高优先级的可选约束限制蓝色 view 的宽度，然后一个低优先级的可选约束用于限制两个 view 的宽度比例。