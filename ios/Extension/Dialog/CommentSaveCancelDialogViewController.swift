//
//  CommentSaveCancelDialogViewController.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/11.
//

import UIKit

class CommentSaveCancelDialogViewController: UIViewController {
  var confirmButtonCompletionClosure: (() -> Void)?
  var cancelButtonClosure: (() -> Void)?
  
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
