# AutoLayout指南·AutoLayout Cookbook

## intrinsic content size 视图

接下来的示例将会使用一些有 intrinsic content size 的 view。一般来说，intrinsic content size 可以简化布局，减少所需约束的数目，但是使用 intrinsic content size 又经常需要设置 view 的 content-hugging 和 compression-resistance（CHCR）优先级，这会增加额外的复杂度。

查看源代码请前往 [AutoLayout CookBook](https://developer.apple.com/sample-code/xcode/downloads/Auto-Layout-Cookbook.zip)

### 简单的 label 和 textField

这一节展示了如何放置一个简单的 label 和一个 textfield。在示例中我们设置 label 的宽度随着它的文案长度而变化，textfield 则伸缩自身来填满剩余的区域。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Label_and_Text_Field_Pair_2x.png" width=500>

由于示例用到了 view 的 intrinsic content size，所以你只需要五条约束就可以实现布局，但是你必须将 CHCR 的优先级设置正确才能获得合理的效果。

查看更多关于 intrinsic content size 和 CHCR 优先级请前往 [Intrinsic Content Size](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW21)

#### 视图和约束

在 IB 中，拖进一个 label 和一个 textfield，设置 label 的文案和 textfield 的占位文案，然后将约束设置如下

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/simple_label_and_text_field_2x.png" width=500>

```
1. Name Label.Leading = Superview.LeadingMargin

2. Name Text Field.Trailing = Superview.TrailingMargin

3. Name Text Field.Leading = Name Label.Trailing + Standard

4. Name Text Field.Top = Top Layout Guide.Bottom + 20.0

5. Name label.Baseline = Name Text Field.Baseline
```

#### 属性

为了使 textfield 伸展来填空空白区域，要设置它的 content-hugging 小于 label 的 content-hugging。当然 IB 默认就将 label 的 content-hugging 设置为 251，而将 textfield 设置为 250。你也可以在尺寸检查器进行修改。

|Name|Horizontal hugging|Vertical hugging|Horizontal resistance|Vertical resistance|
|---|---|---|---|---|
|Name Label|251|251|750|750|
|textfield|250|250|750|750|

#### 讨论

要注意这个布局里只用到了约束 4 和 5 来定义垂直约束，约束 1、2 和 3 来定义水平约束。在 [Creating Nonambiguous, Satisfiable](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AnatomyofaConstraint.html#//apple_ref/doc/uid/TP40010853-CH9-SW16) 一节中我们提到一个 view 至少需要两条水平约束和两条垂直约束，然而这里 label 和 textfield 的 intrinsic content size 已经定义了它们的高度以及 label 的宽度，因此减少了三条约束。

示例还简单假设了 textfield 的高度始终高于 label，从而使用 textfield 的高度来定义从视窗顶部到 textfield 顶部的距离。由于 label 和 textfield 都是用来展示文案的，所以示例利用文案的 Baseline 对二者进行了垂直对齐。

在水平方向上，你仍然需要定义哪一个 view 拓展自身来铺满可填充区域。你需要通过修改 CHCR 优先级来实现。在这个例子中，IB 已经将 name label 的Horizontal hugging 和 Vertical hugging 优先级设置为 251 了，相比于 textfield 的默认 250 优先级，label 将更不容易被伸展。

> 注意
> 
> 如果布局会被展示在一个非常小的屏幕上，那么你就需要修改 compression resistance 来决定当展示空间不足时哪一个 view 会被截断。
> 
> 在这个例子中，修改 compression resistance 的工作将留给读者完成。如果 name label 的文案或者字体过大，那么将没有足够空间来展示，此时会出现有歧义的布局。系统会尝试打破一个约束，所以 textfield 和 label 都有可能会被截断。
> 
> 理想情况下，你会希望创建一个对于可用空间而言不会太大的布局 - 根据需要使用紧凑尺寸类的替代布局。但是当你的 view 被设计为支持多种语言和字体时，你将很难预测每一行文案会有多大。以防万一，修改 compression resistance 会是一个是一个很好的安全选择。

### 动态高度的 label 和 textfield

在 [Simple Label and Text Field](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW8) 示例中我们通过假设 textfield 的高度始终高于 label 简化了约束，但是这并不是始终成立的。如果你将 label 字体的大小增加足够大，label 的高度就会超过 textfield。

这一节示例将根据两个 view 的最高高度动态设置垂直空间，如果设置的字体时系统默认字体，则这一节的布局与上一节完全一样。但是如果你讲 label 的字体大小增加到 36 像素点，则布局的垂直高度就会按照 label 的顶部来计算。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Label_and_Text_Field_Pair_2x.png" width-500>

这个例子有些生硬，毕竟当你增加了 label 的字体大小时，你一般也会增加 textfield 的字体大小。然而如果在 iphone 的辅助设置里设置了一个非常非常大的字体，那么这个技术就会在混合使用动态字体和固定字体的控件时起很大作用。

#### 视图和约束

像上一节一样设置视图层级，然后使用一些较为复杂的约束

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/dynamic_height_label_and_text_field_2x.png" width=500>

```
1. Name Label.Leading = Superview.LeadingMargin

2. Name Text Field.Trailing = Superview.TrailingMargin

3. Name Text Field.Leading = Name Label.Trailing + Standard

4. Name Label.Top >= Top Layout Guide.Bottom + 20.0

5. Name Label.Top = Top Layout Guide.Bottom + 20.0 (Priority 249)

6. Name Text Field.Top >= Top Layout Guide.Bottom + 20.0

7. Name Text Field.Top = Top Layout Guide.Bottom + 20.0 (Priority 249)

8. Name label.Baseline = Name Text Field.Baseline
```

#### 属性

为了使 textfield 铺满可填充区域，要设置它的 content-hugging 低于 label 的 content-hugging。IB 会默认将 label 的content-hugging 设置为 251，textfield 为 250.你也可以在尺寸检查器中修改

|Name|Horizontal hugging|Vertical hugging|Horizontal resistance|Vertical resistance|
|---|---|---|---|---|
|Name Label|251|251|750|750|
|textfield|250|250|750|750|

#### 讨论

这一节对于每一个组件用到了一对约束，一个是必需的大于等于约束，用于定义 view 与边界的最小间距。一个是可选的约束，用于将间距精确设置为 20 个像素点。

对于高度较高的 view，两个约束都可以满足，所以系统会精确设置该 view 高度为 20 像素点，而对于高度较小的 view，只能满足最小间距，另一个约束会被忽略，因此这样就使得 AutoLayout 能在运行时根据 view 的高度变化动态计算出布局。

> 注意：
> 
> 要确保可选约束的优先级低于默认的 content-hugging 优先级，否则系统会尝试打破 content-hugging 约束从而拉伸 view，而不是重新定位其位置。
> 
> 这一点在使用基于 Baseline 对齐的布局时尤其容易迷惑，因为 Baseline  对齐只会在 textView 是按照其 intrinsic content size 展示时才会生效。如果系统重新设置了某个 view 的尺寸，那么文案可能就不是合理的排列，即使设置了必需的 Baseline 约束。

### 固定高度的一列视图

这一节将会把 [Simple Label and Text Field](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW8) 拓展到一列包含 label 和 textfield 的视图中。其中所有 label 的右边线都被对齐。textfield 的左右边线也是对其的，并且横向间距取决于最长的 label。然而与 Simple Label and Text Field 一节类似，示例简单假设了 textfield 的高度始终高于 label。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Label_and_Text_Field_Columns_2x.png" width=500>

#### 视图和约束

类似 Fixed Height Columns 一节一样放置 label 和 textfield，但是需要添加一些额外的约束。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/dynamic_columns_2x.png" width=500>

```
1. First Name Label.Leading = Superview.LeadingMargin

2. Middle Name Label.Leading = Superview.LeadingMargin

3. Last Name Label.Leading = Superview.LeadingMargin

4. First Name Text Field.Leading = First Name Label.Trailing + Standard

5. Middle Name Text Field.Leading = Middle Name Label.Trailing + Standard

6. Last Name Text Field.Leading = Last Name Label.Trailing + Standard

7. First Name Text Field.Trailing = Superview.TrailingMargin

8. Middle Name Text Field.Trailing = Superview.TrailingMargin

9. Last Name Text Field.Trailing = Superview.TrailingMargin

10. First Name Label.Baseline = First Name Text Field.Baseline

11. Middle Name Label.Baseline = Middle Name Text Field.Baseline

12. Last Name Label.Baseline = Last Name Text Field.Baseline

13. First Name Text Field.Width = Middle Name Text Field.Width

14. First Name Text Field.Width = Last Name Text Field.Width

15. First Name Label.Top >= Top Layout Guide.Bottom + 20.0

16. First Name Label.Top = Top Layout Guide.Bottom + 20.0 (Priority 249)

17. First Name Text Field.Top >= Top Layout Guide.Bottom + 20.0

18. First Name Text Field.Top = Top Layout Guide.Bottom + 20.0 (Priority 249)

19. Middle Name Label.Top >= First Name Label.Bottom + Standard

20. Middle Name Label.Top = First Name Label.Bottom + Standard (Priority 249)

21. Middle Name Text Field.Top >= First Name Text Field.Bottom + Standard

22. Middle Name Text Field.Top = First Name Text Field.Bottom + Standard (Priority 249)

23. Last Name Label.Top >= Middle Name Label.Bottom + Standard

24. Last Name Label.Top = Middle Name Label.Bottom + Standard (Priority 249)

25. Last Name Text Field.Top >= Middle Name Text Field.Bottom + Standard

26. Last Name Text Field.Top = Middle Name Text Field.Bottom + Standard (Priority 249)
```

#### 属性

在属性检查器中设置如下属性，要注意将 label 的文案右对齐，右对齐文案可以使你使用比文案更长的 label，并仍保证文案的边线与 textfield 的边线是对齐的。

|View|Attribute|Value|
|---|---|---|
|First Name Label|Text|Frist Name|
|First Name Label|Alignment|Right|
|First Name Text Filed|Placeholder|Enter First Name|
|Last Name Label|Text|Last Name|
|Last Name Label|Alignment|Right|
|Last Name Text Filed|Placeholder|Enter Last Name|
|Middle Name Label|Text|Middle Name|
|Middle Name Label|Alignment|Right|
|Middle Name Text Filed|Placeholder|Enter Middle Name|

对于每一对 label 和 textfield，label 的 content-hugging 都要比 textfield 的大。IB 再一次自动做了这些设置，当然你仍然可以在尺寸检查器中修改它们

|Name|Horizontal hugging|Vertical hugging|Horizontal resistance|Vertical resistance|
|---|---|---|---|---|
|First Name Label|251|251|750|750|
|First Name TextFiled|250|250|750|750|
|Middle Name Label|251|251|750|750|
|Middle Name TextFiled|250|250|750|750|
|Last Name Label|251|251|750|750|
|Last Name TextFiled|250|250|750|750|

#### 讨论

这一节示例的布局仅仅是对 [简单的 label 和 textField](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW8) 一节的三次拷贝，将其一个一个堆叠起来。但为了正确排列每一行，你需要添加一些额外的约束。

首先通过右对齐 label 的文案进行问题简化，你现在可以使所有的 label 保持一样的宽度，无论文案有多长，都可以容易地对齐它们的边线。另外，由于一个 Label 的 compression resistance 优先级高于它的 content hugging，所有的 label 都更易于伸展而难于压缩。所以当对齐了所有 label 的左右边线后，label 会自动按照最长 label 的 intrinsic content size 的宽度来伸展。

所以你只需要将所有 Label 的左右边线对齐就可以了。你同样需要对齐所有 textfield 的左右边线。幸运的是，Label 的左边线已经与父视图的边线对齐了，类似地，textfield 的右边线也与所有父视图的边线对齐。由于每一行都有相同的宽度，所以你只需要将剩下的两个边线(应该是 label 的右边线和 textfield 的左边线)的其中一个对齐，所有行都会被对齐。

有很多方法都可以实现这样的效果，在示例中我们将每一个 textfield 的宽度设置为相同宽度。

### 动态高度的一列视图

这一节示例将把 [动态高度的 label 和 textfield](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW16) 与 [固定高度的一列视图](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW24) 两个示例混合使用，需要达到的目标如下

* label 的右边线基于最长的 label 对齐
* textfield 的宽度相同，且左右边线对齐
* textfield 拓展自身填充父视图的可填充区域
* 每一行的行高取决于此行中最高的元素
* 一切都是动态的，所以当字体大小或 label 的文案变化时，布局会自动更新

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Label_and_Text_Field_Columns_2x.png" width=500>

#### 视图与约束

像固定高度的一列视图一样放置一些 lable 和 textfield，但是需要设置一些额外的约束

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/dynamic_columns_2x.png" width=500>

```
1. First Name Label.Leading = Superview.LeadingMargin

2. Middle Name Label.Leading = Superview.LeadingMargin

3. Last Name Label.Leading = Superview.LeadingMargin

4. First Name Text Field.Leading = First Name Label.Trailing + Standard

5. Middle Name Text Field.Leading = Middle Name Label.Trailing + Standard

6. Last Name Text Field.Leading = Last Name Label.Trailing + Standard

7. First Name Text Field.Trailing = Superview.TrailingMargin

8. Middle Name Text Field.Trailing = Superview.TrailingMargin

9. Last Name Text Field.Trailing = Superview.TrailingMargin

10. First Name Label.Baseline = First Name Text Field.Baseline

11. Middle Name Label.Baseline = Middle Name Text Field.Baseline

12. Last Name Label.Baseline = Last Name Text Field.Baseline

13. First Name Text Field.Width = Middle Name Text Field.Width

14. First Name Text Field.Width = Last Name Text Field.Width

15. First Name Label.Top >= Top Layout Guide.Bottom + 20.0

16. First Name Label.Top = Top Layout Guide.Bottom + 20.0 (Priority 249)

17. First Name Text Field.Top >= Top Layout Guide.Bottom + 20.0

18. First Name Text Field.Top = Top Layout Guide.Bottom + 20.0 (Priority 249)

19. Middle Name Label.Top >= First Name Label.Bottom + Standard

20. Middle Name Label.Top = First Name Label.Bottom + Standard (Priority 249)

21. Middle Name Text Field.Top >= First Name Text Field.Bottom + Standard

22. Middle Name Text Field.Top = First Name Text Field.Bottom + Standard (Priority 249)

23. Last Name Label.Top >= Middle Name Label.Bottom + Standard

24. Last Name Label.Top = Middle Name Label.Bottom + Standard (Priority 249)

25. Last Name Text Field.Top >= Middle Name Text Field.Bottom + Standard

26. Last Name Text Field.Top = Middle Name Text Field.Bottom + Standard (Priority 249)
```

#### 属性

在属性检查器中设置以下属性，特别的，需要将所有 label 的文案右对齐。将 label 右对齐可以使你使用比文案长的 label，并且保证文案的边界依然按照 textfield 的边线对齐。

|View|Attribute|Value|
|---|---|---|
|First Name Label|Text|Frist Name|
|First Name Label|Alignment|Right|
|First Name Text Filed|Placeholder|Enter First Name|
|Last Name Label|Text|Last Name|
|Last Name Label|Alignment|Right|
|Last Name Text Filed|Placeholder|Enter Last Name|
|Middle Name Label|Text|Middle Name|
|Middle Name Label|Alignment|Right|
|Middle Name Text Filed|Placeholder|Enter Middle Name|

对于每一对 label 和 textfield，label 的 content-hugging 都要比 textfield 的大。IB 再一次自动做了这些设置，当然你仍然可以在尺寸检查器中修改它们

|Name|Horizontal hugging|Vertical hugging|Horizontal resistance|Vertical resistance|
|---|---|---|---|---|
|First Name Label|251|251|750|750|
|First Name TextFiled|250|250|750|750|
|Middle Name Label|251|251|750|750|
|Middle Name TextFiled|250|250|750|750|
|Last Name Label|251|251|750|750|
|Last Name TextFiled|250|250|750|750|

#### 讨论

这一节示例简单地混用了[动态高度的 label 和 textfield](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW16) 和 [固定高度的一列视图](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW24) 中介绍的技术。利用动态高度的 label 和 textfield 示例中的技术，使用了一对约束来动态设置行间的垂直间距。利用固定高度的一列视图示例中的技术，将 label 的文案设置为右对齐，并显式声明了列中视图的等宽关系。

> 注意
> 
> 示例中用 20 像素点来设置 view 的顶部与 top Layout guide 的间距，同时设置兄弟 view 之间间距为 8 像素点。这与直接设置一个固定的 20 像素点的顶部间距是一样的效果。但是如果你想使上边距能根据 bar 的显示与否自动适应的话，就需要一些额外的约束。在 [单一自适应 View](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/WorkingwithSimpleConstraints.html#//apple_ref/doc/uid/TP40010853-CH12-SW4) 一节中介绍了一种一般性方法，这里我们将具体的实现留给读者。

正如你所看到的，布局逻辑逐渐变得有些复杂了，但是仍然有一些方法可以简化它。首先，正如前面所提到的，你应当尽可能使用 StackView 来实现你的布局。同时你也可以对组件进行分组，然后对成组的组件进行布局。

### 两个等宽按钮

这一节将展示如何放置两个尺寸相同的按钮。垂直方向上，按钮将与屏幕的底部对齐。水平方向上，按钮会被伸展以铺满可填充区域。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Two_Equal-Width_Buttons_screen_2x.png" width=500>

#### 视图和约束

在 IB 中拖两个按钮到场景中，并用 guideline 将它们与场景底部的对齐，不要纠结于使它们完全等宽，只需要将其中一个伸展以铺满水平区域即可。大致放置好它们的位置后，将约束设置如下。AutoLayout 会计算出它们最终正确的位置。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/two_equal-width_buttons_2x.png" width=500>

```
1. Short Button.Leading = Superview.LeadingMargin

2. Long Button.Leading = Short Button.Trailing + Standard

3. Long Button.Trailing = Superview.TrailingMargin

4. Bottom Layout Guide.Top = Short Button.Bottom + 20.0

5. Bottom Layout Guide.Top = Long Button.Botton + 20.0

6. Short Button.Width = Long Button.Width
```

#### 属性

设置按钮的背景颜色从而更容易查看它们的 frame 是否会根据设备的旋转而变化，另外，还要使用不同长度的文案，从而能够体现按钮的文案不会影响按钮宽度的效果。

View|Attribute|Value
|---|---|---|
Short Button|Background|Light Gray Color
Short Button|Title|short
Long Button|Background|Light Gray Color
Long Button|Title|Much Longer Button Title

#### 讨论

这一节示例在计算布局时使用了按钮的固有高度而不是宽度。水平方向上，按钮会有明确的大小从而保证它们有相同的宽度并能填满可填充区域。可以将本节示例与 [两个等宽视图](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/WorkingwithSimpleConstraints.html#//apple_ref/doc/uid/TP40010853-CH12-SW17) 一节进行比较，从而了解按钮的固有高度如何影响布局。在这节示例中只使用了两个垂直约束而不是四个。

按钮也会被赋值不同长度的文案从而帮助说明按钮的文案如何影响(或者不会影响)布局。

> 注意
> 
> 在这一节中，按钮的背景颜色被设置为亮灰色以帮助你查看它们的 frame。一般按钮和 label 的背景都是透明的，所以查看它们的 frame 变化会比较困难(但不是不可能)。

### 三个等宽按钮

这一节示例拓展了 [两个等宽按钮](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW4) 的示例，从而实现三个等宽按钮的布局。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Three_Equal-Width_Buttons_screen_2x.png" width=500>

#### 视图和约束

将按钮如图放置，并设置约束如下

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/three_equal-width_buttons_2x.png" width=500>

```
1. Short Button.Leading = Superview.LeadingMargin

2. Medium Button.Leading = Short Button.Trailing + Standard

3. Long Button.Leading = Medium Button.Trailing + Standard

4. Long Button.Trailing = Superview.TrailingMargin

5. Bottom Layout Guide.Top = Short Button.Bottom + 20.0

6. Bottom Layout Guide.Top = Medium Button.Bottom + 20.0

7. Bottom Layout Guide.Top = Long Button.Bottom + 20.0

8. Short Button.Width = Medium Button.Width

9. Short Button.Width = Long Button.Width
```

#### 属性

设置按钮的背景颜色从而更容易查看它们的 frame 是否会根据设备的旋转而变化，另外，还要使用不同长度的文案，从而能够体现按钮的文案不会影响按钮宽度的效果。

View|Attribute|Value
|---|---|---|
Short Button|Background|Light Gray Color
Short Button|Title|Short
Medium Button|Background|Light Gray Color
Medium Button|Title|Medium
Long Button|Background|Light Gray Color
Long Button|Title|Long Button Title

#### 讨论

添加一个额外的按钮就需要添加额外三个约束，包括两个水平约束和一个垂直约束。要注意你并没有使用按钮的固有宽度，所以你需要设置至少两个水平约束来唯一确定按钮的位置和尺寸。但是你可以使用按钮的固有高度从而只需要使用一个额外的约束来确定按钮的垂直位置。

> 注意
> 
> 为了快速设置等宽约束，可以选取所有按钮后用 IB 的 Pin 工具创建一个等宽约束，IB 会自动为所有按钮创建所需的约束。

### 两个等间距按钮

表面上看这一节好像与 [两个等宽按钮](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW4) 很类似，但是在这一节示例中按钮的宽度是基于最长的文案来确定的。如果有足够的空白空间，所有按钮都只会以最长文案的按钮的固有的宽度而伸展自身，而额外的空间则会被按钮等分。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Two_Buttons_with_Equal_Spacing_screen_2x.png" width=500>

在 iphone 的竖直模式下，两个等宽按钮和两个等间距按钮的效果非常相似，而如果是在 iphone 的水平模式或者是 iPad 等大屏设备上，这两者的区别就会非常明显。

### 视图与约束

在 IB 中拖出两个按钮和三个 view 对象并放置好位置，使按钮在 view 之间，然后设置约束如下

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/two_buttons_with_equal_spacing_2x.png" width=500>

```
1. Leading Dummy View.Leading = Superview.LeadingMargin

2. Short Button.Leading = Leading Dummy View.Trailing

3. Center Dummy View.Leading = Short Button.Trailing

4. Long Button.Leading = Center Dummy View.Trailing

5. Trailing Dummy View.Leading = Long Button.Trailing

6. Trailing Dummy View.Trailing = Superview.TrailingMargin

7. Bottom Layout Guide.Top = Leading Dummy View.Bottom + 20.0

8. Bottom Layout Guide.Top = Short Button.Bottom + 20.0

9. Bottom Layout Guide.Top = Center Dummy View.Bottom + 20.0

10. Bottom Layout Guide.Top = Long Button.Bottom + 20.0

11. Bottom Layout Guide.Top = Trailing Dummy View.Bottom + 20.0

12. Short Button.Leading >= Superview.LeadingMargin

13. Long Button.Leading >= Short Button.Trailing + Standard

14. Superview.TrailingMargin >= Long Button.Trailing

15. Leading Dummy View.Width = Center Dummy View.Width

16. Leading Dummy View.Width = Trailing Dummy View.Width

17. Short Button.Width = Long Button.Width

18. Leading Dummy View.Height = 0.0

19. Center Dummy View.Height = 0.0

20. Trailing Dummy View.Height = 0.0
```

#### 属性

将按钮的背景颜色设置为非透明颜色，从而方便查看当设置旋转时它们的 frame 的变化。另外，将按钮的文案设置为不同长度的文案，按钮应当基于最长的文案来确定其尺寸。

View|Attribute|Value
|---|---|---|
Short Button|Background|Light Gray Color
Short Button|Title|Short
Long Button|Background|Light Gray Color
Long Button|Title|Much Longer Button Title

#### 讨论

正如你所看到的，约束逐渐变得复杂了起来。不过这个示例只是用于演示一种特定的技术，如果是在实际项目中应当考虑使用 StackView 来代替。

在这里，你希望空白区域能随着父视图的 frame 变化而变化。这意味着你需要一系列的等宽约束来控制空白区域的宽度，但是你不能对着空区域进行约束设置，你只能约束某类确定的对象。

在这个示例中，你使用傀儡 view 来表示空白区域，这些 view 都是 UIView 的空白实例。在示例中为了保证最小化它们在视图层级中的影响，它们被设置为 0 像素点的高度。

> 注意
> 
> 傀儡 view 会对你的布局增加额外的开销，所以你应当谨慎使用。如果这些傀儡 view 很大的话，它们的 graphic context 就会消耗一个相当大的数量，即使它们并未包含任何有意义的信息。
> 
> 此外，这些 view 还会参与视图层级的响应链，这意味着它们会对在响应链中传递的一些类似 hit-testing 的消息进行响应。如果不小心处理，这些 view 就可能中断并相应这些消息并产生不易发现的 bug。

可选的，你可以采用 UILayoutGuide 类的实例来表示这些空白区域。这个轻量级的类用于表示一个可以参与到 AutoLayout 约束的矩形 frame。layoutguide 并没有实际的 graphic context，也不是视图层级的一部分。这使得 layoutguide 最适合用于对元素分组或者定义空白区域。

但不幸的是你不能在 IB 的场景中使用 layoutguide，而在一个基于 storyboard 的场景里混合使用代码创建的视图对象是一件相当复杂的事情。所以作为一个一般规范，相比于使用自定义 layoutguide，最好还是使用 storyboard 和 IB。

这个示例使用了大于等于约束来定义按钮间空白区域的最小长度。必需约束同样保证了按钮和傀儡 view 都有了各自相同的宽度。剩下的布局主要由按钮的 CHCR 优先级来控制。如果没有足够的空间，傀儡 view 就会收缩到 0 像素宽度，按钮会平分可填充区域（并保持标准间距）。可填充区域增加时，按钮只会去拓展到最长按钮的固有宽度，傀儡 view 会填满剩下的所有区域。

### 两个基于 Size-Class 布局的按钮

这个示例使用了两套不同的约束。一个是为 Any-Any 布局设置的，这套约束定义了一对等宽的按钮，与 [两个等宽按钮](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ViewswithIntrinsicContentSize.html#//apple_ref/doc/uid/TP40010853-CH13-SW4) 一节的布局完全相同。

另一套约束是为 Compact-Regular 布局设置的，这套约束定义了一对堆叠起来的按钮，如下图所示

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Buttons_with_Size_Class_Based_Layout_2x.png" width=500>

垂直堆叠的按钮布局用于 iPhone 的垂直模式，而水平按钮行则用于其他 Size-Class 模式。

#### 约束

类似两个等宽按钮示例那样放置两个按钮，在 Any-Any 类型下，设置约束 1 到 6。然后将 IB 的 Size-class 切换到 Compact-Regular 模式。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Setting_the_Compact_Regular_Layout_2x.png" width=500>

去除约束 2 和约束 5，然后添加约束 7、8 和 9。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/compact-regular_layout_2x.png" width=500>

```
1. Short Button.Leading = Superview.LeadingMargin

2. Long Button.Leading = Short Button.Trailing + Standard

3. Long Button.Trailing = Superview.TrailingMargin

4. Bottom Layout Guide.Top = Short Button.Bottom + 20.0

5. Bottom Layout Guide.Top = Long Button.Botton + 20.0

6. Short Button.Width = Long Button.Width

7. Long Button.Leading = Superview.LeadingMargin

8. Short Button.Trailing = Superview.TrailingMargin

9. Long Button.Top = Short Button.Bottom + Standard
```

#### 属性

设置按钮的背景颜色从而更容易查看它们的 frame 是否会根据设备的旋转而变化，另外，还要使用不同长度的文案，从而能够体现按钮的文案不会影响按钮宽度的效果。

|View|Attribute|Value|
|---|---|---|
Short Button|Background|Light Gray Color
Short Button|Title|short
Long Button|Background|Light Gray Color
Long Button|Title|Much Longer Button Title

#### 讨论

IB 能让你设置基于 Size-Class 确定的 view、view 属性和约束。它允许你为三种不同的尺寸类别（Compact、Any、Regular）和长度、宽度确定不同的选项，总共有九种不同的 size-class。其中四种对应于设备上使用的 final size-class(Compact-Compact, Compact-Regular, Regular-Compact, 和 Regular-Regular)，剩下的对应于基类或抽象表现类(Compact-Any, Regular-Any, Any-Compact, Any-Regular, 和 Any-Any)(基于我对 size-class 的理解，我对这块的翻译很不满意)

当在一个给定的 size-class 下加载布局时，系统会为这个 size-class 加载最确定的设置。这意味着 Any-Any size-class 会定义所有 view 都使用的默认值。Compact-Any 设置会定义所有 view 一个紧凑的宽度，而 Compact-Regular 设置只会被用于紧凑宽度和常规高度的 view。当视图的 size-class 发生变化时，例如，当一个 iphone 从垂直旋转为水平模式时，系统会自动地转换布局，并用动画呈现这一变化。

你可以使用这一特性来为 iphone 不同的设备朝向创建不同的布局，也可以使用它来创建不同的 iPad 和 iphone 布局。这种基于特定 size-class 的定制化布局可以根据你想要的效果变得极为宽广也可以极为简易。当然，你的改变越多，storyboard 也就越复杂，而设计和维护也就越困难。

要记住，你需要确保对于每一种可能的 size-class 你都有可行的布局与之对应，包括所有的 size-class 基类。作为一个一般规则，选择一种布局作为你的默认布局会是一种最简单的方法。在 Any-Any size-class 下设计这种布局，然后按照需要修改 Final size-class。记住，你可以在更具体的 size-class 中添加或修改元其中的元素。

要创建更复杂的布局，你可能希望在开始创建布局前绘制出 size-class 的九宫格。九宫格帮助你看到哪些约束会被多种 size-class 共享，并帮助你找到布局和 size-class 的最佳混合。

查看更多使用 size-class 的信息请前往 [调试 AutoLayout](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/TypesofErrors.html#//apple_ref/doc/uid/TP40010853-CH22-SW1)
