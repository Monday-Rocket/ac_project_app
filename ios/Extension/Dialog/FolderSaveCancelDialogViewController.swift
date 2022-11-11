//
//  CustomDialogViewController.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/11.
//

import UIKit

class FolderSaveCancelDialogViewController: UIViewController {

  var confirmButtonCompletionClosure: (() -> Void)?
  var cancelButtonClosure: (() -> Void)?
  
  @IBOutlet weak var contentLabel: UILabel!
  
  @IBOutlet weak var button: UIButton!
  override func viewDidLoad() {
    self.button.tintColor = .primary600
    self.contentLabel.setLineHeight(lineHeight: 19)
    self.contentLabel.textAlignment = .center
  }
  
  @IBAction func onButtonPressed(_ sender: Any) {
    if let callback = confirmButtonCompletionClosure {
      callback()
      
      self.dismiss(animated: true, completion: nil)
    }
  }
  
  @IBAction func onClosePressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
}
