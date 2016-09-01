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
     - parameter index:    cell index for view
     
     - returns: view at cell index
     */
    func carousel(carousel:CarouselView, viewForIndex index:Int) -> UIView?
}

@objc public protocol CarouselViewDelegate:class {
    /**
     cell will add to carousel
     
     - parameter carousel: instance of CarouselView
     - parameter cell:     cell index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, willInstallCell cell:Int)
    /**
     cell will remove from carousel
     
     - parameter carousel: instance of CarouselView
     - parameter cell:     cell index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, willUninstallCell cell:Int)
    /**
     cell did add to carousel
     
     - parameter carousel: instance of CarouselView
     - parameter cell:     cell index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, didInstallCell cell:Int)
    /**
     cell did remove from carousel
     
     - parameter carousel: instance of CarouselView
     - parameter cell:     cell index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, didUninstallCell cell:Int)
    
    

    // MARK: scroll relate delegate
    /**
     cell scroll progress
     
     - parameter carousel: instance of CarouselView
     - parameter from:     from cell(first visiable cell)
     - parameter to:       to cell
     - parameter progress: progess for scroll: progress > 0, cell grow direction, < 0 cell decrease diretion
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, scrollFrom from:Int, to:Int, progress:CGFloat)
    /**
     cell did scroll from cell to cell
     
     - parameter carousel: instance of CarouselView
     - parameter from:     from cell(first visiable cell)
     - parameter to:       to cell
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselView, didScrollFrom from:Int, to:Int)
    

    optional func carouselDidScroll(carousel:CarouselView)
    optional func carouselWillBeginDragging(carousel:CarouselView)
    optional func carouselDidEndDragging(carousel:CarouselView, willDecelerate decelerate: Bool)
    
    optional func carouselWillBeginDecelerating(carousel:CarouselView)
    optional func carouselDidEndDecelerating(carousel:CarouselView)
    
    optional func carouselDidEndScrollingAnimation(carousel:CarouselView)
}

private func formatedInex(index:Int, ofCount count:Int) -> Int {
    var i = index
    while i < 0 {
        i += 100 * count
    }
    return count > 0 ? i % count : 0
}

private func formatedInex(index:CGFloat, ofCount count:CGFloat) -> CGFloat {
    var i = index
    while i < 0 {
        i += 100 * count
    }
    return count > 0 ? i % count : 0
}

public class CarouselCell {
    private var rawIndex:Int = 0
    private(set) var count:Int = 0
    private(set) var view = UIView()
    
    private init(rawIndex:Int) {
        self.rawIndex = rawIndex
    }
    
    init(rawIndex:Int, count:Int, view:UIView) {
        self.rawIndex = rawIndex
        self.count = count
        self.view = view
    }
    
    deinit {
        view.removeFromSuperview()
    }
    
    public var index:Int {
        return formatedInex(rawIndex, ofCount: count)
    }
    
    func reuse(rawIndex:Int) -> CarouselCell {
        self.rawIndex = rawIndex
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
     install cell to view with frame
     
     - parameter toView: the view container
     - parameter frame:  frame in container
     
     - returns: true if cell has not add before, false cell has added
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

private class CarouselCellView: CarouselCell {
    private weak var carouselView: CarouselView?
    private weak var delegate:CarouselViewDelegate?
    
    init(rawIndex:Int, count:Int, view:UIView, carousel: CarouselView, delegate:CarouselViewDelegate?) {
        super.init(rawIndex: rawIndex, count:count, view: view)
        self.carouselView = carousel
        self.delegate = delegate
    }
    
    override func willUninstall() {
        if let carousel = carouselView {
            delegate?.carousel?(carousel, didUninstallCell: index)
        }
    }
    
    override func didUninstall() {
        if let carousel = carouselView {
            delegate?.carousel?(carousel, willUninstallCell: index)
        }
    }
    
    override func willInstall() {
        if let carousel = carouselView {
            delegate?.carousel?(carousel, willInstallCell: index)
        }
    }
    
    override func didInstall() {
        if let carousel = carouselView {
            delegate?.carousel?(carousel, didInstallCell: index)
        }
    }
}

extension CarouselCell {
    var cacheKey: String {
        return "\(index)_\(count)"
    }
}

class CarouselPageCache {
    private var maxSize = 0
    private var cellCount = 0
    private var cachedCells = [String: (Int, CarouselCell)]()
    
    private var queueIndex:Int = 0

    /**
     cache cell
     
     - parameter cell:            cell to cache
     - parameter uninstall:       if true uninstall cell
     - parameter ignoreSizeLimit: if true ignore size limit, you should call limitToCacheSize manually
     */
    func push(cell:CarouselCell, uninstall:Bool = true, ignoreSizeLimit:Bool = false) {
        if uninstall {
            cell.uninstall()
        }
        
        if cachedCells.isEmpty {
            cellCount = cell.count
        } else if cellCount != cell.count {
            cachedCells = [:]
            cellCount = cell.count
        }
        queueIndex += 1
        cachedCells[cell.cacheKey] = (queueIndex, cell)
        
        if !ignoreSizeLimit {
            limitToCacheSize()
        }
    }
    
    func cacheCell(cell:Int, count:Int, removeFromCache:Bool = true) -> CarouselCell? {
        guard count > 0 else {
            return nil
        }
        let cacheKey = "\(cell)_\(count)"
        let cached = cachedCells[cacheKey]
        if removeFromCache {
            cachedCells.removeValueForKey(cacheKey)
        }
        return cached?.1
    }
    
    func clear() {
        cachedCells = [:]
    }
    
    func limitToCacheSize() {
        if 0 < maxSize && maxSize < cachedCells.count {
            let sorted = cachedCells.sort({ $0.1.0 > $1.1.0 })
            var remainedCells = [String: (Int, CarouselCell)]()
            for p in sorted[0..<maxSize] {
                remainedCells[p.0] = p.1
            }
            for p in sorted[maxSize..<sorted.count] {
                p.1.1.uninstall()
            }
            cachedCells = remainedCells
        } else if maxSize == 0 {
            for p in cachedCells {
                p.1.1.uninstall()
            }
            cachedCells = [:]
        }
    }
    
    deinit {
        cachedCells = [:]
    }
}

public enum CarouselDirection {
    case Horizontal, Vertical
}

public enum CarouselType {
    case Linear, Loop
}

public enum CarouselPagingType {
    case None   // not paging
    case Cell   // paging by cell
    case Page   // paging by page
}

public extension CarouselView {
    /// cell witdh: greater than 1
    public var cellWidth:CGFloat {
        return _cellSize.width
    }
    /// cell heigt: greater than 1
    public var cellHeight:CGFloat {
        return _cellSize.height
    }
}

public class CarouselView: UIScrollView {
    private var baseInited = false
    /// visible cell count
    public var cellPerPage:Int = 1 {
        didSet {
            guard cellPerPage > 0 else {
                cellPerPage = 1
                return
            }
            updatePagingEnabled()
            if cellPerPage != oldValue {
                setNeedsLayout()
            }
        }
    }
    /// buffer cell count(cell create but not visible)
    public var buffeCellCount:Int = 1 {        // one side
        didSet {
            if buffeCellCount < 0 {
                buffeCellCount = 0
            } else {
                updateVisibleCell()
            }
        }
    }

    /// page used for loop: extral page it takes
    private var _loopPage:Int = 2
    private var threshold:CGFloat = 1
    /// cells in view
    private var _cells = [CarouselCell]()
    /// cells can be reusable
    private var _reusableCells = CarouselPageCache()
    
    private var _cellSize:CGSize = CGSize(width: 1, height: 1)
    
    private var _preSize:CGSize = CGSizeZero
    private var _preFirstCellIndex:Int = 0
    private var _preContentOffset = CGPointZero
    private var _delegateWrapper = CarouselScrollViewDelegateWrapper()
    
    /// cached cell size: default is zero, if is negative will cache all
    private var reusableCellSize:Int {
        let minSize = cellPerPage + 2 * buffeCellCount
        return cacheSize > minSize ? cacheSize - minSize : cacheSize
    }
    /// reuse cell size number, if negative will cache all cells( high memory usage)
    public var cacheSize:Int = 0 {
        didSet {
            _reusableCells.maxSize = reusableCellSize
        }
    }
    /// layout direction
    public var direction = CarouselDirection.Horizontal {
        didSet {
            if direction != oldValue {
                setNeedsLayout()
            }
        }
    }
    /// cell layout in Loop or Linear
    public var type = CarouselType.Linear
    /// support paging
    public var pagingRequired = true {
        didSet {
            updatePagingEnabled()
        }
    }
    /// if true ignore pagingEnabled and use pagingRequired instead, default is true
    public var ignorePagingEnabled = true
    /// data source of cell views
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
        _reusableCells.clear()
        _cells = []
    }
    
    private func baseInit() {
        guard !baseInited else {
            return
        }
        baseInited = true
        
        contentSize = frame.size
        updateCellSize()
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        pagingEnabled = false
        delegate = _delegateWrapper
        _reusableCells.maxSize = reusableCellSize

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
        
        if cellPerPage > 1 {
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
    
    private func cellSizeEqualToSize(size1: CGSize, _ size2: CGSize) -> Bool {
        return abs(size1.width - size2.width) < 0.001 && abs(size1.height - size2.height) < 0.001
    }
    /**
     update cell size
     
     - returns: true size change, false not
     */
    private final func updateCellSize() -> Bool {
        let width = max(direction == .Horizontal ? frame.width / CGFloat(cellPerPage) : frame.width, threshold)
        let height = max(direction == .Vertical ? frame.height / CGFloat(cellPerPage) : frame.height, threshold)
        let cellSize = CGSize(width: width, height: height)
        if !cellSizeEqualToSize(_cellSize, cellSize) {
            _cellSize = cellSize
            return true
        }
        return false
    }
    
    private func resetCells() {
        switch type {
        case .Linear:
            resetCellsLinear()
        case .Loop:
            resetCellsLoop()
        }
    }
    
    private func fetchCell(index: Int, count:Int, rawIndex:Int) -> CarouselCell {
        let view = dataSource?.carousel(self, viewForIndex: index) ?? UIView()
        return CarouselCellView.init(rawIndex: rawIndex, count: count, view: view, carousel:self, delegate: carouselDelegate)
    }
    
    @inline(__always) func numberOfView() -> Int? {
        return dataSource?.numberOfView(self)
    }
    
    /**
     update current cell frame in _cells
     */
    final public func updateCurrentCellsLayout() {
        guard let pre = _cells.first where !cellSizeEqualToSize(_cellSize, pre.view.frame.size) else {
            return
        }
        switch type {
        case .Linear:
            for cell in _cells {
                cell.view.frame = frameLinear(cell.rawIndex)
            }
        case .Loop:
            for cell in _cells {
                cell.view.frame = frameLoop(cell.rawIndex)
            }
        }
    }
    
    /**
     update visible cell (add or remove cell if needed)
     */
    private func updateVisibleCell() {
        // update current cells layout
        updateCurrentCellsLayout()
        
        // update visible cell
        switch type {
        case .Linear:
            updateVisibleCellLinear()
        case .Loop:
            updateVisibleCellLoop()
        }
        _reusableCells.limitToCacheSize()
    }
    /**
     reload latest data source and update views
     */
    public func reload() {
        resetCells()
        updateVisibleCell()
        
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
        // update cell size
        var shouldAdjustCell = updateCellSize()
        // update content size
        updateContentSize()
        // update cell should display
        updateVisibleCell()
        // update pre size
        if !cellSizeEqualToSize(_preSize, frame.size) {
            _preSize = frame.size
            shouldAdjustCell = true
        }
        
        if shouldAdjustCell {
            scrollToIndex(0)
        }
    }
    
    private func carouselScrollFrom(from:Int, to:Int, progress:CGFloat) {
        carouselDelegate?.carousel?(self, scrollFrom: from, to: to, progress: progress)
    }
    
    private func carouselDidScrollFrom(from:Int, to:Int) {
        carouselDelegate?.carousel?(self, didScrollFrom: from, to: to)
    }
}

// 线性 cell
extension CarouselView {
    private func updateScrollProgressLinear() {
        if let first = firstVisibleCell where first.rawIndex < first.count {
            let index = first.index
            if index != _preFirstCellIndex {
                carouselDidScrollFrom(_preFirstCellIndex, to: index)
                _preFirstCellIndex = index
            } else {
                switch direction {
                case .Horizontal:
                    let cellIncrease = _preContentOffset.x < contentOffset.x
                    let next = cellIncrease ? first.rawIndex + 1 : first.rawIndex - 1
                    if next > 0 && next < first.count {
                        var progress = contentOffset.x / cellWidth
                        progress = cellIncrease ? progress - floor(progress) : progress - ceil(progress)
                        carouselScrollFrom(_preFirstCellIndex, to: next, progress: progress)
                    }
                case .Vertical:
                    let cellIncrease = _preContentOffset.y < contentOffset.y
                    let next = cellIncrease ? first.rawIndex + 1 : first.rawIndex - 1
                    if next > 0 && next < first.count {
                        var progress = contentOffset.y / cellHeight
                        progress = cellIncrease ? progress - floor(progress) : progress - ceil(progress)
                        carouselScrollFrom(_preFirstCellIndex, to: next, progress: progress)
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
                targetSize = CGSizeMake(CGFloat(count) * cellWidth, frame.height)
            } else {
                targetSize = CGSizeMake(cellWidth, CGFloat(count) * cellHeight)
            }
        }
        if !CGSizeEqualToSize(targetSize, contentSize) {
            contentSize = targetSize
        }
    }
    
    private func resetCellsLinear() {
        let pre = _cells
        _cells = []
        for cell in pre {
            cell.uninstall()
        }
        _reusableCells.clear()
    }
    
    private func frameLinear(rawIndex:Int) -> CGRect {
        switch direction {
        case .Horizontal:
            return CGRectMake(CGFloat(rawIndex) * cellWidth, 0, cellWidth, cellHeight)
        case .Vertical:
            return CGRectMake(0, CGFloat(rawIndex) * cellHeight, cellWidth, cellHeight)
        }
    }
    
    private func setupCellLinear(rawIndex:Int, count:Int, tail:Bool = true) -> CarouselCell {
        let cell = _reusableCells.cacheCell(rawIndex, count: count, removeFromCache: true)?.reuse(rawIndex) ?? fetchCell(rawIndex, count: count, rawIndex: rawIndex)
        if tail {
            _cells.append(cell)
        } else {
            _cells.insert(cell, atIndex: 0)
        }
        
        cell.install(self, frame: frameLinear(rawIndex))
        return cell
    }
    
    private func updateVisibleCellLinear() {
        guard let count = numberOfView() where count > 0 else {
            resetCellsLinear()
            return
        }
        
        if direction == .Horizontal {
            let minX = max(ceil(contentOffset.x / cellWidth - CGFloat(buffeCellCount)) * cellWidth, 0)
            let maxX = minX + CGFloat(cellPerPage + buffeCellCount * 2) * cellWidth
            
            // right：remove cell
            while let cell = _cells.last where cell.view.frame.minX + threshold > maxX {
                _reusableCells.push(_cells.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // left：remove cell
            while let cell = _cells.first where cell.view.frame.maxX - threshold < minX {
                _reusableCells.push(_cells.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if _cells.isEmpty {
                setupCellLinear(Int(contentOffset.x / cellWidth), count: count)
            }
            // right：add cell
            while let cell = _cells.last where cell.rawIndex < count - 1 && cell.view.frame.maxX + threshold < maxX {
                setupCellLinear(cell.rawIndex + 1, count: count, tail: true)
            }
            // left：add cell
            while let cell = _cells.first where cell.rawIndex > 0 && cell.view.frame.minX - threshold > minX {
                setupCellLinear(cell.rawIndex - 1, count: count, tail: false)
            }
        } else {
            let minY = max(ceil(contentOffset.y / cellHeight - CGFloat(buffeCellCount)) * cellHeight, 0)
            let maxY = minY + CGFloat(cellPerPage + buffeCellCount * 2) * cellHeight
            
            // tail：remove cell
            while let cell = _cells.last where cell.view.frame.minY + threshold > maxY {
                _reusableCells.push(_cells.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // top：remove cell
            while let cell = _cells.first where cell.view.frame.maxY - threshold < minY {
                _reusableCells.push(_cells.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if _cells.isEmpty {
                setupCellLinear(Int(contentOffset.y / cellHeight), count: count)
            }
            // tail：add cell
            while let cell = _cells.last where cell.rawIndex < count - 1 && cell.view.frame.maxY + threshold < maxY {
                setupCellLinear(cell.rawIndex + 1, count: count, tail: true)
            }
            // top：add cell
            while let cell = _cells.first where cell.rawIndex > 0 && cell.view.frame.minY - threshold > minY {
                setupCellLinear(cell.rawIndex - 1, count: count, tail: false)
            }
        }
    }
}

// loop cell
extension CarouselView {
    // cell zero offset
    private var _offsetCellIndex:Int {
        return cellPerPage * _loopPage
    }
    
    private func updateScrollProgressLoop() {
        if let first = firstVisibleCell {
            let index = first.index
            if index != _preFirstCellIndex {
                carouselDidScrollFrom(_preFirstCellIndex, to: index)
                _preFirstCellIndex = index
            } else {
                switch direction {
                case .Horizontal:
                    let cellIncrease = _preContentOffset.x < contentOffset.x
                    let next = formatedInex(cellIncrease ? first.rawIndex + 1 : first.rawIndex - 1, ofCount: first.count)
                    var progress = contentOffset.x / cellWidth
                    progress = cellIncrease ? progress - floor(progress) : progress - ceil(progress)
                    carouselScrollFrom(_preFirstCellIndex, to: next, progress: progress)
                case .Vertical:
                    let cellIncrease = _preContentOffset.y < contentOffset.y
                    let next = formatedInex(cellIncrease ? first.rawIndex + 1 : first.rawIndex - 1, ofCount: first.count)
                    var progress = contentOffset.y / cellHeight
                    progress = cellIncrease ? progress - floor(progress) : progress - ceil(progress)
                    carouselScrollFrom(_preFirstCellIndex, to: next, progress: progress)
                }
            }
            _preContentOffset = contentOffset
        }
    }
    
    private func updateContentOffsetLoop() {
        _delegateWrapper.ignoreScrollEvent = false
        guard let count = numberOfView() where count > cellPerPage else {
            return
        }
        
        switch direction {
        case .Horizontal:
            let bufferWidth = cellWidth * CGFloat(_offsetCellIndex)
            let totalCellWidth = cellWidth * CGFloat(count)
            let minX = bufferWidth
            let maxX = totalCellWidth + bufferWidth
            if contentOffset.x > maxX {
                _delegateWrapper.ignoreScrollEvent = true
                contentOffset.x -= totalCellWidth
                updateVisibleCellLoop()
            } else if contentOffset.x < minX {
                _delegateWrapper.ignoreScrollEvent = true
                contentOffset.x += totalCellWidth
                updateVisibleCellLoop()
            }
        case .Vertical:
            let bufferHeight = cellHeight * CGFloat(_offsetCellIndex)
            let totalCellHeight = cellHeight * CGFloat(count)
            let minY = bufferHeight
            let maxY = totalCellHeight + bufferHeight
            if contentOffset.y > maxY {
                _delegateWrapper.ignoreScrollEvent = true
                contentOffset.y -= bufferHeight
                updateVisibleCellLoop()
            } else if contentOffset.y < minY {
                _delegateWrapper.ignoreScrollEvent = true
                contentOffset.y += bufferHeight
                updateVisibleCellLoop()
            }
        }
    }
    
    private func updateContentSizeLoop() {
        var targetSize = frame.size
        if let count = numberOfView() where count > cellPerPage {
            let targetCount = count + 2 * _offsetCellIndex
            if direction == .Horizontal {
                targetSize = CGSizeMake(CGFloat(targetCount) * cellWidth, frame.height)
            } else {
                targetSize = CGSizeMake(cellWidth, CGFloat(targetCount) * cellHeight)
            }
        }
        if !CGSizeEqualToSize(targetSize, contentSize) {
            contentSize = targetSize
        }
        
    }
    
    private func resetCellsLoop() {
        let pre = _cells
        _cells = []
        for page in pre {
            page.uninstall()
        }
        _reusableCells.clear()
    }
    
    private func frameLoop(rawIndex:Int) -> CGRect {
        switch direction {
        case .Horizontal:
            return CGRectMake(CGFloat(rawIndex + _offsetCellIndex) * cellWidth, 0, cellWidth, cellHeight)
        case .Vertical:
            return CGRectMake(0, CGFloat(rawIndex + _offsetCellIndex) * cellHeight, cellWidth, cellHeight)
        }
    }
    
    private func setupCellLoop(rawIndex:Int, count:Int, tail:Bool) -> CarouselCell {
        let index = formatedInex(rawIndex, ofCount: count)
        let cell = _reusableCells.cacheCell(index, count: count, removeFromCache: true)?.reuse(rawIndex) ?? fetchCell(index, count: count, rawIndex: rawIndex)
        if tail {
            _cells.append(cell)
        } else {
            _cells.insert(cell, atIndex: 0)
        }
        
        cell.install(self, frame: frameLoop(rawIndex))
        return cell
    }
    
    private func updateVisibleCellLoop() {
        guard let count = numberOfView() where count > 0 else {
            resetCellsLoop()
            return
        }
        
        if direction == .Horizontal {
            let bufferCellWidth = min(CGFloat(cellPerPage + buffeCellCount * 2), CGFloat(count)) * cellWidth
            let maxX = floor((contentOffset.x + bufferCellWidth) / cellWidth) * cellWidth
            let minX = maxX - bufferCellWidth
            
            // right：remove cell
            while let cell = _cells.last where cell.view.frame.minX + threshold > maxX {
                _reusableCells.push(_cells.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // left：remove cell
            while let cell = _cells.first where cell.view.frame.maxX - threshold < minX {
                _reusableCells.push(_cells.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if _cells.isEmpty {
                setupCellLoop(Int(contentOffset.x / cellWidth) - _offsetCellIndex, count: count, tail: true)
            }
            // right：add cell
            while let cell = _cells.last where cell.view.frame.maxX + threshold < maxX {
                setupCellLoop(cell.rawIndex + 1, count: count, tail: true)
            }
            // left：add cell
            while let cell = _cells.first where cell.view.frame.minX - threshold > minX {
                setupCellLoop(cell.rawIndex - 1, count: count, tail: false)
            }
        } else {
            let bufferCellHeight = min(CGFloat(cellPerPage + buffeCellCount * 2), CGFloat(count)) * cellHeight
            let maxY = floor((contentOffset.y + bufferCellHeight) / cellHeight) * cellHeight
            let minY = maxY - bufferCellHeight
            
            // tail：remove cell
            while let cell = _cells.last where cell.view.frame.minY + threshold > maxY {
                _reusableCells.push(_cells.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // top：remove cell
            while let cell = _cells.first where cell.view.frame.maxY - threshold < minY {
                _reusableCells.push(_cells.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if _cells.isEmpty {
                setupCellLoop(Int(contentOffset.y / cellHeight) - _offsetCellIndex, count: count, tail: true)
            }
            // tail：add cell
            while let cell = _cells.last where cell.view.frame.maxY + threshold < maxY {
                setupCellLoop(cell.rawIndex + 1, count: count, tail: true)
            }
            // top：add cell
            while let cell = _cells.first where cell.view.frame.minY - threshold > minY {
                setupCellLoop(cell.rawIndex - 1, count: count, tail: false)
            }
        }
    }
}

// support page enable and adjust content offset
extension CarouselView: UIScrollViewDelegate {
    // this deleate handle paging
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard pagingRequired else {
            return
        }
        switch direction {
        case .Horizontal:
            var targetX = round(targetContentOffset.memory.x / cellWidth) * cellWidth
            targetX = max(min(targetX, contentSize.width), 0)
            targetContentOffset.memory.x = targetX
        case .Vertical:
            var targetY = round(targetContentOffset.memory.y / cellHeight) * cellHeight
            targetY = max(min(targetY, contentSize.height), 0)
            targetContentOffset.memory.y = targetY
        }
    }
    // handle did scroll
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        // update scroll progess
        updateScrollProgress()
        // update content offset(to restrict position) if needed
        updateContentOffset()
        
        carouselDelegate?.carouselDidScroll?(self)
    }
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        carouselDelegate?.carouselWillBeginDragging?(self)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // update content offset(to restrict position) if needed
        updateContentOffset()
        
        carouselDelegate?.carouselDidEndDecelerating?(self)
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        // update content offset(to restrict position) if needed
        updateContentOffset()
        
        carouselDelegate?.carouselDidEndScrollingAnimation?(self)
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        pauseAutoScroll()
        
        carouselDelegate?.carouselWillBeginDragging?(self)
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        resumeAutoScroll()
        
        carouselDelegate?.carouselDidEndDragging?(self, willDecelerate: decelerate)
    }
}

// usefull extension
extension CarouselView {
    public var visibleCells:[CarouselCell] {
        var result = [CarouselCell]()
        switch direction {
        case .Horizontal:
            let minX = contentOffset.x
            let maxX = contentOffset.x + frame.width
            for c in _cells {
                if c.view.frame.minX > minX - threshold && c.view.frame.maxX < maxX + threshold {
                    result.append(c)
                }
            }
        case .Vertical:
            let minY = contentOffset.y
            let maxY = contentOffset.y + frame.height
            for c in _cells {
                if c.view.frame.minY > minY - threshold && c.view.frame.maxY < maxY + threshold {
                    result.append(c)
                }
            }
        }
        return result
    }
    
    public var firstVisibleCell:CarouselCell? {
        var cell = _cells.first
        switch direction {
        case .Horizontal:
            for c in _cells {
                if c.view.frame.maxX - threshold > contentOffset.x {
                    cell = c
                    break
                }
            }
        case .Vertical:
            for c in _cells {
                if c.view.frame.maxY - threshold > contentOffset.y {
                    cell = c
                    break
                }
            }
        }
        return cell
    }
    
    public var lastVisibleIndex:CarouselCell? {
        var cell = _cells.last
        switch direction {
        case .Horizontal:
            for c in _cells {
                if c.view.frame.maxX + threshold > contentOffset.x + frame.width {
                    cell = c
                    break
                }
            }
        case .Vertical:
            for c in _cells {
                if c.view.frame.maxY + threshold > contentOffset.y + frame.height {
                    cell = c
                    break
                }
            }
        }
        return cell
    }
    
    public var firstVisibleCellIndex:CGFloat {
        guard let count = _cells.first?.count where count > 0 else {
            return 0
        }
        switch direction {
        case .Horizontal:
            return formatedInex(contentOffset.x / cellWidth, ofCount: CGFloat(count))
        case .Vertical:
            return formatedInex(contentOffset.y / cellHeight, ofCount: CGFloat(count))
        }
    }
    
    public func scrollToIndex(index:Int, animated:Bool = false) {
        switch type {
        case .Linear:
            var offset = frameLinear(index).origin
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
                setContentOffset(frameLoop(index).origin, animated: animated)
            }
        }
        updateVisibleCell()
    }
    
    public func nextCell(animated:Bool = false) {
        guard let first = firstVisibleCell else {
            return
        }
        scrollToIndex(first.rawIndex + 1, animated: animated)
    }
    
    public func preNext(animated:Bool = false) {
        guard let first = firstVisibleCell else {
            return
        }
        scrollToIndex(first.rawIndex - 1, animated: animated)
    }
}

// support auto scoll
public extension CarouselView {
    func autoScrollToNext() {
        nextCell(true)
    }
    
    func autoScrollToPre() {
        preNext(true)
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
    @inline(__always) private func reload(index:Int, withCount count: Int) {
        switch type {
        case .Linear:
            if index >= 0 && index < count {
                let p = fetchCell(index, count: count, rawIndex: index)
                if let _ = _reusableCells.cacheCell(index, count: count, removeFromCache: false) {
                    _reusableCells.push(p, uninstall: true, ignoreSizeLimit: true)
                } else {
                    for vp in visibleCells {
                        if vp.rawIndex == p.rawIndex {
                            vp.reuse(p.view)
                            break
                        }
                    }
                }
            }
        case .Loop:
            let findex = formatedInex(index, ofCount: count)
            let p = fetchCell(findex, count: count, rawIndex: index)
            if let _ = _reusableCells.cacheCell(index, count: count, removeFromCache: false) {
                _reusableCells.push(p, uninstall: true, ignoreSizeLimit: true)
            } else {
                for vp in visibleCells {
                    if vp.index == p.index {
                        vp.reuse(p.view)
                        break
                    }
                }
            }
        }
    }
    
    public func reload(index index:Int) {
        guard let count = numberOfView() where count > 0 else {
            reload()
            return
        }
        guard let preCount = visibleCells.first?.count where preCount != count else {
            reload()
            return
        }
        
        reload(index, withCount: count)
    }
    
    public func reload(indexs indexs:[Int]) {
        guard let count = numberOfView() where count > 0 else {
            reload()
            return
        }
        
        guard let preCount = visibleCells.first?.count where preCount != count else {
            reload()
            return
        }
        
        for index in Array(Set(indexs)) {
            reload(index, withCount: count)
        }
    }
    
    public func reloadvisibleCells() {
        guard let count = numberOfView() where count > 0 else {
            reload()
            return
        }
        
        guard let preCount = visibleCells.first?.count where preCount != count else {
            reload()
            return
        }
        
        for vp in visibleCells {
            vp.reuse(fetchCell(vp.index, count: vp.count, rawIndex: vp.rawIndex).view)
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
     - parameter index:    cell index
     
     - returns: view controller at cell index
     */
    func carousel(carousel:CarouselViewController, viewControllerForIndex index:Int) -> UIViewController?
}

@objc public protocol CarouselViewControllerDelegate:class {
    /**
     page will add to carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter cell:     cell index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, willInstallCell cell:Int)
    /**
     page will remove from carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter cell:     cell index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, willUninstallCell cell:Int)
    /**
     page did add to carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter cell:     cell index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, didInstallCell cell:Int)
    /**
     page did remove from carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter cell:     cell index
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, didUninstallCell cell:Int)
    
    
    // MARK: scroll relate delegate
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
     - parameter to:       to cell
     
     - returns: Void
     */
    optional func carousel(carousel:CarouselViewController, didScrollFrom from:Int, to:Int)
    
    optional func carouselDidScroll(carousel:CarouselViewController)
    optional func carouselWillBeginDragging(carousel:CarouselViewController)
    optional func carouselDidEndDragging(carousel:CarouselViewController, willDecelerate decelerate: Bool)
    
    optional func carouselWillBeginDecelerating(carousel:CarouselViewController)
    optional func carouselDidEndDecelerating(carousel:CarouselViewController)
    
    optional func carouselDidEndScrollingAnimation(carousel:CarouselViewController)
}

private class CarouselCellViewController:CarouselCell {
    private weak var viewController:UIViewController?
    private weak var carouselViewController:CarouselViewController?
    private weak var vcDelegate:CarouselViewControllerDelegate?
    
    init(rawIndex: Int, count: Int, viewController: UIViewController, carouselViewController:CarouselViewController?, vcDelegate:CarouselViewControllerDelegate?) {
        super.init(rawIndex: rawIndex, count: count, view: viewController.view)
        
        self.viewController = viewController
        self.carouselViewController = carouselViewController
        self.vcDelegate = vcDelegate
    }
    
    private override func willUninstall() {
        if let carousel = carouselViewController {
            viewController?.willMoveToParentViewController(nil)
            vcDelegate?.carousel?(carousel, willUninstallCell: index)
        }
    }
    
    private override func didUninstall() {
        if let carousel = carouselViewController {
            viewController?.removeFromParentViewController()
            vcDelegate?.carousel?(carousel, didUninstallCell: index)
        }
    }
    
    private override func willInstall() {
        if let carousel = carouselViewController {
            if let vc = viewController {
                carousel.addChildViewController(vc)
            }
            vcDelegate?.carousel?(carousel, willInstallCell: index)
        }
    }
    
    private override func didInstall() {
        if let carousel = carouselViewController {
            viewController?.didMoveToParentViewController(carousel)
            vcDelegate?.carousel?(carousel, didInstallCell: index)
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
    
    override func fetchCell(index: Int, count: Int, rawIndex: Int) -> CarouselCell {
        var tvc:UIViewController!
        if let vc = carouselViewController, vc2 = vcDataSource?.carousel(vc, viewControllerForIndex: index) {
            tvc = vc2
        } else {
            tvc = UIViewController()
        }
        return CarouselCellViewController.init(rawIndex: rawIndex, count: count, viewController: tvc, carouselViewController: carouselViewController, vcDelegate: vcDelegate)
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
    
    
    // handle did scroll
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard let vc = carouselViewController else {
            return
        }
        vcDelegate?.carouselDidScroll?(vc)
    }
    
    override func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        super.scrollViewWillBeginDecelerating(scrollView)
        guard let vc = carouselViewController else {
            return
        }
        vcDelegate?.carouselWillBeginDecelerating?(vc)
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView)
        guard let vc = carouselViewController else {
            return
        }
        vcDelegate?.carouselDidEndDecelerating?(vc)
    }
    
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView)
        guard let vc = carouselViewController else {
            return
        }
        vcDelegate?.carouselDidEndScrollingAnimation?(vc)
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        guard let vc = carouselViewController else {
            return
        }
        vcDelegate?.carouselWillBeginDragging?(vc)
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        guard let vc = carouselViewController else {
            return
        }
        vcDelegate?.carouselDidEndDragging?(vc, willDecelerate: decelerate)
    }
}


public class CarouselViewController: UIViewController {
    /// visible cell count
    public var cellPerPage:Int = 1 {
        didSet {
            _carouselView.cellPerPage = cellPerPage
        }
    }
    /// buffer cell count(cell create but not visible)
    public var buffeCellCount:Int = 1 {        // one side
        didSet {
            _carouselView.buffeCellCount = buffeCellCount
        }
    }
    
    /// data source of cell viewcontrollers
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
    
    /// reuse cell size number, if negative will cache all cells( high memory usage)
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
    /// cell layout in Loop or Linear
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
    public var visibleCells:[CarouselCell] {
        return _carouselView.visibleCells
    }
    
    public var firstVisibleCell:CarouselCell? {
        return _carouselView.firstVisibleCell
    }
    
    public var lastVisibleIndex:CarouselCell? {
        return _carouselView.lastVisibleIndex
    }
    
    public var firstVisibleCellIndex:CGFloat {
        return _carouselView.firstVisibleCellIndex
    }
    
    public func scrollToIndex(index:Int, animated:Bool = false) {
        return _carouselView.scrollToIndex(index, animated: animated)
    }
    
    public func nextCell(animated:Bool = false) {
        _carouselView.nextCell(animated)
    }
    
    public func preNext(animated:Bool = false) {
        _carouselView.preNext(animated)
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
     - parameter increase:     cell increase or decrease
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
    
    public func reload(index index:Int) {
        _carouselView.reload(index: index)
    }
    
    public func reload(indexs indexs:[Int]) {
        _carouselView.reload(indexs: indexs)
    }
    
    public func reloadvisibleCells() {
        _carouselView.reloadvisibleCells()
    }
}
