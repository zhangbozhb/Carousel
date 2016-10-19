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

private let c_screenWidth = UIScreen.mainScreen().bounds.width
private let c_screenHeight = UIScreen.mainScreen().bounds.height

protocol CarouselDataSourse:class {
    func numberOfCell() -> Int
    func cellForIndex(index:Int) -> UIView?
}

protocol CarouselDelegate:class {
    // install uninstall
    func carouselWillInstall(cell cell:CarouselCell)
    func carouselWillUninstall(cell cell:CarouselCell)
    func carouselDidInstall(cell cell:CarouselCell)
    func carouselDidUninstall(cell cell:CarouselCell)
    
    // progresss
    func carouselScroll(from from:Int, to:Int, progress:CGFloat)
    func carouselDidScroll(from from:Int, to:Int)
    
    
    func carouselDidScroll()
    func carouselWillBeginDragging()
    func carouselDidEndDraggingWillDecelerate(decelerate: Bool)
    
    func carouselWillBeginDecelerating()
    func carouselDidEndDecelerating()
    
    func carouselDidEndScrollingAnimation()
    
    
    func carouselDidTap(cell:CarouselCell)
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
    private weak var delegate:CarouselDelegate?
    
    private init(rawIndex:Int) {
        self.rawIndex = rawIndex
    }
    
    init(rawIndex:Int, count:Int, view:UIView, delegate:CarouselDelegate?) {
        self.rawIndex = rawIndex
        self.count = count
        self.view = view
        self.delegate = delegate
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
        delegate?.carouselWillUninstall(cell: self)
    }
    
    func didUninstall() {
        delegate?.carouselDidUninstall(cell: self)
    }
    
    func willInstall() {
        delegate?.carouselWillInstall(cell: self)
    }
    
    func didInstall() {
        delegate?.carouselDidInstall(cell: self)
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
    
    func cache(cell cell:Int, count:Int, removeFromCache:Bool = true) -> CarouselCell? {
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
        for c in cachedCells {
            c.1.1.uninstall()
        }
        cachedCells = [:]
    }
    
    func limitToCacheSize() {
        if 0 < maxSize && maxSize < cachedCells.count {
            let sorted = cachedCells.sort({ $0.1.0 > $1.1.0 })
            var remainedCells = [String: (Int, CarouselCell)]()
            for c in sorted[0..<maxSize] {
                remainedCells[c.0] = c.1
            }
            for c in sorted[maxSize..<sorted.count] {
                c.1.1.uninstall()
            }
            cachedCells = remainedCells
        } else if maxSize == 0 {
            for c in cachedCells {
                c.1.1.uninstall()
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
    case Cell   // paging by cell, scroll no limit
    case CellLimit   // paging by cell, but scroll one cell
    case Scoll  // UIScroll paging
}

public extension CarouselScrollView {
    /// cell witdh: greater than 1
    public var cellWidth:CGFloat {
        return _cellSize.width
    }
    /// cell heigt: greater than 1
    public var cellHeight:CGFloat {
        return _cellSize.height
    }
    /// page witdh: greater than 1
    public var pageWidth:CGFloat {
        return max(frame.width, 1)
    }
    /// page heigt: greater than 1
    public var pageHeight:CGFloat {
        return max(frame.height, 1)
    }
}

public class CarouselScrollView: UIScrollView {
    private var baseInited = false
    /// visible cell count
    public var cellPerPage:Int = 1 {
        didSet {
            guard cellPerPage > 0 else {
                cellPerPage = 1
                return
            }
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
    private var _curFirstCellIndex:Int = 0
    private var _ignoreScrollEvent = false
    
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
    public var pagingType = CarouselPagingType.None {
        didSet {
            pagingEnabled = (pagingType == .Scoll && cellPerPage == 1)
        }
    }
    
    /// data source of cell views
    weak var dataSource:CarouselDataSourse?
    /// scroll delegate
    weak var carouselDelegate:CarouselDelegate?
    
    private var autoScrollTimer:NSTimer?
    private var autoScrollIncrease = true

    private var tapGestureRecognizer:UITapGestureRecognizer?
    
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
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        _reusableCells.clear()
        _cells = []
        if let tap = tapGestureRecognizer {
            removeGestureRecognizer(tap)
        }
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
        delegate = self
        _reusableCells.maxSize = reusableCellSize

        _preSize = frame.size
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.handleNotifications(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.handleNotifications(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(self.handeTapGestureRecognizer(_:)))
        userInteractionEnabled = true
        addGestureRecognizer(tap)
        tapGestureRecognizer = tap
    }
    
    final func handleNotifications(notification:NSNotification) {
        UIApplicationWillResignActiveNotification
        switch notification.name {
        case UIApplicationDidBecomeActiveNotification:
            resumeAutoScroll()
            break
        case UIApplicationWillResignActiveNotification:
            pauseAutoScroll()
            break
        default:
            break
        }
    }
    
    final func handeTapGestureRecognizer(tap:UITapGestureRecognizer) {
        let pos = tap.locationInView(self)
        for cell in _cells {
            if cell.view.frame.contains(pos) {
                carouselDelegate?.carouselDidTap(cell)
                break
            }
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
        let pre = _cells
        _cells = []
        for cell in pre {
            cell.uninstall()
        }
        _reusableCells.clear()
    }
    
    private func fetchCell(index: Int, count:Int, rawIndex:Int) -> CarouselCell {
        let view = dataSource?.cellForIndex(index) ?? UIView()
        return CarouselCell.init(rawIndex: rawIndex, count: count, view: view, delegate: carouselDelegate)
    }
    
    @inline(__always) func numberOfView() -> Int? {
        return dataSource?.numberOfCell()
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
        // make sure view size not zero
        guard !CGSizeEqualToSize(CGSize.zero, frame.size) else {
            return
        }
        
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
            scrollToCell(0)
        }
    }
    
    private func carouselScroll(from from:Int, to:Int, progress:CGFloat) {
        carouselDelegate?.carouselScroll(from: from, to: to, progress: progress)
    }
    
    private func carouselDidScroll(from from:Int, to:Int) {
        carouselDelegate?.carouselDidScroll(from: from, to: to)
    }
}

// 线性 cell
extension CarouselScrollView {
    private func updateScrollProgressLinear() {
        guard let first = firstVisibleCell where first.rawIndex >= 0 && first.rawIndex < first.count else {
            return
        }
        
        switch direction {
        case .Horizontal:
            if abs(first.view.frame.minX - contentOffset.x) < threshold || contentOffset.x > frameLinear(_curFirstCellIndex).maxX || contentOffset.x < frameLinear(_curFirstCellIndex - 1).minX {
                if first.rawIndex != _curFirstCellIndex {
                    carouselDidScroll(from: _curFirstCellIndex, to: first.rawIndex)
                    _curFirstCellIndex = first.rawIndex
                }
                return
            }
        case .Vertical:
            if abs(first.view.frame.minY - contentOffset.y) < threshold || contentOffset.y > frameLinear(_curFirstCellIndex).maxY || contentOffset.y < frameLinear(_curFirstCellIndex - 1).minY {
                if first.rawIndex != _curFirstCellIndex {
                    carouselDidScroll(from: _curFirstCellIndex, to: first.rawIndex)
                    _curFirstCellIndex = first.rawIndex
                }
                return
            }
        }
        
        switch direction {
        case .Horizontal:
            let progress = contentOffset.x / cellWidth - CGFloat(_curFirstCellIndex)
            carouselScroll(from: _curFirstCellIndex, to: progress > 0 ? _curFirstCellIndex + 1 : _curFirstCellIndex - 1 , progress: progress)
        case .Vertical:
            let progress = contentOffset.y / cellHeight - CGFloat(_curFirstCellIndex)
            carouselScroll(from: _curFirstCellIndex, to: progress > 0 ? _curFirstCellIndex + 1 : _curFirstCellIndex - 1, progress: progress)
        }
    }
    
    private func updateContentSizeLinear() {
        var targetSize = frame.size
        if let count = numberOfView() where count > 0 {
            let count1 = cellPerPage > 0 ? ((count + cellPerPage - 1) / cellPerPage) * cellPerPage : count
            switch direction {
            case .Horizontal:
                targetSize = CGSizeMake(CGFloat(count1) * cellWidth, frame.height)
            case .Vertical:
                targetSize = CGSizeMake(cellWidth, CGFloat(count1) * cellHeight)
            }
        }
        if !CGSizeEqualToSize(targetSize, contentSize) {
            contentSize = targetSize
        }
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
        let cell = _reusableCells.cache(cell: rawIndex, count: count, removeFromCache: true)?.reuse(rawIndex) ?? fetchCell(rawIndex, count: count, rawIndex: rawIndex)
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
            resetCells()
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
extension CarouselScrollView {
    // cell zero offset
    private var _offsetCellIndex:Int {
        return cellPerPage * _loopPage
    }
    
    private func updateScrollProgressLoop() {
        guard let first = firstVisibleCell else {
            return
        }
        
        switch direction {
        case .Horizontal:
            if abs(first.view.frame.minX - contentOffset.x) < threshold || contentOffset.x > frameLoop(_curFirstCellIndex).maxX || contentOffset.x < frameLoop(_curFirstCellIndex - 1).minX {
                if first.rawIndex != _curFirstCellIndex && first.index != formatedInex(_curFirstCellIndex, ofCount: first.count) {
                    let offset = _curFirstCellIndex - formatedInex(_curFirstCellIndex, ofCount: first.count)
                    carouselDidScroll(from: _curFirstCellIndex - offset, to: first.rawIndex - offset)
                    _curFirstCellIndex = first.rawIndex
                }
                return
            }
        case .Vertical:
            if abs(first.view.frame.minY - contentOffset.y) < threshold || contentOffset.y > frameLoop(_curFirstCellIndex).maxY || contentOffset.y < frameLoop(_curFirstCellIndex - 1).minY {
                if first.rawIndex != _curFirstCellIndex && first.index != formatedInex(_curFirstCellIndex, ofCount: first.count) {
                    let offset = _curFirstCellIndex - formatedInex(_curFirstCellIndex, ofCount: first.count)
                    carouselDidScroll(from: _curFirstCellIndex - offset, to: first.rawIndex - offset)
                    _curFirstCellIndex = first.rawIndex
                }
                return
            }
        }
        
        var progress:CGFloat = 0
        switch direction {
        case .Horizontal:
            progress = contentOffset.x / cellWidth - CGFloat(_curFirstCellIndex + _offsetCellIndex)
        case .Vertical:
            progress = contentOffset.y / cellHeight - CGFloat(_curFirstCellIndex + _offsetCellIndex)
        }
        let offset = _curFirstCellIndex - formatedInex(_curFirstCellIndex, ofCount: first.count)
        carouselScroll(from: _curFirstCellIndex - offset, to: progress > 0 ? _curFirstCellIndex + 1 - offset: _curFirstCellIndex - 1 - offset, progress: progress)
    }
    
    private func updateContentOffsetLoop() {
        _ignoreScrollEvent = false
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
                _ignoreScrollEvent = true
                contentOffset.x -= totalCellWidth
                _curFirstCellIndex = formatedInex(_curFirstCellIndex, ofCount: count)
                updateVisibleCellLoop()
            } else if contentOffset.x < minX {
                _ignoreScrollEvent = true
                contentOffset.x += totalCellWidth
                _curFirstCellIndex = formatedInex(_curFirstCellIndex, ofCount: count)
                updateVisibleCellLoop()
            }
        case .Vertical:
            let bufferHeight = cellHeight * CGFloat(_offsetCellIndex)
            let totalCellHeight = cellHeight * CGFloat(count)
            let minY = bufferHeight
            let maxY = totalCellHeight + bufferHeight
            if contentOffset.y > maxY {
                _ignoreScrollEvent = true
                contentOffset.y -= bufferHeight
                _curFirstCellIndex = formatedInex(_curFirstCellIndex, ofCount: count)
                updateVisibleCellLoop()
            } else if contentOffset.y < minY {
                _ignoreScrollEvent = true
                contentOffset.y += bufferHeight
                _curFirstCellIndex = formatedInex(_curFirstCellIndex, ofCount: count)
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
        let cell = _reusableCells.cache(cell: index, count: count, removeFromCache: true)?.reuse(rawIndex) ?? fetchCell(index, count: count, rawIndex: rawIndex)
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
            resetCells()
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
extension CarouselScrollView: UIScrollViewDelegate {
    // this deleate handle paging
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        switch pagingType {
        case .None:
            return
        case .Cell:
            switch direction {
            case .Horizontal:
                var targetX = round(targetContentOffset.memory.x / cellWidth) * cellWidth
                targetX = max(min(targetX, contentSize.width - pageWidth), 0)
                targetContentOffset.memory.x = targetX
            case .Vertical:
                var targetY = round(targetContentOffset.memory.y / cellHeight) * cellHeight
                targetY = max(min(targetY, contentSize.height - pageHeight), 0)
                targetContentOffset.memory.y = targetY
            }
        case .CellLimit, .Scoll where cellPerPage != 1:
            // handle paging in scrollViewDidEndDragging
            switch direction {
            case .Horizontal:
                targetContentOffset.memory.x = contentOffset.x
            case .Vertical:
                targetContentOffset.memory.y = contentOffset.y
            }
        default:
            break
        }
    }
    // handle did scroll
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        guard !_ignoreScrollEvent else {
            // update visible cells
            updateVisibleCell()
            _ignoreScrollEvent = false
            return
        }
        
        // update visible cells
        updateVisibleCell()
        
        // update scroll progess
        updateScrollProgress()
        // update content offset(to restrict position) if needed
        updateContentOffset()
        
        carouselDelegate?.carouselDidScroll()
    }
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        carouselDelegate?.carouselWillBeginDragging()
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // update content offset(to restrict position) if needed
        updateContentOffset()
        
        carouselDelegate?.carouselDidEndDecelerating()
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        // update content offset(to restrict position) if needed
        updateContentOffset()
        
        carouselDelegate?.carouselDidEndScrollingAnimation()
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        pauseAutoScroll()
        
        carouselDelegate?.carouselWillBeginDragging()
    }
    
    // handle paging and auto scroll
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        resumeAutoScroll()
        
        carouselDelegate?.carouselDidEndDraggingWillDecelerate(decelerate)
        
        // paging
        switch pagingType {
        case .CellLimit, .Scoll where cellPerPage != 1:
            switch direction {
            case .Horizontal:
                var target = round(contentOffset.x / cellWidth) * cellWidth
                let cf = type == .Linear ? frameLinear(_curFirstCellIndex) : frameLoop(_curFirstCellIndex)
                let offset = contentOffset.x - cf.minX
                let offsetThreshold = min(cellWidth / 3, c_screenWidth/5)
                if offset > offsetThreshold {
                    target = ceil(contentOffset.x / cellWidth) * cellWidth
                } else if offset < -offsetThreshold {
                    target = floor(contentOffset.x / cellWidth) * cellWidth
                }
                let targetOffset = abs(target - offset)
                if targetOffset > 0 {
                   setContentOffset(CGPoint(x: target, y: contentOffset.y), animated: targetOffset > 10)
                }
            case .Vertical:
                var target = round(contentOffset.y / cellHeight) * cellHeight
                let cf = type == .Linear ? frameLinear(_curFirstCellIndex) : frameLoop(_curFirstCellIndex)
                let offset = contentOffset.y - cf.minY
                let offsetThreshold = min(cellHeight / 3, c_screenHeight/5)
                if offset > offsetThreshold {
                    target = ceil(contentOffset.y / cellHeight) * cellHeight
                } else if offset < -offsetThreshold {
                    target = floor(contentOffset.y / cellHeight) * cellHeight
                }
                let targetOffset = abs(target - offset)
                if targetOffset > 0 {
                    setContentOffset(CGPoint(x: target, y: contentOffset.y), animated: targetOffset > 10)
                }
            }
        default:
            break
        }
    }
}

// usefull extension
extension CarouselScrollView {
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
    
    public func scrollToCell(index:Int, animated:Bool = false) {
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
        scrollToCell(first.rawIndex + 1, animated: animated)
    }
    
    public func preNext(animated:Bool = false) {
        guard let first = firstVisibleCell else {
            return
        }
        scrollToCell(first.rawIndex - 1, animated: animated)
    }
}

// support auto scoll
public extension CarouselScrollView {
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
public extension CarouselScrollView {
    @inline(__always) private func reload(index:Int, withCount count: Int) {
        switch type {
        case .Linear:
            if index >= 0 && index < count {
                for c in visibleCells {
                    if c.index == index {
                        let cell = fetchCell(index, count: count, rawIndex: c.rawIndex)
                        cell.install(self, frame: type == .Linear ? frameLinear(c.rawIndex) : frameLoop(c.rawIndex))
                        break
                    }
                }
            }
        case .Loop:
            for c in visibleCells {
                if c.index == index {
                    let cell = fetchCell(index, count: count, rawIndex: c.rawIndex)
                    cell.install(self, frame: type == .Linear ? frameLinear(c.rawIndex) : frameLoop(c.rawIndex))
                    break
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
        
        for c in visibleCells {
            let cell = fetchCell(c.index, count: count, rawIndex: c.rawIndex)
            cell.install(self, frame: type == .Linear ? frameLinear(c.rawIndex) : frameLoop(c.rawIndex))
        }
    }
}



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
    
    
    // MARK: select relate delegate
    
    /// did tap cell
    ///
    /// - parameter carousel: instance of CarouselView
    /// - parameter cell:     cell index
    @objc optional func carousel(carousel:CarouselView, didTapAt cell:Int)
}


class CarouselDataSourseForView:CarouselDataSourse {
    weak var carousel:CarouselView?
    weak var dataSource:CarouselViewDataSourse?
    
    func numberOfCell() -> Int {
        guard let carousel = carousel else {
            return 0
        }
        return dataSource?.numberOfView(carousel) ?? 0
    }
    
    func cellForIndex(index: Int) -> UIView? {
        guard let carousel = carousel else {
            return nil
        }
        return dataSource?.carousel(carousel, viewForIndex: index)
    }
}

class CarouselDelegateForView:CarouselDelegate {
    weak var carousel:CarouselView?
    weak var delgate:CarouselViewDelegate?
    
    func carouselWillInstall(cell cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, willInstallCell: cell.index)
    }
    func carouselWillUninstall(cell cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, willUninstallCell: cell.index)
    }
    func carouselDidInstall(cell cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, didInstallCell: cell.index)
    }
    func carouselDidUninstall(cell cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, didUninstallCell: cell.index)
    }
    
    // progresss
    func carouselScroll(from from:Int, to:Int, progress:CGFloat) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, scrollFrom: from, to: to, progress: progress)
    }
    func carouselDidScroll(from from:Int, to:Int) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, didScrollFrom: from, to: to)
    }
    
    // select
    func carouselDidTap(cell: CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, didTapAt: cell.index)
    }
    
    func carouselDidScroll() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselDidScroll?(carousel)
    }
    func carouselWillBeginDragging() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselWillBeginDragging?(carousel)
    }
    func carouselDidEndDraggingWillDecelerate(decelerate: Bool) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselDidEndDragging?(carousel, willDecelerate: decelerate)
    }
    
    func carouselWillBeginDecelerating() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselWillBeginDecelerating?(carousel)
    }
    func carouselDidEndDecelerating() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselDidEndDecelerating?(carousel)
    }
    
    func carouselDidEndScrollingAnimation() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselDidEndScrollingAnimation?(carousel)
    }
}


public class CarouselView:UIView {
    private var baseInited = false
    public let _carousel = CarouselScrollView()
    /// visible cell count
    public var cellPerPage:Int = 1 {
        didSet {
            _carousel.cellPerPage = max(cellPerPage, 1)
        }
    }
    /// buffer cell count(cell create but not visible)
    public var buffeCellCount:Int = 1 {        // one side
        didSet {
            _carousel.buffeCellCount = max(buffeCellCount, 0)
        }
    }
    
    /// reuse cell size number, if negative will cache all cells( high memory usage)
    public var cacheSize:Int = 0 {
        didSet {
            _carousel.cacheSize = cacheSize
        }
    }
    /// layout direction
    public var direction = CarouselDirection.Horizontal {
        didSet {
            _carousel.direction = direction
        }
    }
    /// cell layout in Loop or Linear
    public var type = CarouselType.Linear {
        didSet {
            _carousel.type = type
        }
    }
    /// support paging
    public var pagingType = CarouselPagingType.None {
        didSet {
            _carousel.pagingType = pagingType
        }
    }
    
    /// data source of cell views
    public weak var dataSource:CarouselViewDataSourse? {
        didSet {
            if _dataSource.dataSource !== dataSource {
                _dataSource.dataSource = dataSource
            }
        }
    }
    /// scroll delegate
    public weak var delegate:CarouselViewDelegate? {
        didSet {
            if _delegate.delgate !== delegate {
                _delegate.delgate = delegate
                _carousel.setNeedsLayout()
            }
        }
    }
    private let _dataSource = CarouselDataSourseForView()
    private let _delegate = CarouselDelegateForView()
    
    required public init?(coder aDecoder: NSCoder) {
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
        
        _dataSource.carousel = self
        _delegate.carousel = self
        
        addSubview(_carousel)
        _carousel.frame = bounds
        
        _carousel.dataSource = _dataSource
        _carousel.carouselDelegate = _delegate
        _carousel.reload()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !CGRectEqualToRect(_carousel.frame, bounds) {
            _carousel.frame = bounds
        }
    }
}

//// CarouselViewController
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
    
    // MARK: select relate delegate
    
    /// did tap cell
    ///
    /// - parameter carousel: instance of CarouselViewController
    /// - parameter cell:     cell index
    @objc optional func carousel(carousel:CarouselViewController, didTapAt cell:Int)
}

class CarouselCellForViewController:CarouselCell {
    private var viewController:UIViewController?
    
    deinit {
        viewController?.removeFromParentViewController()
        viewController?.didMoveToParentViewController(nil)
        viewController = nil
    }
}

class CarouselScrollViewForViewController:CarouselScrollView {
    private override func fetchCell(index: Int, count: Int, rawIndex: Int) -> CarouselCell {
        if let ds = dataSource as? CarouselDataSourseForViewController {
            if let ds1 = ds.dataSource, carousel = ds.carousel {
                let vc = ds1.carousel(carousel, viewControllerForIndex: index)
                let view = vc?.view ?? UIView()
                let cell = CarouselCellForViewController.init(rawIndex: rawIndex, count: count, view: view, delegate: carouselDelegate)
                cell.viewController = vc
                return cell
            }
        }
        return super.fetchCell(index, count: count, rawIndex: rawIndex)
    }
}

class CarouselDataSourseForViewController:CarouselDataSourse {
    weak var carousel:CarouselViewController?
    weak var dataSource:CarouselViewControllerDataSourse?
    
    func numberOfCell() -> Int {
        guard let carousel = carousel else {
            return 0
        }
        return dataSource?.numberOfViewController(carousel) ?? 0
    }
    
    func cellForIndex(index: Int) -> UIView? {
        guard let carousel = carousel else {
            return nil
        }
        return dataSource?.carousel(carousel, viewControllerForIndex: index)?.view
    }
}

class CarouselDelegateForViewController:CarouselDelegate {
    weak var carousel:CarouselViewController?
    weak var delgate:CarouselViewControllerDelegate?
    
    func carouselWillInstall(cell cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        if let c = cell as? CarouselCellForViewController, vc = c.viewController {
            carousel.addChildViewController(vc)
        }
        delgate?.carousel?(carousel, willInstallCell: cell.index)
    }
    func carouselWillUninstall(cell cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        if let c = cell as? CarouselCellForViewController, vc = c.viewController {
            vc.removeFromParentViewController()
        }
        delgate?.carousel?(carousel, willUninstallCell: cell.index)
    }
    func carouselDidInstall(cell cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        
        delgate?.carousel?(carousel, didInstallCell: cell.index)
        
        if let c = cell as? CarouselCellForViewController, vc = c.viewController {
            vc.didMoveToParentViewController(carousel)
        }
    }
    func carouselDidUninstall(cell cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        
        delgate?.carousel?(carousel, didUninstallCell: cell.index)
        
        if let c = cell as? CarouselCellForViewController, vc = c.viewController {
            vc.didMoveToParentViewController(nil)
        }
    }
    
    // progresss
    func carouselScroll(from from:Int, to:Int, progress:CGFloat) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, scrollFrom: from, to: to, progress: progress)
    }
    func carouselDidScroll(from from:Int, to:Int) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, didScrollFrom: from, to: to)
    }
    
    // select
    func carouselDidTap(cell: CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, didTapAt: cell.index)
    }
    
    
    func carouselDidScroll() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselDidScroll?(carousel)
    }
    func carouselWillBeginDragging() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselWillBeginDragging?(carousel)
    }
    func carouselDidEndDraggingWillDecelerate(decelerate: Bool) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselDidEndDragging?(carousel, willDecelerate: decelerate)
    }
    
    func carouselWillBeginDecelerating() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselWillBeginDecelerating?(carousel)
    }
    func carouselDidEndDecelerating() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselDidEndDecelerating?(carousel)
    }
    
    func carouselDidEndScrollingAnimation() {
        guard let carousel = carousel else {
            return
        }
        delgate?.carouselDidEndScrollingAnimation?(carousel)
    }
}

public class CarouselViewController: UIViewController {
    /// visible cell count
    public var cellPerPage:Int = 1 {
        didSet {
            _carousel.cellPerPage = max(cellPerPage, 1)
        }
    }
    /// buffer cell count(cell create but not visible)
    public var buffeCellCount:Int = 1 {        // one side
        didSet {
            _carousel.buffeCellCount = max(buffeCellCount, 0)
        }
    }
    
    /// reuse cell size number, if negative will cache all cells( high memory usage)
    public var cacheSize:Int = 0 {
        didSet {
            _carousel.cacheSize = cacheSize
        }
    }
    /// layout direction
    public var direction = CarouselDirection.Horizontal {
        didSet {
            _carousel.direction = direction
        }
    }
    /// cell layout in Loop or Linear
    public var type = CarouselType.Linear {
        didSet {
            _carousel.type = type
        }
    }
    /// support paging
    public var pagingType = CarouselPagingType.None {
        didSet {
            _carousel.pagingType = pagingType
        }
    }
    
    /// data source of cell views
    public weak var dataSource:CarouselViewControllerDataSourse? {
        didSet {
            if _dataSource.dataSource !== dataSource {
                _dataSource.dataSource = dataSource
            }
        }
    }
    /// scroll delegate
    public weak var delegate:CarouselViewControllerDelegate? {
        didSet {
            if _delegate.delgate !== delegate {
                _delegate.delgate = delegate
                _carousel.setNeedsLayout()
            }
        }
    }
    private let _dataSource = CarouselDataSourseForViewController()
    private let _delegate = CarouselDelegateForViewController()
    
    
    /// if true viewWillAppear will resume auto scroll, viewDidDisappear will pause auto scroll
    public var autoScrolOnlyViewAppeared = true
    
    public var _carousel: CarouselScrollView {
        return view as! CarouselScrollView
    }
    
    override public func loadView() {
        _dataSource.carousel = self
        _delegate.carousel = self
        
        let carouselView = CarouselScrollViewForViewController.init(frame: UIScreen.mainScreen().bounds)
        carouselView.dataSource = _dataSource
        carouselView.carouselDelegate = _delegate
        view = carouselView
    }
}


public protocol CarouselProtocol {
    var _carousel: CarouselScrollView {get}
}


// usefull extension
extension CarouselProtocol {
    public var visibleCells:[CarouselCell] {
        return _carousel.visibleCells
    }
    
    public var firstVisibleCell:CarouselCell? {
        return _carousel.firstVisibleCell
    }
    
    public var lastVisibleIndex:CarouselCell? {
        return _carousel.lastVisibleIndex
    }
    
    public var firstVisibleCellIndex:CGFloat {
        return _carousel.firstVisibleCellIndex
    }
    
    public func scrollToCell(index:Int, animated:Bool = false) {
        return _carousel.scrollToCell(index, animated: animated)
    }
    
    public func nextCell(animated:Bool = false) {
        _carousel.nextCell(animated)
    }
    
    public func preNext(animated:Bool = false) {
        _carousel.preNext(animated)
    }
}

// auto scoll
extension CarouselProtocol {
    /**
     auto scroll
     default auto scroll is disable
     - parameter timeInterval: scroll time interval
     - parameter increase:     cell increase or decrease
     */
    public func autoScroll(timeInterval:NSTimeInterval, increase:Bool) {
        _carousel.autoScroll(timeInterval, increase: increase)
    }
    
    /**
     stop auto scroll
     */
    public func stopAutoScroll() {
        _carousel.stopAutoScroll()
    }
    /**
     pause auto scroll
     */
    public func pauseAutoScroll() {
        _carousel.pauseAutoScroll()
    }
    /**
     resume auto scroll
     if your never call autoScroll(_:increase), auto scroll will not work
     */
    public func resumeAutoScroll() {
        _carousel.resumeAutoScroll()
    }
}

// add reload relative method
extension CarouselProtocol {
    public func reload() {
        _carousel.reload()
    }
    
    public func reload(index index:Int) {
        _carousel.reload(index: index)
    }
    
    public func reload(indexs indexs:[Int]) {
        _carousel.reload(indexs: indexs)
    }
    
    public func reloadvisibleCells() {
        _carousel.reloadvisibleCells()
    }
}


// support auto scoll
extension CarouselView: CarouselProtocol {

}

extension CarouselViewController: CarouselProtocol {
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if autoScrolOnlyViewAppeared {
            _carousel.resumeAutoScroll()
        }
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if autoScrolOnlyViewAppeared {
            _carousel.pauseAutoScroll()
        }
    }
}
