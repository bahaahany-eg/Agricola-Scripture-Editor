//
//  ScrollSyncManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

fileprivate enum Side
{
	case left, right
	
	var opposite: Side
	{
		switch self
		{
		case .left: return .right
		case .right: return .left
		}
	}
}

// The different vertical positions the cells can be matched at
fileprivate enum MatchPosition
{
	case top, center
	
	var scrollPosition: UITableViewScrollPosition
	{
		switch self
		{
		case .center: return .middle
		case .top: return .top
		}
	}
	
	func targetY(ofHeight height: CGFloat) -> CGFloat
	{
		switch self
		{
		case .center: return height / 2
		case .top: return height * 0.075
		}
	}
	
	// The used matching position depends on the keyboard state
	static var current: MatchPosition
	{
		return Keyboard.instance.isVisible ? .top : .center
	}
}

// This class handles the simultaneous scrolling of two scroll views
class ScrollSyncManager: NSObject, UITableViewDelegate
{
	// TYPES	-----------------
	
	// Target table view, associated path id -> index of the target table view's associated cell
	typealias IndexForPath = (UITableView, String) -> [IndexPath]
	
	
	// ATTRIBUTES	-------------
	
	private weak var leftTableView: UITableView!
	private weak var rightTableView: UITableView!
	
	private var pathFinder: IndexForPath
	
	//private var lastOffsetY: [Side : CGFloat] = [.left: 0, .right: 0]
	//private var lastOffsetTime: [Side : TimeInterval] = [.left: 0, .right: 0]
	//private var lastVelocity: [Side : CGFloat] = [.left: 0, .right: 0]
	//private var lastAcceleration: [Side : CGFloat] = [.left: 0, .right: 0]
	private var isDragging = false
	
	private var lastAnchorCell: AnyObject?
	
	private var syncScrolling: Side?
	
	// ResourceId -> ( Index -> Height )
	private var cellHeights: [String : [IndexPath : CGFloat]]
	private var defaultCellHeight: CGFloat = 400
	private var currentHeightIds: [Side : String]
	
	private var cellSelectionListeners = [TableCellSelectionListener]()
	
	
	// COMPUTED PROPERTIES	-----
	
	// The unigue resource identifier for the left hand side table.
	// This should be modified when the type of the table contents changes.
	var leftResourceId: String
	{
		get { return currentHeightIds[.left]! }
		set
		{
			if !cellHeights.containsKey(newValue)
			{
				cellHeights[newValue] = [:]
			}
			currentHeightIds[.left] = newValue
		}
	}
	
	
	// INIT	---------------------
	
	init(leftTable: UITableView, rightTable: UITableView, leftResourceId: String, rightResourceId: String, using pathFinder: @escaping IndexForPath)
	{
		leftTableView = leftTable
		rightTableView = rightTable
		
		self.pathFinder = pathFinder
		
		cellHeights = [String : [IndexPath : CGFloat]]()
		cellHeights[leftResourceId] = [:]
		cellHeights[rightResourceId] = [:]
		
		currentHeightIds = [Side.left: leftResourceId, Side.right: rightResourceId]
		
		super.init()
		
		rightTable.delegate = self
		leftTableView.delegate = self
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return cellHeight(side: sideOfTable(tableView), index: indexPath)
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		let scrolledSide = sideOfTable(scrollView)
		
		// Doesn't react to scrolls caused by sync scrolling
		guard scrolledSide != syncScrolling else
		{
			return
		}
		
		// When the table is scrolled to top or bottom, the other table will be too
		if scrollView.isAtTop
		{
			tableOfSide(scrolledSide.opposite).scrollToTop()
		}
		else if scrollView.isAtBottom
		{
			tableOfSide(scrolledSide.opposite).scrollToBottom()
		}
		// Otherwise the tables are matched by their center cells
		else
		{
			/*
			// Records the scroll speed
			let currentTime = Date().timeIntervalSince1970
			let duration = currentTime - lastOffsetTime[scrolledSide]!
			
			// Doesn't record very short intervals
			if duration >= 0.1
			{
				let offsetY = scrollView.contentOffset.y
				
				// If the interval is very long, there hasn't been a scroll for a while and the program needs to recollect the material
				if duration <= 1
				{
					// x = x0 + v*t
					// -> v = (x - x0) / t
					let velocity = (offsetY - lastOffsetY[scrolledSide]!) / CGFloat(duration)
					
					// Calculates the deceleration as well
					// a = (v - v0) / t
					let acceleration = (velocity - lastVelocity[scrolledSide]!) / CGFloat(duration)
					
					lastAcceleration[scrolledSide] = acceleration
					lastVelocity[scrolledSide] = velocity
				}
				else
				{
					lastAcceleration[scrolledSide] = 0
					lastVelocity[scrolledSide] = 0
				}
				
				lastOffsetY[scrolledSide] = offsetY
				lastOffsetTime[scrolledSide] = currentTime
			}*/
			
			syncScroll(toSide: scrolledSide, /*velocity: lastVelocity[scrolledSide]!, acceleration: lastAcceleration[scrolledSide]!, */skipIfAnchorStill: true)
		}
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
	{
		isDragging = true
		
		if syncScrolling == sideOfTable(scrollView)
		{
			syncScrolling = nil
		}
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
	{
		isDragging = false
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		// Informs any interested selection listener
		guard let cell = tableView.cellForRow(at: indexPath) else
		{
			print("ERROR: Could not find selected cell")
			return
		}
		
		guard let identifier = cell.reuseIdentifier else
		{
			print("ERROR: Selected cell did not have a reuse identifier")
			return
		}
		
		cellSelectionListeners.filter { $0.targetedCellIds.contains(identifier) }.forEach { $0.onTableCellSelected(cell, identifier: identifier) }
	}
	
	
	// OTHER METHODS	------
	
	func syncScrollToRight()
	{
		// Behaves slightly differently when anchor table is at top or bottom
		let anchorTable = tableOfSide(.right)
		
		if anchorTable.isAtTop
		{
			tableOfSide(.left).scrollToTop()
		}
		else if anchorTable.isAtBottom
		{
			tableOfSide(.left).scrollToBottom()
		}
		else
		{
			syncScroll(toSide: .right)
		}
	}
	
	// TODO: Only works on the right table for now
	func scrollToAnchor(cell: UITableViewCell)
	{
		let table = tableOfSide(.right)
		
		guard let index = table.indexPath(for: cell) else
		{
			return
		}
		
		// Based on the keyboard usage, either scrolls the cell to the center or top
		switch MatchPosition.current
		{
		case .center: table.scrollToRow(at: index, at: MatchPosition.center.scrollPosition, animated: true)
		case .top:
			// A small cell may be left in the top 'buffer' area so that sync scrolling connects the right cells
			let topAreaHeight = MatchPosition.top.targetY(ofHeight: table.visibleContentHeight)
			
			var topIndex = index
			var bufferHeight = cellHeight(side: .right, index: index)
			
			// Fills the 'buffer' area with small cells, if necessary
			while topIndex.row > 0 && bufferHeight <= topAreaHeight
			{
				topIndex = IndexPath(row: topIndex.row - 1, section: topIndex.section)
				bufferHeight += cellHeight(side: .right, index: topIndex)
			}
			
			// Scrolls to the top, leaving a possible buffer
			syncScrolling = .left
			table.scrollToRow(at: topIndex, at: .top, animated: true)
		}
	}
	
	// Adds a new cell selection listener to the informed selection listeners
	func registerSelectionListener(_ listener: TableCellSelectionListener)
	{
		if !cellSelectionListeners.contains(where: { $0 === listener })
		{
			cellSelectionListeners.append(listener)
		}
	}
	
	// Removes the listener from the informed selection listeners
	func removeSelectionListener(_ listener: TableCellSelectionListener)
	{
		cellSelectionListeners = cellSelectionListeners.filter { !($0 === listener) }
	}
	
	private func syncScroll(toSide anchorSide: Side, /*velocity: CGFloat = 0, acceleration: CGFloat = 0, */skipIfAnchorStill: Bool = false)
	{
		// Matches either the top or the middle of the two tables
		// This is decided based on whether the virtual keyboard is displayed or not
		let anchorPosition = MatchPosition.current
		let scrolledTable = tableOfSide(anchorSide)
		
		// TODO: THIS CAUSES JITTERING
		guard let newCell = anchorCell(atPosition: anchorPosition, inTable: scrolledTable/*, withVelocity: velocity, andAcceleration: acceleration*/) else
		{
			print("ERROR: No visible cells at \(anchorSide)")
			return
		}
		
		guard !(skipIfAnchorStill && newCell === lastAnchorCell) else
		{
			return
		}
		lastAnchorCell = newCell
		
		// finds the matching cell in the other table
		guard let pathId = (newCell as? ParagraphAssociated)?.pathId else
		{
			print("ERROR: Path id of the cell is not available")
			return
		}
		
		let syncScrollSide = anchorSide.opposite
		let syncTarget = tableOfSide(syncScrollSide)
		
		updateVisibleRowHeights(forTable: scrolledTable)
		updateVisibleRowHeights(forTable: syncTarget)
		
		if let targetIndex = matchIndex(of: pathFinder(syncTarget, pathId), onSide: syncScrollSide, atPosition: anchorPosition)
		{
			// Scrolls the other table so that the matching cell is visible
			syncScrolling = syncScrollSide
			syncTarget.scrollToRow(at: targetIndex, at: anchorPosition.scrollPosition, animated: true)
		}
	}
	
	private func updateVisibleRowHeights(forTable tableView: UITableView)
	{
		guard let visibleRowIndices = tableView.indexPathsForVisibleRows, !visibleRowIndices.isEmpty else
		{
			return
		}
		
		let heightId = currentHeightIds[sideOfTable(tableView)]!
		var totalHeight: CGFloat = 0
		
		for indexPath in visibleRowIndices
		{
			let height = tableView.rectForRow(at: indexPath).height
			cellHeights[heightId]?[indexPath] = height
			totalHeight += height
		}
		
		defaultCellHeight = totalHeight / CGFloat(visibleRowIndices.count)
	}
	
	private func sideOfTable(_ table: AnyObject) -> Side
	{
		if table === leftTableView
		{
			return .left
		}
		else
		{
			return .right
		}
	}
	
	private func tableOfSide(_ side: Side) -> UITableView
	{
		if side == .left
		{
			return leftTableView
		}
		else
		{
			return rightTableView
		}
	}
	
	private func cellHeight(side: Side, index: IndexPath) -> CGFloat
	{
		return cellHeights[currentHeightIds[side]!]![index] ?? defaultCellHeight
	}
	
	private func matchIndex(of indexes: [IndexPath], onSide side: Side, atPosition position: MatchPosition) -> IndexPath?
	{
		guard !indexes.isEmpty else
		{
			return nil
		}
		
		let heightId = currentHeightIds[side]!
		let heights = indexes.map { cellHeights[heightId]![$0].or(defaultCellHeight) }
		let totalHeight = heights.reduce(0, { $0 + $1 })
		
		let matchY = position.targetY(ofHeight: totalHeight)
		
		var y: CGFloat = 0
		for i in 0 ..< indexes.count
		{
			let nextY = y + heights[i]
			
			if nextY > matchY
			{
				return indexes[i]
			}
			
			y = nextY
		}
		
		return nil
	}
	
	// Velocity is in pixels per second
	private func anchorCell(atPosition position: MatchPosition, inTable tableView: UITableView/*, withVelocity velocity: CGFloat, andAcceleration acceleration: CGFloat*/) -> UITableViewCell?
	{
		// Finds the index path of each cell
		guard let indexPaths = tableView.indexPathsForVisibleRows, !indexPaths.isEmpty else
		{
			print("ERROR: No visible cells available")
			return nil
		}
		
		// Finds the height of each cell
		let side = sideOfTable(tableView)
		let cellHeights = indexPaths.map { cellHeight(side: side, index: $0)/*tableView.rectForRow(at: $0).height*/ }
		
		// Calculates the velocity modifier, which depends from dragging state, velocity and deceleration values
		//let duration: CGFloat = isDragging ? 0 : 0.5
		// a = dv / dt
		// s = vt + at^2 / 2
		//let travelDistance = velocity * duration + acceleration * duration * duration / 2
		//print(tableView.contentOffset.y - tableView.rectForRow(at: indexPaths.first!).minY)
		
		// Calculates the height of the visible area
		let totalHeight = tableView.visibleContentHeight //cellHeights.reduce(0, { result, h in return result + h })
		let cellHeightsTotal = cellHeights.reduce(0, +)
		
		// Velocity is also taken into account when determining the anchor cell position (counts 0.5 second reaction time)
		let anchorY = position.targetY(ofHeight: totalHeight) //max(0, min(position.targetY(ofHeight: totalHeight) + travelDistance, totalHeight - 1))
		
		// Finds the anchor cell
		var y: CGFloat = (totalHeight - cellHeightsTotal) * cellHeightDistributionModifier(for: cellHeights) /*tableView.rectForRow(at: indexPaths.first!).minY - tableView.contentOffset.y*/ // Can't use rect for row here
		for i in 0 ..< cellHeights.count
		{
			let nextY = y + cellHeights[i]
			
			if nextY >= anchorY
			{
				return tableView.cellForRow(at: indexPaths[i])
			}
			
			y = nextY
		}
		
		//return tableView.cellForRow(at: indexPaths[indexPaths.count / 2])
		
		// print("ERROR: Couldn't find a cell that would contain y of \(anchorY)")
		return tableView.cellForRow(at: indexPaths.last!)
	}
	
	private func cellHeightDistributionModifier(for cellHeights: [CGFloat]) -> CGFloat
	{
		var upperSideTotal: CGFloat = 1
		var lowerSideTotal: CGFloat = 1
		
		if cellHeights.count < 2
		{
			// If 0-1 cells, no real distribution change
			return 0.5
		}
		else if cellHeights.count == 2
		{
			// 2 Cells, distribution between those two
			upperSideTotal = cellHeights[0]
			lowerSideTotal = cellHeights[1]
		}
		else if cellHeights.count % 2 == 0
		{
			// 4, 6, 8, ... cells, distribution between first and second half
			let splitIndex = cellHeights.count / 2 // Belongs to the latter half
			upperSideTotal = cellHeights[0 ..< splitIndex].reduce(0, +)
			lowerSideTotal = cellHeights[splitIndex ..< cellHeights.count].reduce(0, +)
		}
		else
		{
			// 3, 5, 7, ... cells, excludes center cells and checks distribution against others
			let splitIndex = cellHeights.count / 2 // excluded
			upperSideTotal = cellHeights[0 ..< splitIndex].reduce(0, +)
			lowerSideTotal = cellHeights[splitIndex + 1 ..< cellHeights.count].reduce(0, +)
		}
		
		return upperSideTotal / (upperSideTotal + lowerSideTotal)
	}
}
