//
//  LinkSavedDialogViewController.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/11.
//

import UIKit

class LinkSavedDialogViewController: UIViewController {
  var confirmButtonCompletionClosure: (() -> Void)?
  var cancelButtonClosure: (() -> Void)?
  var contentText: String?
  
  @IBOutlet weak var button: UIButton!
  
  override func viewDidLoad() {
    self.button.tintColor = .primary600
  }
  
  @IBAction func onButtonPressed(_ sender: Any) {
    if let callback = confirmButtonCompletionClosure {
      callback()
      
      self.dismiss(animated: true, completion: nil)
    }
  }
  
  @IBAction func onClosePressed(_ sender: Any) {
    self.onButtonPressed(sender)
  }
}
