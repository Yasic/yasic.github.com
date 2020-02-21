---
category: AutoLayout
description: "Stack View 提供了一种简单的方式，可以不引入复杂的约束就能运用 AutoLayout 的特性构建用用户界面。一个 StackView 可以定义一行或者一列的用户界面元素。StackView 运用以下属性来调整这些元素。"
---

# AutoLayout指南·概述

## AutoLayout Without Constraints

Stack View 提供了一种简单的方式，可以不引入复杂的约束就能运用 AutoLayout 的特性构建用用户界面。一个 StackView 可以定义一行或者一列的用户界面元素。StackView 运用以下属性来调整这些元素。

* axis(UIStackView Only)：定义 StackView 的轴向是垂直还是水平
* orientation(NSStackView only)：定义 StackView 的轴向是垂直还是水平
* distribution：定义子 view 沿轴向的排布方式
* alignment：设定如何沿轴线垂直方向排布子视图
* spacing：设定子视图间距

可以在 Interface Builder 中拖一个垂直或者水平的 StackView 到画布上来使用一个 StackView，然后拖出其他内容放到 Stack 中。

如果一个对象自身有固有内容尺寸(intrinsic content size)，则放置到 StackView 中后仍然会保持这一尺寸。如果对象本身没有 intrinsic content size，IB 将会提供一个默认尺寸给它。你可以重新调整对象的尺寸，IB 也会添加约束来维护视图的尺寸。

要进一步调整这个布局，也可以用属性检查器修改 StackView 的属性。比如下面的例子设置了 StackView 的间距为 8，distribution 为 Fills Equallly(默认使用Fill模式，自视图各自按照各自尺寸显示，Fill Equally模式的意思是让所有自视图尺寸大小相等)。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/IB_StackView_Simple_2x.png" width=500>

StackView 也会基于子视图的抗拉伸属性和抗压缩属性来设置布局，你可以用尺寸检查器来修改这些属性。

> 注意：
> 
> 你可以直接通过添加约束的方式来调整子视图的布局，但是要避免任何可能的约束冲突：一般来说，如果一个视图的尺寸默认返回其 Intrinsic Content Size 值，就可以安全给这一维度添加约束。更多关于约束冲突的信息查看 [不安全的布局](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ConflictingLayouts.html#//apple_ref/doc/uid/TP40010853-CH19-SW1)

此外，你也可以嵌套 StackView 到其他 StackView 中，构建更加复杂的布局。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/IB_StackView_NestedStacks_2x.png" width=500>

总而言之，应当尽可能用 StackView 去设置你的布局，只有 StackView 无法达到你想到的效果时才应该借助创建约束的方式去实现。

更多关于使用 StackView 的信息查看 [UIStackView Class Reference](https://developer.apple.com/documentation/uikit/uistackview) 或 [NSStackView Class Reference](https://developer.apple.com/documentation/appkit/nsstackview)

> 注意：
> 
> 尽管嵌套 StackView 的使用可以创建更复杂的用户界面，你也不能完全避免使用约束。至少你仍然会需要用约束来布局最外层 StackView 的位置或者尺寸大小。