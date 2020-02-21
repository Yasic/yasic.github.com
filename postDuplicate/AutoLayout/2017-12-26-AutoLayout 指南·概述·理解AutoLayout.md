# AutoLayout指南·概述

[原地址](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/index.html#//apple_ref/doc/uid/TP40010853-CH7-SW1)

## 理解 AutoLayout

基于设置在 view 上的约束，Auto Layout 可以动态计算视图层级中所有 view 的大小和位置。例如，你可以使一个按钮的中心与一张图片的 view 水平对齐，并使按钮的上边缘始终保持低于图像底部 8 个点。如果图片 view 的大小或位置发生了变化，按钮的位置也会自动变化从而保持约束。

这种基于约束方式设计的界面允许你构建的用户界面能动态响应内部与外部的变化。

## 外部变化

当你的 superView 的大小或形状发生变化时会引起所谓的“外部变化”，对于这些变化，你必须更新视图层级的布局从而使用好可利用的空间。这里有一些常见的外部变化的来源

* 用户在 OSX 上改变了 window 的大小（OS X）
* 用户在 iPad 上进入或离开 Split View (iOS)
* 设备发生了旋转 (iOS)
* 设备来电以及录音导航栏出现或者隐藏 (iOS)
* 你希望支持不同大小的 sizeClass
* 你希望支持不同屏幕尺寸

大部分变化都可能在运行时发生，并需要应用做出动态的响应。即使屏幕尺寸不会发生显著的变化，创建一个适配性强的用户界面也会使你的应用同时在 4S 和 6P 上，甚至是在 iPad 上运行良好。Auto Layout 同时也是支持 iPad 的 Slide Over 和 Split View 模式的关键组件。

## 内部变化

当应用的视图或控制器大小发生变化时，就会引起所谓的“内部变化”。这里有一些常见的内部变化发生的来源：

* 展示在 app 里的内容发生了变化
* app 需要支持国际化
* app 需要支持动态字体大小(Dynamic Type)

当应用展示的内容发生变化时，新的内容或许需要一个与旧的视图不一样的布局结构。这种情况一般发生在展示图片或文案的应用中。例如，一个新闻 app 需要调整布局来适应不同尺寸的新闻文章。或者一个照片拼图需要处理多种多样的图片尺寸与分辨率。

使应用能够适应不同语言、地区和文化的过程称为国际化。国际化应用的布局必须把这些差异考虑在内，同时在这个应用所支持的所有语言与地区中，正确显示布局。

国际化对于布局有三个主要的影响。首先，当我们将用户界面上的文案翻译为一个不同的语言时，字符需要不同空间来展示。例如德语相对于英语就需要比较多的空间来展示，而日语所需空间一般会少很多。

其次，不同地区展示日期与数字的样式可能有所不同，即使这些地区使用同一种语言。尽管这些样式相对于语言的变化较小，用户界面依然需要适配这些微小尺寸的变化。

最后，改变语言不仅仅会影响到文案的尺寸，也会影响到布局的组织结构，不同语言会使用不同的排版方向。例如英语使用从左到右的排版方向，而阿拉伯语和希伯来语则使用从右到左的排版方向。因此用户界面元素的顺序也需要进行调整以适应这种排版的不同。如果在展示英语文案的界面里有一个居于右下角的按钮，则在展示阿拉伯语文案的界面里它需要展示在左下角。

最后，如果应用还支持动态字体大小，那么用户就可以改变应用中文案的字体大小了。这一特性会同时改变用户界面上所有文本组件的高度和宽度。当用户在应用运行时改变了字体大小，那么应用就必须同时改变字体和布局结构来适应这种变化。

### 自动布局与基于 Frame 的布局对比

构建用户界面有三种主要的方式。你可以用 frame 代码布局用户界面，也可以用 autoResizing 技术自动实现对外部变化的一些响应，同时也可以用 autoLayout 技术。

传统的开发过程中，开发者们通过手动为视图层级中的每个 view 设置 frame 的方式，来布局他们的用户界面，frame 定义了 view 在父视图坐标系统里的位置和宽高。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/layout_views_2x.png" width=500>

为了正确构建用户界面，你需要计算视图层级中每一个 view 的位置和尺寸，当界面发生变化时，需要再次计算所有受影响 view 的 frame。

用代码定义一个 view 的 frame 在很多时候提供了足够的灵活性和稳定性。当变化发生时，你可以逐步设置任何你想要的变化效果。但正是由于需要自己手动处理所有变化情况，使用 frame 布局一个非常简单的界面也需要大量精力去设计、调试和维护。因此许多开发者都非常关注如何创建一个真正自适应的用户界面并有效减少复杂的布局维护工作。

当然你可以使用 AutoResizing 特性来帮助缓解一些 frame 布局带来的复杂工作。一个 AutoResizing 掩码定义了当一个父视图发生变化时，子视图如何改变自身的 frame。这一特性简化了为适应外部变化而创建的布局代码。

然而，autoresizing mask提供了一小部分的自动适配。对于复杂的用户界面，你通常还需要手动添加很多autoresizing mask来适配。此外，autoresizing mask只适配了外部变化，不支持内部变化。

AutoLayout 利用一系列的约束来定义你的用户界面。约束表达了两个 view 之间的布局关系。AutoLayout 会基于约束来计算每一个 view 的尺寸和大小。这种布局可以动态响应内部与外部的各种变化。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/layout_constraints_2x.png" width=500>

利用约束生成特定布局表现的逻辑远远不同于编写过程式代码的逻辑或是面向对象代码的逻辑。很幸运的是，掌握 AutoLayout 并不同于掌握其他的编程能力。你只需要做到两步：首先理解基于约束进行布局的背后逻辑，其次学习相应的 API。你已经在学习其他编程能力时熟练掌握了这两步，AutoLayout 在这一点上并没有什么差别。

指南剩下的部分将会帮助你逐步过渡到 AutoLayout 上来。[无约束的自动布局](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AutoLayoutWithoutConstraints.html#//apple_ref/doc/uid/TP40010853-CH8-SW1) 章节将会阐述一种高水平的抽象概念来简化用户界面背后所创建的 AutoLayout。[详解约束](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW1) 阐述为了更好使用 AutoLayout 需要掌握的理论知识。[在 IB 中使用约束](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/WorkingwithConstraintsinInterfaceBuidler.html#//apple_ref/doc/uid/TP40010853-CH10-SW1) 介绍了自动布局用到的一些工具。[编程实现约束](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ProgrammaticallyCreatingConstraints.html#//apple_ref/doc/uid/TP40010853-CH16-SW1) 和 [AutoLayout 烹饪书](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/LayoutUsingStackViews.html#//apple_ref/doc/uid/TP40010853-CH3-SW1) 细致描述了 AutoLayout 的 API。最后，[AutoLayout 烹饪书](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/LayoutUsingStackViews.html#//apple_ref/doc/uid/TP40010853-CH3-SW1) 陈列了一些不同复杂度下的示例布局，你可以学习并在自己的项目中使用这些示例。[AutoLayout 调试](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/TypesofErrors.html#//apple_ref/doc/uid/TP40010853-CH22-SW1) 则提供了一些设备和工具用以在出错时对 AutoLayout 进行修复。