//
//  ConnectionListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Classes conforming to this protocol react to connection status changes
protocol ConnectionListener: class
{
	// This function will be called when the connection status changes
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	
	// This function will be called when the transfer progres updates
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
}
