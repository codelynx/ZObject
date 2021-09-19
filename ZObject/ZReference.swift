//
//	ZReference.swift
//	ZObject
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import Foundation

/*
class ZReference<T: ZObject> {
	private unowned let storage: ZStorage
	let type: ZObject.Type
	let identifier: Int
	init(storage: ZStorage, type: ZObject.Type, identifier: Int) {
		self.storage = storage
		self.type = type
		self.identifier = identifier
	}
	init(_ object: T) {
		self.storage = object.storage
		self.type = T.self
		self.identifier = object.identifier
	}
	func object() -> T? {
		let object: T? = self.storage.instanciateObject(identifier: self.identifier)
		return object
	}
}
*/

public class ZReferences<T: ZObject> {
	var identifiers: [Int]
	class var idsKey: String { return "ids" }
	init(objects: [T]) {
		self.identifiers = objects.map { $0.identifier }
	}
	init?(coder: NSCoder) {
		self.identifiers = coder.decodeObject(forKey: Self.idsKey) as! [Int]
	}
	init(identifiers: [Int]) {
		self.identifiers = identifiers
	}
}
