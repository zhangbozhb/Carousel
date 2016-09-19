# CarouselSwift


[![Language: Swift 3](https://img.shields.io/badge/language-Swift%203-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platform: iOS 8+](https://img.shields.io/badge/platform-iOS%208%2B-blue.svg?style=flat)
[![Cocoapods compatible](https://img.shields.io/badge/Cocoapods-compatible-4BC51D.svg?style=flat)](https://cocoapods.org)
[![License: MIT](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/jiecao-fm/SwiftTheme/blob/master/LICENSE)


###ScreenShots
![CarouselSwift](https://github.com/zhangbozhb/Carousel/blob/master/screenshots_1.gif)


# Introduction

CarouselSwift implement carouse effect. Available Features:
* Both Loop and Linear:
    * Loop: cell is loop, act seems infinite.
    * Linear: cell is limit and highly optimization in memory usage.
* Both horizontal and vertical layout direction
* Multi cell in view.
* Modify delegate of UIPanGestureRecognizer is available
* Other:
    * auto scoll: implement with NSTimer and easy to usage
    * scroll cell progress: directly available in delegate

#### CarouselSwift Adv & Dis:

* Advantage:
     * Easy to usage：CarouselSwift is easy to use in its prefer field.
     * Avoid hard to fix problem by system provide component:
     	* UIPanGestureRecognizer delegate modify

	* CarouselSwift VS Component provided by system
 
    | | CarouselSwift | UITableView | UICollectionView | UIPageViewController |
    | :------ | :------: | :------: | :------: | :------: |
    | Horizontal Layout | √  | ×  | √  | √ |
    | Vertical Layout |  √  | ×  | √ | √ |
    | Cell arrange in linear  | √  | × | √  | √ |
    | Cell arrange in loop  | √  | ×  | ×  | √ |
    | Cell size require same  | √  | ×  | ×  | √ |
    | Reusage optimization | √  | √  | √  | √ |
    | Cell reusable  | ×(partial)  | √  | √ | √ |
    | multi cell in one page | √  | √  | √ | × |
    | pagingEnable  | √  | ×  | ×  | √ |
    | UIPanGestureRecognizer delegate modify  | √ | × |  × |  × |
    | scroll progress | √ | √(indirect) | √ (indirect) | × |

	According comparison above，you may find that CarouselSwift has much in common to UIPageViewController, but more simple to use.
	* CarouselSwift VS Other similar component：
		* CarouselSwift horizontal and vertical layout direction, other one only
		* CarouselSwift support cell in linear and loop arrange, other one only
		* CarouselSwift cell reuse ability avoid large memory cost
		* CarouselSwift multi view in one page

* Restriction:
    * All page/cell has the same size. If size is different, use UITableView or UICollectionView instead.

## How it works(Principle)：

CarouselSwift implement with UIScrollView
* adopt UIScrollView as container
* Loop(infinite)：use N + 2 cell, and set contentOffset when reach 0 and N
* auto scroll：NSTimer
* auto scroll and manual scroll:  UIScrollViewDelegate的 scrollViewWillBeginDragging(_:) invalidate timer, scrollViewDidEndDragging(_:willDecelerate:) fire timer


## Usage

### CarouselView
```Swift
let carousel = CarouselView.init(frame: view.bounds)
view.addSubview(carousel)
carousel.type = .loop   // set cell loop or linear
carousel.dataSource = self  // set data source cell view
carousel.reload()   // load datas

carousel.autoScroll(2, increase: true)  // set auto scroll
carousel.delegate = self    // set scroll delegate

carousel.scrollTo(cell: 1) // scroll to specify cell
carousel.cellPerPage = 3 // number view show in one page


// CarouselViewDataSourse
func numberOfView(carousel:CarouselView) -> Int  // total count of view
func carousel(carousel:CarouselView, viewForIndex index:Int) -> UIView?

```

### CarouselViewController
```Swift
let carousel = CarouselViewController()
carousel.type = .loop   // set cell loop or linear
carousel.dataSource = self  // set data source cell view
carousel.reload()   // load datas

carousel.autoScroll(2, increase: true)  // set auto scroll
carousel.delegate = self    // set scroll delegate

carousel.scrollTo(cell: 1) // scroll to specify cell
carousel.cellPerPage = 3 // number view show in one page


// CarouselViewControllerDataSourse
func numberOfViewController(carousel:CarouselViewController) -> Int  // total count of view controller
func carousel(carousel:CarouselViewController, viewControllerForIndex index:Int) -> UIViewController?


```

### CocoaPods

``` ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'CarouselSwift'
```

If you use swift 2, use pod 'CarouselSwift' , '~> 0.1'


# CarouselSwift 介绍

CarouselSwift 旋转木马效果这个是最为常见的效果, 实现了以下功能:
* 轮播和线性滑动支持:
    * 轮播（Loop）: 也就是我们通常说的无限循环功能
    * 线性滑动（Linear）: 采用 reusable cell的方式, 使用极少的内存资源(需要时候进行显示); 类似 UITableView, UICollectionView, UIPageViewController
* 支持多个方向:
    * 水平: 横向(Horizontal)
    * 垂直: 纵向（Vertical)
* 支持多个页面: 视图内同时显示多个page
* 可以修改 手势（UIPanGestureRecognizer）的delegate实现特殊的功能（比如边界, 显示特殊的view或者push/pop view）
* 其它:
    * 自动轮播: 缺省封装了timer实现自动轮播, 可以直接使用
    * 切换进度: 在 delegate中自动计算切换page 的进度


#### CarouselSwift 优势与限制:

* 优势:
     * 简单易用：CarouselSwift在其使用场景下，使用更简单, 开源具有很大的自主性。
     * 避免系统使用组建，难以解决的问题：
     	* UIPanGestureRecognizer delegate 手势修改问题
     	* UIPageViewController Crash问题:
            * view controller 为空时候的, 滑动crash问题相比不会陌生
            * setViewControllers(_:direction:animated:completion:)
            
	* CarouselSwift 与系统提供的组件简单比较

    | | CarouselSwift | UITableView | UICollectionView | UIPageViewController |
    | :------ | :------: | :------: | :------: | :------: | 
    | 水 平 布 局 | √  | ×  | √  | √ |
    | 垂 直 布 局 |  √  | ×  | √ | √ |
    | 内 容 线 性 排 列  | √  | × | √  | √ |
    | 内 容 循 环 排 列  | √  | ×  | ×  | √ |
    | cell 是 否 要 求 相 同  | √  | ×  | ×  | √ |
    | 重 用 优 化 | √  | √  | √  | √ |
    | cell 是 否 可 以 重 用  | ×(部分) | √  | √ | √ |
    | page 中 显 示 多 个 cell | √  | √  | √ | × |
    | 是 否 支 持 分 页  | √  | ×  | ×  | √ |
    | UIPanGestureRecognizer delegate 修 改  | √ | × |  × |  × |
    | 滑 动 进 度 | √ | √(间接)|  √(间接) | × |

	通过上面的比较，可以发现 CarouselSwift 和 UIPageViewController 有很大的相似性（其实差不多就是模仿 UIPageViewController 来做的），使用起来更为简单
	* CarouselSwift 与其他类似功能组建比较：
		* CarouselSwift 同时支持水平和垂直，而其他通常支持一种
		* CarouselSwift 同时支持内容线性排列和循环排列，而其他通常支持一种
		* CarouselSwift cell采用重用的方式，避免避免将所有 view 都加载
		* CarouselSwift 单页内可以显示多个view，其它只支持一个

* 限制与使用场景:
    * CarouselSwift 只适合用于每个 cell 的大小完全相同的场景, 无法像 UITableView和UICollectionView支持不同的大小的 cell，对于 cell 大小不一致的是否，推荐使用系统组件

## 原理：

CarouselSwift 是采用 UIScrollView 来实现的
* 采用的是 UIScrollView 作为容器来实现的
* 轮播(无限循环)：使用 N + 2 个cell, 在滑动到 0, N的时候通过调整contentOffset
* 自动滚动：通过使用 NSTimer 定时来实现
* 自动滚动与手势配合:  UIScrollViewDelegate的 scrollViewWillBeginDragging(_:) 关闭timer, scrollViewDidEndDragging(_:willDecelerate:) 开启timer


## 使用

### CarouselView
```Swift
let carousel = CarouselView.init(frame: view.bounds)
view.addSubview(carousel)
carousel.type = .loop   // 设置内容 cell 是否循环
carousel.dataSource = self  // 设置数据源 cell view
carousel.reload()   // 加载数据

carousel.autoScroll(2, increase: true)  // 设置自动滚动
carousel.delegate = self    // 设置滚动 delegate, 获取滚动进度

carousel.scrollTo(cell: 1) // 滚动到指定 cell
carousel.cellPerPage = 3 // 单页可以显示 view 数量


// CarouselViewDataSourse
func numberOfView(carousel:CarouselView) -> Int  // 返回用于显示 view 的总数
func carousel(carousel:CarouselView, viewForIndex index:Int) -> UIView? // index 对应的 view, nil则表示该 index 不显示

```

### CarouselViewController
```Swift
let carousel = CarouselViewController()
carousel.carouselView.type = .loop   // 设置内容 cell 是否循环
carousel.dataSource = self  // 设置数据源 cell view
carousel.reload()   // 加载数据

carousel.autoScroll(2, increase: true)  // 设置自动滚动
carousel.delegate = self    // 设置滚动 delegate, 获取滚动进度

carousel.scrollTo(cell: 1) // 滚动到指定 cell
carousel.cellPerPage = 3 // 单页可以显示 view 数量


// CarouselViewControllerDataSourse
func numberOfViewController(carousel:CarouselViewController) -> Int  // total count of view controller
func carousel(carousel:CarouselViewController, viewControllerForIndex index:Int) -> UIViewController? // index 对应的 view controller, nil则表示该 index 不显示

```
