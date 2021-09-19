//
//  DocumentTableViewController.swift
//  DocumentTableViewController
//
//  Created by Kaz Yoshikawa on 9/13/21.
//  Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import UIKit

class DocumentTableViewController: UITableViewController {
	
	lazy var documentDirectoryURL: URL = {
		return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	}()
	
	private var _documentURLs: [URL]?
	var documentURLs: [URL] {
		if let documentURLs = self._documentURLs { return documentURLs }
		let documentURLs = self.makeDocumentURLs()
		_documentURLs = documentURLs
		return documentURLs
	}
	
	func makeDocumentURLs() -> [URL] {
		do {
			let urls = try FileManager.default.contentsOfDirectory(at: self.documentDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
			return urls.filter { $0.pathExtension == "sqlite" }
		}
		catch { fatalError("\(error)") }
	}
	
	func makeDocumentFile() -> URL {
		let documentURL = documentDirectoryURL.appendingPathComponent((UUID().uuidString as NSString).appendingPathExtension("sqlite")!)
		let success = FileManager.default.createFile(atPath: documentURL.path, contents: nil, attributes: nil)
		guard success else { fatalError() }
		return documentURL
	}

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self._documentURLs = nil
		self.tableView.reloadData()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}

	func presentDocument(fileURL: URL) {
		guard let storyboard = self.storyboard else { fatalError() }
		let viewController = storyboard.instantiateViewController(withIdentifier: "drawView") as! DrawViewController
		viewController.documentURL = fileURL
		self.navigationController?.pushViewController(viewController, animated: true)
	}

	@IBAction func addAction(_ sender: UIBarButtonItem) {
		let documetFileURL = self.makeDocumentFile()
		self.presentDocument(fileURL: documetFileURL)
	}

	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.documentURLs.count
	}
	
	 override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
	 	let filePath = self.documentURLs[indexPath.row]
		 let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		 cell.textLabel?.text = filePath.lastPathComponent
		 return cell
	 }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let documentURL = self.documentURLs[indexPath.row]
		self.presentDocument(fileURL: documentURL)
	}

	/*
	 // Override to support conditional editing of the table view.
	 override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
	 // Return false if you do not want the specified item to be editable.
	 return true
	 }
	 */
	
	/*
	 // Override to support editing the table view.
	 override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
	 if editingStyle == .delete {
	 // Delete the row from the data source
	 tableView.deleteRows(at: [indexPath], with: .fade)
	 } else if editingStyle == .insert {
	 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	 }
	 }
	 */
	
	/*
	 // Override to support rearranging the table view.
	 override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
	 
	 }
	 */
	
	/*
	 // Override to support conditional rearranging of the table view.
	 override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
	 // Return false if you do not want the item to be re-orderable.
	 return true
	 }
	 */
	
	 // MARK: - Navigation
	 
	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let viewController = segue.destination as? DrawViewController,
		   let indexPath = tableView.indexPathForSelectedRow {
			viewController.documentURL = self.documentURLs[indexPath.row]
		}
	}
	
}
