# 007-Autolayout指南·调试 AutoLayout

## 错误类型

AutoLayout 中的错误可以大致分为三大类

* 无法满足的布局。你的布局没有可行解，前往 [无法满足的布局](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/ConflictingLayouts.html#//apple_ref/doc/uid/TP40010853-CH19-SW1) 查看更多信息
* 有歧义的布局。你的布局有两个或更多可能的解。前往 [有歧义布局](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/AmbiguousLayouts.html#//apple_ref/doc/uid/TP40010853-CH18-SW1) 查看更多信息
* 逻辑错误。在你的布局逻辑中有 bug，前往 [逻辑错误](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/LogicalErrors.html#//apple_ref/doc/uid/TP40010853-CH20-SW1) 查看更多信息

大多数时候，真正的问题只是确定出了什么错误。你添加了你认为你需要的约束，但当你运行 app 时，事情并不像你希望的那样运转。

一般来说，当你理解了问题，解决方案也就显而易见了。移除冲突的约束，添加缺失的约束，调整优先级顺序使布局有一个明确的可行解。当然，要能够容易地理解问题则需要经过一些测试和错误。像其他技能一样，这也遵循熟能生巧的规律。

但是有时候问题会更加复杂，此时你可能需要查看 [调试技巧](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/DebuggingTricksandTips.html#//apple_ref/doc/uid/TP40010853-CH21-SW1) 一节