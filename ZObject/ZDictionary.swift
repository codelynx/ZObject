//
//	ZDictionary.swift
//	ZObject
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import Foundation

public class ZDictionary: ZObject {
	private var dictionary = NSMutableDictionary()
	override init(storage: ZStorage) throws {
		try super.init(storage: storage)
	}
	override init(identifier: Int, storage: ZStorage) throws {
		try super.init(identifier: identifier, storage: storage)
	}
	required init?(coder: NSCoder) {
		guard let dictionary = coder.decodeObject() as? NSDictionary else { return nil }
		super.init(coder: coder)
		self.dictionary.setDictionary(dictionary as! [AnyHashable : Any])
	}
	public override func encode(with coder: NSCoder) {
		coder.encode(self.dictionary)
	}
}
