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
    
    self.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showCancelDialog(_:))))
    
  }
  
  @IBAction func onSavePressed(_ sender: Any) {
    guard let comment = self.commentTextField.text, let savedLink = self.link else {
      return
    }
    UserDefaultsHelper.saveComment(savedLink, comment)
    
    self.showSuccessDialog()
  }
  
  func showSuccessDialog() {
    let sb = UIStoryboard.init(name: "Dialog", bundle: nil)
    
    let dialogVC = sb.instantiateViewController(withIdentifier: "LinkSavedDialog") as! LinkSavedDialogViewController
    
    dialogVC.modalPresentationStyle = .overCurrentContext
    dialogVC.modalTransitionStyle = .crossDissolve
    dialogVC.contentText = saveType == SaveType.New ? "새 폴더에 링크와 코멘트가 담겼어요" : "선택한 폴더에 링크와 코멘트가 담겼어요"
    dialogVC.confirmButtonCompletionClosure = {
      self.hideExtensionWithCompletionHandler()
    }
    
    self.present(dialogVC, animated: true, completion: nil)
  }
  
  @IBAction func onClosePressed(_ sender: Any) {
    self.hideExtensionWithCompletionHandler()
  }
  
  @objc func showCancelDialog(_ sender: Any) {
    let sb = UIStoryboard.init(name: "Dialog", bundle: nil)
    
    let dialogVC = sb.instantiateViewController(withIdentifier: "CommentSaveCancelDialog") as! CommentSaveCancelDialogViewController
    
    dialogVC.modalPresentationStyle = .overCurrentContext
    dialogVC.modalTransitionStyle = .crossDissolve
    dialogVC.confirmButtonCompletionClosure = {
      self.hideExtensionWithCompletionHandler()
    }
    
    self.present(dialogVC, animated: true, completion: nil)
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
