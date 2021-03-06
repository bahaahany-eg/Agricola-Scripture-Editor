//
//  VersionCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This cell displays a single version of a paragraph
// The cells are generally used for comparing and choosing between different conflicting versions
class VersionCell: UICollectionViewCell
{
    // OUTLETS	-------------
	
	@IBOutlet weak var authorLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var contentTextView: UITextView!
	
	
	// ATTRIBUTES	---------
	
	static let identifier = "VersionCell"
	
	
	// OTHER METHODS	----
	
	func configure(author: String, created: Date, content: Paragraph)
	{
		authorLabel.text = "\(author) \(NSLocalizedString("wrote", comment: "Part of conflict version description. Preceeded by author name"))"
		
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		
		timeLabel.text = formatter.string(from: created)

		contentTextView.display(paragraph: content)
		
		print("STATUS: Setting up cell for \(author)")
	}
}
