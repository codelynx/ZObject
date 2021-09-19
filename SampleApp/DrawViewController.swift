//
//  ViewController.swift
//  SampleApp
//
//  Created by Kaz Yoshikawa on 9/12/21.
//  Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import UIKit
import ZObject_ios

class DrawViewController: UIViewController {

	var documentURL: URL!

	@IBOutlet weak var toolSegmentedControl: UISegmentedControl!
	
	lazy var storage: ZStorage = {
		return try! ZStorage(fileURL: self.documentURL!)
	}()
	lazy var contents: Contents = {
		return try! self.storage.instanciateObjects(of: Contents.self).first ?? Contents(storage: self.storage)
	}()

	@IBOutlet weak var drawView: DrawView!
	var selection: [Shape] { return self.drawView.selection }

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		assert(self.documentURL != nil)
		self.drawView.contents = self.contents
		self.drawView.delegate = self
		self.navigationItem.title = (self.documentURL.lastPathComponent as NSString).deletingPathExtension
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		try? self.contents.save(storage: self.storage)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.trashButtonItem.isEnabled = self.drawView.selection.count > 0
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let navigationController = segue.destination as? UINavigationController,
		   let viewController = navigationController.topViewController as? LayerTableViewController {
			viewController.drawView = self.drawView
		}
	}

	deinit {
		print(Self.self, #function)
	}

	// MARK: -

	enum TouchToolValue: Int {
		case oval
		case rectangle
		case hand
	}

	@IBAction func toolAction(_ sender: UISegmentedControl) {
		switch TouchToolValue(rawValue: sender.selectedSegmentIndex) {
		case .oval:
			self.touchTool = self.drawView.ovalTool
			self.drawView.selection = []
		case .rectangle:
			self.touchTool = self.drawView.rectangleTool
			self.drawView.selection = []
		case .hand:
			self.touchTool = self.drawView.handTool
		default: fatalError()
		}
		self.drawView.setNeedsDisplay()
	}
	
	lazy var touchTool: TouchTool = {
		return OvalTool(drawView: drawView)
	}()


	@IBOutlet weak var trashButtonItem: UIBarButtonItem!
	
	@IBAction func trashAction(_ sender: UIBarButtonItem) {
		self.drawView.trash(shapes: self.selection)
	}
	

}

extension DrawViewController: LayerTableViewCellDelegate {
	func update() {
		self.drawView.setNeedsDisplay()
	}
}

extension DrawViewController: DrawViewDelegate {
	func selectionDidChange() {
		self.trashButtonItem.isEnabled = self.drawView.selection.count > 0
	}
}
