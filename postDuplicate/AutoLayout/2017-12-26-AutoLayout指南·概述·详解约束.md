# AutoLayout指南·概述

## 详解约束

AutoLayout 用一系列的线性约束来实现视图层级的布局，每一个约束对应一个等式。你的目标就是声明一系列的等式，这些等式有且仅有一个可能的解。

下面就是一个简单的等式的例子

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/view_formula_2x.png" width=500>

译者注：由于APP所处环境的不同，布局可能会不同，像英文环境中，页面布局是从左到右布局，而像阿拉伯语环境中，页面布局是从右到左的布局方式，因此有了Leading和Trailing的概念，为的就是一次布局后可以正常的显示在多种语言环境中。

这个约束表示红色 view 的头部(Leading)必须在蓝色 view 尾部(Trailing)之后相距 8 个单位的位置。等式由以下几个部分组成

* Item 1，在这个例子中就是等式的第一个元素红色 view，它必须是一个 view 或者是一个 layout guide
* Attribute 1，第一个元素被约束的属性，在这个例子中就是红色 view 的头部边缘(LeadingEdge)
* RelationShip，等式左边与右边的关系，可以是相等，大于等于，小于等于三种关系中的一种。在这里用到了相等关系
* Mutiplier，乘数因子，属性 2 的值会被乘以这个浮点数，在这里 mutiplier 等于 1.0
* Item 2，等式的第二个元素，在这里就是蓝色 view，不像第一个 item，这里的 item 可以为空
* Attribute2，第二个元素被约束的属性，在这个例子中就是蓝色 view 的尾部，如果第二个 Item 为空，则 Attitude2 就不能为一个属性
* Constant，常量因子，一个浮点数常量，在这里就是 8.0，这个值会和 Attribute2 的值进行加和

在我们的界面中，大多数约束都定义了两个元素之间的关系。这些元素可以是 view 或者 layout guide。约束也可以用于定义单个元素的两个属性之间的关系，比如设置一个元素的长宽比。你也可以对一个元素的宽或高声明一个常量，此时上述表达式中的第二个元素和第二个属性就是空的，而 mutiplier 则为 0.0。

### Auto Layout 属性

在 AutoLayout 中属性定义了一中可以被约束的特性。一般来说，属性包括四条边缘（Leading、Trailing、Top、Bottom），以及 width、height、centerX 和 centerY。而文本元素还包含一个或多个基线(Baseline)属性。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/attributes_2x.png" width=500>

在 [NSLayoutAttribute](https://developer.apple.com/documentation/uikit/nslayoutconstraint.attribute) 中枚举了全部的属性。

> 注意
> 
> 虽然 OSX 和 iOS 都用到 NSLayoutAttribute 枚举值，但是它们在定义上仍有一些细微的差别。所以在查看属性列表时要确保查看的属性列表对应的是正确的平台文件

### 约束关系式示例

AutoLayout 的约束关系式的大量参数和属性使你可以创造出各种各样的约束。你可以定义 View 之间的间距，对齐 view 的边线，定义两个 View 之间的相对尺寸，甚至定义一个 view 的长宽比。但是并不是所有属性都可以相互兼容(搭配到一起进行约束的设置)。

属性大致可以分为两类，一类是 size 属性（比如 Height 和 Width），一类是 location 属性（比如 Leading, Left, 和 Top）。size 属性被用于确定元素有多大，但没有指定这个元素的位置。location 属性被用于确定元素相对于其他元素的位置，但没有指定元素的尺寸大小。

由于属性之间有这些差别，因此在约束中要注意以下几个规则：

* 不能用 size 属性约束 location 属性
* 不能用常量设置 location 属性
* 不能用除了 1.0 之外的因子给 location 属性使用
* 对于 location 属性，不能用垂直属性约束水平属性
* 对于 location 属性，不能用 Leading 和 Trailing 约束 Left 和 Right

例如，在没有其他上下文信息的情况下，将一个元素的 top 设置为常量 20.0 是没有任何意义的。你必须总是定义一个元素的 location 属性与其他元素的location属性之间的关系，比如设置一个元素在父 view 的顶部（Top）下方 20 单位长的距离处。然而，设置一个元素的高度为 20.0 却是有意义的。查阅 [Interpreting Values](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW22) 获取更多信息。

下面列举一些常见的约束关系式。

> 注意
> 
> 本章节所有表达式均由伪代码组成，查看正式代码编写的关系式请前往 [Programmatically Creating Constraints](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ProgrammaticallyCreatingConstraints.html#//apple_ref/doc/uid/TP40010853-CH16-SW1) 或 [Auto Layout Cookbook](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/LayoutUsingStackViews.html#//apple_ref/doc/uid/TP40010853-CH3-SW1)

```
// 设置一个常量高度
View.height = 0.0 * NotAnAttribute + 40.0
 
// 设置两个按钮的固定距离
Button_2.leading = 1.0 * Button_1.trailing + 8.0
 
// 声明两个按钮的左边线
Button_1.leading = 1.0 * Button_2.leading + 0.0
 
// 设置两个按钮等宽
Button_1.width = 1.0 * Button_2.width + 0.0
 
// 将一个 view 在父 view 中居中
View.centerX = 1.0 * Superview.centerX + 0.0
View.centerY = 1.0 * Superview.centerY + 0.0
 
// 设置一个 view 的长宽比
View.height = 2.0 * View.width + 0.0
```

### 相等、而非赋值

一定要注意约束关系式表达的是相等关系、而非进行属性赋值。

当 AutoLayout 处理这些关系式时，它不仅仅是将等式右边的值赋给左边，取而代之的是，它会计算 Attribute1 和 Attribute2 的值并保证二者符合关系式。这意味着我们可以自由地在等式中重新组合元素，下面列举了与上一节的表达式列表相同约束而不同形式的表达式。

```
// 设置两个按钮之间固定距离
Button_1.trailing = 1.0 * Button_2.leading - 8.0
 
// 声明两个按钮的左边线
Button_2.leading = 1.0 * Button_1.leading + 0.0
 
// 设置两个按钮等宽
Button_2.width = 1.0 * Button.width + 0.0
 
// 使一个 view 在父 view 中居中
Superview.centerX = 1.0 * View.centerX + 0.0
Superview.centerY = 1.0 * View.centerY + 0.0
 
// 设置一个 view 的长宽比
View.width = 0.5 * View.height + 0.0
```

> 注意
>
> 在变换元素顺序时要注意转换乘数因子和常量因子。例如常量 8.0 需要变为 -8.0，常量因子 2.0 要变换为 0.5。而常量因子 0.0 和乘数因子 1.0 则保持不变。

你会发现 AutoLayout 经常提供多种方式来解决相同的问题，所以你需要选择一种最清晰的表达方式。但无疑不同的开发者对最清晰的表达方式有不同的看法，此时保持一致比保持正确更重要。如果你不能一直保持同一种表达方式，那么你将不断在使用中遇到各种问题。比如这篇指南就用到了以下一些规则：

* 优先使用整数乘数因子，好过于小数乘数因子
* 优先使用正数作为乘数因子，好过于使用负数作为常数因子
* 在任何位置中的view， 布局都应该遵照：从前(Leading)到后(Trailing)，从上(Top)到下(Bottom)的顺序

### 创建无歧义、可满足的布局

使用 AutoLayout 要达到的目的是提供一系列的约束表达式，同时有且仅有一个可行解。有歧义的约束表达式则会出现多个可行解。不可满足的约束表达式没有可行解。

一般来说，每一个 view 的尺寸和位置都必须被约束。假设父 view 的尺寸已经设置好（比如是 iOS 上一个 Scene 的根视图），对于每一个 View 的每一个维度，一个无歧义、可满足的表达式都需要至少两个约束来表达（不算父视图）。但是你可以采取不同的方式去实现你想要的效果。比如下面三种布局都是用无歧义、可满足的表达式实现的(只展示了水平约束)

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/constraint_examples_2x.png" width=500>

* 第一个布局约束了 view 的头部与父视图头部的关系，以及 view 的固定宽度，这样根据父视图的尺寸和其他约束就可以计算边线的位置。
* 第二个布局约束了 view 的头部及尾部与父视图的关系。根据父视图的尺寸和其他约束就可以计算出这个 view 的宽度。
* 第三个布局约束了 view 的头部与父视图的关系，同时将 view 居中展示在父视图中。根据父视图的尺寸和其他约束就可以计算出这个 view 的边线位置和宽度。

注意每一个布局都由一个 view 和两个水平约束组成。在每一种情况中都定义了 view 的宽度和水平位置。这意味着这些布局在水平轴向上符合无歧义、可满足的布局要求。但是当父视图的宽度发生改变时这些约束可能就无法正常生效了。

在第一个布局中，view 的宽度不会改变，很多时候这并不是你需要的效果。事实上，作为一个普遍适用的规则，你应该避免将 view 的尺寸声明为一个常量。AutoLayout 是被设计用于在不同的设备环境下动态适应和改变布局的利器，而当你给 view 赋值了一个固定尺寸之后这一特性就将无法生效了。

可能没有那么显著，但其实第二个布局和第三个布局的表现是相同的。它们俩都维护了当前视图与父视图之间的固定边缘留白，无论父视图的宽度如何改变。然而它们并不是完全相同的。一般来说，第二个示例会更容易理解，但第三个示例却更有效，尤其是当你需要居中放置很多元素的时候。所以你应当始终为你的布局选择最好的实现方式。

现在考虑一些更复杂的布局情况。想象一下如果你想在 iPhone 的屏幕上并排展示两个 view，你需要确保它们的每条边都有合适的边缘留白，同时它们总是有相同的宽度。并且当设备屏幕发生旋转时它们应当正确地修正它们的尺寸。

下面的插图展示了屏幕在竖直和水平方向时这两个 view 的展示情况。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Blocks_Portrait_2x.png" width=500>

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Blocks_Landscape_2x.png" width=500>

所以我们应当如何进行约束设置呢？下面的插图展示了一种最直接的约束方式。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/two_view_example_1_2x.png" width=500>

上图用到了以下这些约束

```
// 垂直约束
Red.top = 1.0 * Superview.top + 20.0
Superview.bottom = 1.0 * Red.bottom + 20.0
Blue.top = 1.0 * Superview.top + 20.0
Superview.bottom = 1.0 * Blue.bottom + 20.0
 
// 水平约束
Red.leading = 1.0 * Superview.leading + 20.0
Blue.leading = 1.0 * Red.trailing + 8.0
Superview.trailing = 1.0 * Blue.trailing + 20.0
Red.width = 1.0 * Blue.width + 0.0
```

遵循前文提到的布局规则，这里有两个 view，四条垂直约束和四条水平约束。尽管不是最可靠的，但确实能保证实现你需要的效果。更重要的是，这些约束唯一确定了两个 view 的尺寸和位置，生成了无歧义、可满足的布局。移除任何一条约束都将导致约束有歧义，而添加额外的约束可能引入布局冲突。

但是这并不是约束实现的唯一方式。下面有一个与之等同的实现途径

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/two_view_example_2_2x.png" width=500>

除了固定蓝色视图的顶部(top)和底部(bottom)与它们的父视图之间的距离，你可以让蓝色视图的顶部(top)与红色视图的顶部(top)对齐。同样地，让蓝色视图的底部(bottom)与红色视图底部(bottom)对齐。下面是详细的约束

```
// 垂直约束
Red.top = 1.0 * Superview.top + 20.0
Superview.bottom = 1.0 * Red.bottom + 20.0
Red.top = 1.0 * Blue.top + 0.0
Red.bottom = 1.0 * Blue.bottom + 0.0
 
// 水平约束
Red.leading = 1.0 * Superview.leading + 20.0
Blue.leading = 1.0 * Red.trailing + 8.0
Superview.trailing = 1.0 * Blue.trailing + 20.0
Red.width = 1.0 * Blue.width + 0.0
```

这种方式也包含了两个 view 和四条垂直约束、四条水平约束，同时也是无歧义可满足的布局。

> 但是哪种方式更好呢？
> 
> 两种方式都实现了需要的布局效果，但是哪种方式更好呢？
> 很不幸，并没有客观可行的方式去证明其中一种方式优于另一种，每种方式都有其优点和不足。
> 
> 第一种方式在移除 view 时表现更健壮。从视图层级中移除一个 view 的同时也会移除与之相关的所有引用。所以如果你移除了红色的 view，蓝色的 view 将会剩下三条约束规则。你只需要加入一条约束就可以再次正确实现约束布局。而第二种方式下移除红色 view 将使得蓝色 view 只剩下一条约束。
> 
> 但另一方面，在第一种情况下，如果你需要使 view 的顶部和底部对齐，你需要保证他们的约束使用了相同的常数值，如果你改变了其中一个常数值，你需要记得同时修改 view 对应的另一个常数值。

### 约束不等式

到目前为止，所有的示例都是展示的约束等式，但这只是故事的一部分。约束也可以以不等式的形式表示。特别地，约束之间的关系可以是相等的，大于等于的，或者小于等于的。

例如，你可以用约束来定义一个view的最小尺寸或最大尺寸，如表3-3：

表3-3 设置一个最小和最大尺寸

```
// 设置最小宽度
View.width >= 0.0 * NotAnAttribute + 40.0
 
// 设置最大宽度
View.width <= 0.0 * NotAnAttribute + 280.0
```

一旦你开始用不等式时，每个视图的每个维度的两个约束就失效了。你可以总是用两个不等式替换一个等式。在表3-4中，一个等式关系和一对不等式关系都产生相同的结果。

表3-4 用两个不等式替换一个等式

```
// 一个单独的等式关系
Blue.leading = 1.0 * Red.trailing + 8.0
 
// 可以被两个不等式关系替换
Blue.leading >= 1.0 * Red.trailing + 8.0
Blue.leading <= 1.0 * Red.trailing + 8.0
```

相反却不一定成立，因为两个不等式不一定等于一个等式关系。例如，在表3-3中的不等式限定了这个视图的宽度的可能值范围–但是对于它们本身，它们没有定义宽度。你仍然需要在这个范围内附加横向约束来定义视图的位置和宽度。

译者注：这一段的中心思想是，一个等式可以用两个不等式来表示，但是两个不等式不能表示一个等式。

### 约束优先级

默认情况下所有的约束都是必需的。AutoLayout 必需计算出满足所有约束的唯一可行解。如果无法计算出这一可行解就会出错。AutoLayout 会在控制台打印出未满足的约束的信息，并随机打破一个约束条件。然后它就会计算出没有这一约束条件下的可行解。具体请看 [Unsatisfiable Layouts](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ConflictingLayouts.html#//apple_ref/doc/uid/TP40010853-CH19-SW1)。

你也可以创建一些可选的约束。所有的约束都有一个从 1 到 1000 的优先级，只有优先级为 1000 的约束是必须的，其他都是可选的。

当计算可行解时，AutoLayout 会按照优先级从高到低，尝试满足所有的约束条件。如果它无法满足一个可选的约束条件，则会跳过这一约束条件并继续计算下一个约束条件。

可选的约束即使无法被满足仍然可以对布局产生影响。如果在跳过这一约束后布局发生了歧义，那么系统会选择一种最接近被跳过的约束条件的可行解，在这种情况下，未满足的可选约束作为一种力量让视图向它们靠拢。

可选约束一般会和不等式约束成对出现。比如在 [Listing 3-4](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW9) 中你可以给两张不等式设置不同的优先级。可以设置大于等于关系式为必须的，而小于等于关系式为可选的（优先级250）。这意味着蓝色 view 与红色 view 的间距不会小于 8 个像素点。但是其他约束可以将它们拉开更大的距离。同样的，可选约束会基于其他约束条件，确保蓝色 view 与红色 view 尽可能接近 8 个像素点的间距。

> 注意
>
> 不要认为所有优先级都设置为 1000 是最靠谱的方式。优先级应当有基本的四种系统定义的类型，low（250），medium（500），high（750），必需（1000）。你可能需要将其中一些约束优先级设置得高出其他优先级 1 到 2 个点以防止布局错乱。如果你所使用的优先级远超出这四种，你可能需要重新审查你的布局逻辑。
> 
> [UILayoutPriority](https://developer.apple.com/documentation/uikit/uilayoutpriority) 里有优先级的所有预定义值。

### 固有内容尺寸(intrinsic content size)

到目前为止，所有的示例都是用约束的方式来定义视图的位置和它们的大小的。然而有一些 view 可以根据所含内容确定其自身的自然尺寸。这种属性被称为 intrinsic content size。比如一个按钮的 intrinsic content size 就是它的 title 的尺寸加上一个小边距。

并不是所有 view 都有 intrinsic content size，对于有这一属性的 view 来说，intrinsic content size 可以定义它的高度、宽度或者两者都有。下面是一些常见的示例

一般继承自UIControl的视图都有固有内容尺寸

|View|Intrinsic Content Size|
|---|---|
|UIView 和 NSView|没有 intrinsic content size|
|Sliders|iOS 上只定义宽度，OSX 上会根据 slider 类型定义宽度或者高度|
|Label，Button，Switch，TextFiled|定义宽度和高度|
|TextView 和 ImageView|可变的 intrinsic content size|

intrinsic content size 是基于 view 当前所含内容确定的，一个 label 或者 buttton 的 intrinsic content size 是基于其所含文案的数目和字体确定的。对于其他 view，intrinsic content size 的确定更为复杂。例如，一个空白的 imageview 没有 intrinsic content size，一旦你添加一张图片，它的固有内容尺寸就被设置成了图片的尺寸。

一个 textView 的 intrinsic content size 会根据内容、是否可以滑动以及其他运用在这个 view 上的约束而变化。比如，对于可以滑动的 textView 没有 intrinsic content size，对于不能滑动的 textView，其 intrinsic content size 默认由其所包含文案不折行时的尺寸所确定。例如如果文案中没有折行符，intrinsic content size 就由布局单行文案所需的宽高来确定。如果你添加了约束来确定 view 的宽度，intrinsic content size 就会根据所给的宽度来确定展示文案所需的高度。

AutoLayout 在每一个维度上用一对约束来表示一个 view 的 intrinsic content size。其中内容压缩属性 content hugging 使 view 内聚从而更好贴合其内容，而抗压缩属性 content compression 则将 view 拓展从而避免内容被截断。

这些约束都用下面所示的不等式来表达，在这里 intrinsicHeight 和 intrinsicWidth 常量表示 intrinsic content size 所含的高度和宽度。

```
// Compression Resistance
View.height >= 0.0 * NotAnAttribute + IntrinsicHeight
View.width >= 0.0 * NotAnAttribute + IntrinsicWidth
 
// Content Hugging
View.height <= 0.0 * NotAnAttribute + IntrinsicHeight
View.width <= 0.0 * NotAnAttribute + IntrinsicWidth
```

这些约束中的每一个约束均有其自己的优先级，默认情况下，view 的 content hugging 优先级默认为 250，compression resistance 优先级默认为 750。所以一个 view 很容易被延展，但不容易被压缩。对于大多数继承自 UIControl 的视图，这是符合预期的。例如，你可以安全地将一个 button 伸展出超出其 intrinsic content size 所定义的尺寸，但如果你压缩一个 button 则可能导致其内容被截断。Interface Builder 有时会修改这些优先级以防止被截断，具体请查看 [Setting Content-Hugging and Compression-Resistance Priorities](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/WorkingwithConstraintsinInterfaceBuidler.html#//apple_ref/doc/uid/TP40010853-CH10-SW2)

尽量在你的布局中使用 view 的 intrinsic content size，这将帮助你在内容发生变化时 view 的尺寸能动态适应，同时也会减少你需要创建的无歧义不冲突的约束的数目。但是你仍然需要配置 view 的 content-hugging 和 compression-resistance 属性（CHCR）。下面是处理 intrinsic content size 的一些指导建议：

* 当你需要拉伸一系列 view 以充满一个区域时，如果所有 view 都有相同的 content-hugging 优先级，则这样的布局会产生歧义。AutoLayout 并不知道应该拉伸哪一个 view。

一个常见的例子是一对 label 和 textfield，当你希望 label 保持 intrinsic content size，而 textfield 填满额外的空白区域时，你需要确保 textfield 的水平 content-hugging 优先级低于 label 的水平 content-hugging 优先级。

事实上，由于这样的例子很常见，IB 已经自动做了这些处理，它将所有 label 的 content-hugging 优先级设置为 251。如果你使用代码来设置布局，那么你需要自己修改 content-hugging 的优先级。

* 如果 view 含有不可见的背景时（如 button 或者 label），尝试拉伸它们超出其 intrinsic content size 的值的时候可能会出现错误的或者意想不到的布局效果。虽然问题可能没有那么明显，因为文案只是被简单地展示到了错误的地方而已。为了阻止这样意想不到的拉伸，应当增加它们的 content-hugging 优先级。

* 基线 BaseLine 约束只有在 view 的尺寸满足其 intrinsic content size 时才会起作用，如果一个 view 被垂直拉伸或者压缩了，那么 baseline 约束将不能正确地对齐。

* 一些 view，例如 switch，应当始终保持其 intrinsic content size，所以要增加它们的 CHCR 优先级来阻止其被拉伸或者压缩。

* 避免赋值给 view 一个确定的 CHCR 优先级。一个 view 出现错误的尺寸总是好过发生布局冲突。如果一个 view 需要始终保持其 intrinsic content size，那么应当考虑使用一个非常高的优先级来代替（999）。这种方法一般可以保证 view 不会被压缩或拉伸，但是仍提供了一个压缩阈值从而确保你的 view 会在一个远大于或远小于你所预期的屏幕尺寸上正常显示。

### intrinsic content size 与 fitting size 对比

intrinsic content size 就像是 AutoLayout 的一个输入值，当一个 view 含有 intrinsic content size 时，系统将会创建一些约束用于表示尺寸，同时根据这些约束来计算对应的布局。

而 fitting size 则是 AutoLayout 引擎的输出。它是基于 view 的约束计算出的一个尺寸。如果 view 用 AutoLayout 来布局它的子 view，那么系统就可以根据其内容来计算一个 fitting size 赋予它。

StackView 是一个很好的例子，如果没有其他约束，系统就会按照 StackView 的子视图和属性来计算它的尺寸。很多时候 StackView 都表现得像是有一个 intrinsic content size，你可以只使用一个水平或者垂直约束就能创建一个有效布局来定义它的位置。但其实它的尺寸是由 AutoLayout 计算得出而非输入 intrinsic content size 得出的。所以设置 StackView 的 CHCR 优先级是不会起作用的，因为它并没有 intrinsic content size 属性。

如果你需要使 StackView 的 fitting size 适配其外部的元素时，你可以创建显式的约束以捕捉这些关系，或者修改 StackView 的内部元素相对于外部元素外部元素的 CHCR 优先级。

### 解读参数值

AutoLayout 的参数单位始终是 point(pt = px/scale)，然而这些测量值的确切含义取决于所涉及的属性和视图的布局方向。

|AutoLayout 属性|参数值|注意|
|---|---|---|
|Height Width|view 的尺寸|这些属性可以被声明为常量，或者与其他宽高属性绑定，不能是负数|
|Top Bottom Baseline|当下滑屏幕时这些参数会增加|这些参数只能与 CenterY，Top，Bottom 和 Baseline 属性绑定|
|Leading Trailing|对于一个从左到右的布局，当你向右移动时这些值会增加。对于一个从右到左的布局，当你向左移动时这些值会增加|这个参数只能与  Leading, Trailing, 和 Center X 绑定|
|Left Right|当你向右移动时这些参数会增加|这些参数只能与 Left、Right、CenterX 属性绑定。你应当尽量用 Leading 和 Trailing 属性来代替 Left 和 Right，这样可以使布局动态适应 view 的阅读方向。默认的阅读方向取决于用户所设置的系统语言。在 iOS 中，设置 view 的 semanticContentAttribute 属性可以确定是否在语言切换时进行布局方向转换|
|Center X Center Y|基于约束表达式其他属性而确定|CenterX 可以与 CenterX、Leading、Trailing、Right 和 Left 属性绑定。CenterY 可以与 CenterY、Top、Bottom、和 Baseline 属性绑定|