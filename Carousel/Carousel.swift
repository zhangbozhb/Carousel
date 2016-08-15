//
//  Carousel.swift
//  Carousel
//
//  Created by travel on 16/7/26.
//
//	iOS 8.0+
//
//	The MIT License (MIT)
//	Copyright © 2016 travel.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of
//	this software and associated documentation files (the "Software"), to deal in
//	the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//	the Software, and to permit persons to whom the Software is furnished to do so,
//	subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

public protocol CarouselScrollViewDataSourse:class {
    func numberOfView(carousel:CarouselScrollView) -> Int
    func carousel(carousel:CarouselScrollView, viewForIndex:Int) -> UIView?
}

@objc public protocol CarouselScrollViewDelegate:class {
    optional func carousel(carousel:CarouselScrollView, scrollFrom:Int, to:Int, progress:CGFloat)
    optional func carousel(carousel:CarouselScrollView, didScrollFrom:Int, to:Int)
}

private func formatedPage(page:Int, ofCount count:Int) -> Int {
    var p = page
    while p < 0 {
        p += 100 * count
    }
    return count > 0 ? p % count : 0
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
    
    public var validPage:Int {
        return formatedPage(page, ofCount: count)
    }
    
    func reuse(page:Int) -> CarouselPage {
        self.page = page
        return self
    }
    
    public func removePage() {
        view.removeFromSuperview()
    }
}

extension CarouselPage {
    var cacheKey: String {
        return "\(validPage)_\(count)"
    }
}

class CarouselPageCache {
    private var maxSize = 0
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
    
    func limitToCacheSize() {
        if 0 < maxSize && maxSize < cachedPages.count {
            let sorted = cachedPages.sort({ $0.1.0 > $1.1.0 })
            var remainedPages = [String: (Int, CarouselPage)]()
            for p in sorted[0..<maxSize] {
                remainedPages[p.0] = p.1
            }
            for p in sorted[maxSize..<sorted.count] {
                p.1.1.removePage()
            }
            cachedPages = remainedPages
        } else if maxSize == 0 {
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

public enum CarouselDirection {
    case Horizontal, Vertical
}

public enum CarouselType {
    case Linear, Loop
}

public extension CarouselScrollView {
    public var pageWidth:CGFloat {
        return direction == .Horizontal ? frame.width / CGFloat(visiblePageCount) : frame.width
    }
    public var pageHeight:CGFloat {
        return direction == .Vertical ? frame.height / CGFloat(visiblePageCount) : frame.height
    }
}

public class CarouselScrollView: UIScrollView {
    private var baseInited = false
    private(set) var visiblePageCount:UInt = 3
    private(set) var bufferPageCount:UInt = 1    // one side
    
    private var threshold:CGFloat = 1
    private var pageViews = [CarouselPage]()
    private var reusablePages = CarouselPageCache()
    
    
    private var _preFirstPage:Int = 0
    private var _preContentOffset = CGPointZero
    private var _delegateWrapper = CarouselScrollViewDelegateWrapper()
    
    /// cached page size: default is zero, if is negative will cache all
    private var reusablePageSize:Int {
        let minSize = Int(visiblePageCount + 2 * bufferPageCount)
        return cacheSize > minSize ? cacheSize - minSize : cacheSize
    }
    public var cacheSize:Int = 0 {
        didSet {
            reusablePages.maxSize = reusablePageSize
        }
    }
    public var direction = CarouselDirection.Horizontal
    public var type = CarouselType.Linear
    public var pagingRequired = true {
        didSet {
            pagingEnabled = false
        }
    }
    public var dataSource:CarouselScrollViewDataSourse? {
        didSet {
            if dataSource !== oldValue {
                reload()
            }
        }
    }
    public weak var carouselDelegate:CarouselScrollViewDelegate?
    
    private var autoScrollTimer:NSTimer?
    private var autoScrollIncrease = true
    
    
    private var contextKVO:Int = 0
    private var kPaths = [String]()
    private var kdelegatePath = "delegate"
    private var kpagingEnabled = "pagingEnabled"
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    
    deinit {
        for path in kPaths {
            removeObserver(self, forKeyPath: path)
        }
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        reusablePages.clear()
        pageViews = []
    }
    
    private func baseInit() {
        guard !baseInited else {
            return
        }
        baseInited = true
        
        contentSize = frame.size
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        pagingEnabled = false
        delegate = _delegateWrapper
        reusablePages.maxSize = reusablePageSize
        
        _delegateWrapper.wrapper = self
        
        addObserver(self, forKeyPath: kdelegatePath, options: .New, context: &contextKVO)
        kPaths.append(kdelegatePath)
        addObserver(self, forKeyPath: kpagingEnabled, options: .New, context: &contextKVO)
        kPaths.append(kpagingEnabled)
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &contextKVO else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        if keyPath == kdelegatePath {
            if let value = change?[NSKeyValueChangeNewKey] as? UIScrollViewDelegate where value !== _delegateWrapper {
                _delegateWrapper.source = value
                delegate = _delegateWrapper
            }
        } else if keyPath == kpagingEnabled {
            if let value = change?[NSKeyValueChangeNewKey] as? NSNumber where value.boolValue {
                pagingEnabled = false
            }
        }
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
        reusablePages.limitToCacheSize()
    }
    
    public func reload() {
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
    
    func updateScrollProgress()  {
        switch type {
        case .Linear:
            updateScrollProgressLinear()
        case .Loop:
            updateScrollProgressLoop()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateContentSize()
        updateVisiblePage()
    }
}

// 线性page
extension CarouselScrollView {
    private func updateScrollProgressLinear() {
        if let first = firstVisiblePage where first.page < first.count {
            
            let validPage = first.validPage
            if validPage != _preFirstPage {
                carouselDelegate?.carousel?(self, didScrollFrom: _preFirstPage, to: validPage)
                _preFirstPage = validPage
            } else {
                switch direction {
                case .Horizontal:
                    let increasePage = _preContentOffset.x < contentOffset.x
                    let next = increasePage ? first.page + 1 : first.page - 1
                    if next > 0 && next < first.count {
                        var progress = contentOffset.x / pageWidth
                        progress = increasePage ? progress - floor(progress) : progress - ceil(progress)
                        carouselDelegate?.carousel?(self, scrollFrom: _preFirstPage, to: next, progress: progress)
                    }
                case .Vertical:
                    let increasePage = _preContentOffset.y < contentOffset.y
                    let next = increasePage ? first.page + 1 : first.page - 1
                    if next > 0 && next < first.count {
                        var progress = contentOffset.y / pageHeight
                        progress = increasePage ? progress - floor(progress) : progress - ceil(progress)
                        carouselDelegate?.carousel?(self, scrollFrom: _preFirstPage, to: next, progress: progress)
                    }
                }
            }
            _preContentOffset = contentOffset
        }
    }
    
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
            
            // right：remove page
            while let page = pageViews.last where page.view.frame.minX + threshold > maxX {
                reusablePages.push(pageViews.removeLast())
            }
            // left：remove page
            while let page = pageViews.first where page.view.frame.maxX - threshold < minX {
                reusablePages.push(pageViews.removeFirst())
            }
            
            // handle empty
            if pageViews.isEmpty {
                setupPageLinear(Int(contentOffset.x / pageWidth), count: count)
            }
            // right：add page
            while let page = pageViews.last where page.page < count - 1 && page.view.frame.maxX + threshold < maxX {
                setupPageLinear(page.page + 1, count: count, tail: true)
            }
            // left：add page
            while let page = pageViews.first where page.page > 0 && page.view.frame.minX - threshold > minX {
                setupPageLinear(page.page - 1, count: count, tail: false)
            }
        } else {
            let pageHeight = self.pageHeight
            let minY = max(ceil(contentOffset.y / pageHeight - CGFloat(bufferPageCount)) * pageHeight, 0)
            let maxY = minY + CGFloat(visiblePageCount + bufferPageCount * 2) * pageHeight
            
            // tail：remove page
            while let page = pageViews.last where page.view.frame.minY + threshold > maxY {
                reusablePages.push(pageViews.removeLast())
            }
            // top：remove page
            while let page = pageViews.first where page.view.frame.maxY - threshold < minY {
                reusablePages.push(pageViews.removeFirst())
            }
            
            // handle empty
            if pageViews.isEmpty {
                setupPageLinear(Int(contentOffset.y / pageHeight), count: count)
            }
            // tail：add page
            while let page = pageViews.last where page.page < count - 1 && page.view.frame.maxY + threshold < maxY {
                setupPageLinear(page.page + 1, count: count, tail: true)
            }
            // top：add page
            while let page = pageViews.first where page.page > 0 && page.view.frame.minY - threshold > minY {
                setupPageLinear(page.page - 1, count: count, tail: false)
            }
        }
    }
}

// loop page
extension CarouselScrollView {
    // page zero offset
    private var offsetPage:Int {
        return Int(visiblePageCount)
    }
    
    private func updateScrollProgressLoop() {
        if let first = firstVisiblePage {
            let validPage = first.validPage
            if validPage != _preFirstPage {
                carouselDelegate?.carousel?(self, didScrollFrom: _preFirstPage, to: validPage)
                _preFirstPage = validPage
            } else {
                switch direction {
                case .Horizontal:
                    let increasePage = _preContentOffset.x < contentOffset.x
                    let next = formatedPage(increasePage ? first.page + 1 : first.page - 1, ofCount: first.count)
                    var progress = contentOffset.x / pageWidth
                    progress = increasePage ? progress - floor(progress) : progress - ceil(progress)
                    carouselDelegate?.carousel?(self, scrollFrom: _preFirstPage, to: next, progress: progress)
                case .Vertical:
                    let increasePage = _preContentOffset.y < contentOffset.y
                    let next = formatedPage(increasePage ? first.page + 1 : first.page - 1, ofCount: first.count)
                    var progress = contentOffset.y / pageHeight
                    progress = increasePage ? progress - floor(progress) : progress - ceil(progress)
                    carouselDelegate?.carousel?(self, scrollFrom: _preFirstPage, to: next, progress: progress)
                }
            }
            _preContentOffset = contentOffset
        }
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
    
    private func setupPageLoop(page:Int, count:Int, tail:Bool) -> CarouselPage {
        let validPage = formatedPage(page, ofCount: count)
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
            
            // right：remove page
            while let page = pageViews.last where page.view.frame.minX + threshold > maxX {
                reusablePages.push(pageViews.removeLast())
            }
            // left：remove page
            while let page = pageViews.first where page.view.frame.maxX - threshold < minX {
                reusablePages.push(pageViews.removeFirst())
            }
            
            // handle empty
            if pageViews.isEmpty {
                setupPageLoop(Int(contentOffset.x / pageWidth) - offsetPage, count: count, tail: true)
            }
            // right：add page
            while let page = pageViews.last where page.view.frame.maxX + threshold < maxX {
                setupPageLoop(page.page + 1, count: count, tail: true)
            }
            // left：add page
            while let page = pageViews.first where page.view.frame.minX - threshold > minX {
                setupPageLoop(page.page - 1, count: count, tail: false)
            }
        } else {
            let pageHeight = self.pageHeight
            let bufferPageHeight = min(CGFloat(visiblePageCount + bufferPageCount * 2), CGFloat(count)) * pageHeight
            let maxY = floor((contentOffset.y + bufferPageHeight) / pageHeight) * pageHeight
            let minY = maxY - bufferPageHeight
            
            // tail：remove page
            while let page = pageViews.last where page.view.frame.minY + threshold > maxY {
                reusablePages.push(pageViews.removeLast())
            }
            // top：remove page
            while let page = pageViews.first where page.view.frame.maxY - threshold < minY {
                reusablePages.push(pageViews.removeFirst())
            }
            
            // handle empty
            if pageViews.isEmpty {
                setupPageLoop(Int(contentOffset.y / pageHeight) - offsetPage, count: count, tail: true)
            }
            // tail：add page
            while let page = pageViews.last where page.view.frame.maxY + threshold < maxY {
                setupPageLoop(page.page + 1, count: count, tail: true)
            }
            // top：add page
            while let page = pageViews.first where page.view.frame.minY - threshold > minY {
                setupPageLoop(page.page - 1, count: count, tail: false)
            }
        }
    }
}

// support page enable and adjust content offset
extension CarouselScrollView: UIScrollViewDelegate {
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard pagingRequired else {
            return
        }
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
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        // update scroll progess
        updateScrollProgress()
        
        // update content offset if needed
        updateContentOffset()
    }
}

// usefull extension
extension CarouselScrollView {
    public var visiblePages:[CarouselPage] {
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
    
    public var firstVisiblePage:CarouselPage? {
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
    
    public var lastVisiblePage:CarouselPage? {
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
    
    public func scrollToPage(page:Int, animated:Bool = false) {
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
            if Int(contentSize.width) > Int(frame.width) || Int(contentSize.height) > Int(frame.height) {
                setContentOffset(frameLoop(page).origin, animated: animated)
            }
        }
        updateVisiblePage()
    }
    
    public func nextPage(animated:Bool = false) {
        guard let first = firstVisiblePage else {
            return
        }
        scrollToPage(first.page + 1, animated: animated)
    }
    
    public func prePage(animated:Bool = false) {
        guard let first = firstVisiblePage else {
            return
        }
        scrollToPage(first.page - 1, animated: animated)
    }
}

// support auto scoll
public extension CarouselScrollView {
    func autoScrollNext() {
        nextPage(true)
    }
    
    func autoScrollPre() {
        prePage(true)
    }
    
    public func autoScroll(timeInterval:NSTimeInterval, increase:Bool) {
        autoScrollIncrease = increase
        autoScrollTimer?.invalidate()
        autoScrollTimer = NSTimer.scheduledTimerWithTimeInterval(
            timeInterval,
            target: self,
            selector: increase ? #selector(self.autoScrollNext) : #selector(self.autoScrollPre),
            userInfo: nil,
            repeats: true)
    }
    
    public func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    public func pauseAutoScroll() {
        autoScrollTimer?.invalidate()
    }
    
    public func resumeAutoScroll() {
        if let timer = autoScrollTimer {
            autoScroll(timer.timeInterval, increase: autoScrollIncrease)
        }
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        pauseAutoScroll()
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        resumeAutoScroll()
    }
}


class CarouselScrollViewDelegateWrapper:NSObject, UIScrollViewDelegate {
    weak var source:UIScrollViewDelegate?
    weak var wrapper:UIScrollViewDelegate?
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        wrapper?.scrollViewDidScroll?(scrollView)
        source?.scrollViewDidScroll?(scrollView)
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        wrapper?.scrollViewDidZoom?(scrollView)
        source?.scrollViewDidZoom?(scrollView)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        wrapper?.scrollViewWillBeginDragging?(scrollView)
        source?.scrollViewWillBeginDragging?(scrollView)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        wrapper?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        source?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        wrapper?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        source?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        wrapper?.scrollViewWillBeginDecelerating?(scrollView)
        source?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        wrapper?.scrollViewDidEndScrollingAnimation?(scrollView)
        source?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return source?.viewForZoomingInScrollView?(scrollView)
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        wrapper?.scrollViewWillBeginZooming?(scrollView, withView: view)
        source?.scrollViewWillBeginZooming?(scrollView, withView: view)
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        wrapper?.scrollViewDidEndZooming?(scrollView, withView: view, atScale: scale)
        source?.scrollViewDidEndZooming?(scrollView, withView: view, atScale: scale)
    }
    
    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return source?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }
    
    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        wrapper?.scrollViewDidScrollToTop?(scrollView)
        source?.scrollViewDidScrollToTop?(scrollView)
    }
}
