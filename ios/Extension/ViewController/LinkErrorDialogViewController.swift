//
//  LinkErrorDialogViewController.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/12/13.
//

import UIKit

class LinkErrorDialogViewController: UIViewController {
  var confirmButtonCompletionClosure: (() -> Void)?
  var cancelButtonClosure: (() -> Void)?
  var contentText: String?
  @IBOutlet weak var confirmButton: UIButton!
  
  override func viewDidLoad() {
    self.confirmButton.tintColor = .primary600
  }
  
  @IBAction func onButtonPressed(_ sender: Any) {
    self.hideExtensionWithCompletionHandler()
  }
  
  @IBAction func onClosePressed(_ sender: Any) {
    self.onButtonPressed(sender)
  }
  
  private func hideExtensionWithCompletionHandler() {
    UIView.animate(withDuration: 0.3, animations: {
      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    }, completion: { _ in
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
  }
}

