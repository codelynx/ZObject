//
//	ZStorage.swift
//	ZObject
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import Foundation
import SQLite3


public enum ZStorageError: String, Error {
	case rollback
	case failedInstanciatingObject
	case storageNotFound
	case internalError
}

open class ZStorage: NSObject {

	private static let objectTableKey = "object"
	private static let idKey = "id"
	private static let typeColumnKey = "type"
	private static let dataColumnKey = "data"
	private static let refcountKey = "refcount"

	static private (set) var counter = 0
	let database: ZSQLDatabase
	let fileURL: URL

	public init(fileURL: URL) throws {
		typealias U = ZStorage
		self.fileURL = fileURL
		try self.database = ZSQLDatabase(fileURL: fileURL)
		let query = try self.database.query("""
			CREATE TABLE IF NOT EXISTS \(U.objectTableKey)(
				\(U.idKey) INTEGER PRIMARY KEY AUTOINCREMENT,
				\(U.typeColumnKey) TEXT NOT NULL,
				\(U.dataColumnKey) BINARY,
				\(U.refcountKey) INTEGER NOT NULL
			);
		""")
		let result = query.step()
		guard result.done else { throw ZSQLStatus(result) }
	}

	deinit {
		print(Self.self, "deallocating:", self.fileURL.path)
		Self.counter -= 1
	}

	public var errorMessage: String? { return self.database.errorMessage }

	private var objectCache = NSMapTable<NSNumber, ZObject>.strongToWeakObjects()

	public func foget(objects: [ZObject]) {
		for object in objects {
			objectCache.removeObject(forKey: object.identifier as NSNumber)
		}
	}

	public func isCashed(object: ZObject) -> Bool {
		if let cachedObject = self.objectCache.object(forKey: object.identifier as NSNumber), cachedObject.identifier == object.identifier { return true }
		else { return false }
	}

	public func countObjects<T: ZObject>(of objectType: T.Type) throws -> Int {
		typealias U = ZStorage
		let typeString = String(describing: T.self)
		let query = try self.database.query("SELECT COUNT(*) FROM \(U.objectTableKey) WHERE \(U.typeColumnKey) = '\(typeString)' AND \(U.refcountKey) > 0;")
		guard let count = query.step().row?.value(index: 0) as Int? else { fatalError() }
		return count
	}

	public func makeReferences<T: ZObject>(of objectType: T.Type) throws -> ZReferences<T> {
		typealias U = ZStorage
		let typeString = String(describing: T.self)
		let query = try self.database.query(
			"SELECT \(U.idKey), \(U.typeColumnKey) FROM \(U.objectTableKey) WHERE \(U.typeColumnKey) = '\(typeString)' AND \(U.refcountKey) > 0;"
		)
		var identifiers = [Int]()
		while let row = query.step().row {
			if let identifier = row[U.idKey] as? Int {
				identifiers.append(identifier)
			}
		}
		return ZReferences(identifiers: identifiers)
	}

	public func instanciateObjects<T: ZObject>(identifiers: [Int], of objectType: T.Type) throws -> [T] {
		typealias U = ZStorage
		let typeString = String(describing: T.self)
		let identifiersList = identifiers.map { String($0) }.joined(separator: ",")
		let query = try self.database.query("""
			SELECT \(U.idKey), \(U.typeColumnKey), \(U.dataColumnKey) FROM \(U.objectTableKey)
			WHERE \(U.typeColumnKey) = '\(typeString)' AND \(U.idKey) IN (\(identifiersList)) AND \(U.refcountKey) > 0;
		""")
		var objects = [T]()
		while let row = query.step().row {
			
			guard let identifier: Int = row[U.idKey] as? Int else { fatalError() }
			if let object = self.objectCache.object(forKey: identifier as NSNumber) as? T  {
				objects.append(object)
			}
			else if let typeString = row[U.typeColumnKey] as? String, let data = row[U.dataColumnKey] as? Data {
				if let object = try? ZObjectKeyedUnarchiver.unarchiveTopLevelObjectWithData(data, storage: self) as? T {
					let objectType = String(describing: type(of: object))
					if objectType != typeString {
						print("\(Self.self): type mismatch, it is expected '\(typeString)' but '\(objectType)' id=\(identifier)")
					}
					objects.append(object)
					self.objectCache.setObject(object, forKey: identifier as NSNumber)
				}
				else { fatalError("\(Self.self): unable to unarchive an object id=\(identifier)") }
			}
			else { fatalError() }
		}
		return objects
	}

	public func instanciateObject<T: ZObject>(identifier: Int, of objectType: T.Type) throws -> T? {
		return try self.instanciateObjects(identifiers: [identifier], of: T.self).first
	}

	public func instanciateObjects<T: ZObject>(reference: ZReferences<T>) throws -> [T] {
		return try self.instanciateObjects(identifiers: reference.identifiers, of: T.self)
	}

	public func instanciateObjects<T: ZObject>(of objectType: T.Type) throws -> [T] {
		typealias U = ZStorage
		let typeString = String(describing: T.self)
		let query = try self.database.query(
			"SELECT \(U.idKey), \(U.typeColumnKey), \(U.dataColumnKey) FROM \(U.objectTableKey) WHERE \(U.typeColumnKey) = '\(typeString)' AND \(U.refcountKey) > 0;"
		)
		var objects = [T]()
		while let row = query.step().row {
			guard let identifier = row[U.idKey] as? Int else { continue }
			if let object = self.objectCache.object(forKey: identifier as NSNumber) as? T  {
				objects.append(object)
			}
			else if let typeString = row[U.typeColumnKey] as? String, let data = row[U.dataColumnKey] as? Data {
				if let object = try? ZObjectKeyedUnarchiver.unarchiveTopLevelObjectWithData(data, storage: self) as? T {
					let objectType = String(describing: type(of: object))
					if objectType != typeString {
						print("\(Self.self): type mismatch, it is expected '\(typeString)' but '\(objectType)' id=\(identifier)")
					}
					objects.append(object)
					self.objectCache.setObject(object, forKey: identifier as NSNumber)
				}
				else { fatalError("\(Self.self): unable to unarchive an object id=\(identifier)") }
			}
			else { fatalError() }
		}
		return objects
	}

	private func columnNames(statement: OpaquePointer) -> [String] {
		let numberOfColumns = sqlite3_column_count(statement)
		return (0..<numberOfColumns).map { NSString(utf8String: sqlite3_column_name(statement, $0))! as String }
	}

	public func insert<T: ZObject>(object: T) throws {
		typealias T = ZStorage
		let data = try! ZObjectKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false, storage: self)
		let typeString = String(describing: type(of: object))
		let refcount = 1
		let query = try self.database.query(
				"INSERT INTO \(T.objectTableKey) (\(T.typeColumnKey), \(T.dataColumnKey), \(T.refcountKey)) VALUES (?1, ?2, ?3);",
				typeString, data, refcount)
		let result = query.step()
		guard result.done else { throw ZSQLStatus(result)  }
		let identifier = self.database.lastInsertRowID
		object.identifier = Int(identifier)
		object.storage = self
		self.objectCache.setObject(object, forKey: identifier as NSNumber)
	}

	public func save<T: ZObject>(object: T) throws {
		if object.storage == self { try self.update(object: object) }
		else { try self.insert(object: object) }
	}

	public func update<T: ZObject>(object: T) throws {
		typealias T = ZStorage
		assert(object.storage == self)
		guard object.identifier > 0 else { return }
		let identifier = object.identifier
		let data = try! ZObjectKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false, storage: self)
		let typeString = String(describing: type(of: object))
		let query = try self.database.query(
			"UPDATE \(T.objectTableKey) SET \(T.dataColumnKey) = ?1, \(T.typeColumnKey) = ?2  WHERE \(T.idKey) = \(identifier);",
			data, typeString)
		let result = query.step()
		guard result.done else { throw ZSQLStatus(result) }
	}

	public func refcount(object: ZObject) throws -> Int {
		typealias U = ZStorage
		let identifier = object.identifier
		let query = try self.database.query(
			"SELECT \(U.idKey), \(U.refcountKey) FROM \(U.objectTableKey) WHERE \(U.idKey) = \(identifier);"
		)
		let result = query.step()
		guard let row = result.row else { fatalError() }
		guard let refcount = row[U.refcountKey] as? Int else { fatalError() }
		return refcount
	}

	public func keep(objects: [ZObject]) throws {
		typealias U = ZStorage
		let identifiersList = objects.map { String($0.identifier) }.joined(separator: ",")
		let query = try self.database.query("UPDATE \(U.objectTableKey) SET \(U.refcountKey) = \(U.refcountKey) + 1  WHERE \(U.idKey) IN (\(identifiersList));")
		_ = query.step()
	}

	public func unkeep(objects: [ZObject]) throws {
		typealias U = ZStorage
		let identifiersList = objects.map { String($0.identifier) }.joined(separator: ",")
		let query = try self.database.query("UPDATE \(U.objectTableKey) SET \(U.refcountKey) = \(U.refcountKey) - 1  WHERE \(U.idKey) IN (\(identifiersList));")
		_ = query.step()
	}

	public func keep(object: ZObject) throws {
		try self.keep(objects: [object])
	}
	
	public func waste(object: ZObject) throws {
		try self.unkeep(objects: [object])
	}

	public func delete<T: ZObject>(object: T) throws {
		typealias T = ZStorage
		guard object.identifier > 0 else { return }
		let identifier = object.identifier
		let query = try self.database.query(
			"DELETE FROM \(T.objectTableKey) WHERE \(T.idKey)=\(identifier);"
		)
		let result = query.step()
		guard result.done else { fatalError() }
		self.objectCache.removeObject(forKey: identifier as NSNumber)
	}
	public var autocommit: Bool {
		return self.database.autocommit
	}

	public var underTransaction: Bool {
		return self.database.underTransaction
	}

	public func committing(closure: (() throws ->())) throws {
		let query1 = try self.database.query("BEGIN TRANSACTION;")
		guard query1.step().done else { fatalError() }
		do {
			try closure()
			let query2 = try self.database.query("COMMIT")
			guard query2.step().done else { fatalError() }
		}
		catch {
			let query2 = try self.database.query("ROLLBACK")
			guard query2.step().done else { fatalError() }
		}
	}

	
}


