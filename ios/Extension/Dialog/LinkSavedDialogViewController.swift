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
      goToApp()
    }
  }
  
  func goToApp() {
    let urlString = "linkpool://com.mr.acProjectApp"
    
    let url = URL(string: urlString)
    _ = openURL(url!)
  }
  
  @objc func openURL(_ url: URL) -> Bool {
    var responder: UIResponder? = self
    
    while responder != nil {
      if let application = responder as? UIApplication {
        return application.perform(#selector(openURL(_:)), with: url) != nil
      }
      responder = responder?.next
    }
    return false
  }
  
  @IBAction func onClosePressed(_ sender: Any) {
    if let callback = confirmButtonCompletionClosure {
      callback()
      self.dismiss(animated: true, completion: nil)
    }
  }
}
