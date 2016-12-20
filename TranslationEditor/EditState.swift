//
//  EditState.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These structs define a runtime editing state of a paragraph
/*
enum EditState
{
	case notChanged
	case edited(originalId: String, text: NSAttributedString)
}*/


struct EditState
{
	var text: NSAttributedString
	var isConflict = false
}