---
category: AutoLayout
description: "当系统针对约束计算出多于一个可行解的时候就会出现有歧义的布局错误，大致可以分为两大错误："
---

# 009-Autolayout指南·调试 AutoLayout

## 有歧义的布局

当系统针对约束计算出多于一个可行解的时候就会出现有歧义的布局错误，大致可以分为两大错误：

* 布局需要额外的约束来唯一确定每一个 view 的位置

当你确定了哪些 view 有歧义后，就添加额外的约束来唯一确定 view 的尺寸和位置

* 布局的部分可选约束有相同的优先级，系统无法确定应当打破哪个约束

这时你需要通过改变 view 的优先级，使约束的优先级不相等，从而让系统明确哪些约束可以被打破。系统会优先打破最低优先级的约束。

### 检测有歧义的约束

就像无法满足的约束一样，IB 通常可以在开发者设计阶段就检测出有歧义的布局，并提出修复意见。这些歧义点会作为警告出现在问题导航栏里，或者作为错误出现在文件大纲里，以及在画布上用红线标出。查阅 [识别无法满足的约束](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ConflictingLayouts.html#//apple_ref/doc/uid/TP40010853-CH19-SW3) 获得更多信息。

同无法满足的约束一样，IB 也并不能检测出所有可能的歧义点。许多错误只能通过测试来发现。

当运行时出现了一个有歧义的布局时，Autolayout 会选择一个可能的解来使用。这意味着布局可能正是你所期待的，也可能完全不是你期待的样子。另外这样的情况并不会在控制台输出警告信息，也没有办法为有歧义的布局设置断点。

因此，相比于无法满足的布局，有歧义的布局通常很难识别和检测出来。即使歧义点有相对明显、可视化的影响，也很难确定错误原因是歧义点还是由于你的布局逻辑。

但是幸运的是，你可以调用一些方法来帮助你识别有歧义的布局，但是所有这些方法都只能被用于调试。在你可以访问到视图层级的地方设置一个断点，然后在控制台调用下列方法的一个：

* hasAmbiguousLayout 支持 iOS 和 OS X。对一个错位 view 调用此方法，如果 view 的 frame 是有歧义的，则返回 YES，否则返回 NO
* exerciseAmbiguityInLayout 支持 iOS 和 OS X。对于有歧义的布局调用此方法，系统将会在可能的可行解之间切换
* constraintsAffectingLayoutForAxis 仅支持 iOS。对一个 view 调用此方法，将返回一系列
* constraintsAffectingLayoutForOrientation
* _autolayoutTrace iOS 上一个私有方法，对一个 view 调用此方法会返回一个字符串，字符串包含此 view 的整个视图层级的诊断信息，如果 view 的 translatesAutoresizingMaskIntoConstraints 属性设置为 YES，则有歧义的 view 会被标记出来

你需要在控制台输入 oc 语法来执行这些命令。例如，当程序运行中触发断点后，向控制台输入 ``` call [self.myView exerciseAmbiguityInLayout]``` 从而在 myView 对象上调用 ```exerciseAmbiguityInLayout``` 这个方法。类似的，输入 ```po [self.myView autolayoutTrace]``` 从而打印出有关 myView 的视图层级的布局诊断信息。

> 注意：
> 
> 确保在运行上面列举的诊断方法之前已经修复了 IB 发现的布局问题。IB 会尝试修复它发现的任何错误，这意味着如果它发现了一个有歧义的布局，它就会添加约束从而使布局不再有歧义。
> 
> 这样一来，hasAmbiguousLayout 就会返回 NO，exerciseAmbiguityInLayout 也不能起作用，而 constraintsAffectingLayoutForAxis: 可能会返回一些额外的、非预期的约束条件。