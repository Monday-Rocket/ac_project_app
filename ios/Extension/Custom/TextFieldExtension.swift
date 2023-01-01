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
    if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
      let keyboardRectangle = keyboardFrame.cgRectValue
      let keyboardHeight = keyboardRectangle.height
      self.view.window?.frame.origin.y = -keyboardHeight
    }
  }
  
  @objc func keyboardWillHide(notification: NSNotification) {
    NSLog("❇️ key board hide!")
    self.view.window?.frame.origin.y = 0
//    self.view.transform = CGAffineTransform(translationX: 0, y: 0)
  }
  
  @objc func hideKeyboard(_ sender: Any) {
    view.endEditing(true)
  }
  
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let textFieldText = textField.text,
          let rangeOfTextToReplace = Range(range, in: textFieldText) else {
      return false
    }
    let substringToReplace = textFieldText[rangeOfTextToReplace]
    let count = textFieldText.count - substringToReplace.count + string.count
    return count <= 10
  }
  
}
