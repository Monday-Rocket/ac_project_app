//
//  CommentOverflowDialogViewController.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/12/18.
//

import UIKit

class CommentOverflowDialogViewController: UIViewController {
  
  
  @IBOutlet weak var contentLabel: UILabel!
  
  @IBOutlet weak var button: UIButton!
  
  override func viewDidLoad() {
    self.button.tintColor = .primary600
    self.contentLabel.setLineHeight(lineHeight: 19)
    self.contentLabel.textAlignment = .center
  }
  
  @IBAction func onCloseClick(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
}
