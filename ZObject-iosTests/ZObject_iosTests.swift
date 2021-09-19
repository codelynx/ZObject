//
//	ZObject_iosTests.swift
//	ZObject-iosTests
//
//	Created by Kaz Yoshikawa on 9/12/21.
//

import XCTest
@testable import ZObject_ios

protocol Shape: ZObject {
}

class Circle: ZObject, Shape {
	var center: CGPoint
	var radius: CGFloat
	enum Keys: String { case center, radius }
	init(center: CGPoint, radius: CGFloat, storage: ZStorage) throws {
		self.center = center
		self.radius = radius
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(self.center, forKey: Self.Keys.center.rawValue)
		coder.encode(self.radius, forKey: Self.Keys.radius.rawValue)
	}
	required init?(coder: NSCoder) {
		self.center = coder.decodeCGPoint(forKey: Self.Keys.center.rawValue)
		self.radius = coder.decodeObject(forKey: Self.Keys.radius.rawValue) as! CGFloat
		super.init(coder: coder)
	}
	override var description: String {
		return "{\(Self.self): center=\(self.center), radius=\(radius)}"
	}
}

class Rectangle: ZObject, Shape {
	var origin: CGPoint
	var size: CGSize
	enum Keys: String { case origin, size }
	init(origin: CGPoint, size: CGSize, storage: ZStorage) throws {
		self.origin = origin
		self.size = size
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(self.origin, forKey: Self.Keys.origin.rawValue)
		coder.encode(self.size, forKey: Self.Keys.size.rawValue)
	}
	required init?(coder: NSCoder) {
		self.origin = coder.decodeCGPoint(forKey: Self.Keys.origin.rawValue)
		self.size = coder.decodeCGSize(forKey: Self.Keys.size.rawValue)
		super.init(coder: coder)
	}
	override var description: String {
		return "{\(Self.self): origin=\(self.origin), size=\(size)}"
	}
}

class Layer: ZObject {
	var shapes: [Shape]
	static let shapesKey = "shapes"
	init(shapes: [Shape], storage: ZStorage) throws {
		self.shapes = shapes
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		coder.encode(shapes, forKey: Self.shapesKey)
		super.encode(with: coder)
	}
	required init?(coder: NSCoder) {
		self.shapes = coder.decodeObject(forKey: Self.shapesKey) as! [Shape]
		super.init(coder: coder)
	}
}

class Page: ZObject {
	var layers: [Layer]
	static let layersKey = "layers"
	init(layers: [Layer], storage: ZStorage) throws {
		self.layers = layers
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		coder.encode(layers, forKey: Self.layersKey)
		super.encode(with: coder)
	}
	required init?(coder: NSCoder) {
		self.layers = coder.decodeObject(forKey: Self.layersKey) as! [Layer]
		super.init(coder: coder)
	}
}

class Contents: ZObject {
	var pages: [Page]
	static let pagesKey = "pages"
	init(pages: [Page], storage: ZStorage) throws {
		self.pages = pages
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		coder.encode(pages, forKey: Self.pagesKey)
		super.encode(with: coder)
	}
	required init?(coder: NSCoder) {
		self.pages = coder.decodeObject(forKey: Self.pagesKey) as! [Page]
		super.init(coder: coder)
	}
}

// MARK: -

class ZObject_iosTests: XCTestCase {
	
	static func fileURL(with name: String) -> URL {
		let directory = NSTemporaryDirectory()
		let filePath = (directory as NSString).appendingPathComponent("\(name).sqlite")
		return URL(fileURLWithPath: filePath)
	}
	
	static func deleteFileIfExsits(fileURL: URL) {
		if FileManager.default.fileExists(atPath: fileURL.path) {
			try? FileManager.default.removeItem(at: fileURL)
		}
	}
	
	var file1URL: URL { return Self.fileURL(with: "file1") }
	var file2URL: URL { return Self.fileURL(with: "file2") }
	var file3URL: URL { return Self.fileURL(with: "file3") }
	var file4URL: URL { return Self.fileURL(with: "file4") }
	var file5URL: URL { return Self.fileURL(with: "file5") }
	var file6URL: URL { return Self.fileURL(with: "file6") }

	override func setUpWithError() throws {
		print(NSTemporaryDirectory())
	}
	
	override func tearDownWithError() throws {
		print(Self.self, #function)
	}
	
	func prepare_test1() throws {
	}

	func test1() throws {
		Self.deleteFileIfExsits(fileURL: self.file1URL)

		let storage = try ZStorage(fileURL: self.file1URL)
		let c1a = try Circle(center: CGPoint(x: 100, y: 200), radius: 300, storage: storage)
		let c2a = try Circle(center: CGPoint(x: 400, y: 500), radius: 600, storage: storage)
		let c3a = try Circle(center: CGPoint(x: 700, y: 800), radius: 900, storage: storage)
		let r1a = try Rectangle(origin: CGPoint(x: 101, y: 102), size: CGSize(width: 103, height: 104), storage: storage)
		let r2a = try Rectangle(origin: CGPoint(x: 201, y: 202), size: CGSize(width: 203, height: 204), storage: storage)
		let r3a = try Rectangle(origin: CGPoint(x: 301, y: 302), size: CGSize(width: 303, height: 304), storage: storage)
		let layer1a = try Layer(shapes: [c1a, r1a], storage: storage)
		let layer2a = try Layer(shapes: [c2a, r2a], storage: storage)
		let layer3a = try Layer(shapes: [c3a, r3a], storage: storage)
		let page1a = try Page(layers: [layer1a, layer2a], storage: storage)
		let page2a = try Page(layers: [layer3a], storage: storage)
		let contents = try Contents(pages: [page1a, page2a], storage: storage)
		try contents.save(storage: storage)

		guard let contents = try storage.instanciateObjects(of: Contents.self).first else { throw ZStorageError.failedInstanciatingObject }
		XCTAssert(contents.pages.count == 2)
		let page1b = contents.pages[0]
		let page2b = contents.pages[1]
		XCTAssert(page1b.layers.count == 2)
		XCTAssert(page2b.layers.count == 1)
		let layer1b = page1b.layers[0]
		let layer2b = page1b.layers[1]
		let layer3b = page2b.layers[0]
		XCTAssert(layer1b.shapes.count == 2)
		XCTAssert(layer2b.shapes.count == 2)
		XCTAssert(layer3b.shapes.count == 2)
		let (c1b, r1b) = (layer1b.shapes[0] as! Circle, layer1b.shapes[1] as! Rectangle)
		let (c2b, r2b) = (layer2b.shapes[0] as! Circle, layer2b.shapes[1] as! Rectangle)
		let (c3b, r3b) = (layer3b.shapes[0] as! Circle, layer3b.shapes[1] as! Rectangle)

		XCTAssert(c1b.center == CGPoint(x: 100, y: 200) && c1b.radius == 300)
		XCTAssert(c2b.center == CGPoint(x: 400, y: 500) && c2b.radius == 600)
		XCTAssert(c3b.center == CGPoint(x: 700, y: 800) && c3b.radius == 900)
		XCTAssert(r1b.origin == CGPoint(x: 101, y: 102) && r1b.size == CGSize(width: 103, height: 104))
		XCTAssert(r2b.origin == CGPoint(x: 201, y: 202) && r2b.size == CGSize(width: 203, height: 204))
		XCTAssert(r3b.origin == CGPoint(x: 301, y: 302) && r3b.size == CGSize(width: 303, height: 304))
	}
	
	func test2() throws {
		// makse sure cache is working
		Self.deleteFileIfExsits(fileURL: self.file2URL)
		let storage = try ZStorage(fileURL: self.file2URL)
		let c1 = try Circle(center: CGPoint(x: 110, y: 210), radius: 310, storage: storage)
		let c1i = c1.identifier
		XCTAssert(storage.isCashed(object: c1))
		let circles = try storage.instanciateObjects(of: Circle.self)
		XCTAssert(circles.count == 1)
		let c2 = circles.first!
		let c2i = c2.identifier
		XCTAssert(c1i == c2i)
	}

	func test3() throws {
		// testing transaction / commit / rollback
		Self.deleteFileIfExsits(fileURL: self.file3URL)

		let storage = try ZStorage(fileURL:self.file3URL)
		let c1 = try Circle(center: CGPoint(x: 100, y: 200), radius: 300, storage: storage)
		XCTAssert(c1.identifier >= 0)
		let objects1 = try storage.instanciateObjects(of: Circle.self)
		XCTAssert(objects1.count == 1)
		
		try storage.committing {
			let c2 = try Circle(center: CGPoint(x: 101, y: 201), radius: 301, storage: storage)
			XCTAssert(c2.identifier >= 0)
		}
		let objects2 = try storage.instanciateObjects(of: Circle.self)
		XCTAssert(objects2.count == 2)

		try storage.committing {
			let c3 = try Circle(center: CGPoint(x: 102, y: 202), radius: 302, storage: storage)
			XCTAssert(c3.identifier >= 0)
			throw ZStorageError.rollback
		}
		let objects3 = try storage.instanciateObjects(of: Circle.self)
		XCTAssert(objects3.count == 2) // c3 should have been cancelled

		try storage.committing {
			let c4 = try Circle(center: CGPoint(x: 103, y: 203), radius: 303, storage: storage)
			XCTAssert(c4.identifier >= 0)
		}
		let objects4 = try storage.instanciateObjects(of: Circle.self)
		XCTAssert(objects4.count == 3)
	}

	func test4() throws {
		Self.deleteFileIfExsits(fileURL: self.file4URL)
		let storage = try ZStorage(fileURL:self.file4URL)

		let r1a = try Rectangle(origin: CGPoint(x: 101, y: 102), size: CGSize(width: 103, height: 104), storage: storage)
		let r2a = try Rectangle(origin: CGPoint(x: 201, y: 202), size: CGSize(width: 203, height: 204), storage: storage)
		let layer1a = try Layer(shapes: [r1a, r2a], storage: storage)

		let c1a = try Circle(center: CGPoint(x: 100, y: 200), radius: 300, storage: storage)
		let c2a = try Circle(center: CGPoint(x: 400, y: 500), radius: 600, storage: storage)
		layer1a.shapes = [c1a, c2a]
		try layer1a.save(storage: storage)
	}

	func test5() throws {
		// test deleting objects
		Self.deleteFileIfExsits(fileURL: self.file5URL)
		let storage = try ZStorage(fileURL:self.file5URL)
		let r1a = try Rectangle(origin: CGPoint(x: 101, y: 102), size: CGSize(width: 103, height: 104), storage: storage)
		let r2a = try Rectangle(origin: CGPoint(x: 201, y: 202), size: CGSize(width: 203, height: 204), storage: storage)
		let c1a = try Circle(center: CGPoint(x: 100, y: 200), radius: 300, storage: storage)
		let c2a = try Circle(center: CGPoint(x: 400, y: 500), radius: 600, storage: storage)
		try storage.delete(object: r2a)
		try storage.delete(object: c2a)
		let r1x = try storage.instanciateObjects(of: Circle.self)
		XCTAssert(r1x.count == 1)
		let c1x = try storage.instanciateObjects(of: Circle.self)
		XCTAssert(c1x.count == 1)
	}

	func test6() throws {
		Self.deleteFileIfExsits(fileURL: self.file6URL)
		let storage = try ZStorage(fileURL:self.file6URL)
		let r = try Rectangle(origin: CGPoint(x: 101, y: 102), size: CGSize(width: 103, height: 104), storage: storage)
		let refcount1 = try r.refcount()
		XCTAssert(refcount1 == 1)
		try r.keep()
		let refcount2 = try r.refcount()
		XCTAssert(refcount2 == 2)
		try r.keep()
		let refcount3 = try r.refcount()
		XCTAssert(refcount3 == 3)
		try r.waste()
		let refcount4 = try r.refcount()
		XCTAssert(refcount4 == 2)
		try r.waste()
		let refcount5 = try r.refcount()
		XCTAssert(refcount5 == 1)
	}

	func testPerformanceExample() throws {
		// This is an example of a performance test case.
		self.measure {
			// Put the code you want to measure the time of here.
		}
	}
	
}


