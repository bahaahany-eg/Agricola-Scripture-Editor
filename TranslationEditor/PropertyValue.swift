//
//  PropertyValue.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.11.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Property values are used for wrapping JSON compatible values into an easy-to-access general value
struct PropertyValue: CustomStringConvertible, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral, ExpressibleByBooleanLiteral, ExpressibleByFloatLiteral
{
	// ATTRIBUTES	---------
	
	static let empty = PropertyValue()
	
	private let value: Any?
	
	
	// COMP. PROPS	----------
	
	// The JSON representation of this value
	var description: String
	{
		// Pure string values are wrapped in ""
		// For example, compare '"true"' and 'true' or '"Matti"' and 'Matti'
		if let string = value as? String
		{
			return "\"" + string + "\""
		}
		else
		{
			return string()
		}
	}
	
	// Whether the value in this wrapper is nil
	var isEmpty: Bool {return value == nil}
	
	// Whether the value in this wrapper is non-nill
	var isDefined: Bool {return !isEmpty}
	
	var any: Any?
	{
		// Property set values are wrapped into dictionaries
		if let object = value as? PropertySet
		{
			return object.toDict
		}
		// Property value arrays are wrapped into arrays of any
		else if let array = value as? [PropertyValue]
		{
			var anyArray = [Any]()
			for value in array
			{
				if let any = value.any
				{
					anyArray.append(any)
				}
			}
			
			return anyArray
		}
		// Other types stay as they are
		else
		{
			return value
		}
	}
	
	var string: String?
	{
		if let string = value as? String
		{
			return string
		}
		else if let value = value
		{
			return "\(value)"
		}
		
		return nil
	}
	
	var int: Int?
	{
		if let int = value as? Int
		{
			return int
		}
		else if let double = value as? Double
		{
			return Int(double)
		}
		else if let bool = value as? Bool
		{
			return bool ? 1 : 0
		}
		else if let string = value as? String
		{
			if let int = Int(string)
			{
				return int
			}
			else if let double = Double(string)
			{
				return Int(double)
			}
		}
		
		return nil
	}
	
	var double: Double?
	{
		if let double = value as? Double
		{
			return double
		}
		else if let int = value as? Int
		{
			return Double(int)
		}
		else if let bool = value as? Bool
		{
			return bool ? 1.0 : 0.0
		}
		else if let string = value as? String
		{
			return Double(string)
		}
		
		return nil
	}
	
	var bool: Bool?
	{
		if let bool = value as? Bool
		{
			return bool
		}
		else if let int = value as? Int
		{
			return int != 0
		}
		else if let double = value as? Double
		{
			return double != 0.0
		}
		else if let string = value as? String
		{
			return string == "true"
		}
		
		return nil
	}
	
	var object: PropertySet?
	{
		if let object = value as? PropertySet
		{
			return object
		}
		
		return nil
	}
	
	var array: [PropertyValue]?
	{
		if let array = value as? [PropertyValue]
		{
			return array
		}
		
		return nil
	}
	
	
	// SUBSCRIPT	------
	
	subscript(propertyName: String) -> PropertyValue
	{
		return object()[propertyName]
	}
	
	subscript(index: Int) -> PropertyValue
	{
		if let array = array
		{
			if index >= 0 && index < array.count
			{
				return array[index]
			}
		}
		
		return PropertyValue.empty
	}
	
	
	// INIT	----------
	
	init(integerLiteral value: Int)
	{
		self.value = value
	}
	
	init(stringLiteral value: String)
	{
		self.value = value
	}
	
	init(unicodeScalarLiteral value: String)
	{
		self.value = value
	}
	
	init(extendedGraphemeClusterLiteral value: String)
	{
		self.value = value
	}
	
	init(booleanLiteral value: Bool)
	{
		self.value = value
	}
	
	init(floatLiteral value: Double)
	{
		self.value = value
	}
	
	init(_ str: String?)
	{
		value = str
	}
	
	init(_ bool: Bool?)
	{
		value = bool
	}
	
	init(_ int: Int?)
	{
		value = int
	}
	
	init(_ double: Double?)
	{
		value = double
	}
	
	init(_ object: PropertySet?)
	{
		value = object
	}
	
	/*
	init(_ object: JSONConvertible?)
	{
		self.init(object?.toPropertySet)
	}*/
	
	init(_ array: [PropertyValue]?)
	{
		value = array
	}
	
	init(_ array: [PropertyValueWrapable]?)
	{
		self.init(array?.map { $0.value })
	}
	
	/*
	init(_ array: [JSONConvertible]?)
	{
		self.init(array, { PropertyValue($0) })
	}*/
	
	private init(any: Any? = nil)
	{
		value = any
	}
	
	// TODO: Use protocol instead
	// Wraps an object into a property value, if possible
	// Only strings, booleans, integers and double, property set (or [String : Any]) 
	// and arrays ([PropertyValue] or [Any]) can be wrapped as property values
	// Also JSON convertible objects and arrays consisting of them can be wrapped into values
	// If the provided value is not of any of those types, nil is returned
	static func of(_ any: Any?) -> PropertyValue?
	{
		// Propertyvalues are not wrapped further
		if let value = any as? PropertyValue
		{
			return value
		}
		else if any is String || any is Int || any is Double || any is Bool || any is PropertySet || any is [PropertyValue]
		{
			return PropertyValue(any: any)
		}
		else if let wrapable = any as? PropertyValueWrapable
		{
			return wrapable.value
		}
		else if let array = any as? [PropertyValueWrapable]
		{
			return PropertyValue(array)
		}
		else if let dict = any as? [String : Any]
		{
			return PropertyValue(PropertySet(dict))
		}
		else if let array = any as? [Any]
		{
			var propertyArray = [PropertyValue]()
			for any in array
			{
				if let value = PropertyValue.of(any)
				{
					propertyArray.append(value)
				}
			}
			
			return PropertyValue(propertyArray)
		}
		else
		{
			return nil
		}
	}
	
	
	// OTHER METHODS	------
	
	func string(or defaultString: String = "") -> String
	{
		if let str = string
		{
			return str
		}
		else
		{
			return defaultString
		}
	}
	
	func int(or defaultInt: Int = 0) -> Int
	{
		if let int = int
		{
			return int
		}
		else
		{
			return defaultInt
		}
	}
	
	func double(or defaultDouble: Double = 0.0) -> Double
	{
		if let double = double
		{
			return double
		}
		else
		{
			return defaultDouble
		}
	}
	
	func time(or defaultTime: TimeInterval = Date().timeIntervalSince1970) -> TimeInterval
	{
		return double(or: defaultTime)
	}
	
	func bool(or defaultBool: Bool = false) -> Bool
	{
		if let bool = bool
		{
			return bool
		}
		else
		{
			return defaultBool
		}
	}
	
	func object(or defaultObject: PropertySet = PropertySet.empty) -> PropertySet
	{
		if let object = object
		{
			return object
		}
		else
		{
			return defaultObject
		}
	}
	
	func array(or defaultArray: [PropertyValue] = []) -> [PropertyValue]
	{
		if let array = array
		{
			return array
		}
		else
		{
			return defaultArray
		}
	}
	
	// Maps the value to a specific type of array. Non-mapable values are ignored
	func array<T>(_ f: (PropertyValue) throws -> T?) rethrows -> [T]
	{
		if let array = array
		{
			return try array.compactMap(f)
		}
		else
		{
			return []
		}
	}
	
	
	// Maps the value to a specific type of dictionary. Non-mapable values are ignored
	func object<T>(_ f: (PropertyValue) throws -> T?) rethrows -> [String: T]
	{
		if let object = object
		{
			return try object.properties.flatMapValues(f)
		}
		else
		{
			return [:]
		}
	}
}
