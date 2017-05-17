//
//  BookProgressStatus.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is a simple struct for storing book completion status
struct BookProgressStatus: Comparable
{
	// ATTRIBUTES	---------------
	
	// How many paragraphs does the book contain in total (size)
	var paragraphAmount: Int
	// How many of the paragraphs are still empty
	var emptyParagraphAmount: Int
	// How many total commits (exluding empty versions) have been made
	var totalCommits: Int
	
	
	// COMPUTED PROPERTIES	-------
	
	// How many paragraphs have already been filled (first draft)
	var filledParagraphAmount: Int { return paragraphAmount - emptyParagraphAmount }
	
	// The 'completion rate' of the book
	// This reflects the quantity of the translation
	var fullness: Double
	{
		if paragraphAmount == 0
		{
			return 0
		}
		else
		{
			return Double(filledParagraphAmount) / Double(paragraphAmount)
		}
	}
	
	// How many commits there are per single filled paragraph on average
	// This reflects the quality of the translation
	var averageCommitsPerParagraph: Double
	{
		if filledParagraphAmount == 0
		{
			return 0
		}
		else
		{
			return Double(totalCommits) / Double(filledParagraphAmount)
		}
	}
	
	
	// OPERATORS	---------------
	
	static func ==(_ left: BookProgressStatus, _ right: BookProgressStatus) -> Bool
	{
		return left.paragraphAmount == right.paragraphAmount && left.emptyParagraphAmount == right.emptyParagraphAmount && left.totalCommits == right.totalCommits
	}
	
	static func <(_ left: BookProgressStatus, _ right: BookProgressStatus) -> Bool
	{
		return left.fullness.compare(with: right.fullness) ?? left.averageCommitsPerParagraph.compare(with: right.averageCommitsPerParagraph) ?? left.totalCommits.compare(with: right.totalCommits) ?? (left.paragraphAmount < right.paragraphAmount)
	}
}
