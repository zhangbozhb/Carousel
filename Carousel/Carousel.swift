//
//  Carousel.swift
//  Carousel
//
//  Created by travel on 16/7/26.
//  Copyright © 2016年 travel. All rights reserved.
//

import UIKit

protocol CarouselScrollViewDataSourse:class {
    func numberOfView(carousel:CarouselScrollView) -> Int
    func carousel(carousel:CarouselScrollView, viewForIndex:Int) -> UIView?
}


enum CarouselDirection {
    case Horizontal, Vertical
}

enum CarouselType {
    case Linear, Loop
}

extension CarouselScrollView {
    var pageWidth:CGFloat {
        return direction == .Horizontal ? frame.width / CGFloat(visiblePage) : frame.width
    }
    var pageHeight:CGFloat {
        return direction == .Vertical ? frame.height / CGFloat(visiblePage) : frame.height
    }
}

class CarouselPage {
    private(set) var page:Int = 0
    private(set) var count:Int = 0
    
    private(set) var view = UIView()
    
    private init(page:Int) {
        self.page = page
    }
    
    init(page:Int, count:Int, view:UIView) {
        self.page = page
        self.count = count
        self.view = view
    }
    
    deinit {
        view.removeFromSuperview()
    }
    
    var validPage:Int {
        var p = page
        while p < 0 {
            p += 100 * count
        }
        return count > 0 ? p % count : 0
    }
    
    func reuse(page:Int, count:Int) -> CarouselPage? {
        if self.count == count {
            self.page = page
            return self
        }
        return nil
    }
}

class CarouselScrollView: UIScrollView {
    private var baseInited = false
    private(set) var visiblePage:UInt = 3
    private(set) var bufferPage:UInt = 1    // one side
    
    private var threshold:CGFloat = 1
    private var pageViews = [CarouselPage]()
    
    
    var direction = CarouselDirection.Horizontal
    var type = CarouselType.Linear
    var dataSource:CarouselScrollViewDataSourse? {
        didSet {
            if dataSource !== oldValue {
                reload()
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    
    private func baseInit() {
        guard !baseInited else {
            return
        }
        baseInited = true
        
        contentSize = frame.size
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        delegate = self
    }
    
    private func resetPages() {
        switch type {
        case .Linear:
            resetPagesLinear()
        case .Loop:
            resetPagesLoop()
        }
    }
    
    private func fetchPage(page:Int) -> UIView {
        return dataSource?.carousel(self, viewForIndex: page) ?? UIView()
    }
    
    
    private func updateVisiblePage() {
        switch type {
        case .Linear:
            updateVisiblePageLinear()
        case .Loop:
            updateVisiblePageLoop()
        }
    }
    
    func reload() {
        resetPages()
        updateVisiblePage()
        
        updateContentSize()
    }
    
    func updateContentSize() {
        switch type {
        case .Linear:
            updateContentSizeLinear()
        case .Loop:
            updateContentSizeLoop()
        }
    }
    
    func updateContentOffset() {
        switch type {
        case .Linear:
            break
        case .Loop:
            updateContentOffsetLoop()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateContentSize()
        updateVisiblePage()
    }
}

// 线性page
extension CarouselScrollView {
    
    private func updateContentSizeLinear() {
        var targetSize = frame.size
        if let count = dataSource?.numberOfView(self) where count > 0 {
            if direction == .Horizontal {
                targetSize = CGSizeMake(CGFloat(count) * pageWidth, frame.height)
            } else {
                targetSize = CGSizeMake(pageWidth, CGFloat(count) * pageHeight)
            }
        }
        if !CGSizeEqualToSize(targetSize, contentSize) {
            contentSize = targetSize
        }
    }
    
    private func resetPagesLinear() {
        let pre = pageViews
        pageViews = []
        for page in pre {
            page.view.removeFromSuperview()
        }
    }
    
    private func frameLinear(page:Int) -> CGRect {
        switch direction {
        case .Horizontal:
            let pageWidth = self.pageWidth
            return CGRectMake(CGFloat(page) * pageWidth, 0, pageWidth, pageHeight)
        case .Vertical:
            let pageHeight = self.pageHeight
            return CGRectMake(0, CGFloat(page) * pageHeight, pageWidth, pageHeight)
        }
    }
    
    private func setupPageLinear(page:Int, count:Int, tail:Bool = true) -> CarouselPage {
        let pageView = CarouselPage.init(page: page, count: count, view: fetchPage(page))
        
        if tail {
            pageViews.append(pageView)
        } else {
            pageViews.insert(pageView, atIndex: 0)
        }
        
        addSubview(pageView.view)
        pageView.view.frame = frameLinear(page)
        return pageView
    }
    
    private func updateVisiblePageLinear() {
        guard let ds = dataSource where ds.numberOfView(self) > 0 && frame.width > 0 else {
            resetPagesLinear()
            return
        }
        
        let count = ds.numberOfView(self)
        if direction == .Horizontal {
            let pageWidth = self.pageWidth
            let minX = max(ceil(contentOffset.x / pageWidth - CGFloat(bufferPage)) * pageWidth, 0)
            let maxX = minX + CGFloat(visiblePage + bufferPage * 2) * pageWidth
            
            // 右侧：移除page
            while let page = pageViews.last where page.view.frame.minX + threshold > maxX {
                pageViews.removeLast()
                page.view.removeFromSuperview()
            }
            // 左侧：移除page
            while let page = pageViews.first where page.view.frame.maxX - threshold < minX {
                pageViews.removeFirst()
                page.view.removeFromSuperview()
            }
            
            // 处理为空情况
            if pageViews.isEmpty {
                setupPageLinear(Int(contentOffset.x / pageWidth), count: count)
            }
            // 右侧：添加page
            while let page = pageViews.last where page.page < count - 1 && page.view.frame.maxX + threshold < maxX {
                setupPageLinear(page.page + 1, count: count, tail: true)
            }
            // 左侧：添加page
            while let page = pageViews.first where page.page > 0 && page.view.frame.minX - threshold > minX {
                setupPageLinear(page.page - 1, count: count, tail: false)
            }
        } else {
            let pageHeight = self.pageHeight
            let minY = max(ceil(contentOffset.y / pageHeight - CGFloat(bufferPage)) * pageHeight, 0)
            let maxY = minY + CGFloat(visiblePage + bufferPage * 2) * pageHeight
            
            // 尾部：移除page
            while let page = pageViews.last where page.view.frame.minY + threshold > maxY {
                pageViews.removeLast()
                page.view.removeFromSuperview()
            }
            // 首部：移除page
            while let page = pageViews.first where page.view.frame.maxY - threshold < minY {
                pageViews.removeFirst()
                page.view.removeFromSuperview()
            }
            
            // 处理为空情况
            if pageViews.isEmpty {
                setupPageLinear(Int(contentOffset.y / pageHeight), count: count)
            }
            // 尾部：添加page
            while let page = pageViews.last where page.page < count - 1 && page.view.frame.maxY + threshold < maxY {
                setupPageLinear(page.page + 1, count: count, tail: true)
            }
            // 首部：添加page
            while let page = pageViews.first where page.page > 0 && page.view.frame.minY - threshold > minY {
                setupPageLinear(page.page - 1, count: count, tail: false)
            }
        }
    }
}

private let minPixi = 1 / UIScreen.mainScreen().scale
// 循环page
extension CarouselScrollView {
    // 第一个page相对于 0 偏移的page数量
    private var offsetPage:Int {
        return Int(visiblePage)
    }
    
    private func updateContentOffsetLoop() {
        guard let count = dataSource?.numberOfView(self) where count > Int(visiblePage) else {
            return
        }
        if decelerating {
            return
        }

        switch direction {
        case .Horizontal:
            let bufferWidth = pageWidth * CGFloat(visiblePage)
            let totalPageWidth = pageWidth * CGFloat(count)
            let minX = bufferWidth
            let maxX = totalPageWidth + bufferWidth
            if contentOffset.x > maxX {
                contentOffset.x -= totalPageWidth
                updateVisiblePageLoop()
            } else if contentOffset.x < minX {
                contentOffset.x += totalPageWidth
                updateVisiblePageLoop()
            }
        case .Vertical:
            let bufferHeight = pageHeight * CGFloat(visiblePage)
            let totalPageHeight = pageHeight * CGFloat(count)
            let minY = bufferHeight
            let maxY = totalPageHeight + bufferHeight
            if contentOffset.y > maxY {
                contentOffset.y -= bufferHeight
                updateVisiblePageLoop()
            } else if contentOffset.y < minY {
                contentOffset.y += bufferHeight
                updateVisiblePageLoop()
            }
        }
    }
    
    private func updateContentSizeLoop() {
        var targetSize = frame.size
        if let count = dataSource?.numberOfView(self) where count > Int(visiblePage) {
            let targetCount = count + Int(2 * visiblePage)
            if direction == .Horizontal {
                targetSize = CGSizeMake(CGFloat(targetCount) * pageWidth, frame.height)
            } else {
                targetSize = CGSizeMake(pageWidth, CGFloat(targetCount) * pageHeight)
            }
        }
        if !CGSizeEqualToSize(targetSize, contentSize) {
            contentSize = targetSize
        }
        
    }
    
    private func resetPagesLoop() {
        let pre = pageViews
        pageViews = []
        for page in pre {
            page.view.removeFromSuperview()
        }
    }
    
    private func frameLoop(page:Int) -> CGRect {
        switch direction {
        case .Horizontal:
            let pageWidth = self.pageWidth
            return CGRectMake(CGFloat(page + offsetPage) * pageWidth, 0, pageWidth, pageHeight)
        case .Vertical:
            let pageHeight = self.pageHeight
            return CGRectMake(0, CGFloat(page + offsetPage) * pageHeight, pageWidth, pageHeight)
        }
    }
    
    private func validPageLoop(page:Int, count:Int) -> Int {
        var p = page
        while p < 0 {
            p += 100 * count
        }
        return count > 0 ? p % count : 0
    }

    private func setupPageLoop(page:Int, count:Int, tail:Bool, inout reusablePages:[CarouselPage]) -> CarouselPage {
        let validPage = validPageLoop(page, count: count)
        var pageView:CarouselPage!
        for (index, p) in reusablePages.enumerate() {
            if p.validPage == validPage && p.count == count {
                pageView = p.reuse(page, count: count)
                reusablePages.removeAtIndex(index)
                break
            }
        }
        if pageView == nil {
            pageView = CarouselPage.init(page: page, count: count, view: fetchPage(validPage))
        }
        if tail {
            pageViews.append(pageView)
        } else {
            pageViews.insert(pageView, atIndex: 0)
        }
        
        addSubview(pageView.view)
        pageView.view.frame = frameLoop(page)
        return pageView
    }
    
    private func updateVisiblePageLoop() {
        guard let ds = dataSource where ds.numberOfView(self) > 0 && frame.width > 0 else {
            resetPagesLoop()
            return
        }
        
        let count = ds.numberOfView(self)
        if direction == .Horizontal {
            let pageWidth = self.pageWidth
            let bufferPageWidth = min(CGFloat(visiblePage + bufferPage * 2), CGFloat(count)) * pageWidth
            let maxX = floor((contentOffset.x + bufferPageWidth) / pageWidth) * pageWidth
            let minX = maxX - bufferPageWidth
            var toRemovePages = [CarouselPage]()
            
            // 右侧：移除page
            while let page = pageViews.last where page.view.frame.minX + threshold > maxX {
                toRemovePages.append(pageViews.removeLast())
            }
            // 左侧：移除page
            while let page = pageViews.first where page.view.frame.maxX - threshold < minX {
                toRemovePages.insert(pageViews.removeFirst(), atIndex: 0)
            }
            
            // 处理为空情况
            if pageViews.isEmpty {
                var empty = [CarouselPage]()
                setupPageLoop(Int(contentOffset.x / pageWidth) - offsetPage, count: count, tail: true, reusablePages: &empty)
            }
            // 右侧：添加page
            while let page = pageViews.last where page.view.frame.maxX + threshold < maxX {
                setupPageLoop(page.page + 1, count: count, tail: true, reusablePages: &toRemovePages)
            }
            // 左侧：添加page
            while let page = pageViews.first where page.view.frame.minX - threshold > minX {
                setupPageLoop(page.page - 1, count: count, tail: false, reusablePages: &toRemovePages)
            }
        } else {
            let pageHeight = self.pageHeight
            let bufferPageHeight = min(CGFloat(visiblePage + bufferPage * 2), CGFloat(count)) * pageHeight
            let maxY = floor((contentOffset.y + bufferPageHeight) / pageHeight) * pageHeight
            let minY = maxY - bufferPageHeight
            var toRemovePages = [CarouselPage]()
            
            // 尾部：移除page
            while let page = pageViews.last where page.view.frame.minY + threshold > maxY {
                toRemovePages.append(pageViews.removeLast())
            }
            // 首部：移除page
            while let page = pageViews.first where page.view.frame.maxY - threshold < minY {
                toRemovePages.insert(pageViews.removeFirst(), atIndex: 0)
            }
            
            // 处理为空情况
            if pageViews.isEmpty {
                var empty = [CarouselPage]()
                setupPageLoop(Int(contentOffset.y / pageHeight) - offsetPage, count: count, tail: true, reusablePages: &empty)
            }
            // 尾部：添加page
            while let page = pageViews.last where page.view.frame.maxY + threshold < maxY {
                setupPageLoop(page.page + 1, count: count, tail: true, reusablePages: &toRemovePages)
            }
            // 首部：添加page
            while let page = pageViews.first where page.view.frame.minY - threshold > minY {
                setupPageLoop(page.page - 1, count: count, tail: false, reusablePages: &toRemovePages)
            }
        }
    }
}

extension CarouselScrollView: UIScrollViewDelegate {
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        switch direction {
        case .Horizontal:
            let pageWidth = self.pageWidth
            var targetX = round(targetContentOffset.memory.x / pageWidth) * pageWidth
            targetX = max(min(targetX, contentSize.width), 0)
            targetContentOffset.memory.x = targetX
        case .Vertical:
            let pageHeight = self.pageHeight
            var targetY = round(targetContentOffset.memory.y / pageHeight) * pageHeight
            targetY = max(min(targetY, contentSize.height), 0)
            targetContentOffset.memory.y = targetY
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateContentOffset()
    }
}

extension CarouselScrollView {
    var visiblePageViews:[CarouselPage] {
        var result = [CarouselPage]()
        switch direction {
        case .Horizontal:
            let minX = contentOffset.x
            let maxX = contentOffset.x + frame.width
            for p in pageViews {
                if p.view.frame.minX > minX - threshold && p.view.frame.maxX < maxX + threshold {
                    result.append(p)
                }
            }
        case .Vertical:
            let minY = contentOffset.y
            let maxY = contentOffset.y + frame.height
            for p in pageViews {
                if p.view.frame.minY > minY - threshold && p.view.frame.maxY < maxY + threshold {
                    result.append(p)
                }
            }
        }
        return result
    }
    
    var firstVisiblePageViews:CarouselPage? {
        var page = pageViews.first
        switch direction {
        case .Horizontal:
            for p in pageViews {
                if p.view.frame.maxX - threshold > contentOffset.x {
                    page = p
                    break
                }
            }
        case .Vertical:
            for p in pageViews {
                if p.view.frame.maxY - threshold > contentOffset.y {
                    page = p
                    break
                }
            }
        }
        return page
    }
    
    var lastVisiblePageViews:CarouselPage? {
        var page = pageViews.last
        switch direction {
        case .Horizontal:
            for p in pageViews {
                if p.view.frame.maxX + threshold > contentOffset.x + frame.width {
                    page = p
                    break
                }
            }
        case .Vertical:
            for p in pageViews {
                if p.view.frame.maxY + threshold > contentOffset.y + frame.height {
                    page = p
                    break
                }
            }
        }
        return page
    }
    
    func scrollToPage(page:Int, animated:Bool = false) {
        switch type {
        case .Linear:
            setContentOffset(frameLinear(page).origin, animated: animated)
            
        case .Loop:
            setContentOffset(frameLoop(page).origin, animated: animated)
        }
        updateVisiblePage()
    }
}

