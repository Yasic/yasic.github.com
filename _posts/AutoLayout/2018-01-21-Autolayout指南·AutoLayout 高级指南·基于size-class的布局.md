---
category: AutoLayout
description: "IB 的 storyboard 默认会使用 size-class。size-class 是为 UI 元素，如 scene 或 view，所声明的形状。它们提供了对于元素尺寸的一个粗糙的表述。IB 能使你基于当前的 size-class 自定义许多你的布局的特性。然后当 size-class 变化时布局就会自动适应。特别的，你可以在每一个 size-class 的基础上设置以下特性："
---

# 013-Autolayout指南·AutoLayout 高级指南

## 基于 size-class 的布局

IB 的 storyboard 默认会使用 size-class。size-class 是为 UI 元素，如 scene 或 view，所声明的形状。它们提供了对于元素尺寸的一个粗糙的表述。IB 能使你基于当前的 size-class 自定义许多你的布局的特性。然后当 size-class 变化时布局就会自动适应。特别的，你可以在每一个 size-class 的基础上设置以下特性：

* 注册或取消注册一个 view 或者控制器
* 注册或取消注册一个约束
* 设置选中属性的值（例如字体或布局边界设置）

当系统加载 scene 时会实例化所有视图，控件和约束，并将这些项目分配给视图控制器（如果有的话）中相应的 outlet。你可以通过它们的 outlet 访问其中任何一个元素，无论当前 scene 的 size-class 是什么。但是系统只会在元素被注册到当前 size-class 时爱会添加这些元素到视图层级上。

当 view 的 size-class 改变时（例如，当你旋转一个 iphone 或者在 iPad 的全屏和 splitView 间切换 app 时），系统会自动从视图层级中添加或移除元素。系统也会为 view 的布局变化添加动画。

> 注意：
> 
> 系统会保持对一个未注册元素的引用，所以这些元素不会被销毁，即使它们被移除出视图层级。

## final-size-class 与 base-size-class

IB 能识别出九种不同的 size-class。

其中四种属于 final-size-class：Compact-Compact, Compact-Regular, Regular-Compact, and Regular-Regular。final-size-class 代表设备上显示的实际 size-class。

剩下五种属于 base-size-class：Compact-Any, Regular-Any, Any-Compact, Any-Regular, and Any-Any。它们是一些代表两种或两种以上 final-size-class 的抽象 size-class。例如，注册在 Compact-Any 下的元素会同时展示在 Compact-Compact 和 Compact-Regular 两种 size-class 下。

任何设置在更具体的 size-class 中的东西总是会覆盖更一般的 size-class。此外，你必须为一共九个 size-class（甚至是 base-size-class）都提供一个无歧义、可满足的布局。 因此，从最一般性的 size-class 到最具体性的 size-class 通常是最容易的。你可以选择你的的应用程序的默认布局，并在 Any-Any size-class 中设计它，然后根据需要修改其他的 base-size-class 或 final-size-class。

### 使用 size-class 工具

利用 IB 的 size-class 工具选中你正在编辑的 size-class，这个工具被展示在编辑窗口的底部中央位置。IB 默认会选择 Any-Any 作为启动时的 size-class。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Size_Class_Tool_2x.png" width=500>

可以点击 size-class 工具来切换到一个新的 size-class。IB 会展示一个弹窗，里面有一个包含所有 size-class 的九宫格。在九宫格上移动鼠标来改变 size-class。九宫格的顶部会展示选中的 size-class 的名称，底部展示这个 size-class 的描述信息（包括它会影响到的设备和旋转方向）。九宫格还会在当前 size-class 所影响到的 size-class 的格子上展示一个绿色原点。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Selecting_A__Size_Class_2x.png" width=500>

只有被注册到当前 size-class 的 view 和约束才能被添加到画布上。而当删除元素的时候，元素如何删除会影响到删除时的布局表现。

* 从画布或 document outline 中删除元素将会完全从项目中删除此元素
* 通过命令行从画布或 document outline 中删除元素只会从当前 size-class 取消注册此元素
* 如果 scene 有多个 size-class，则从画布或 document outline 以外的任何地方删除元素（例如，从尺寸检查器中选择和删除约束）将会仅从当前的 size-class 中取消注册此元素
* 如果你只编辑了 Any-Any 这个 size-class，那么删除一个元素将会完全从项目中移除此元素

如果你编辑了任何非 Any-Any 的 size-class，IB 就会将编辑窗口底部的 toolbar 变成蓝色高亮显示。这样能使你很容易发现你在编辑一个更加具体确定的 size-class。

### 使用检查器

你也可以修改检查器中的 size-class-specific 设置，任何支持 size-class-specific 的设置都会在检查器中展示，旁边还会有一个小加号图标。

默认的，检查器会设置 Any-Any 的值。为了给更加具体的 size-class 设置一个不同的值，你可以点击加号图标来添加一个新的 size-class，然后选择你想添加的 size-class 的宽度和高度。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Adding_Size_Class_2x.png" width=500>

检查器会按行显示每个 size-class： Any-Any 设置在最上面一行，下面列出了更具体的 size-class。你可以独立编辑每行的值，同时不影响到其他行的设置。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Setting_Size-Class_Specific_Values_2x.png" width=500>

点击每一行行首的 x 图标可以移除一个自定义的 size-class。

查看 Size-Classes-Design-Help 获取更多帮助信息。