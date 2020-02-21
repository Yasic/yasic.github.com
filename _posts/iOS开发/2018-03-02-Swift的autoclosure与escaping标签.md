---
category: iOS开发
description: "在《函数式 Swift》第四章提到了 Swift 的 autoclosure 标签能够避免创建显式闭包的需求。"
---

## @autoclosure

在《函数式 Swift》第四章提到了 Swift 的 autoclosure 标签能够避免创建显式闭包的需求。

在 Swift 中有一个特殊类型叫做函数类型，它由一个参数类型和返回值类型组成，用于表示一个函数、方法或闭包的类型，形式如下

```
parameter type -> return type
```

autoclosure 标签能够将特定表达式上的表达式当做隐式闭包来捕获，也就是将一个表达式当做函数类型来处理，例如对于下面一个函数

```swift
    func testAutoClosure(target:@autoclosure () -> String) {
        print(target())
    }
```

它接受一个函数类型的参数，但是调用的时候可以直接传入表达式作为参数

```swift
testAutoClosure(target: "Hello World")
```

假如没有 autoclure 标签，我们就需要按照如下几种方式调用

```swift
        testAutoClosure { () -> String in
            return "Hello World"
        }
        
        testAutoClosure(target: {"Hello World"})
        
        testAutoClosure{"Hello World"}
```

简而言之，autoclosure 作用就是简化闭包调用形式。

autoclosure 标签在 Swift 系统 API 中使用也很广泛，例如 ?? 操作符的定义

```
func ??<T>(optional: T?, @autoclosure defaultValue: () -> T?) -> T?

func ??<T>(optional: T?, @autoclosure defaultValue: () -> T) -> T
```

这样实现的原因是，如果 ?? 第二个参数直接接受一个特定值，那么在调用时第二个参数如果是函数就必须先被执行得到一个返回值，即使最终进行判断后并没有使用第二个参数，这样会带来不必要的计算消耗，尤其是当第二个参数的函数内进行的操作比较复杂时。那么定义一个闭包就可以在需要用到第二个参数时才执行闭包内的逻辑。进一步，为了像上面一样，能够简化闭包调用，所以使用 autoclosure 标签修饰了闭包参数。

当然使用 autoclosure 也有需要注意的地方

> 最后要提一句的是，@autoclosure 并不支持带有输入参数的写法，也就是说只有形如 () -> T 的参数才能使用这个特性进行简化。另外因为调用者往往很容易忽视 @autoclosure 这个特性，所以在写接受 @autoclosure 的方法时还请特别小心，如果在容易产生歧义或者误解的时候，还是使用完整的闭包写法会比较好。

## @Escaping

escaping 是闭包的另一个修饰符。当闭包的某个参数在闭包返回后才被调用时称这个参数是逃逸的参数，Swift 默认不允许闭包的参数逃逸，所以下面的定义是不能通过编译的

```swift
    func canNotEscape(target:()->Bool) -> ()->Bool{
        return target
    }
```

而下面这种形式就是可以逃逸的闭包参数

```swift
    var completionHandlers: [() -> Void] = []
    func someFunctionWithEscapingClosure(completionHandler: @escaping () -> Void) {
        completionHandlers.append(completionHandler)
    }
```

要注意一点，对于可以逃逸的闭包参数，其实现内部必须显式使用 self 引用，而非逃逸闭包参数则可以隐式使用 self 引用。

```swift
class SomeClass{
    var x = 10
    func doSomething() {
        someFunctionWithEscapingClosure { self.x = 100 }
        someFunctionWithNonescapingClosure { x = 200 }
    }
    
    func someFunctionWithNonescapingClosure(closure: () -> Void) {
        closure()
    }
    
    var completionHandlers: [() -> Void] = []
    func someFunctionWithEscapingClosure(completionHandler: @escaping () -> Void) {
        completionHandlers.append(completionHandler)
    }
}
```