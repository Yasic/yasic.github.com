---
category: AutoLayout
description: "约束改变是指任何改变约束的基础数学表达式的元素（见下图）。你可以查阅 [详解约束](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW1) 了解约束表达式更多内容。"
---

# 016-Autolayout指南·AutoLayout 高级指南

## 更改约束

约束改变是指任何改变约束的基础数学表达式的元素（见下图）。你可以查阅 [详解约束](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW1) 了解约束表达式更多内容。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/view_formula_2x.png" width=500>

下面这些行为都会造成至少一条约束的改变：

* 激活或停用约束
* 改变约束中的常量因子
* 改变约束优先级
* 将一个 view 从视图层级中移除

其他例如设置一个 control 的属性、修改视图层级等操作也能改变约束。当一个改变发生时，系统会稍后对布局进行更新（查阅 [延时布局更新](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ModifyingConstraints.html#//apple_ref/doc/uid/TP40010853-CH29-SW3)）

一般来说，你可以在任何时候进行这些改变。理想情况下，大多数约束条件都应在 Interface Builder 中设置，或者在控制器的初始设置期间由视图控制器用编程方式创建（例如在 [viewDidLoad](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621495-viewdidload) 方法中）。

如果你需要在运行时动态改变约束，通常最好在应用程序状态发生改变时进行。例如，如果你想改变一个约束来响应一个按钮的点击，那么直接在按钮的点击事件中进行改变。

有时候出于性能原因，你可能需要进行一组约束的批处理。查阅 [批处理约束改变操作](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ModifyingConstraints.html#//apple_ref/doc/uid/TP40010853-CH29-SW2) 了解更多信息。

### 延时布局更新

AutoLayout 不会立即更新受影响的 view 的 frame，而是安排不久的将来进行布局。此延迟操作会更新布局的约束，然后计算视图层次结构中所有视图的帧。

你可以通过调用 [setNeedsLayout](https://developer.apple.com/documentation/uikit/uiview/1622601-setneedslayout) 或 [setNeedsUpdateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622450-setneedsupdateconstraints) 安排你自己的延时布局更新操作。

延时布局操作过程实际上涉及到两个有关视图层级的过程：

* 根据需要更新约束
* 根据需要重新定位 view 的 frame

#### 约束更新操作

系统会遍历视图层级，对所有 ViewController 调用 [updateViewConstraints](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621379-updateviewconstraints) 方法，对所有 view 调用 [updateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622512-updateconstraints) 方法。你可以覆写这些方法来优化你的约束更新操作。（查看 [批处理约束更新操作](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ModifyingConstraints.html#//apple_ref/doc/uid/TP40010853-CH29-SW2)）。

#### 布局更新操作

系统会遍历视图层级，对所有 ViewController 调用 [viewWillLayoutSubviews](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621437-viewwilllayoutsubviews) 方法，对所有 view 调用 [layoutSubviews](https://developer.apple.com/documentation/uikit/uiview/1622482-layoutsubviews) 方法。默认情况下，[layoutSubviews](https://developer.apple.com/documentation/uikit/uiview/1622482-layoutsubviews) 方法会用由 Auto Layout 引擎所计算出来的矩形更新每个子视图的 frame。你可以覆写这些方法修改布局。（查看 [自定义布局](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ModifyingConstraints.html#//apple_ref/doc/uid/TP40010853-CH29-SW4)）。

### 批处理约束更新操作

在影响布局的变化发生之后，立即更新约束一般来说更加清晰和容易。而将这些更改延迟到稍后的某个方法会使代码变得更复杂和更难理解。

然而有些时候出于性能表现的原因，你会想要进行一些约束更新的批处理操作。只有当更改约束的操作太慢，或者一个视图正在进行一些冗余的更改时才能进行这种操作。

为了对一个更新进行批处理，你可以对保持此约束的 view 调用 [setNeedsUpdateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622450-setneedsupdateconstraints) 方法来代替直接更新约束的操作。然后覆写 [updateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622512-updateconstraints) 方法来修改受影响的约束。

> 注意：
> 
> 你的 [updateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622512-updateconstraints) 方法的实现应该尽可能高效。不要停用所有的约束，然后重新激活所需的约束。你应该有方法跟踪你的约束，并在每一次更新过程中激活它们。只改变需要改变的元素。在每一次更新过程中，你必须保证应用的当前状态有合适的约束。

始终记得在你的 [updateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622512-updateconstraints) 方法实现的最后一步调用父类的方法实现。

不要在你的 [updateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622512-updateconstraints) 方法中调用 [setNeedsUpdateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622450-setneedsupdateconstraints)  方法，这会导致循环调用问题。

### 自定义布局

覆写 [viewWillLayoutSubviews](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621437-viewwilllayoutsubviews) 或 [layoutSubviews](https://developer.apple.com/documentation/uikit/uiview/1622482-layoutsubviews) 方法可以修改布局引擎返回的布局结果。

> 重要：
> 
> 尽可能使用约束来定义你的所有布局，这样布局结果更加健壮，也更加便于调试。你应当只在需要创建一个无法用约束表达的布局时才覆写 [viewWillLayoutSubviews](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621437-viewwilllayoutsubviews) 或 [layoutSubviews](https://developer.apple.com/documentation/uikit/uiview/1622482-layoutsubviews) 方法。

当你覆写了这些方法之后，布局会处于一种不稳定的状态。一些 view 可能已经被布置，而另一些可能没有。你需要关注你是如何修改视图层级的，否则就可能造成循环调用。下面这些规则可能能帮助你避免循环调用：

* 你必须在你的方法实现里调用父类的同名方法
* 你可以安全地使你的子视图树中的视图布局无效，但是，这一步必须在调用父类的实现之前进行
* 不要禁用你的子视图之外的其他 view 的布局，否则会引起循环调用
* 不要调用 [setNeedsUpdateConstraints](https://developer.apple.com/documentation/uikit/uiview/1622450-setneedsupdateconstraints)，否则会引起循环调用
* 不要调用 [setNeedsLayout](https://developer.apple.com/documentation/uikit/uiview/1622601-setneedslayout)，否则会引起循环调用
* 要小心地改变约束，否则可能会意外地使你的子视图树外的某些 view 的布局失效