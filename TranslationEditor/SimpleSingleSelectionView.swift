//
//  SimpleSingleSelectionView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation


// This delegate handles reactions to value selections for the view
protocol SimpleSingleSelectionViewDelegate: class
{
	// This function is called whenever a new item is selected
	func onValueChanged(_ newValue: String, selectedAt index: Int?)
}

// This view can be used for selecting a single element from a list that can be filtered
// The view also supports addition of new elements
@IBDesignable class SimpleSingleSelectionView: CustomXibView, UITableViewDataSource, UITableViewDelegate
{
	// OUTLETS	--------------
	
	@IBOutlet weak var selectionTableView: UITableView!
	@IBOutlet weak var insertField: UITextField!
	
	
	// ATTRIBUTES	----------
	
	weak var delegate: SimpleSingleSelectionViewDelegate?
	weak var datasource: FilteredSelectionDataSource?
	
	private var value = ""
	private(set) var selectedIndex: Int?
	private var displayedIndices = [Int]()
	
	
	// INIT	------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "SimpleSingleSelection")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "SimpleSingleSelection")
	}
	
	override func awakeFromNib()
	{
		selectionTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		
		selectionTableView.dataSource = self
		selectionTableView.delegate = self
	}
	
	
	// ACTIONS	--------------
	
	@IBAction func valueChanged(_ sender: Any)
	{
		value = insertField.trimmedText
		selectedIndex = nil
		selectionTableView.selectRow(at: nil, animated: false, scrollPosition: .none)
		reloadData()
	}
	
	@IBAction func valueEditingEnded(_ sender: Any)
	{
		informDelegate()
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return displayedIndices.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
		
		if let datasource = datasource
		{
			cell.configure(text: datasource.labelForOption(atIndex: displayedIndices[indexPath.row]))
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		select(index: displayedIndices[indexPath.row])
	}
	
	
	// OTHER METHODS	-------
	
	func reloadData()
	{
		guard let datasource = datasource else
		{
			print("ERROR:  SimpleSingleSelectionView doesn't have a datasource to use")
			return
		}
		
		// Updates the displayed indices
		if !value.isEmpty
		{
			displayedIndices = (0 ..< datasource.numberOfOptions).flatMap { ($0 == selectedIndex || datasource.indexIsIncludedInFilter(index: $0, filter: value)) ? $0 : nil }
		}
		else
		{
			displayedIndices = Array(0 ..< datasource.numberOfOptions)
		}
		
		selectionTableView.reloadData()
		
		if let selectedIndex = selectedIndex, let selectedTableIndex = displayedIndices.index(where: { $0 == selectedIndex })
		{
			selectionTableView.selectRow(at: IndexPath(row: selectedTableIndex, section: 0), animated: false, scrollPosition: .top)
		}
	}
	
	private func select(index: Int)
	{
		selectedIndex = index
		
		if let datasource = datasource
		{
			value = datasource.labelForOption(atIndex: index)
			insertField.text = value
			reloadData()
		}
		
		informDelegate()
	}
	
	private func informDelegate()
	{
		delegate?.onValueChanged(value, selectedAt: selectedIndex)
	}
}