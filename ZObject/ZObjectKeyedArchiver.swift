//
//	ZObjectKeyedArchiver.swift
//	ZObject
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import Foundation

public class ZObjectKeyedArchiver: NSKeyedArchiver {
	
	private static let semaphore = DispatchSemaphore(value: 1)
	private static var storage: ZStorage?
	private (set) public var _storage: ZStorage?

	class func archivedData(withRootObject object: Any, requiringSecureCoding requiresSecureCoding: Bool, storage: ZStorage) throws -> Data {
		Self.semaphore.wait()
		Self.storage = storage
		return try super.archivedData(withRootObject: object, requiringSecureCoding: requiresSecureCoding)
	}
	override init() {
		self._storage = Self.storage
		super.init()
		Self.semaphore.signal()
	}
	override init(requiringSecureCoding requiresSecureCoding: Bool) {
		self._storage = Self.storage
		super.init(requiringSecureCoding: requiresSecureCoding)
	}
}

public class ZObjectKeyedUnarchiver: NSKeyedUnarchiver {
	
	private static let semaphore = DispatchSemaphore(value: 1)
	private static var storage: ZStorage?
	private (set) public var _storage: ZStorage?

	class func unarchiveTopLevelObjectWithData(_ data: Data, storage: ZStorage) throws -> Any? {
		Self.semaphore.wait()
		Self.storage = storage
		return try super.unarchiveTopLevelObjectWithData(data)
	}
	override init(forReadingWith data: Data) {
		self._storage = Self.storage
		super.init(forReadingWith: data)
		Self.storage = nil
		Self.semaphore.signal()
	}
	override init(forReadingFrom data: Data) throws {
		self._storage = Self.storage
		try super.init(forReadingFrom: data)
		self.decodingFailurePolicy = .setErrorAndReturn
		Self.storage = nil
		Self.semaphore.signal()
	}
}

public extension NSCoder {
	var storage: ZStorage? {
		if let archiver = self as? ZObjectKeyedArchiver {
			return archiver._storage
		}
		if let unarchiver = self as? ZObjectKeyedUnarchiver {
			return unarchiver._storage
		}
		return nil
	}
}
