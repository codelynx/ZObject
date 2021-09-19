//
//	LayerTableViewCell.swift
//	SampleApp
//
//	Created by Kaz Yoshikawa on 9/12/21.
//	Copyright © 2021 Electricwoods LLC. All rights reserved.
//

import UIKit

protocol LayerTableViewCellDelegate: AnyObject {
	func update()
}

class LayerTableViewCell: UITableViewCell {
	
	weak var delegate: LayerTableViewCellDelegate!
	var drawingLayer: Layer!

	@IBOutlet weak var visibleButton: UIButton!

	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		assert(self.delegate != nil)
		assert(self.visibleButton != nil)
		assert(self.drawingLayer != nil)
		let imageName = self.imageName(isHidden: self.drawingLayer.isHidden)
		self.visibleButton.setImage(UIImage(systemName: imageName), for: .normal)
	}

	func imageName(isHidden: Bool) -> String {
		return isHidden ? "eye.slash" : "eye"
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	@IBAction func toggleVisible(_ sender: UIButton) {
		self.drawingLayer.isHidden = !self.drawingLayer.isHidden
		self.delegate.update()
		self.setNeedsLayout()
	}
	
}
