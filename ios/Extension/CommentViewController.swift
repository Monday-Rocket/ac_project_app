//
//  CommentViewController.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/11.
//

import Foundation
import UIKit

class CommentViewController: UIViewController {
  @IBOutlet weak var saveCommentButton: UIButton!
  @IBOutlet weak var commentTextField: PaddingTextField!
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var backgroundView: UIView!
  @IBOutlet weak var layoutView: UIView!
  
  var link: String?
  var saveType: SaveType?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // MARK: - 상단 Round
    self.layoutView?.layer.cornerRadius = 30
    
    
    self.commentTextField.addTarget(self, action: #selector(self.onCommentChanged(_:)), for: .editingChanged)
    
    self.saveCommentButton?.tintColor = .secondary
    
    self.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.hideExtensionWithCompletionHandler(_:))))
    
  }
  
  @IBAction func onClosePressed(_ sender: Any) {
    self.hideExtensionWithCompletionHandler()
  }
  
  @objc func hideExtensionWithCompletionHandler(_ sender: UITapGestureRecognizer? = nil) {
    UIView.animate(withDuration: 0.3, animations: {
      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    }, completion: { _ in
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
  }
  
  @objc func onCommentChanged(_ sender: Any) {
    let comment = self.commentTextField.text ?? ""
    
    self.saveCommentButton.tintColor = comment.isEmpty ? .secondary : .primary600
  }
}
