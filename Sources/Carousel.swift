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


public protocol CarouselViewDataSourse:class {
    /**
     number of view for carouse
     
     - parameter carousel: CarouselView instance
     
     - returns: number of view
     */
    func numberOfView(carousel:CarouselView) -> Int
    /**
     iew at index for carouse
     
     - parameter carousel: instance of CarouselView
     - parameter index:    page index for view
     
     - returns: view at page index
     */
    func carousel(carousel:CarouselView, viewForIndex index:Int) -> UIView?
}

@objc public protocol CarouselViewDelegate:class {
    /**
     page scroll progress
     
     - parameter carousel: instance of CarouselView
     - parameter from:     from page(first visiable page)
     - parameter to:       to page
     - parameter progress: progess for scroll: progress > 0, page grow direction, < 0 page decrease diretion
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, scrollFrom from:Int, to:Int, progress:CGFloat)
    /**
     page did scroll from page to page
     
     - parameter carousel: instance of CarouselView
     - parameter from:     from page(first visiable page)
     - parameter to:       to page
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, didScrollFrom from:Int, to:Int)
    /**
     page will add to carousel
     
     - parameter carousel: instance of CarouselView
     - parameter page:     page index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, willInstallPage page:Int)
    /**
     page will remove from carousel
     
     - parameter carousel: instance of CarouselView
     - parameter page:     page index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, willUninstallPage page:Int)
    /**
     page did add to carousel
     
     - parameter carousel: instance of CarouselView
     - parameter page:     page index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, didInstallPage page:Int)
    /**
     page did remove from carousel
     
     - parameter carousel: instance of CarouselView
     - parameter page:     page index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, didUninstallPage page:Int)
}

private func formatedPage(page:Int, ofCount count:Int) -> Int {
    var p = page
    while p < 0 {
        p += 100 * count
    }
    return count > 0 ? p % count : 0
}

private func formatedPage(page:CGFloat, ofCount count:CGFloat) -> CGFloat {
    var p = page
    while p < 0 {
        p += 100 * count
    }
    return count > 0 ? p % count : 0
}

public class CarouselPage {
    private var page:Int = 0
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
    
    func reuse(view:UIView) {
        guard self.view !== view else {
            return
        }
        
        let pre = self.view
        self.view = view
        if let c = pre.superview {
            c.insertSubview(view, aboveSubview: pre)
            view.frame = pre.frame
            pre.removeFromSuperview()
        }
    }
    
    public func uninstall() {
        willUninstall()
        view.removeFromSuperview()
        didUninstall()
    }
    
    /**
     install page to view with frame
     
     - parameter toView: the view container
     - parameter frame:  frame in container
     
     - returns: true if page has not add before, false page has added
     */
    func install(toView:UIView, frame:CGRect) {
        if view.superview !== toView {
            willInstall()
            view.removeFromSuperview()
            toView.addSubview(view)
            didInstall()
        }
        view.frame = frame
    }
    
    func willUninstall() {
    }
    
    func didUninstall() {
    }
    
    func willInstall() {
    }
    
    func didInstall() {
    }
}

private class CarouselPageView: CarouselPage {
    private weak var carouselView: CarouselView?
    private weak var delegate:CarouselViewDelegate?
    
    init(page:Int, count:Int, view:UIView, carousel: CarouselView, delegate:CarouselViewDelegate?) {
        super.init(page: page, count:count, view: view)
        self.carouselView = carousel
        self.delegate = delegate
    }
    
    override func willUninstall() {
        if let carousel = carouselView {
            delegate?.carousel?(carousel, didUninstallPage: validPage)
        }
    }
    
    override func didUninstall() {
        if let carousel = carouselView {
            delegate?.carousel?(carousel, willUninstallPage: validPage)
        }
    }
    
    override func willInstall() {
        if let carousel = carouselView {
            delegate?.carousel?(carousel, willInstallPage: validPage)
        }
    }
    
    override func didInstall() {
        if let carousel = carouselView {
            delegate?.carousel?(carousel, didInstallPage: validPage)
        }
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

    /**
     cache page
     
     - parameter page:            page to cache
     - parameter uninstall:       if true uninstall page
     - parameter ignoreSizeLimit: if true ignore size limit, you should call limitToCacheSize manually
     */
    func push(page:CarouselPage, uninstall:Bool = true, ignoreSizeLimit:Bool = false) {
        if uninstall {
            page.uninstall()
        }
        
        if cachedPages.isEmpty {
            pageCount = page.count
        } else if pageCount != page.count {
            cachedPages = [:]
            pageCount = page.count
        }
        queueIndex += 1
        cachedPages[page.cacheKey] = (queueIndex, page)
        
        if !ignoreSizeLimit {
            limitToCacheSize()
        }
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
                p.1.1.uninstall()
            }
            cachedPages = remainedPages
        } else if maxSize == 0 {
            for p in cachedPages {
                p.1.1.uninstall()
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

public extension CarouselView {
    /// page witdh: greate than 1
    public var pageWidth:CGFloat {
        return max(direction == .Horizontal ? frame.width / CGFloat(visiblePageCount) : frame.width, threshold)
    }
    /// page heigt: greate than 1
    public var pageHeight:CGFloat {
        return max(direction == .Vertical ? frame.height / CGFloat(visiblePageCount) : frame.height, threshold)
    }
}

public class CarouselView: UIScrollView {
    private var baseInited = false
    /// visible page count
    public var visiblePageCount:Int = 1 {
        didSet {
            if visiblePageCount <= 0 {
                visiblePageCount = 1
            }
            updatePagingEnabled()
            if visiblePageCount != oldValue {
                relayoutPage()
            }
        }
    }
    /// buffer page count(page create but not visible)
    public var bufferPageCount:Int = 1 {        // one side
        didSet {
            if bufferPageCount < 0 {
                visiblePageCount = 0
            } else {
                updateVisiblePage()
            }
        }
    }

    private var loopPageTimes:Int = 2
    private var threshold:CGFloat = 1
    private var pageViews = [CarouselPage]()
    private var reusablePages = CarouselPageCache()
    
    private var _preSize:CGSize = CGSize()
    private var _preFirstPage:Int = 0
    private var _preContentOffset = CGPointZero
    private var _delegateWrapper = CarouselScrollViewDelegateWrapper()
    
    /// cached page size: default is zero, if is negative will cache all
    private var reusablePageSize:Int {
        let minSize = visiblePageCount + 2 * bufferPageCount
        return cacheSize > minSize ? cacheSize - minSize : cacheSize
    }
    /// reuse page size number, if negative will cache all pages( high memory usage)
    public var cacheSize:Int = 0 {
        didSet {
            reusablePages.maxSize = reusablePageSize
        }
    }
    /// layout direction
    public var direction = CarouselDirection.Horizontal
    /// page layout in Loop or Linear
    public var type = CarouselType.Linear
    /// support paging
    public var pagingRequired = true {
        didSet {
            updatePagingEnabled()
        }
    }
    /// if true ignore pagingEnabled and use pagingRequired instead, default is true
    public var ignorePagingEnabled = true
    /// data source of page views
    public weak var dataSource:CarouselViewDataSourse? {
        didSet {
            if dataSource !== oldValue {
                reload()
            }
        }
    }
    /// scroll delegate
    public weak var carouselDelegate:CarouselViewDelegate?
    
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
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        _preSize = frame.size
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.handleNotifications(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.handleNotifications(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
        
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
            updatePagingEnabled()
        }
    }
    /**
     update pagingEnabled pagingRequired to avoid both true
     */
    private func updatePagingEnabled() {
        guard pagingEnabled && pagingRequired else {
            return
        }
        
        if visiblePageCount > 1 {
            pagingEnabled = false
        } else {
            if ignorePagingEnabled {
                pagingEnabled = false
            } else {
                pagingRequired = false
            }
        }
    }
    
    final func handleNotifications(notification:NSNotification) {
        UIApplicationWillResignActiveNotification
        switch notification.name {
        case UIApplicationDidBecomeActiveNotification:
            resumeAutoScroll()
        case UIApplicationWillResignActiveNotification:
            pauseAutoScroll()
        default:
            break
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
    
    private func fetchPage(validPage: Int, count:Int, page:Int) -> CarouselPage {
        let view = dataSource?.carousel(self, viewForIndex: validPage) ?? UIView()
        return CarouselPageView.init(page: page, count: count, view: view, carousel:self, delegate: carouselDelegate)
    }
    
    @inline(__always) func numberOfView() -> Int? {
        return dataSource?.numberOfView(self)
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
    /**
     reload latest data source and update views
     */
    public func reload() {
        resetPages()
        updateVisiblePage()
        
        updateContentSize()
    }
    /**
     relayout but do not promise to load latest data source
     */
    private func relayoutPage() {
        let pre = pageViews
        pageViews = []
        for page in pre {
            reusablePages.push(page, uninstall: false, ignoreSizeLimit: true)
        }
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
        
        if !CGSizeEqualToSize(_preSize, frame.size) {
            relayoutPage()
            scrollToPage(Int(preSizePage))
            _preSize = frame.size
        } else {
            updateContentSize()
            updateVisiblePage()
        }
    }
    
    private var preSizePage:CGFloat {
        var page:CGFloat = 0
        switch direction {
        case .Horizontal:
            page = _preSize.width > 0 ? contentOffset.x * CGFloat(visiblePageCount) / _preSize.width : 0
        case .Vertical:
            page = _preSize.height > 0 ? contentOffset.y * CGFloat(visiblePageCount) / _preSize.height : 0
        }
        return page - CGFloat(_offsetPage)
    }
    
    
    private func carouselScrollFrom(from:Int, to:Int, progress:CGFloat) {
        carouselDelegate?.carousel?(self, scrollFrom: from, to: to, progress: progress)
    }
    
    private func carouselDidScrollFrom(from:Int, to:Int) {
        carouselDelegate?.carousel?(self, didScrollFrom: from, to: to)
    }
}

// 线性page
extension CarouselView {
    private func updateScrollProgressLinear() {
        if let first = firstVisiblePage where first.page < first.count {
            let validPage = first.validPage
            if validPage != _preFirstPage {
                carouselDidScrollFrom(_preFirstPage, to: validPage)
                _preFirstPage = validPage
            } else {
                switch direction {
                case .Horizontal:
                    let increasePage = _preContentOffset.x < contentOffset.x
                    let next = increasePage ? first.page + 1 : first.page - 1
                    if next > 0 && next < first.count {
                        var progress = contentOffset.x / pageWidth
                        progress = increasePage ? progress - floor(progress) : progress - ceil(progress)
                        carouselScrollFrom(_preFirstPage, to: next, progress: progress)
                    }
                case .Vertical:
                    let increasePage = _preContentOffset.y < contentOffset.y
                    let next = increasePage ? first.page + 1 : first.page - 1
                    if next > 0 && next < first.count {
                        var progress = contentOffset.y / pageHeight
                        progress = increasePage ? progress - floor(progress) : progress - ceil(progress)
                        carouselScrollFrom(_preFirstPage, to: next, progress: progress)
                    }
                }
            }
            _preContentOffset = contentOffset
        }
    }
    
    private func updateContentSizeLinear() {
        var targetSize = frame.size
        if let count = numberOfView() where count > 0 {
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
            page.uninstall()
        }
        reusablePages.clear()
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
        let pageView = reusablePages.cachePage(page, count: count, removeFromCache: true)?.reuse(page) ?? fetchPage(page, count: count, page: page)
        if tail {
            pageViews.append(pageView)
        } else {
            pageViews.insert(pageView, atIndex: 0)
        }
        
        pageView.install(self, frame: frameLinear(page))
        return pageView
    }
    
    private func updateVisiblePageLinear() {
        guard let count = numberOfView() where count > 0 else {
            resetPagesLinear()
            return
        }
        
        if direction == .Horizontal {
            let pageWidth = self.pageWidth
            let minX = max(ceil(contentOffset.x / pageWidth - CGFloat(bufferPageCount)) * pageWidth, 0)
            let maxX = minX + CGFloat(visiblePageCount + bufferPageCount * 2) * pageWidth
            
            // right：remove page
            while let page = pageViews.last where page.view.frame.minX + threshold > maxX {
                reusablePages.push(pageViews.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // left：remove page
            while let page = pageViews.first where page.view.frame.maxX - threshold < minX {
                reusablePages.push(pageViews.removeFirst(), uninstall: false, ignoreSizeLimit: true)
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
                reusablePages.push(pageViews.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // top：remove page
            while let page = pageViews.first where page.view.frame.maxY - threshold < minY {
                reusablePages.push(pageViews.removeFirst(), uninstall: false, ignoreSizeLimit: true)
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
extension CarouselView {
    // page zero offset
    private var _offsetPage:Int {
        return visiblePageCount * loopPageTimes
    }
    
    private func updateScrollProgressLoop() {
        if let first = firstVisiblePage {
            let validPage = first.validPage
            if validPage != _preFirstPage {
                carouselDidScrollFrom(_preFirstPage, to: validPage)
                _preFirstPage = validPage
            } else {
                switch direction {
                case .Horizontal:
                    let increasePage = _preContentOffset.x < contentOffset.x
                    let next = formatedPage(increasePage ? first.page + 1 : first.page - 1, ofCount: first.count)
                    var progress = contentOffset.x / pageWidth
                    progress = increasePage ? progress - floor(progress) : progress - ceil(progress)
                    carouselScrollFrom(_preFirstPage, to: next, progress: progress)
                case .Vertical:
                    let increasePage = _preContentOffset.y < contentOffset.y
                    let next = formatedPage(increasePage ? first.page + 1 : first.page - 1, ofCount: first.count)
                    var progress = contentOffset.y / pageHeight
                    progress = increasePage ? progress - floor(progress) : progress - ceil(progress)
                    carouselScrollFrom(_preFirstPage, to: next, progress: progress)
                }
            }
            _preContentOffset = contentOffset
        }
    }
    
    private func updateContentOffsetLoop() {
        _delegateWrapper.ignoreScrollEvent = false
        guard let count = numberOfView() where count > visiblePageCount else {
            return
        }
        
        switch direction {
        case .Horizontal:
            let pageWidth = self.pageWidth
            let bufferWidth = pageWidth * CGFloat(_offsetPage)
            let totalPageWidth = pageWidth * CGFloat(count)
            let minX = bufferWidth
            let maxX = totalPageWidth + bufferWidth
            if contentOffset.x > maxX {
                _delegateWrapper.ignoreScrollEvent = true
                contentOffset.x -= totalPageWidth
                updateVisiblePageLoop()
            } else if contentOffset.x < minX {
                _delegateWrapper.ignoreScrollEvent = true
                contentOffset.x += totalPageWidth
                updateVisiblePageLoop()
            }
        case .Vertical:
            let pageHeight = self.pageHeight
            let bufferHeight = pageHeight * CGFloat(_offsetPage)
            let totalPageHeight = pageHeight * CGFloat(count)
            let minY = bufferHeight
            let maxY = totalPageHeight + bufferHeight
            if contentOffset.y > maxY {
                _delegateWrapper.ignoreScrollEvent = true
                contentOffset.y -= bufferHeight
                updateVisiblePageLoop()
            } else if contentOffset.y < minY {
                _delegateWrapper.ignoreScrollEvent = true
                contentOffset.y += bufferHeight
                updateVisiblePageLoop()
            }
        }
    }
    
    private func updateContentSizeLoop() {
        var targetSize = frame.size
        if let count = numberOfView() where count > visiblePageCount {
            let targetCount = count + 2 * _offsetPage
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
            page.uninstall()
        }
        reusablePages.clear()
    }
    
    private func frameLoop(page:Int) -> CGRect {
        switch direction {
        case .Horizontal:
            let pageWidth = self.pageWidth
            return CGRectMake(CGFloat(page + _offsetPage) * pageWidth, 0, pageWidth, pageHeight)
        case .Vertical:
            let pageHeight = self.pageHeight
            return CGRectMake(0, CGFloat(page + _offsetPage) * pageHeight, pageWidth, pageHeight)
        }
    }
    
    private func setupPageLoop(page:Int, count:Int, tail:Bool) -> CarouselPage {
        let validPage = formatedPage(page, ofCount: count)
        let pageView = reusablePages.cachePage(validPage, count: count, removeFromCache: true)?.reuse(page) ?? fetchPage(validPage, count: count, page: page)
        if tail {
            pageViews.append(pageView)
        } else {
            pageViews.insert(pageView, atIndex: 0)
        }
        
        pageView.install(self, frame: frameLoop(page))
        return pageView
    }
    
    private func updateVisiblePageLoop() {
        guard let count = numberOfView() where count > 0 else {
            resetPagesLoop()
            return
        }
        
        if direction == .Horizontal {
            let pageWidth = self.pageWidth
            let bufferPageWidth = min(CGFloat(visiblePageCount + bufferPageCount * 2), CGFloat(count)) * pageWidth
            let maxX = floor((contentOffset.x + bufferPageWidth) / pageWidth) * pageWidth
            let minX = maxX - bufferPageWidth
            
            // right：remove page
            while let page = pageViews.last where page.view.frame.minX + threshold > maxX {
                reusablePages.push(pageViews.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // left：remove page
            while let page = pageViews.first where page.view.frame.maxX - threshold < minX {
                reusablePages.push(pageViews.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if pageViews.isEmpty {
                setupPageLoop(Int(contentOffset.x / pageWidth) - _offsetPage, count: count, tail: true)
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
                reusablePages.push(pageViews.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // top：remove page
            while let page = pageViews.first where page.view.frame.maxY - threshold < minY {
                reusablePages.push(pageViews.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if pageViews.isEmpty {
                setupPageLoop(Int(contentOffset.y / pageHeight) - _offsetPage, count: count, tail: true)
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
extension CarouselView: UIScrollViewDelegate {
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
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // update content offset(to restrict position) if needed
        updateContentOffset()
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        // update content offset(to restrict position) if needed
        updateContentOffset()
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        pauseAutoScroll()
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        resumeAutoScroll()
    }
}

// usefull extension
extension CarouselView {
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
    
    public var firstVisiblePageIndex:CGFloat {
        guard let count = pageViews.first?.count where count > 0 else {
            return 0
        }
        switch direction {
        case .Horizontal:
            return formatedPage(contentOffset.x / pageWidth, ofCount: CGFloat(count))
        case .Vertical:
            return formatedPage(contentOffset.y / pageHeight, ofCount: CGFloat(count))
        }
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
public extension CarouselView {
    func autoScrollToNext() {
        nextPage(true)
    }
    
    func autoScrollToPre() {
        prePage(true)
    }
    
    /**
     auto scroll
     default auto scroll is disable
     - parameter timeInterval: scroll time interval
     - parameter increase:     page increase or decrease
     */
    public func autoScroll(timeInterval:NSTimeInterval, increase:Bool) {
        autoScrollIncrease = increase
        autoScrollTimer?.invalidate()
        autoScrollTimer = NSTimer.scheduledTimerWithTimeInterval(
            timeInterval,
            target: self,
            selector: increase ? #selector(self.autoScrollToNext) : #selector(self.autoScrollToPre),
            userInfo: nil,
            repeats: true)
    }
    
    /**
     stop auto scroll
     */
    public func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    /**
     pause auto scroll
     */
    public func pauseAutoScroll() {
        autoScrollTimer?.invalidate()
    }
    /**
     resume auto scroll
     if your never call autoScroll(_:increase), auto scroll will not work
     */
    public func resumeAutoScroll() {
        if let timer = autoScrollTimer {
            autoScroll(timer.timeInterval, increase: autoScrollIncrease)
        }
    }
}

// add reload relative method
public extension CarouselView {
    @inline(__always) private func reload(page:Int, withCount count: Int) {
        switch type {
        case .Linear:
            if page >= 0 && page < count {
                let p = fetchPage(page, count: count, page: page)
                if let _ = reusablePages.cachePage(page, count: count, removeFromCache: false) {
                    reusablePages.push(p, uninstall: true, ignoreSizeLimit: true)
                } else {
                    for vp in visiblePages {
                        if vp.page == p.page {
                            vp.reuse(p.view)
                            break
                        }
                    }
                }
            }
        case .Loop:
            let validPage = formatedPage(page, ofCount: count)
            let p = fetchPage(validPage, count: count, page: page)
            if let _ = reusablePages.cachePage(page, count: count, removeFromCache: false) {
                reusablePages.push(p, uninstall: true, ignoreSizeLimit: true)
            } else {
                for vp in visiblePages {
                    if vp.validPage == p.validPage {
                        vp.reuse(p.view)
                        break
                    }
                }
            }
        }
    }
    
    public func reload(page page:Int) {
        guard let count = numberOfView() where count > 0 else {
            reload()
            return
        }
        guard let preCount = visiblePages.first?.count where preCount != count else {
            reload()
            return
        }
        
        reload(page, withCount: count)
    }
    
    public func reload(pages pages:[Int]) {
        guard let count = numberOfView() where count > 0 else {
            reload()
            return
        }
        
        guard let preCount = visiblePages.first?.count where preCount != count else {
            reload()
            return
        }
        
        for page in Array(Set(pages)) {
            reload(page, withCount: count)
        }
    }
    
    public func reloadVisiblePages() {
        guard let count = numberOfView() where count > 0 else {
            reload()
            return
        }
        
        guard let preCount = visiblePages.first?.count where preCount != count else {
            reload()
            return
        }
        
        for vp in visiblePages {
            vp.reuse(fetchPage(vp.validPage, count: vp.count, page: vp.page).view)
        }
    }
}

class CarouselScrollViewDelegateWrapper:NSObject, UIScrollViewDelegate {
    weak var source:UIScrollViewDelegate?
    weak var wrapper:UIScrollViewDelegate?
    /// ignore scroll event: use if customer set content offset and want not fire delegate scrollViewDidScroll:
    var ignoreScrollEvent = false
    
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
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        wrapper?.scrollViewDidEndDecelerating?(scrollView)
        source?.scrollViewDidEndDecelerating?(scrollView)
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


public protocol CarouselViewControllerDataSourse:class {
    /**
     number of view controller for carouse
     
     - parameter carousel: instance of CarouselViewController
     
     - returns: number of view controller
     */
    func numberOfViewController(carousel:CarouselViewController) -> Int
    /**
     view controller at index for carouse
     
     - parameter carousel: instance of CarouselViewController
     - parameter index:    page index
     
     - returns: view controller at page index
     */
    func carousel(carousel:CarouselViewController, viewControllerForIndex index:Int) -> UIViewController?
}

@objc public protocol CarouselViewControllerDelegate:class {
    /**
     page scroll progress
     
     - parameter carousel: instance of CarouselViewController
     - parameter from:     from page(first visiable page)
     - parameter to:       to page
     - parameter progress: progess for scroll: progress > 0, page grow direction, < 0 page decrease diretion
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, scrollFrom from:Int, to:Int, progress:CGFloat)
    /**
     page did scroll from page to page
     
     - parameter carousel: instance of CarouselViewController
     - parameter from:     from page(first visiable page)
     - parameter to:       to page
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, didScrollFrom from:Int, to:Int)
    /**
     page will add to carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter page:     page index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, willInstallPage page:Int)
    /**
     page will remove from carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter page:     page index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, willUninstallPage page:Int)
    /**
     page did add to carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter page:     page index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, didInstallPage page:Int)
    /**
     page did remove from carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter page:     page index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, didUninstallPage page:Int)
}

private class CarouselPageInViewController:CarouselPage {
    private weak var viewController:UIViewController?
    private weak var carouselViewController:CarouselViewController?
    private weak var vcDelegate:CarouselViewControllerDelegate?
    
    init(page: Int, count: Int, viewController: UIViewController, carouselViewController:CarouselViewController?, vcDelegate:CarouselViewControllerDelegate?) {
        super.init(page: page, count: count, view: viewController.view)
        
        self.viewController = viewController
        self.carouselViewController = carouselViewController
        self.vcDelegate = vcDelegate
    }
    
    private override func willUninstall() {
        if let carousel = carouselViewController {
            viewController?.willMoveToParentViewController(nil)
            vcDelegate?.carousel?(carousel, willUninstallPage: validPage)
        }
    }
    
    private override func didUninstall() {
        if let carousel = carouselViewController {
            viewController?.removeFromParentViewController()
            vcDelegate?.carousel?(carousel, didUninstallPage: validPage)
        }
    }
    
    private override func willInstall() {
        if let carousel = carouselViewController {
            if let vc = viewController {
                carousel.addChildViewController(vc)
            }
            vcDelegate?.carousel?(carousel, willInstallPage: validPage)
        }
    }
    
    private override func didInstall() {
        if let carousel = carouselViewController {
            viewController?.didMoveToParentViewController(carousel)
            vcDelegate?.carousel?(carousel, didInstallPage: validPage)
        }
    }
}

private class CarouselViewInViewController:CarouselView {
    weak var carouselViewController:CarouselViewController?
    weak var vcDataSource:CarouselViewControllerDataSourse?
    weak var vcDelegate:CarouselViewControllerDelegate?
    
    override func numberOfView() -> Int? {
        guard let vc = carouselViewController else {
            return nil
        }
        return vcDataSource?.numberOfViewController(vc)
    }
    
    override func fetchPage(validPage: Int, count: Int, page: Int) -> CarouselPage {
        var tvc:UIViewController!
        if let vc = carouselViewController, vc2 = vcDataSource?.carousel(vc, viewControllerForIndex: validPage) {
            tvc = vc2
        } else {
            tvc = UIViewController()
        }
        return CarouselPageInViewController.init(page: page, count: count, viewController: tvc, carouselViewController: carouselViewController, vcDelegate: vcDelegate)
    }
    
    private override func carouselScrollFrom(from:Int, to:Int, progress:CGFloat) {
        guard let vc = carouselViewController else {
            return
        }
        vcDelegate?.carousel?(vc, scrollFrom: from, to: to, progress: progress)
    }
    
    private override func carouselDidScrollFrom(from:Int, to:Int) {
        guard let vc = carouselViewController else {
            return
        }
        vcDelegate?.carousel?(vc, didScrollFrom: from, to: to)
    }
}


public class CarouselViewController: UIViewController {
    /// visible page count
    public var visiblePageCount:Int = 1 {
        didSet {
            _carouselView.visiblePageCount = visiblePageCount
        }
    }
    /// buffer page count(page create but not visible)
    public var bufferPageCount:Int = 1 {        // one side
        didSet {
            _carouselView.bufferPageCount = bufferPageCount
        }
    }
    
    /// data source of page viewcontrollers
    public weak var dataSource:CarouselViewControllerDataSourse? {
        didSet {
            if dataSource !== oldValue {
                _carouselView.vcDataSource = dataSource
            }
        }
    }
    
    /// scroll delegate
    public weak var delegate:CarouselViewControllerDelegate? {
        didSet {
            if delegate !== oldValue {
                _carouselView.vcDelegate = delegate
            }
        }
    }
    
    /// reuse page size number, if negative will cache all pages( high memory usage)
    public var cacheSize:Int = 0 {
        didSet {
            _carouselView.cacheSize = cacheSize
        }
    }
    /// layout direction
    public var direction = CarouselDirection.Horizontal {
        didSet {
            _carouselView.direction = direction
        }
    }
    /// page layout in Loop or Linear
    public var type = CarouselType.Linear {
        didSet {
            _carouselView.type = type
        }
    }
    /// support paging
    public var pagingRequired = true {
        didSet {
            _carouselView.pagingRequired = pagingRequired
        }
    }
    
    /// if true viewWillAppear will resume auto scroll, viewDidDisappear will pause auto scroll
    public var autoScrolOnlyViewAppeared = true
    
    private var _carouselView: CarouselViewInViewController {
        return view as! CarouselViewInViewController
    }
    
    public var carouselView: CarouselView {
        return view as! CarouselView
    }
    
    override public func loadView() {
        let carouselView = CarouselViewInViewController.init(frame: UIScreen.mainScreen().bounds)
        carouselView.vcDataSource = dataSource
        carouselView.vcDelegate = delegate
        carouselView.carouselViewController = self
        view = carouselView
    }
}

// usefull extension
public extension CarouselViewController {
    public var visiblePages:[CarouselPage] {
        return _carouselView.visiblePages
    }
    
    public var firstVisiblePage:CarouselPage? {
        return _carouselView.firstVisiblePage
    }
    
    public var lastVisiblePage:CarouselPage? {
        return _carouselView.lastVisiblePage
    }
    
    public var firstVisiblePageIndex:CGFloat {
        return _carouselView.firstVisiblePageIndex
    }
    
    public func scrollToPage(page:Int, animated:Bool = false) {
        return _carouselView.scrollToPage(page, animated: animated)
    }
    
    public func nextPage(animated:Bool = false) {
        _carouselView.nextPage(animated)
    }
    
    public func prePage(animated:Bool = false) {
        _carouselView.prePage(animated)
    }
}

// support auto scoll
public extension CarouselViewController {
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if autoScrolOnlyViewAppeared {
            carouselView.resumeAutoScroll()
        }
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if autoScrolOnlyViewAppeared {
            carouselView.pauseAutoScroll()
        }
    }
    
    /**
     auto scroll
     default auto scroll is disable
     - parameter timeInterval: scroll time interval
     - parameter increase:     page increase or decrease
     */
    public func autoScroll(timeInterval:NSTimeInterval, increase:Bool) {
        _carouselView.autoScroll(timeInterval, increase: increase)
    }
    
    /**
     stop auto scroll
     */
    public func stopAutoScroll() {
        _carouselView.stopAutoScroll()
    }
    /**
     pause auto scroll
     */
    public func pauseAutoScroll() {
        _carouselView.pauseAutoScroll()
    }
    /**
     resume auto scroll
     if your never call autoScroll(_:increase), auto scroll will not work
     */
    public func resumeAutoScroll() {
        _carouselView.resumeAutoScroll()
    }
}

// add reload relative method
public extension CarouselViewController {
    public func reload() {
        _carouselView.reload()
    }
    
    public func reload(page page:Int) {
        _carouselView.reload(page: page)
    }
    
    public func reload(pages pages:[Int]) {
        _carouselView.reload(pages: pages)
    }
    
    public func reloadVisiblePages() {
        _carouselView.reloadVisiblePages()
    }
}
