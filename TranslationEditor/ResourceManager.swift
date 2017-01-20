//
//  ResourceManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate struct BookData
{
	let book: Book
	let binding: ParagraphBinding
	let datasource: TranslationTableViewDS
}

fileprivate struct NotesData
{
	let resource: ResourceCollection
	let datasource: NotesTableDS
}

// This class handles the functions concerning the resource table
class ResourceManager
{
	// ATTRIBUTES	-----------
	
	private weak var resourceTableView: UITableView?
	
	private var sourceBooks = [BookData]()
	private var notes = [NotesData]()
	
	private var currentLiveResource: LiveResource?
	private var currentResourceIndex: Int?
	
	
	// INIT	-------------------
	
	init(resourceTableView: UITableView)
	{
		self.resourceTableView = resourceTableView
	}
	
	
	// OTHER METHODS	-------
	
	func setResources(sourceBooks: [(Book, ParagraphBinding)], notes: [ResourceCollection])
	{
		// TODO: Deactivate old resources if they are not present anymore
		
		self.sourceBooks = sourceBooks.map
		{
			book, binding in
			
			return BookData(book: book, binding: binding, datasource: TranslationTableViewDS(tableView: resourceTableView!, cellReuseId: "sourceCell", bookId: book.idString))
		}
		
		self.notes = notes.map { NotesData(resource: $0, datasource: NotesTableDS(tableView: resourceTableView!, resourceCollectionId: $0.idString)) }
	}
	
	func indexPathsForTargetPathId(_ targetPathId: String) -> [IndexPath]
	{
		// No selected resource -> No index paths
		guard let currentResourceIndex = currentResourceIndex else
		{
			return []
		}
		
		if currentResourceIndex < sourceBooks.count
		{
			let sourceBookData = sourceBooks[currentResourceIndex]
			return sourceBookData.binding.sourcesForTarget(targetPathId).flatMap { sourceBookData.datasource.indexForPath($0) }
		}
		else
		{
			let notesData = notes[currentResourceIndex - sourceBooks.count]
			return notesData.datasource.indexesForPath(targetPathId)
		}
	}
	
	func targetPathsForSourcePath(_ sourcePathId: String) -> [String]
	{
		// No selected resource -> No path
		guard let currentResourceIndex = currentResourceIndex else
		{
			return []
		}
		
		// In translation data, bindings are used
		if currentResourceIndex < sourceBooks.count
		{
			return sourceBooks[currentResourceIndex].binding.targetsForSource(sourcePathId)
		}
		// Notes are already using the same path ids
		else
		{
			return [sourcePathId]
		}
	}
}
