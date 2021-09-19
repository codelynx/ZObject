//
//	ZSQL.swift
//	ZObject
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import Foundation
import SQLite3

public struct ZSQLStatus: Error, CustomStringConvertible {
	let status: Int32
	public init(_ status: Int32) {
		self.status = status
	}
	public init(_ result: ZSQLResult) {
		self.status = result.status
	}
	public var description: String {
		switch self.status {
		case SQLITE_OK: return "SQLITE_OK: Successful result"
		case SQLITE_ERROR: return "SQLITE_ERROR: Generic error"
		case SQLITE_INTERNAL: return "SQLITE_INTERNAL: Internal logic error in SQLite"
		case SQLITE_PERM: return "SQLITE_PERM: Access permission denied"
		case SQLITE_ABORT: return "SQLITE_ABORT: Callback routine requested an abort"
		case SQLITE_BUSY: return "SQLITE_BUSY: The database file is locked"
		case SQLITE_LOCKED: return "SQLITE_LOCKED: A table in the database is locked"
		case SQLITE_NOMEM: return "SQLITE_NOMEM: A malloc() failed"
		case SQLITE_READONLY: return "SQLITE_READONLY: Attempt to write a readonly database"
		case SQLITE_INTERRUPT: return "SQLITE_INTERRUPT: Operation terminated by sqlite3_interrupt()"
		case SQLITE_IOERR: return "SQLITE_INTERRUPT: Some kind of disk I/O error occurred"
		case SQLITE_CORRUPT: return "SQLITE_CORRUPT: The database disk image is malformed"
		case SQLITE_NOTFOUND: return "SQLITE_NOTFOUND: Unknown opcode in sqlite3_file_control()"
		case SQLITE_FULL: return "SQLITE_FULL: Insertion failed because database is full"
		case SQLITE_CANTOPEN: return "SQLITE_CANTOPEN: Unable to open the database file"
		case SQLITE_PROTOCOL: return "SQLITE_PROTOCOL: Database lock protocol error"
		case SQLITE_EMPTY: return "SQLITE_EMPTY: Internal use only"
		case SQLITE_SCHEMA: return "SQLITE_SCHEMA: The database schema changed"
		case SQLITE_TOOBIG: return "SQLITE_TOOBIG: String or BLOB exceeds size limit"
		case SQLITE_CONSTRAINT: return "SQLITE_CONSTRAINT: Abort due to constraint violation"
		case SQLITE_MISMATCH: return "SQLITE_MISMATCH: Data type mismatch"
		case SQLITE_MISUSE: return "SQLITE_MISUSE: Library used incorrectly"
		case SQLITE_NOLFS: return "SQLITE_NOLFS: Uses OS features not supported on host"
		case SQLITE_AUTH: return "SQLITE_AUTH: Authorization denied"
		case SQLITE_FORMAT: return "SQLITE_FORMAT: Not used"
		case SQLITE_RANGE: return "SQLITE_RANGE: 2nd parameter to sqlite3_bind out of range"
		case SQLITE_NOTADB: return "SQLITE_NOTADB: File opened that is not a database file"
		case SQLITE_NOTICE: return "SQLITE_NOTICE: Notifications from sqlite3_log()"
		case SQLITE_WARNING: return "SQLITE_WARNING: Warnings from sqlite3_log()"
		case SQLITE_ROW: return "SQLITE_ROW: sqlite3_step() has another row ready"
		case SQLITE_DONE: return "SQLITE_DONE: sqlite3_step() has finished executing"
		default: return "Unknown SQLITE status \(self.status)"
		}
	}
}

enum ZSQLError: Error {
	case failedOpenFile
	case columnNotFound
}

public class ZSQLDatabase {
	let fileURL: URL
	private (set) var database: OpaquePointer?
	private (set) var status: Int32
	public init(fileURL: URL) throws {
		self.fileURL = fileURL
		self.status = sqlite3_open(fileURL.path, &self.database)
		guard self.status == SQLITE_OK else { fatalError(self.errorMessage ?? ZSQLStatus(self.status).description) }
	}
	public var errorMessage: String? { String(utf8String: sqlite3_errmsg(self.database)) }
	public func query(_ query: String, _ arguments: ZSQLColumnValue...) throws -> ZSQLQuery {
		return try ZSQLQuery(database: self, query: query, arguments: arguments)
	}
	public var lastInsertRowID: Int {
		return Int(sqlite3_last_insert_rowid(self.database))
	}
	public var autocommit: Bool {
		return sqlite3_get_autocommit(self.database) != 0
	}
	public var underTransaction: Bool {
		return !self.autocommit
	}
}

public class ZSQLQuery {
	let database: ZSQLDatabase
	let query: String
	private (set) var statement: OpaquePointer?
	private (set) var status: Int32
	init(database: ZSQLDatabase, query: String, arguments: [ZSQLColumnValue]) throws {
		self.database = database
		self.query = query
		self.status = sqlite3_prepare_v2(self.database.database, query, -1, &self.statement, nil)
		guard self.status == SQLITE_OK else { throw ZSQLStatus(self.status) }
		
		for (index, argment) in arguments.enumerated() {
			let index = Int32(index + 1)
			switch argment {
			case let value as Int:
				sqlite3_bind_int64(self.statement, index, sqlite3_int64(value))
			case let value as Double:
				sqlite3_bind_double(self.statement, index, value)
			case let value as String:
				sqlite3_bind_text(self.statement, index, (value as NSString).utf8String, -1, nil)
			case let value as Data:
				sqlite3_bind_blob(self.statement, index, (value as NSData).bytes, Int32(value.count), nil)
			case is NSNull:
				sqlite3_bind_null(self.statement, index)
			default:
				break
			}
		}
	}
	deinit {
		sqlite3_finalize(statement)
	}
	func step() -> ZSQLResult {
		self.status = sqlite3_step(statement)
		let result = ZSQLResult(status: self.status, statement: self.statement, query: self)
		self.result = result
		return result
	}
	var result: ZSQLResult?
}

public protocol ZSQLColumnValue {}
extension Int: ZSQLColumnValue {}
extension Double: ZSQLColumnValue {}
extension String: ZSQLColumnValue {}
extension Data: ZSQLColumnValue {}
extension NSNull: ZSQLColumnValue {}

public class ZSQLResult {
	let status: Int32
	let statement: OpaquePointer?
	let query: ZSQLQuery
	init(status: Int32, statement: OpaquePointer?, query: ZSQLQuery) {
		self.status = status
		self.statement = statement
		self.query = query
	}
	var row: ZSQLRow? {
		return (self.status == SQLITE_ROW) ? ZSQLRow(statement: self.statement) : nil
	}
	var OK: Bool { self.status == SQLITE_OK }
	var done: Bool { self.status == SQLITE_DONE }
}

public class ZSQLRow {
	let statement: OpaquePointer?
	public init(statement: OpaquePointer?) {
		self.statement = statement
	}
	public func rawValue(column: Int) -> ZSQLColumnValue? {
		let count = sqlite3_column_count(self.statement)
		guard column >= 0 && column < count else { fatalError() }
		switch sqlite3_column_type(self.statement, Int32(column)) {
		case SQLITE_INTEGER:
			let value = sqlite3_column_int64(self.statement, Int32(column))
			return Int(value)
		case SQLITE_FLOAT:
			let value = sqlite3_column_double(self.statement, Int32(column))
			return Double(value)
		case SQLITE_BLOB:
			let length = Int(sqlite3_column_bytes(self.statement, Int32(column)))
			let data = Data(bytes: sqlite3_column_blob(self.statement, Int32(column)), count: length)
			return data
		case SQLITE_TEXT:
			let string = String(cString: sqlite3_column_text(self.statement, Int32(column))) // type in string
			return string
		case SQLITE_NULL:
			return NSNull()
		default:
			return nil
		}
	}
	public func value<T: ZSQLColumnValue>(index: Int) -> T? {
		return self.rawValue(column: index) as? T
	}
	public func value<T: ZSQLColumnValue>(named name: String) -> T? {
		guard let index = self.columnNames.firstIndex(of: name) else { fatalError() }
		return self.rawValue(column: index) as? T
	}
	public lazy var columnNames: [String] = {
		return (0 ..< sqlite3_column_count(self.statement)).map { index in
			guard let rawValue = sqlite3_column_name(self.statement, index) else { fatalError() }
			return String(cString: rawValue)
		}
	}()
	public lazy var values: [String: ZSQLColumnValue] = {
		return (0 ..< sqlite3_column_count(self.statement)).reduce(into: [String: ZSQLColumnValue]()) { dictionary, index in
			guard let rawValue = sqlite3_column_name(self.statement, index) else { fatalError() }
			let columnName = String(cString: rawValue)
			dictionary[columnName] = self.rawValue(column: Int(index))
		}
	}()
	subscript(key: String) -> ZSQLColumnValue? {
		return self.values[key]
	}
}
