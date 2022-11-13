//
//  TextFieldExtension.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/13.
//

import UIKit

extension UIViewController: UITextFieldDelegate {
  
  func setKeyboardObserver() {
    NotificationCenter.default.addObserver(self, selector: #selector(UIViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(UIViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object:nil)
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
    self.view.addGestureRecognizer(tapGesture)
  }
  
  @objc func keyboardWillShow(notification: NSNotification) {
    NSLog("❇️ key board show!")
    if self.view.window?.frame.origin.y == 0 {
      UIView.animate(withDuration: 0.1) {
        self.view.window?.frame.origin.y -= 150
      }
    }
  }
  
  @objc func keyboardWillHide(notification: NSNotification) {
    NSLog("❇️ key board hide!")
    if self.view.window?.frame.origin.y != 0 {
      UIView.animate(withDuration: 0.1) {
        self.view.window?.frame.origin.y += 150
      }
    }
  }
  
  @objc func hideKeyboard(_ sender: Any) {
    if self.view.window?.frame.origin.y != 0 {
      UIView.animate(withDuration: 0.1) {
        self.view.window?.frame.origin.y += 150
      }
    }
    view.endEditing(true)
  }
  
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
}
