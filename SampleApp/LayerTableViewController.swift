//
//	LayerTableViewController.swift
//	SampleApp
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import UIKit
import ZObject_ios


class LayerTableViewController: UITableViewController {

	var drawView: DrawView!
	var storage: ZStorage { return self.drawView.contents.storage! }

	var layers: [Layer] { return self.drawView.contents.layers }
	var activeLayer: Layer {
		get { return self.drawView.activeLayer }
		set { self.drawView.activeLayer = newValue }
	}

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		assert(self.drawView != nil)
		let activeLayerIndex = self.layers.firstIndex(of: self.activeLayer)!
		self.tableView.selectRow(at: IndexPath(row: activeLayerIndex, section: 0), animated: false, scrollPosition: .none)
	}

	deinit {
		print(Self.self, #function)
	}

	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.layers.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let layer = self.layers[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LayerTableViewCell
		cell.delegate = self
		cell.drawingLayer =  layer
		cell.textLabel?.text = String(layer.identifier)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let layer = self.layers[indexPath.row]
		self.activeLayer = layer
	}
	
	// MARK: -
	
	@IBAction func addLayer(_ sender: UIBarButtonItem) {
		let layer = try! Layer(storage: self.storage)
		self.drawView.contents.layers.append(layer)
		self.drawView.activeLayer = layer
		let index = self.drawView.contents.layers.firstIndex(of: layer) ?? 0
		self.tableView.reloadData()
		self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .none)
	}

}

extension LayerTableViewController: LayerTableViewCellDelegate {
	func update() {
		self.drawView.setNeedsDisplay()
	}
}
