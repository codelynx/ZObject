//
//	DrawView.swift
//	SampleApp
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import UIKit


protocol DrawViewDelegate: AnyObject {
	var touchTool: TouchTool { get }
	func selectionDidChange()
}

class DrawView: UIView {

	weak var delegate: DrawViewDelegate!
	var contents: Contents!

	private var _activeLayer: Layer?
	var activeLayer: Layer {
		get { return _activeLayer ?? contents.layers.first! }
		set { _activeLayer = newValue }
	}
	var selection = [Shape]() {
		didSet { self.delegate.selectionDidChange() }
	}

	var touchTool: TouchTool { self.delegate!.touchTool }

	@IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
	@IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!

	override func layoutSubviews() {
		super.layoutSubviews()
		assert(self.contents != nil)
		assert(self.delegate != nil)
	}

	deinit {
		print(Self.self, #function)
	}

	override func draw(_ rect: CGRect) {
		print(Self.self, #function, "self.selection.count=", self.selection.count)
		let context = Context(selection: self.selection)
		for layer in self.contents.layers {
			layer.draw(context: context)
		}
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.touchTool.touchesBegan(touches, with: event)
		self.setNeedsDisplay()
	}
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.touchTool.touchesMoved(touches, with: event)
		self.setNeedsDisplay()
	}
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.touchTool.touchesEnded(touches, with: event)
		self.setNeedsDisplay()
	}
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.touchTool.touchesCancelled(touches, with: event)
		self.setNeedsDisplay()
	}

	lazy var ovalTool: OvalTool = { return OvalTool(drawView: self) }()
	lazy var rectangleTool: RectangleTool = { return RectangleTool(drawView: self) }()
	lazy var handTool: HandTool = { return HandTool(drawView: self) }()

	func add(shape: Shape) {
		self.activeLayer.shapes.append(shape)
		self.setNeedsDisplay()
	}

	func hitTest(point: CGPoint) -> Shape? {
		for layer in self.contents.layers.reversed() {
			if let shape = layer.hitTest(point: point) {
				self.selection = [shape]
				self.setNeedsDisplay()
				return shape
			}
		}
		return nil
	}

	func trash(shapes: [Shape]) {
		for layer in self.contents.layers {
			layer.trash(shapes: shapes)
		}
		self.selection = []
		self.setNeedsDisplay()
	}
}
