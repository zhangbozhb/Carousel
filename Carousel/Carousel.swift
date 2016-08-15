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


public class CarouselPage {
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
    
    func reuse(page:Int) -> CarouselPage {
        self.page = page
        return self
    }
    
    func removePage() {
        view.removeFromSuperview()
    }
}

extension CarouselPage {
    var cacheKey: String {
        return "\(validPage)_\(count)"
    }
}

class CarouselPageCache {
    private var pageCount = 0
    private var cachedPages = [String: (Int, CarouselPage)]()
    
    private var queueIndex:Int = 0

    func push(page:CarouselPage) {
        if cachedPages.isEmpty {
            pageCount = page.count
        } else if pageCount != page.count {
            cachedPages = [:]
            pageCount = page.count
        }
        queueIndex += 1
        cachedPages[page.cacheKey] = (queueIndex, page)
    }
    
    func cachePage(page:Int, count:Int, removeFromCache:Bool = true) -> CarouselPage? {
        guard count > 0 else {
            return nil
        }
        let cacheKey = "\(page)_\(count)"
        let cached = cachedPages[cacheKey]
        if removeFromCache {
            cachedPages.removeValueForKey(cacheKey)
        }
        return cached?.1
    }
    
    func clear() {
        cachedPages = [:]
    }
    
    func limitSize(size:Int) {
        if size > 0 && cachedPages.count > size {
            let sorted = cachedPages.sort({ $0.1.0 > $1.1.0 })
            var remainedPages = [String: (Int, CarouselPage)]()
            for p in sorted[0..<size] {
                remainedPages[p.0] = p.1
            }
            for p in sorted[size..<sorted.count] {
                p.1.1.removePage()
            }
            cachedPages = remainedPages
        } else if size == 0 {
            for p in cachedPages {
                p.1.1.removePage()
            }
            cachedPages = [:]
        }
    }
    
    deinit {
        cachedPages = [:]
    }
}

enum CarouselDirection {
    case Horizontal, Vertical
}

enum CarouselType {
    case Linear, Loop
}

extension CarouselScrollView {
    var pageWidth:CGFloat {
        return direction == .Horizontal ? frame.width / CGFloat(visiblePageCount) : frame.width
    }
    var pageHeight:CGFloat {
        return direction == .Vertical ? frame.height / CGFloat(visiblePageCount) : frame.height
    }
}

class CarouselScrollView: UIScrollView {
    private var baseInited = false
    private(set) var visiblePageCount:UInt = 3
    private(set) var bufferPageCount:UInt = 1    // one side
    
    private var threshold:CGFloat = 1
    private var pageViews = [CarouselPage]()
    private var reusablePages = CarouselPageCache()
    
    /// cached page size: default is zero, if is negative will cache all
    var cacheSize:Int = 0
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
        let minSize = Int(visiblePageCount + 2 * bufferPageCount)
        reusablePages.limitSize(cacheSize > minSize ? cacheSize - minSize : cacheSize)
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
        let pageView = reusablePages.cachePage(page, count: count, removeFromCache: true)?.reuse(page) ?? CarouselPage.init(page: page, count: count, view: fetchPage(page))
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
            let minX = max(ceil(contentOffset.x / pageWidth - CGFloat(bufferPageCount)) * pageWidth, 0)
            let maxX = minX + CGFloat(visiblePageCount + bufferPageCount * 2) * pageWidth
            
            // 右侧：移除page
            while let page = pageViews.last where page.view.frame.minX + threshold > maxX {
                reusablePages.push(pageViews.removeLast())
            }
            // 左侧：移除page
            while let page = pageViews.first where page.view.frame.maxX - threshold < minX {
                reusablePages.push(pageViews.removeFirst())
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
            let minY = max(ceil(contentOffset.y / pageHeight - CGFloat(bufferPageCount)) * pageHeight, 0)
            let maxY = minY + CGFloat(visiblePageCount + bufferPageCount * 2) * pageHeight
            
            // 尾部：移除page
            while let page = pageViews.last where page.view.frame.minY + threshold > maxY {
                reusablePages.push(pageViews.removeLast())
            }
            // 首部：移除page
            while let page = pageViews.first where page.view.frame.maxY - threshold < minY {
                reusablePages.push(pageViews.removeFirst())
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

// 循环page
extension CarouselScrollView {
    // 第一个page相对于 0 偏移的page数量
    private var offsetPage:Int {
        return Int(visiblePageCount)
    }
    
    private func updateContentOffsetLoop() {
        guard let count = dataSource?.numberOfView(self) where count > Int(visiblePageCount) else {
            return
        }
        if decelerating {
            return
        }

        switch direction {
        case .Horizontal:
            let bufferWidth = pageWidth * CGFloat(visiblePageCount)
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
            let bufferHeight = pageHeight * CGFloat(visiblePageCount)
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
        if let count = dataSource?.numberOfView(self) where count > Int(visiblePageCount) {
            let targetCount = count + Int(2 * visiblePageCount)
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
        reusablePages.clear()
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

    private func setupPageLoop(page:Int, count:Int, tail:Bool) -> CarouselPage {
        let validPage = validPageLoop(page, count: count)
        let pageView = reusablePages.cachePage(validPage, count: count, removeFromCache: true)?.reuse(page) ?? CarouselPage.init(page: page, count: count, view: fetchPage(validPage))
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
            let bufferPageWidth = min(CGFloat(visiblePageCount + bufferPageCount * 2), CGFloat(count)) * pageWidth
            let maxX = floor((contentOffset.x + bufferPageWidth) / pageWidth) * pageWidth
            let minX = maxX - bufferPageWidth
            
            // 右侧：移除page
            while let page = pageViews.last where page.view.frame.minX + threshold > maxX {
                reusablePages.push(pageViews.removeLast())
            }
            // 左侧：移除page
            while let page = pageViews.first where page.view.frame.maxX - threshold < minX {
                reusablePages.push(pageViews.removeFirst())
            }
            
            // 处理为空情况
            if pageViews.isEmpty {
                setupPageLoop(Int(contentOffset.x / pageWidth) - offsetPage, count: count, tail: true)
            }
            // 右侧：添加page
            while let page = pageViews.last where page.view.frame.maxX + threshold < maxX {
                setupPageLoop(page.page + 1, count: count, tail: true)
            }
            // 左侧：添加page
            while let page = pageViews.first where page.view.frame.minX - threshold > minX {
                setupPageLoop(page.page - 1, count: count, tail: false)
            }
        } else {
            let pageHeight = self.pageHeight
            let bufferPageHeight = min(CGFloat(visiblePageCount + bufferPageCount * 2), CGFloat(count)) * pageHeight
            let maxY = floor((contentOffset.y + bufferPageHeight) / pageHeight) * pageHeight
            let minY = maxY - bufferPageHeight
            
            // 尾部：移除page
            while let page = pageViews.last where page.view.frame.minY + threshold > maxY {
                reusablePages.push(pageViews.removeLast())
            }
            // 首部：移除page
            while let page = pageViews.first where page.view.frame.maxY - threshold < minY {
                reusablePages.push(pageViews.removeFirst())
            }
            
            // 处理为空情况
            if pageViews.isEmpty {
                setupPageLoop(Int(contentOffset.y / pageHeight) - offsetPage, count: count, tail: true)
            }
            // 尾部：添加page
            while let page = pageViews.last where page.view.frame.maxY + threshold < maxY {
                setupPageLoop(page.page + 1, count: count, tail: true)
            }
            // 首部：添加page
            while let page = pageViews.first where page.view.frame.minY - threshold > minY {
                setupPageLoop(page.page - 1, count: count, tail: false)
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
    var visiblePages:[CarouselPage] {
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
    
    var firstVisiblePage:CarouselPage? {
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
    
    var lastVisiblePage:CarouselPage? {
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
            var offset = frameLinear(page).origin
            switch direction {
            case .Horizontal:
                let maxX = contentSize.width - frame.width
                offset.x = max(min(maxX, offset.x), 0)
            case .Vertical:
                let maxY = contentSize.height - frame.height
                offset.y = max(min(maxY, offset.y), 0)
            }
            setContentOffset(offset, animated: animated)
        case .Loop:
            setContentOffset(frameLoop(page).origin, animated: animated)
        }
        updateVisiblePage()
    }
    
    func nextPage(animated:Bool = false) {
        guard let first = firstVisiblePage else {
            return
        }
        scrollToPage(first.page + 1, animated: animated)
    }
    
    func prePage(animated:Bool = false) {
        guard let first = firstVisiblePage else {
            return
        }
        scrollToPage(first.page - 1, animated: animated)
    }
}

