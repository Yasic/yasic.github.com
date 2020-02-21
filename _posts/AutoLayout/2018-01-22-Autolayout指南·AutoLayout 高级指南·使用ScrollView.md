---
category: AutoLayout
description: "当你使用 scrollView 时，需要定义 scrollView 的 frame 在父视图中的尺寸和位置，同时定义内容区域的尺寸。所有这些属性都可以用 AutoLayout 来设置。"
---

# 014-Autolayout指南·AutoLayout 高级指南

## 使用 ScrollView

当你使用 scrollView 时，需要定义 scrollView 的 frame 在父视图中的尺寸和位置，同时定义内容区域的尺寸。所有这些属性都可以用 AutoLayout 来设置。

为了支持 scrollView，系统会根据约束定位的位置不同来解释约束。

* 与其他视图一样，scrollView 和 scrollView 外的对象之间的任何约束都会被附加到滚动视图的框架
* 对于 scrollView 及其内容之间的约束，展示行为会根据受约束的属性而变化
  * scrollView 与其内容区的边缘和间距的约束会被附加到 scrollView 的内容区域
  * 高度，宽度或坐标中心等约束会被附加到滚动视图的 frame 上
* 你也可以使用 scrollView 的内容区和 scrollView 外部对象之间的约束来为 scrollView 的内容区提供一个固定的位置，使得内容区看起来像是浮动在 scrollView 上

对于大多数常见的布局方案来说，如果使用虚拟视图或布局分组来包含 scrollView 的内容，逻辑就会变得容易很多，在使用 Interface Builder 进行这些操作时，一般步骤如下所示

* 将 scrollView 添加到 scene 里
* 像平常一样拖曳约束来定义 scrollView 的尺寸和位置
* 向 scrollView 添加一个 view。设置 view 的 Xcode 特定标签为内容视图
* 将内容视图的顶部，底部，头部和尾部固定到滚动视图的相应边缘，内容视图就会被定义为 scrollView 的内容区域

> 提醒：
> 
> 内容视图并没有一个固定的尺寸，它可以伸展和压缩来适应你放进去的任何 view 或 control

* （可选的）设置内容视图的宽度等于 scrollView 的宽度可以使内容视图在水平方向上填满 scrollView，从而禁止水平方向上的滚动
* （可选的）设置内容视图的高度等于 scrollView 的高度可以使内容视图在竖直方向上填满 scrollView，从而禁止竖直方向上的滚动
* 将 scrollView 的内容放置在内容视图里，和平常一样使用约束来定位内容视图内的内容

> 重要：
> 
> 你的布局必须完全定义内容视图的尺寸（步骤 5 和 步骤 6 定义的除外）。要根据内容的 intrinsic size 来设置高度，你必须保证约束链和视图链从内容视图的顶边到底边有不间断的延伸。 同样，要设置宽度，你必须保证约束链和视图链从内容视图的前导边缘到后边缘有一个不间断的延伸。
> 
> 如果你的内容没有固有内容尺寸，你必须为内容视图或内容设置一个适当的尺寸约束。
> 
> 当内容视图比 scrollView 高度要高时，scrollView 就能够在垂直方向上滑动。当内容视图比 scrollView 宽度要宽时，scrollView 就能够在水平方向上滑动。否则默认情况下 scrollView 是不能滑动的。