//
//  USXCrossReferenceProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This USX content processor generates Cross References based on the collected char data
class USXCrossReferenceProcessor: USXContentProcessor
{
	// TYPES	--------------------------
	
	typealias Generated = CrossReference
	typealias Processed = CharData
	
	
	// ATTRIBUTES	----------------------
	
	private let style: CrossReferenceStyle
	private let caller: String
	private let verseIndex: VerseIndex?
	
	
	// INIT	------------------------------
	
	init(caller: String, style: CrossReferenceStyle, lastVerseIndex: VerseIndex?)
	{
		self.caller = caller
		self.style = style
		self.verseIndex = lastVerseIndex
	}
	
	// Creates a new parser for a note element
	// The parser should start after the note element start
	// The parser will stop at the end of the note element (or at the next verse marker, if the content is somehow malformed like that)
	static func createParser(caller: XMLParserDelegate, callerAttValue: String, style: CrossReferenceStyle, lastVerseIndex: VerseIndex?, targetPointer: UnsafeMutablePointer<[CrossReference]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<CrossReference, CharData>
	{
		let parser = USXContentParser<Generated, Processed>(caller: caller, containingElement: .note, lowestBreakMarker: .verse, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXCrossReferenceProcessor(caller: callerAttValue, style: style, lastVerseIndex: lastVerseIndex))
		
		return parser
	}
	
	
	// IMPLEMENTED METHODS	--------------
	
	func getParser(_ caller: USXContentParser<CrossReference, CharData>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[CharData]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// Character content parsing is delegated to a CharData parser
		if elementName == USXContainerElement.char.rawValue
		{
			return (USXCharParser(caller: caller, targetData: targetPointer), true)
		}
		else
		{
			print("ERROR: Unknown element \(elementName) in USXCrossReferenceParser")
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<CrossReference, CharData>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[CharData]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Footnotes should not contain any raw character data. However, if there is some, it is parsed too
		print("ERROR: Raw character data in USXCrossReferenceParser")
		return USXCharParser(caller: caller, targetData: targetPointer)
	}
	
	func generate(from content: [CharData], using errorHandler: @escaping ErrorHandler) -> CrossReference?
	{
		var originIndex = verseIndex
		
		// Checks if the origin reference can be parsed from character data
		if let originReference = content.first(where: { $0.style == .crossReferenceOriginReference })
		{
			if let startIndex = originReference.text.range(of: ".")?.upperBound
			{
				let remaining = originReference.text.suffix(from: startIndex)
				
				if let endIndex = remaining.rangeOfCharacter(from: CharacterSet(charactersIn: ",. :-"))?.lowerBound
				{
					originIndex = VerseIndex.parse(from: String(remaining.prefix(upTo: endIndex))) ?? originIndex
				}
			}
		}
		
		return CrossReference(caller: caller, style: style, charData: content, originVerseIndex: originIndex)
	}
}
