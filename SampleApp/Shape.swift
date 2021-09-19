//
//  Shape.swift
//  SampleApp
//
//  Created by Kaz Yoshikawa on 9/12/21.
//  Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import UIKit
import ZObject_ios

class Context {
	var selection: [Shape]
	init(selection: [Shape]) {
		self.selection = selection
	}
}

protocol Shape: ZObject {
	var rect: CGRect { get set }
	func draw(context: Context)
	func hitTest(point: CGPoint) -> Bool
}

extension Shape {
	var handles: [CGRect] {
		let rect = self.rect
		let minXminY = CGPoint(x: rect.minX, y: rect.minY)
		let maxXminY = CGPoint(x: rect.maxX, y: rect.minY)
		let minXmaxY = CGPoint(x: rect.minX, y: rect.maxY)
		let maxXmaxY = CGPoint(x: rect.maxX, y: rect.maxY)
		return [minXminY, maxXminY, minXmaxY, maxXmaxY]
				.map { CGRect(x: $0.x - 4, y: $0.y - 4, width: 9, height: 9) }
	}
	func drawMarker() {
		for handle: CGRect in self.handles {
			UIColor.blue.set()
			UIRectFill(handle)
		}
	}
	func offsetBy(dx : CGFloat, dy: CGFloat) {
		self.rect = self.rect.offsetBy(dx: dx, dy: dy)
	}
}

extension Array where Element: AnyObject {
	func removing(_ others: [Element]) -> Array {
		var items = self
		items.removeAll { item in others.contains { other in item === other } }
		return items
	}
}


class Oval: ZObject, Shape {
	var rect: CGRect
	private enum Keys: String { case rect }
	init(rect: CGRect, shorage: ZStorage) throws {
		self.rect = rect
		try super.init(storage: shorage)
	}
	override func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(self.rect, forKey: Self.Keys.rect.rawValue)
	}
	required init?(coder: NSCoder) {
		self.rect = coder.decodeCGRect(forKey: Self.Keys.rect.rawValue)
		super.init(coder: coder)
	}
	func draw(context: Context) {
		UIColor.black.set()
		let path = UIBezierPath(ovalIn: self.rect)
		path.lineWidth = 2.0
		path.stroke()
		if context.selection.contains(where: { $0 == self }) {
			self.drawMarker()
		}
	}
	func hitTest(point: CGPoint) -> Bool {
		return self.rect.contains(point)
	}
}

class Rectangle: ZObject, Shape {
	var rect: CGRect
	private enum Keys: String { case rect }
	init(rect: CGRect, storage: ZStorage) throws {
		self.rect = rect
		try super.init(storage: storage)
	}
	override func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(self.rect, forKey: Self.Keys.rect.rawValue)
	}
	required init?(coder: NSCoder) {
		self.rect = coder.decodeCGRect(forKey: Self.Keys.rect.rawValue)
		super.init(coder: coder)
	}
	func draw(context: Context) {
		UIColor.black.set()
		let path = UIBezierPath(rect: self.rect)
		path.lineWidth = 2.0
		path.stroke()
		if context.selection.contains(where: { $0 == self }) {
			self.drawMarker()
		}
	}
	func hitTest(point: CGPoint) -> Bool {
		return self.rect.contains(point)
	}
}

class Layer: ZObject {
	private enum Keys: String { case shapes, hidden }
	var shapes: [Shape]
	var isHidden: Bool = false
	init(shapes: [Shape]? = nil, storage: ZStorage) throws {
		self.shapes = shapes ?? []
		try super.init(storage: storage)
	}
	deinit {
		print(Self.self, #function)
	}
	override func encode(with coder: NSCoder) {
		coder.encode(self.shapes, forKey: Self.Keys.shapes.rawValue)
		coder.encode(self.isHidden, forKey: Self.Keys.hidden.rawValue)
		super.encode(with: coder)
	}
	required init?(coder: NSCoder) {
		self.shapes = coder.decodeObject(forKey: Self.Keys.shapes.rawValue) as! [Shape]
		self.isHidden = coder.decodeBool(forKey: Self.Keys.hidden.rawValue)
		super.init(coder: coder)
	}
	func draw(context: Context) {
		if !self.isHidden {
			for shape in self.shapes {
				shape.draw(context: context)
			}
		}
	}
	func hitTest(point: CGPoint) -> Shape? {
		if !self.isHidden {
			for shape in shapes.reversed() {
				if shape.hitTest(point: point) { return shape }
			}
		}
		return nil
	}
	func trash(shapes others: [Shape]) {
		self.shapes.removeAll { shape in
			others.contains { other in
				other === shape
			}
		}
	}
}

class Contents: ZObject {
	var layers: [Layer]
	static let layersKey = "layers"
	init(layers: [Layer]? = nil, storage: ZStorage) throws {
		print(Self.self, #function)
		let layers = layers ?? []
		self.layers = (layers.count > 0) ? layers : [try Layer(storage: storage)]
		try super.init(storage: storage)
	}
	deinit {
		print(Self.self, #function)
	}
	override func encode(with coder: NSCoder) {
		coder.encode(layers, forKey: Self.layersKey)
		super.encode(with: coder)
	}
	required init?(coder: NSCoder) {
		let layers = coder.decodeObject(forKey: Self.layersKey) as! [Layer]
		let storage = coder.storage!
		self.layers = (layers.count > 0) ? layers : [try! Layer(storage: storage)]
		super.init(coder: coder)
	}
}
