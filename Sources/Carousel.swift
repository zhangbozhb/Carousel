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

private let c_screenWidth = UIScreen.main.bounds.width
private let c_screenHeight = UIScreen.main.bounds.height

protocol CarouselDataSourse:class {
    func numberOfCell() -> Int
    func cellForIndex(_ index:Int) -> UIView?
}

protocol CarouselDelegate:class {
    // install uninstall
    func carouselWillInstall(cell:CarouselCell)
    func carouselWillUninstall(cell:CarouselCell)
    func carouselDidInstall(cell:CarouselCell)
    func carouselDidUninstall(cell:CarouselCell)
    
    // progresss
    func carouselScroll(from:Int, to:Int, progress:CGFloat)
    func carouselDidScroll(from:Int, to:Int)
    
    
    func carouselDidScroll()
    func carouselWillBeginDragging()
    func carouselDidEndDraggingWillDecelerate(_ decelerate: Bool)
    
    func carouselWillBeginDecelerating()
    func carouselDidEndDecelerating()
    
    func carouselDidEndScrollingAnimation()
    
    
    func carouselDidTap(cell:CarouselCell)
}

private func formatedInex(_ index:Int, ofCount count:Int) -> Int {
    var i = index
    while i < 0 {
        i += 100 * count
    }
    return count > 0 ? i % count : 0
}

private func formatedInex(_ index:CGFloat, ofCount count:CGFloat) -> CGFloat {
    var i = index
    while i < 0 {
        i += 100 * count
    }
    return count > 0 ? i.truncatingRemainder(dividingBy: count) : 0
}

open class CarouselCell {
    fileprivate var rawIndex:Int = 0
    fileprivate(set) var count:Int = 0
    fileprivate(set) var view = UIView()
    fileprivate weak var delegate:CarouselDelegate?
    
    fileprivate init(rawIndex:Int) {
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
    
    open var index:Int {
        return formatedInex(rawIndex, ofCount: count)
    }
    
    func reuse(_ rawIndex:Int) -> CarouselCell {
        self.rawIndex = rawIndex
        return self
    }
    
    open func uninstall() {
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
    func install(_ toView:UIView, frame:CGRect) {
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
    fileprivate var maxSize = 0
    fileprivate var cellCount = 0
    fileprivate var cachedCells = [String: (Int, CarouselCell)]()
    
    fileprivate var queueIndex:Int = 0
    
    /**
     cache cell
     
     - parameter cell:            cell to cache
     - parameter uninstall:       if true uninstall cell
     - parameter ignoreSizeLimit: if true ignore size limit, you should call limitToCacheSize manually
     */
    func push(_ cell:CarouselCell, uninstall:Bool = true, ignoreSizeLimit:Bool = false) {
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
    
    func cache(cell:Int, count:Int, removeFromCache:Bool = true) -> CarouselCell? {
        guard count > 0 else {
            return nil
        }
        let cacheKey = "\(cell)_\(count)"
        let cached = cachedCells[cacheKey]
        if removeFromCache {
            cachedCells.removeValue(forKey: cacheKey)
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
            let sorted = cachedCells.sorted(by: { $0.1.0 > $1.1.0 })
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
    case horizontal, vertical
}

public enum CarouselType {
    case linear, loop
}

public enum CarouselPagingType {
    case none   // not paging
    case cell   // paging by cell, scroll no limit
    case cellLimit   // paging by cell, but scroll one cell
    case scoll  // UIScroll paging
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

open class CarouselScrollView: UIScrollView {
    fileprivate var baseInited = false
    /// visible cell count
    open var cellPerPage:Int = 1 {
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
    open var buffeCellCount:Int = 1 {        // one side
        didSet {
            if buffeCellCount < 0 {
                buffeCellCount = 0
            } else {
                updateVisibleCell()
            }
        }
    }
    
    /// page used for loop: extral page it takes
    fileprivate var _loopPage:Int = 2
    fileprivate var threshold:CGFloat = 1
    /// cells in view
    fileprivate var _cells = [CarouselCell]()
    /// cells can be reusable
    fileprivate var _reusableCells = CarouselPageCache()
    
    fileprivate var _cellSize:CGSize = CGSize(width: 1, height: 1)
    
    fileprivate var _preSize:CGSize = CGSize.zero
    fileprivate var _curFirstCellIndex:Int = 0
    fileprivate var _ignoreScrollEvent = false
    
    /// cached cell size: default is zero, if is negative will cache all
    fileprivate var reusableCellSize:Int {
        let minSize = cellPerPage + 2 * buffeCellCount
        return cacheSize > minSize ? cacheSize - minSize : cacheSize
    }
    /// reuse cell size number, if negative will cache all cells( high memory usage)
    open var cacheSize:Int = 0 {
        didSet {
            _reusableCells.maxSize = reusableCellSize
        }
    }
    /// layout direction
    open var direction = CarouselDirection.horizontal {
        didSet {
            if direction != oldValue {
                setNeedsLayout()
            }
        }
    }
    /// cell layout in Loop or Linear
    open var type = CarouselType.linear
    /// support paging
    open var pagingType = CarouselPagingType.none {
        didSet {
            isPagingEnabled = (pagingType == .scoll && cellPerPage == 1)
        }
    }
    
    /// data source of cell views
    weak var dataSource:CarouselDataSourse?
    /// scroll delegate
    weak var carouselDelegate:CarouselDelegate?
    
    fileprivate var autoScrollTimer:Timer?
    fileprivate var autoScrollIncrease = true
    
    fileprivate var tapGestureRecognizer:UITapGestureRecognizer?
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        _reusableCells.clear()
        _cells = []
        if let tap = tapGestureRecognizer {
            removeGestureRecognizer(tap)
        }
    }
    
    fileprivate func baseInit() {
        guard !baseInited else {
            return
        }
        baseInited = true
        
        contentSize = frame.size
        _ = updateCellSize()
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        isPagingEnabled = false
        delegate = self
        _reusableCells.maxSize = reusableCellSize
        
        _preSize = frame.size
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotifications(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotifications(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(self.handeTapGestureRecognizer(tap:)))
        isUserInteractionEnabled = true
        addGestureRecognizer(tap)
        tapGestureRecognizer = tap
    }
    
    @objc final func handleNotifications(_ notification:Notification) {
        switch notification.name {
        case NSNotification.Name.UIApplicationDidBecomeActive:
            resumeAutoScroll()
            break
        case NSNotification.Name.UIApplicationWillResignActive:
            pauseAutoScroll()
            break
        default:
            break
        }
    }
    
    @objc final func handeTapGestureRecognizer(tap:UITapGestureRecognizer) {
        let pos = tap.location(in: self)
        for cell in _cells {
            if cell.view.frame.contains(pos) {
                carouselDelegate?.carouselDidTap(cell: cell)
                break
            }
        }
    }
    
    fileprivate func cellSizeEqualToSize(_ size1: CGSize, _ size2: CGSize) -> Bool {
        return abs(size1.width - size2.width) < 0.001 && abs(size1.height - size2.height) < 0.001
    }
    /**
     update cell size
     
     - returns: true size change, false not
     */
    fileprivate final func updateCellSize() -> Bool {
        let width = max(direction == .horizontal ? frame.width / CGFloat(cellPerPage) : frame.width, threshold)
        let height = max(direction == .vertical ? frame.height / CGFloat(cellPerPage) : frame.height, threshold)
        let cellSize = CGSize(width: width, height: height)
        if !cellSizeEqualToSize(_cellSize, cellSize) {
            _cellSize = cellSize
            return true
        }
        return false
    }
    
    fileprivate func resetCells() {
        let pre = _cells
        _cells = []
        for cell in pre {
            cell.uninstall()
        }
        _reusableCells.clear()
    }
    
    fileprivate func fetchCell(_ index: Int, count:Int, rawIndex:Int) -> CarouselCell {
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
        guard let pre = _cells.first , !cellSizeEqualToSize(_cellSize, pre.view.frame.size) else {
            return
        }
        switch type {
        case .linear:
            for cell in _cells {
                cell.view.frame = frameLinear(cell.rawIndex)
            }
        case .loop:
            for cell in _cells {
                cell.view.frame = frameLoop(cell.rawIndex)
            }
        }
    }
    
    /**
     update visible cell (add or remove cell if needed)
     */
    fileprivate func updateVisibleCell() {
        // make sure view size not zero
        guard !CGSize.zero.equalTo(frame.size) else {
            return
        }

        // update current cells layout
        updateCurrentCellsLayout()
        
        // update visible cell
        switch type {
        case .linear:
            updateVisibleCellLinear()
        case .loop:
            updateVisibleCellLoop()
        }
        _reusableCells.limitToCacheSize()
    }
    /**
     reload latest data source and update views
     */
    open func reload() {
        resetCells()
        updateVisibleCell()
        
        updateContentSize()
    }
    
    func updateContentSize() {
        switch type {
        case .linear:
            updateContentSizeLinear()
        case .loop:
            updateContentSizeLoop()
        }
    }
    
    func updateContentOffset() {
        switch type {
        case .linear:
            break
        case .loop:
            updateContentOffsetLoop()
        }
    }
    
    func updateScrollProgress()  {
        switch type {
        case .linear:
            updateScrollProgressLinear()
        case .loop:
            updateScrollProgressLoop()
        }
    }
    
    override open func layoutSubviews() {
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
            scrollTo(cell: 0)
        }
    }
    
    fileprivate func carouselScroll(from:Int, to:Int, progress:CGFloat) {
        carouselDelegate?.carouselScroll(from: from, to: to, progress: progress)
    }
    
    fileprivate func carouselDidScroll(from:Int, to:Int) {
        carouselDelegate?.carouselDidScroll(from: from, to: to)
    }
}

// 线性 cell
extension CarouselScrollView {
    fileprivate func updateScrollProgressLinear() {
        guard let first = firstVisibleCell , first.rawIndex >= 0 && first.rawIndex < first.count else {
            return
        }
        
        switch direction {
        case .horizontal:
            if abs(first.view.frame.minX - contentOffset.x) < threshold || contentOffset.x > frameLinear(_curFirstCellIndex).maxX || contentOffset.x < frameLinear(_curFirstCellIndex - 1).minX {
                if first.rawIndex != _curFirstCellIndex {
                    carouselDidScroll(from: formatedInex(_curFirstCellIndex, ofCount: first.count) , to: formatedInex(first.rawIndex, ofCount: first.count))
                    _curFirstCellIndex = first.rawIndex
                }
                return
            }
        case .vertical:
            if abs(first.view.frame.minY - contentOffset.y) < threshold || contentOffset.y > frameLinear(_curFirstCellIndex).maxY || contentOffset.y < frameLinear(_curFirstCellIndex - 1).minY {
                if first.rawIndex != _curFirstCellIndex {
                    carouselDidScroll(from: formatedInex(_curFirstCellIndex, ofCount: first.count) , to: formatedInex(first.rawIndex, ofCount: first.count))
                    _curFirstCellIndex = first.rawIndex
                }
                return
            }
        }
        
        switch direction {
        case .horizontal:
            let progress = contentOffset.x / cellWidth - CGFloat(_curFirstCellIndex)
            carouselScroll(from: formatedInex(_curFirstCellIndex, ofCount: first.count), to: formatedInex(progress > 0 ? _curFirstCellIndex + 1 : _curFirstCellIndex - 1, ofCount: first.count) , progress: progress)
        case .vertical:
            let progress = contentOffset.y / cellHeight - CGFloat(_curFirstCellIndex)
            carouselScroll(from: formatedInex(_curFirstCellIndex, ofCount: first.count), to: formatedInex(progress > 0 ? _curFirstCellIndex + 1 : _curFirstCellIndex - 1, ofCount: first.count), progress: progress)
        }
    }
    
    fileprivate func updateContentSizeLinear() {
        var targetSize = frame.size
        if let count = numberOfView() , count > 0 {
            let count1 = cellPerPage > 0 ? ((count + cellPerPage - 1) / cellPerPage) * cellPerPage : count
            switch direction {
            case .horizontal:
                targetSize = CGSize(width: CGFloat(count1) * cellWidth, height: frame.height)
            case .vertical:
                targetSize = CGSize(width: cellWidth, height: CGFloat(count1) * cellHeight)
            }
        }
        if !targetSize.equalTo(contentSize) {
            contentSize = targetSize
        }
    }
    
    fileprivate func frameLinear(_ rawIndex:Int) -> CGRect {
        switch direction {
        case .horizontal:
            return CGRect(x: CGFloat(rawIndex) * cellWidth, y: 0, width: cellWidth, height: cellHeight)
        case .vertical:
            return CGRect(x: 0, y: CGFloat(rawIndex) * cellHeight, width: cellWidth, height: cellHeight)
        }
    }
    
    fileprivate func setupCellLinear(_ rawIndex:Int, count:Int, tail:Bool = true) -> CarouselCell {
        let cell = _reusableCells.cache(cell: rawIndex, count: count, removeFromCache: true)?.reuse(rawIndex) ?? fetchCell(rawIndex, count: count, rawIndex: rawIndex)
        if tail {
            _cells.append(cell)
        } else {
            _cells.insert(cell, at: 0)
        }
        
        cell.install(self, frame: frameLinear(rawIndex))
        return cell
    }
    
    fileprivate func updateVisibleCellLinear() {
        guard let count = numberOfView() , count > 0 else {
            resetCells()
            return
        }
        
        if direction == .horizontal {
            let minX = max(ceil(contentOffset.x / cellWidth - CGFloat(buffeCellCount)) * cellWidth, 0)
            let maxX = minX + CGFloat(cellPerPage + buffeCellCount * 2) * cellWidth
            
            // right：remove cell
            while let cell = _cells.last , cell.view.frame.minX + threshold > maxX {
                _reusableCells.push(_cells.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // left：remove cell
            while let cell = _cells.first , cell.view.frame.maxX - threshold < minX {
                _reusableCells.push(_cells.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if _cells.isEmpty {
                _ = setupCellLinear(Int(contentOffset.x / cellWidth), count: count)
            }
            // right：add cell
            while let cell = _cells.last , cell.rawIndex < count - 1 && cell.view.frame.maxX + threshold < maxX {
                _ = setupCellLinear(cell.rawIndex + 1, count: count, tail: true)
            }
            // left：add cell
            while let cell = _cells.first , cell.rawIndex > 0 && cell.view.frame.minX - threshold > minX {
                _ = setupCellLinear(cell.rawIndex - 1, count: count, tail: false)
            }
        } else {
            let minY = max(ceil(contentOffset.y / cellHeight - CGFloat(buffeCellCount)) * cellHeight, 0)
            let maxY = minY + CGFloat(cellPerPage + buffeCellCount * 2) * cellHeight
            
            // tail：remove cell
            while let cell = _cells.last , cell.view.frame.minY + threshold > maxY {
                _reusableCells.push(_cells.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // top：remove cell
            while let cell = _cells.first , cell.view.frame.maxY - threshold < minY {
                _reusableCells.push(_cells.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if _cells.isEmpty {
                _ = setupCellLinear(Int(contentOffset.y / cellHeight), count: count)
            }
            // tail：add cell
            while let cell = _cells.last , cell.rawIndex < count - 1 && cell.view.frame.maxY + threshold < maxY {
                _ = setupCellLinear(cell.rawIndex + 1, count: count, tail: true)
            }
            // top：add cell
            while let cell = _cells.first , cell.rawIndex > 0 && cell.view.frame.minY - threshold > minY {
                _ = setupCellLinear(cell.rawIndex - 1, count: count, tail: false)
            }
        }
    }
}

// loop cell
extension CarouselScrollView {
    // cell zero offset
    fileprivate var _offsetCellIndex:Int {
        return cellPerPage * _loopPage
    }
    
    fileprivate func updateScrollProgressLoop() {
        guard let first = firstVisibleCell else {
            return
        }
        
        switch direction {
        case .horizontal:
            if abs(first.view.frame.minX - contentOffset.x) < threshold || contentOffset.x > frameLoop(_curFirstCellIndex).maxX || contentOffset.x < frameLoop(_curFirstCellIndex - 1).minX {
                if first.rawIndex != _curFirstCellIndex && first.index != formatedInex(_curFirstCellIndex, ofCount: first.count) {
                    let offset = _curFirstCellIndex - formatedInex(_curFirstCellIndex, ofCount: first.count)
                    let from = formatedInex(_curFirstCellIndex - offset, ofCount: first.count)
                    let to = formatedInex(first.rawIndex - offset, ofCount: first.count)
                    carouselDidScroll(from: from, to: to)
                    _curFirstCellIndex = first.rawIndex
                }
                return
            }
        case .vertical:
            if abs(first.view.frame.minY - contentOffset.y) < threshold || contentOffset.y > frameLoop(_curFirstCellIndex).maxY || contentOffset.y < frameLoop(_curFirstCellIndex - 1).minY {
                if first.rawIndex != _curFirstCellIndex && first.index != formatedInex(_curFirstCellIndex, ofCount: first.count) {
                    let offset = _curFirstCellIndex - formatedInex(_curFirstCellIndex, ofCount: first.count)
                    let from = formatedInex(_curFirstCellIndex - offset, ofCount: first.count)
                    let to = formatedInex(first.rawIndex - offset, ofCount: first.count)
                    carouselDidScroll(from: from, to: to)
                    _curFirstCellIndex = first.rawIndex
                }
                return
            }
        }
        
        var progress:CGFloat = 0
        switch direction {
        case .horizontal:
            progress = contentOffset.x / cellWidth - CGFloat(_curFirstCellIndex + _offsetCellIndex)
        case .vertical:
            progress = contentOffset.y / cellHeight - CGFloat(_curFirstCellIndex + _offsetCellIndex)
        }
        let offset = _curFirstCellIndex - formatedInex(_curFirstCellIndex, ofCount: first.count)
        var from = _curFirstCellIndex - offset
        var to = progress > 0 ? _curFirstCellIndex + 1 - offset: _curFirstCellIndex - 1 - offset
        from =  formatedInex(from, ofCount: first.count)
        to =  formatedInex(to, ofCount: first.count)
        carouselScroll(from: from, to: to, progress: progress)
    }
    
    fileprivate func updateContentOffsetLoop() {
        _ignoreScrollEvent = false
        guard let count = numberOfView() , count > cellPerPage else {
            return
        }
        
        switch direction {
        case .horizontal:
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
        case .vertical:
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
    
    fileprivate func updateContentSizeLoop() {
        var targetSize = frame.size
        if let count = numberOfView() , count > cellPerPage {
            let targetCount = count + 2 * _offsetCellIndex
            if direction == .horizontal {
                targetSize = CGSize(width: CGFloat(targetCount) * cellWidth, height: frame.height)
            } else {
                targetSize = CGSize(width: cellWidth, height: CGFloat(targetCount) * cellHeight)
            }
        }
        if !targetSize.equalTo(contentSize) {
            contentSize = targetSize
        }
    }
    
    fileprivate func frameLoop(_ rawIndex:Int) -> CGRect {
        switch direction {
        case .horizontal:
            return CGRect(x: CGFloat(rawIndex + _offsetCellIndex) * cellWidth, y: 0, width: cellWidth, height: cellHeight)
        case .vertical:
            return CGRect(x: 0, y: CGFloat(rawIndex + _offsetCellIndex) * cellHeight, width: cellWidth, height: cellHeight)
        }
    }
    
    fileprivate func setupCellLoop(_ rawIndex:Int, count:Int, tail:Bool) -> CarouselCell {
        let index = formatedInex(rawIndex, ofCount: count)
        let cell = _reusableCells.cache(cell: index, count: count, removeFromCache: true)?.reuse(rawIndex) ?? fetchCell(index, count: count, rawIndex: rawIndex)
        if tail {
            _cells.append(cell)
        } else {
            _cells.insert(cell, at: 0)
        }
        
        cell.install(self, frame: frameLoop(rawIndex))
        return cell
    }
    
    fileprivate func updateVisibleCellLoop() {
        guard let count = numberOfView() , count > 0 else {
            resetCells()
            return
        }
        
        if direction == .horizontal {
            let bufferCellWidth = min(CGFloat(cellPerPage + buffeCellCount * 2), CGFloat(count)) * cellWidth
            let maxX = floor((contentOffset.x + bufferCellWidth) / cellWidth) * cellWidth
            let minX = maxX - bufferCellWidth
            
            // right：remove cell
            while let cell = _cells.last , cell.view.frame.minX + threshold > maxX {
                _reusableCells.push(_cells.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // left：remove cell
            while let cell = _cells.first , cell.view.frame.maxX - threshold < minX {
                _reusableCells.push(_cells.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if _cells.isEmpty {
                _ = setupCellLoop(Int(contentOffset.x / cellWidth) - _offsetCellIndex, count: count, tail: true)
            }
            // right：add cell
            while let cell = _cells.last , cell.view.frame.maxX + threshold < maxX {
                _ = setupCellLoop(cell.rawIndex + 1, count: count, tail: true)
            }
            // left：add cell
            while let cell = _cells.first , cell.view.frame.minX - threshold > minX {
                _ = setupCellLoop(cell.rawIndex - 1, count: count, tail: false)
            }
        } else {
            let bufferCellHeight = min(CGFloat(cellPerPage + buffeCellCount * 2), CGFloat(count)) * cellHeight
            let maxY = floor((contentOffset.y + bufferCellHeight) / cellHeight) * cellHeight
            let minY = maxY - bufferCellHeight
            
            // tail：remove cell
            while let cell = _cells.last , cell.view.frame.minY + threshold > maxY {
                _reusableCells.push(_cells.removeLast(), uninstall: false, ignoreSizeLimit: true)
            }
            // top：remove cell
            while let cell = _cells.first , cell.view.frame.maxY - threshold < minY {
                _reusableCells.push(_cells.removeFirst(), uninstall: false, ignoreSizeLimit: true)
            }
            
            // handle empty
            if _cells.isEmpty {
                _ = setupCellLoop(Int(contentOffset.y / cellHeight) - _offsetCellIndex, count: count, tail: true)
            }
            // tail：add cell
            while let cell = _cells.last , cell.view.frame.maxY + threshold < maxY {
                _ = setupCellLoop(cell.rawIndex + 1, count: count, tail: true)
            }
            // top：add cell
            while let cell = _cells.first , cell.view.frame.minY - threshold > minY {
                _ = setupCellLoop(cell.rawIndex - 1, count: count, tail: false)
            }
        }
    }
}

// support page enable and adjust content offset
extension CarouselScrollView: UIScrollViewDelegate {
    // this deleate handle paging
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        switch pagingType {
        case .none:
            return
        case .cell:
            switch direction {
            case .horizontal:
                var targetX = round(targetContentOffset.pointee.x / cellWidth) * cellWidth
                targetX = max(min(targetX, contentSize.width - pageWidth), 0)
                targetContentOffset.pointee.x = targetX
            case .vertical:
                var targetY = round(targetContentOffset.pointee.y / cellHeight) * cellHeight
                targetY = max(min(targetY, contentSize.height - pageHeight), 0)
                targetContentOffset.pointee.y = targetY
            }
        case .cellLimit, 
             .scoll where cellPerPage != 1:
            // handle paging in scrollViewDidEndDragging
            switch direction {
            case .horizontal:
                targetContentOffset.pointee.x = contentOffset.x
            case .vertical:
                targetContentOffset.pointee.y = contentOffset.y
            }
        default:
            break
        }
    }
    // handle did scroll
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        carouselDelegate?.carouselWillBeginDragging()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // update content offset(to restrict position) if needed
        updateContentOffset()
        
        carouselDelegate?.carouselDidEndDecelerating()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // update content offset(to restrict position) if needed
        updateContentOffset()
        
        carouselDelegate?.carouselDidEndScrollingAnimation()
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pauseAutoScroll()
        
        carouselDelegate?.carouselWillBeginDragging()
    }
    
    // handle paging and auto scroll
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        resumeAutoScroll()
        
        carouselDelegate?.carouselDidEndDraggingWillDecelerate(decelerate)
        
        // paging
        switch pagingType {
        case .cellLimit, 
             .scoll where cellPerPage != 1:
            switch direction {
            case .horizontal:
                var target = round(contentOffset.x / cellWidth) * cellWidth
                let cf = type == .linear ? frameLinear(_curFirstCellIndex) : frameLoop(_curFirstCellIndex)
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
            case .vertical:
                var target = round(contentOffset.y / cellHeight) * cellHeight
                let cf = type == .linear ? frameLinear(_curFirstCellIndex) : frameLoop(_curFirstCellIndex)
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
        case .horizontal:
            let minX = contentOffset.x
            let maxX = contentOffset.x + frame.width
            for c in _cells {
                if c.view.frame.minX > minX - threshold && c.view.frame.maxX < maxX + threshold {
                    result.append(c)
                }
            }
        case .vertical:
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
        case .horizontal:
            for c in _cells {
                if c.view.frame.maxX - threshold > contentOffset.x {
                    cell = c
                    break
                }
            }
        case .vertical:
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
        case .horizontal:
            for c in _cells {
                if c.view.frame.maxX + threshold > contentOffset.x + frame.width {
                    cell = c
                    break
                }
            }
        case .vertical:
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
        guard let count = _cells.first?.count , count > 0 else {
            return 0
        }
        switch direction {
        case .horizontal:
            return formatedInex(contentOffset.x / cellWidth, ofCount: CGFloat(count))
        case .vertical:
            return formatedInex(contentOffset.y / cellHeight, ofCount: CGFloat(count))
        }
    }
    
    public func scrollTo(cell:Int, animated:Bool = false) {
        switch type {
        case .linear:
            var offset = frameLinear(cell).origin
            switch direction {
            case .horizontal:
                let maxX = contentSize.width - frame.width
                offset.x = max(min(maxX, offset.x), 0)
            case .vertical:
                let maxY = contentSize.height - frame.height
                offset.y = max(min(maxY, offset.y), 0)
            }
            setContentOffset(offset, animated: animated)
        case .loop:
            if Int(contentSize.width) > Int(frame.width) || Int(contentSize.height) > Int(frame.height) {
                setContentOffset(frameLoop(cell).origin, animated: animated)
            }
        }
        updateVisibleCell()
    }
    
    public func nextCell(_ animated:Bool = false) {
        guard let first = firstVisibleCell else {
            return
        }
        scrollTo(cell: first.rawIndex + 1, animated: animated)
    }
    
    public func preNext(_ animated:Bool = false) {
        guard let first = firstVisibleCell else {
            return
        }
        scrollTo(cell: first.rawIndex - 1, animated: animated)
    }
}

// support auto scoll
public extension CarouselScrollView {
    @objc func autoScrollToNext() {
        nextCell(true)
    }
    
    @objc func autoScrollToPre() {
        preNext(true)
    }
    
    /**
     auto scroll
     default auto scroll is disable
     - parameter timeInterval: scroll time interval
     - parameter increase:     page increase or decrease
     */
    public func autoScroll(_ timeInterval:TimeInterval, increase:Bool) {
        autoScrollIncrease = increase
        autoScrollTimer?.invalidate()
        autoScrollTimer = Timer.scheduledTimer(
            timeInterval: timeInterval,
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
    @inline(__always) fileprivate func reload(_ index:Int, withCount count: Int) {
        switch type {
        case .linear:
            if index >= 0 && index < count {
                for c in visibleCells {
                    if c.index == index {
                        let cell = fetchCell(index, count: count, rawIndex: c.rawIndex)
                        cell.install(self, frame: type == .linear ? frameLinear(c.rawIndex) : frameLoop(c.rawIndex))
                        break
                    }
                }
            }
        case .loop:
            for c in visibleCells {
                if c.index == index {
                    let cell = fetchCell(index, count: count, rawIndex: c.rawIndex)
                    cell.install(self, frame: type == .linear ? frameLinear(c.rawIndex) : frameLoop(c.rawIndex))
                    break
                }
            }
        }
    }
    
    public func reload(index:Int) {
        guard let count = numberOfView() , count > 0 else {
            reload()
            return
        }
        guard let preCount = visibleCells.first?.count , preCount != count else {
            reload()
            return
        }
        
        reload(index, withCount: count)
    }
    
    public func reload(indexs:[Int]) {
        guard let count = numberOfView() , count > 0 else {
            reload()
            return
        }
        
        guard let preCount = visibleCells.first?.count , preCount != count else {
            reload()
            return
        }
        
        for index in Array(Set(indexs)) {
            reload(index, withCount: count)
        }
    }
    
    public func reloadvisibleCells() {
        guard let count = numberOfView() , count > 0 else {
            reload()
            return
        }
        
        guard let preCount = visibleCells.first?.count , preCount != count else {
            reload()
            return
        }
        
        for c in visibleCells {
            let cell = fetchCell(c.index, count: count, rawIndex: c.rawIndex)
            cell.install(self, frame: type == .linear ? frameLinear(c.rawIndex) : frameLoop(c.rawIndex))
        }
    }
}



public protocol CarouselViewDataSourse:class {
    /**
     number of view for carouse
     
     - parameter carousel: CarouselView instance
     
     - returns: number of view
     */
    func numberOfView(_ carousel:CarouselView) -> Int
    /**
     iew at index for carouse
     
     - parameter carousel: instance of CarouselView
     - parameter index:    cell index for view
     
     - returns: view at cell index
     */
    func carousel(_ carousel:CarouselView, viewForIndex index:Int) -> UIView?
}

@objc public protocol CarouselViewDelegate:class {
    /**
     cell will add to carousel
     
     - parameter carousel: instance of CarouselView
     - parameter cell:     cell index
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselView, willInstallCell cell:Int)
    /**
     cell will remove from carousel
     
     - parameter carousel: instance of CarouselView
     - parameter cell:     cell index
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselView, willUninstallCell cell:Int)
    /**
     cell did add to carousel
     
     - parameter carousel: instance of CarouselView
     - parameter cell:     cell index
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselView, didInstallCell cell:Int)
    /**
     cell did remove from carousel
     
     - parameter carousel: instance of CarouselView
     - parameter cell:     cell index
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselView, didUninstallCell cell:Int)
    
    
    
    // MARK: scroll relate delegate
    /**
     cell scroll progress
     
     - parameter carousel: instance of CarouselView
     - parameter from:     from cell(first visiable cell)
     - parameter to:       to cell
     - parameter progress: progess for scroll: progress > 0, cell grow direction, < 0 cell decrease diretion
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselView, scrollFrom from:Int, to:Int, progress:CGFloat)
    /**
     cell did scroll from cell to cell
     
     - parameter carousel: instance of CarouselView
     - parameter from:     from cell(first visiable cell)
     - parameter to:       to cell
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselView, didScrollFrom from:Int, to:Int)
    
    
    @objc optional func carouselDidScroll(_ carousel:CarouselView)
    @objc optional func carouselWillBeginDragging(_ carousel:CarouselView)
    @objc optional func carouselDidEndDragging(_ carousel:CarouselView, willDecelerate decelerate: Bool)
    
    @objc optional func carouselWillBeginDecelerating(_ carousel:CarouselView)
    @objc optional func carouselDidEndDecelerating(_ carousel:CarouselView)
    
    @objc optional func carouselDidEndScrollingAnimation(_ carousel:CarouselView)
    
    
    // MARK: select relate delegate
    
    /// did tap cell
    ///
    /// - parameter carousel: instance of CarouselView
    /// - parameter cell:     cell index
    @objc optional func carousel(_ carousel:CarouselView, didTapAt cell:Int)
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
    
    func cellForIndex(_ index: Int) -> UIView? {
        guard let carousel = carousel else {
            return nil
        }
        return dataSource?.carousel(carousel, viewForIndex: index)
    }
}

class CarouselDelegateForView:CarouselDelegate {
    weak var carousel:CarouselView?
    weak var delgate:CarouselViewDelegate?
    
    func carouselWillInstall(cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, willInstallCell: cell.index)
    }
    func carouselWillUninstall(cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, willUninstallCell: cell.index)
    }
    func carouselDidInstall(cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, didInstallCell: cell.index)
    }
    func carouselDidUninstall(cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, didUninstallCell: cell.index)
    }
    
    // progresss
    func carouselScroll(from:Int, to:Int, progress:CGFloat) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, scrollFrom: from, to: to, progress: progress)
    }
    func carouselDidScroll(from:Int, to:Int) {
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
    func carouselDidEndDraggingWillDecelerate(_ decelerate: Bool) {
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


open class CarouselView:UIView {
    fileprivate var baseInited = false
    open let _carousel = CarouselScrollView()
    /// visible cell count
    open var cellPerPage:Int = 1 {
        didSet {
            _carousel.cellPerPage = max(cellPerPage, 1)
        }
    }
    /// buffer cell count(cell create but not visible)
    open var buffeCellCount:Int = 1 {        // one side
        didSet {
            _carousel.buffeCellCount = max(buffeCellCount, 0)
        }
    }
    
    /// reuse cell size number, if negative will cache all cells( high memory usage)
    open var cacheSize:Int = 0 {
        didSet {
            _carousel.cacheSize = cacheSize
        }
    }
    /// layout direction
    open var direction = CarouselDirection.horizontal {
        didSet {
            _carousel.direction = direction
        }
    }
    /// cell layout in Loop or Linear
    open var type = CarouselType.linear {
        didSet {
            _carousel.type = type
        }
    }
    /// support paging
    open var pagingType = CarouselPagingType.none {
        didSet {
            _carousel.pagingType = pagingType
        }
    }
    
    /// data source of cell views
    open weak var dataSource:CarouselViewDataSourse? {
        didSet {
            if _dataSource.dataSource !== dataSource {
                _dataSource.dataSource = dataSource
            }
        }
    }
    /// scroll delegate
    open weak var delegate:CarouselViewDelegate? {
        didSet {
            if _delegate.delgate !== delegate {
                _delegate.delgate = delegate
                _carousel.setNeedsLayout()
            }
        }
    }
    fileprivate let _dataSource = CarouselDataSourseForView()
    fileprivate let _delegate = CarouselDelegateForView()
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    
    fileprivate func baseInit() {
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if !_carousel.frame.equalTo(bounds) {
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
    func numberOfViewController(_ carousel:CarouselViewController) -> Int
    /**
     view controller at index for carouse
     
     - parameter carousel: instance of CarouselViewController
     - parameter index:    cell index
     
     - returns: view controller at cell index
     */
    func carousel(_ carousel:CarouselViewController, viewControllerForIndex index:Int) -> UIViewController?
}

@objc public protocol CarouselViewControllerDelegate:class {
    /**
     page will add to carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter cell:     cell index
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselViewController, willInstallCell cell:Int)
    /**
     page will remove from carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter cell:     cell index
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselViewController, willUninstallCell cell:Int)
    /**
     page did add to carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter cell:     cell index
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselViewController, didInstallCell cell:Int)
    /**
     page did remove from carousel
     
     - parameter carousel: instance of CarouselViewController
     - parameter cell:     cell index
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselViewController, didUninstallCell cell:Int)
    
    
    // MARK: scroll relate delegate
    /**
     page scroll progress
     
     - parameter carousel: instance of CarouselViewController
     - parameter from:     from page(first visiable page)
     - parameter to:       to page
     - parameter progress: progess for scroll: progress > 0, page grow direction, < 0 page decrease diretion
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselViewController, scrollFrom from:Int, to:Int, progress:CGFloat)
    /**
     page did scroll from page to page
     
     - parameter carousel: instance of CarouselViewController
     - parameter from:     from page(first visiable page)
     - parameter to:       to cell
     
     - returns: Void
     */
    @objc optional func carousel(_ carousel:CarouselViewController, didScrollFrom from:Int, to:Int)
    
    @objc optional func carouselDidScroll(_ carousel:CarouselViewController)
    @objc optional func carouselWillBeginDragging(_ carousel:CarouselViewController)
    @objc optional func carouselDidEndDragging(_ carousel:CarouselViewController, willDecelerate decelerate: Bool)
    
    @objc optional func carouselWillBeginDecelerating(_ carousel:CarouselViewController)
    @objc optional func carouselDidEndDecelerating(_ carousel:CarouselViewController)
    
    @objc optional func carouselDidEndScrollingAnimation(_ carousel:CarouselViewController)
    
    // MARK: select relate delegate
    
    /// did tap cell
    ///
    /// - parameter carousel: instance of CarouselViewController
    /// - parameter cell:     cell index
    @objc optional func carousel(_ carousel:CarouselViewController, didTapAt cell:Int)
}

class CarouselCellForViewController:CarouselCell {
    fileprivate var viewController:UIViewController?
    
    deinit {
        viewController?.removeFromParentViewController()
        viewController?.didMove(toParentViewController: nil)
        viewController = nil
    }
}

class CarouselScrollViewForViewController:CarouselScrollView {
    fileprivate override func fetchCell(_ index: Int, count: Int, rawIndex: Int) -> CarouselCell {
        if let ds = dataSource as? CarouselDataSourseForViewController {
            if let ds1 = ds.dataSource, let carousel = ds.carousel {
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
    
    func cellForIndex(_ index: Int) -> UIView? {
        guard let carousel = carousel else {
            return nil
        }
        return dataSource?.carousel(carousel, viewControllerForIndex: index)?.view
    }
}

class CarouselDelegateForViewController:CarouselDelegate {
    weak var carousel:CarouselViewController?
    weak var delgate:CarouselViewControllerDelegate?
    
    func carouselWillInstall(cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        if let c = cell as? CarouselCellForViewController, let vc = c.viewController {
            carousel.addChildViewController(vc)
        }
        delgate?.carousel?(carousel, willInstallCell: cell.index)
    }
    func carouselWillUninstall(cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        if let c = cell as? CarouselCellForViewController, let vc = c.viewController {
            vc.removeFromParentViewController()
        }
        delgate?.carousel?(carousel, willUninstallCell: cell.index)
    }
    func carouselDidInstall(cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        
        delgate?.carousel?(carousel, didInstallCell: cell.index)
        
        if let c = cell as? CarouselCellForViewController, let vc = c.viewController {
            vc.didMove(toParentViewController: carousel)
        }
    }
    func carouselDidUninstall(cell:CarouselCell) {
        guard let carousel = carousel else {
            return
        }
        
        delgate?.carousel?(carousel, didUninstallCell: cell.index)
        
        if let c = cell as? CarouselCellForViewController, let vc = c.viewController {
            vc.didMove(toParentViewController: nil)
        }
    }
    
    // progresss
    func carouselScroll(from:Int, to:Int, progress:CGFloat) {
        guard let carousel = carousel else {
            return
        }
        delgate?.carousel?(carousel, scrollFrom: from, to: to, progress: progress)
    }
    func carouselDidScroll(from:Int, to:Int) {
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
    func carouselDidEndDraggingWillDecelerate(_ decelerate: Bool) {
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

open class CarouselViewController: UIViewController {
    /// visible cell count
    open var cellPerPage:Int = 1 {
        didSet {
            _carousel.cellPerPage = max(cellPerPage, 1)
        }
    }
    /// buffer cell count(cell create but not visible)
    open var buffeCellCount:Int = 1 {        // one side
        didSet {
            _carousel.buffeCellCount = max(buffeCellCount, 0)
        }
    }
    
    /// reuse cell size number, if negative will cache all cells( high memory usage)
    open var cacheSize:Int = 0 {
        didSet {
            _carousel.cacheSize = cacheSize
        }
    }
    /// layout direction
    open var direction = CarouselDirection.horizontal {
        didSet {
            _carousel.direction = direction
        }
    }
    /// cell layout in Loop or Linear
    open var type = CarouselType.linear {
        didSet {
            _carousel.type = type
        }
    }
    /// support paging
    open var pagingType = CarouselPagingType.none {
        didSet {
            _carousel.pagingType = pagingType
        }
    }
    
    /// data source of cell views
    open weak var dataSource:CarouselViewControllerDataSourse? {
        didSet {
            if _dataSource.dataSource !== dataSource {
                _dataSource.dataSource = dataSource
            }
        }
    }
    /// scroll delegate
    open weak var delegate:CarouselViewControllerDelegate? {
        didSet {
            if _delegate.delgate !== delegate {
                _delegate.delgate = delegate
                _carousel.setNeedsLayout()
            }
        }
    }
    fileprivate let _dataSource = CarouselDataSourseForViewController()
    fileprivate let _delegate = CarouselDelegateForViewController()
    
    
    /// if true viewWillAppear will resume auto scroll, viewDidDisappear will pause auto scroll
    open var autoScrolOnlyViewAppeared = true
    
    open var _carousel: CarouselScrollView {
        return view as! CarouselScrollView
    }
    
    override open func loadView() {
        _dataSource.carousel = self
        _delegate.carousel = self
        
        let carouselView = CarouselScrollViewForViewController.init(frame: UIScreen.main.bounds)
        carouselView.dataSource = _dataSource
        carouselView.carouselDelegate = _delegate
        view = carouselView
    }
}


public protocol CarouselProtocol {
    var _carousel: CarouselScrollView {get}
}


// usefull extension
public extension CarouselProtocol {
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
    
    public func scrollTo(cell:Int, animated:Bool = false) {
        return _carousel.scrollTo(cell: cell, animated: animated)
    }
    
    public func nextCell(_ animated:Bool = false) {
        _carousel.nextCell(animated)
    }
    
    public func preNext(_ animated:Bool = false) {
        _carousel.preNext(animated)
    }
}

// auto scoll
public extension CarouselProtocol {
    /**
     auto scroll
     default auto scroll is disable
     - parameter timeInterval: scroll time interval
     - parameter increase:     cell increase or decrease
     */
    public func autoScroll(_ timeInterval:TimeInterval, increase:Bool) {
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
public extension CarouselProtocol {
    public func reload() {
        _carousel.reload()
    }
    
    public func reload(index:Int) {
        _carousel.reload(index: index)
    }
    
    public func reload(indexs:[Int]) {
        _carousel.reload(indexs: indexs)
    }
    
    public func reloadvisibleCells() {
        _carousel.reloadvisibleCells()
    }
}

// enable tap
public extension CarouselProtocol {
    public var isTapEnabled:Bool {
        get {
            return _carousel.isUserInteractionEnabled && (_carousel.tapGestureRecognizer?.isEnabled ?? false)
        }
        set {
            if newValue {
                _carousel.isUserInteractionEnabled = true
            }
            _carousel.tapGestureRecognizer?.isEnabled = newValue
        }
    }
}


// support auto scoll
extension CarouselView: CarouselProtocol {
    
}

extension CarouselViewController: CarouselProtocol {
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if autoScrolOnlyViewAppeared {
            _carousel.resumeAutoScroll()
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if autoScrolOnlyViewAppeared {
            _carousel.pauseAutoScroll()
        }
    }
}
