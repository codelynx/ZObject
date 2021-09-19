//
//	ZObject.swift
//	ZObject
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import Foundation

open class ZObject: NSObject, NSCoding {
	private static let idKey = "id"
	public weak var storage: ZStorage?
	public var identifier: Int
	public init(storage: ZStorage) throws {
		self.identifier = -1
		self.storage = storage
		super.init()
		try storage.insert(object: self)
		assert(self.identifier != -1)
	}
	public init(identifier: Int, storage: ZStorage) throws {
		self.identifier = identifier
		self.storage = storage
		super.init()
	}
	required public init?(coder: NSCoder) {
		self.identifier = coder.decodeInteger(forKey: Self.idKey)
		self.storage = coder.storage!
		super.init()
	}
	deinit {
	}
	open func encode(with coder: NSCoder) {
		coder.encode(self.identifier, forKey: Self.idKey)
		self.storage = coder.storage!
	}
	open func save(storage: ZStorage?) throws {
		guard let storage = storage ?? self.storage else { throw ZStorageError.storageNotFound }
		try storage.save(object: self)
	}
	public func refcount() throws -> Int {
		guard let storage = self.storage else { fatalError() }
		return try storage.refcount(object: self)
	}
	public func keep() throws {
		guard let storage = self.storage else { fatalError() }
		try storage.keep(object: self)
	}
	public func waste() throws {
		guard let storage = self.storage else { fatalError() }
		try storage.waste(object: self)
	}
}
