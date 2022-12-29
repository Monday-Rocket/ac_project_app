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
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var backgroundView: UIView!
  @IBOutlet weak var layoutView: UIView!
  @IBOutlet var commentTextView: UITextView!
  
  var link: String?
  var saveType: SaveType?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
      // MARK: - 상단 Round
    self.layoutView?.layer.cornerRadius = 30
    self.layoutView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
    self.saveCommentButton?.tintColor = .secondary
    
    self.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showCancelDialog(_:))))
    
    self.commentTextView.textColor = .grey400
    self.commentTextView.tintColor = .grey700
    self.commentTextView.contentInset = UIEdgeInsets(top: 15.0, left: 16.0, bottom: 15.0, right: 16.0)
    self.commentTextView.textContainerInset = UIEdgeInsets.zero
    self.commentTextView.delegate = self
    
      // MARK: - 키보드 처리
    setKeyboardObserver()
  }
  
  @IBAction func onSavePressed(_ sender: Any) {
    guard let comment = self.commentTextView.text, let savedLink = self.link else {
      return
    }
    
    if comment.count > 500 {
      self.showCommentOverflowDialog()
    } else {
      UserDefaultsHelper.saveComment(savedLink, comment)
      self.showSuccessDialog()
    }
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
  
  @objc func showCommentOverflowDialog() {
    let sb = UIStoryboard.init(name: "Dialog", bundle: nil)
    
    let dialogVC = sb.instantiateViewController(withIdentifier: "CommentOverflowDialog") as! CommentOverflowDialogViewController
    
    dialogVC.modalPresentationStyle = .overCurrentContext
    dialogVC.modalTransitionStyle = .crossDissolve
    
    self.present(dialogVC, animated: true, completion: nil)
  }
  
  @objc func hideExtensionWithCompletionHandler(_ sender: UITapGestureRecognizer? = nil) {
    UIView.animate(withDuration: 0.3, animations: {
      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    }, completion: { _ in
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
  }
}

extension CommentViewController: UITextViewDelegate {
  
  func textViewDidBeginEditing(_ textView: UITextView) {
      // TextColor로 처리합니다. text로 처리하게 된다면 placeholder와 같은걸 써버리면 동작이 이상하겠죠?
    if textView.textColor == UIColor.grey400 {
      textView.text = nil // 텍스트를 날려줌
      textView.textColor = .grey700
    }
    
  }
    // UITextView의 placeholder
  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.isEmpty {
      textView.text = "저장한 링크에 대해 간단하게 메모해보세요"
      textView.textColor = .grey400
    }
  }
  
  func textViewDidChange(_ textView: UITextView) {
    let comment = textView.text!
    
    self.saveCommentButton.tintColor = comment.isEmpty ? .secondary : .primary600
  }
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    guard let str = textView.text else { return true }
    let newLength = str.count + text.count - range.length
    return newLength <= 500
  }
}
