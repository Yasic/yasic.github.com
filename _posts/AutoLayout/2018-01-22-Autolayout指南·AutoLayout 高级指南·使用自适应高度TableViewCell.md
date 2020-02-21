---
category: AutoLayout
description: "在 iOS 中你可以使用 AutoLayout 来定义一个 TableViewCell 的高度，但是这一特性默认是没有打开的。"
---

# 015-Autolayout指南·AutoLayout 高级指南

## 使用自适应高度 TableViewCell

在 iOS 中你可以使用 AutoLayout 来定义一个 TableViewCell 的高度，但是这一特性默认是没有打开的。

一般来说，一个 cell 的高度是由 tableview 的代理对象的  tableView:heightForRowAtIndexPath: 来决定的。为了实现自适应高度的 TableViewCell，你必须设置 tableview 的 rowHeight 属性为 UITableViewAutomaticDimension，并为 tableview 的 estimatedRowHeight 属性设置一个值。一旦这两个属性都被设置了，系统就会使用 AutoLayout 来计算实际行高。

```objective_c
tableView.estimatedRowHeight = 85.0
tableView.rowHeight = UITableViewAutomaticDimension
```

接下来，将 tableviewcell 的内容放置在 cell 的内容视图中。为了定义 cell 的高度，你需要保证约束链和视图链从内容视图的顶边到底边有不间断的延伸，最终撑起内容区高度。如果你的 view 有固有内容高度，系统会使用这些高度，如果没有，你就必须显式得为视图或视图内的内容添加适合的高度约束。

<img src="https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/Art/Chain_of_Views_and_Constraints_2x.png" width=500>

此外，你要尝试使预估高度尽量精确。系统会根据这些预估高度计算一些值，例如滚动条高度。越精确的预估高度越能实现无缝的用户体验。

> 注意：
> 
> 使用 tableviewcell 时，不能更改预定义内容的布局（例如，textLabel，detailTextLabel 和 imageView 的属性）。
> 
> 下面这些约束都是支持的：
> 
> * 定位子视图相对于内容视图的约束
> * 定位子视图相对于 cell 的边缘的约束
> * 定位子视图相对于预定义内容视图的约束