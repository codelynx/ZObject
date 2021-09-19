//
//	TouchTool.swift
//	SampleApp
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import UIKit
import ZObject_ios

protocol TouchTool: AnyObject {
	func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
	func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
	func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
	func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
}

protocol ShapeTool: TouchTool {
	var drawView: DrawView { get }
	var touch: UITouch? { get set }
	var point1: CGPoint? { get set }
	var shape: Shape? { get set }
	func makeShape(rect: CGRect) -> Shape?
}

extension ShapeTool {
	var storage: ZStorage { return self.drawView.contents.storage! }
	func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touch = touches.first {
			let point = touch.location(in: touch.view)
			self.point1 = point
			self.touch = touch
			if let shape = self.makeShape(rect: CGRect(point, point)) {
				self.shape = shape
				self.drawView.add(shape: shape)
			}
		}
	}
	func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touch = self.touch, touches.contains(touch) {
			let point2 = touch.location(in: touch.view)
			if let point1 = self.point1, let shape = self.shape {
				shape.rect = CGRect(point1, point2)
			}
		}
	}
	func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touch = self.touch, touches.contains(touch) {
			let point2 = touch.location(in: touch.view)
			if let point1 = self.point1 {
				self.shape?.rect = CGRect(point1, point2)
			}
			self.point1 = nil
			self.shape = nil
		}
	}
	func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touch = self.touch, touches.contains(touch) {
			self.point1 = nil
			self.shape = nil
		}
	}
}

class OvalTool: ShapeTool {
	unowned let drawView: DrawView
	var touch: UITouch?
	var point1: CGPoint?
	var point2: CGPoint?
	var shape: Shape?
	init(drawView: DrawView) {
		self.drawView = drawView
	}
	func makeShape(rect: CGRect) -> Shape? {
		return try? Oval(rect: rect, shorage: self.storage)
	}
}

class RectangleTool: ShapeTool {
	unowned let drawView: DrawView
	var touch: UITouch?
	var point1: CGPoint?
	var point2: CGPoint?
	var shape: Shape?
	init(drawView: DrawView) {
		self.drawView = drawView
	}
	func makeShape(rect: CGRect) -> Shape? {
		return try? Rectangle(rect: rect, storage: self.storage)
	}
}

class HandTool: TouchTool {
	unowned let drawView: DrawView
	var touch: UITouch?
	var point: CGPoint?
	var selection: Shape?
	init(drawView: DrawView) {
		self.drawView = drawView
	}
	func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		print(self.self, #function, #line)
		if let touch = touches.first {
			let location = touch.location(in: touch.view)
			if let shape = self.drawView.hitTest(point: location) {
				self.drawView.selection = [shape]
				self.touch = touch
				self.point = location
			}
			else {
				self.drawView.selection = []
			}
			self.drawView.setNeedsDisplay()
		}
	}
	func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		print(self.self, #function)
		if let touch = self.touch, touches.contains(touch), let point = self.point {
			let location = touch.location(in: touch.view)
			for shape in self.drawView.selection {
				shape.offsetBy(dx: location.x - point.x , dy: location.y - point.y)
			}
			self.point = location
		}
	}
	func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		print(self.self, #function)
	}
	func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		print(self.self, #function)
	}
}

extension CGRect {
	init(_ point1: CGPoint, _ point2: CGPoint) {
		let (x1, y1) = (min(point1.x, point2.x), min(point1.y, point2.y))
		let (x2, y2) = (max(point1.x, point2.x), max(point1.y, point2.y))
		self = CGRect(origin: CGPoint(x: x1, y: y1), size: CGSize(width: x2 - x1, height: y2 - y1))
	}
}
