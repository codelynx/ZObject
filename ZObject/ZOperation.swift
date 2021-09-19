//
//	ZOperation.swift
//	ZObject
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import Foundation

public protocol ZOperation: ZObject {
	func perform()
	func undo()
	func redo()
}

