//
//  NewFolderViewControll.swift
//  Extension
//
//  Created by 유재선 on 2022/10/30.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class NewFolderViewController : UIViewController {
  
  @IBOutlet weak var backgroundView: UIView!
  @IBOutlet weak var layoutView: UIView!
  
  @IBOutlet weak var newFolderNameField : UITextField!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var visibleToggleButton: UIImageView!

  @IBOutlet weak var firstSaveButton : UIButton!
  @IBOutlet weak var secondSaveButton: UIButton!
  
  var keyHeight: CGFloat?
  
  var link: String?
  var imageLink: String?
  var newFolderVisible = false
  
  let dbHelper = DBHelper.shared

  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // MARK: - 상단 Round
    layoutView?.layer.cornerRadius = 30
    
    // MARK: - 배경 누를 때 팝업
    self.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showConfirmDialog(_:))))
    
    self.firstSaveButton?.tintColor = UIColor.secondary
    self.secondSaveButton?.tintColor = UIColor.grey300
    
    self.setNameTextField()
    
    self.visibleToggleButton.isUserInteractionEnabled = true
    self.visibleToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTogglePressed(_:))))
    
    NSLog("❇️ link: \(link ?? ""), image: \(imageLink ?? "")")
    
    // MARK: - 키보드 처리
    setKeyboardObserver()
    
    self.newFolderNameField.returnKeyType = .done
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let viewController = segue.destination as? FolderSaveSuccessViewController {
      viewController.link = self.link
      viewController.folder = Folder(
        name: newFolderNameField.text!,
        visible: newFolderVisible ? 0 : 1,
        imageLink: imageLink
      )
      viewController.saveType = SaveType.New
    }
  }
  
  @IBAction func didEndOnExit(_ sender: Any) {
  }
  
  @objc func onTogglePressed(_ sender: UILongPressGestureRecognizer) {
    if newFolderVisible {
      newFolderVisible = false
      visibleToggleButton.image = UIImage(named: "toggle_off")
    } else {
      newFolderVisible = true
      visibleToggleButton.image = UIImage(named: "toggle_on")
    }
    
  }
  
  fileprivate func setNameTextField() {
    newFolderNameField.addTarget(self, action: #selector(self.onFolderNameChange(_:)), for: .editingChanged)
    newFolderNameField.textColor = UIColor.grey800
    newFolderNameField.tintColor = UIColor.primary600
    
    
    let border = CALayer()
    border.frame = CGRect(
      x: 0,
      y: newFolderNameField.frame.size.height + 9,
      width: newFolderNameField.frame.size.width,
      height: 2
    )
    border.backgroundColor = UIColor.primary600.cgColor
    newFolderNameField.layer.addSublayer(border)
  }
  
  @objc func onFolderNameChange(_ sender: Any?) {
    let text = self.newFolderNameField?.text ?? ""
    
    self.firstSaveButton?.tintColor = text.isEmpty ? UIColor.secondary : UIColor.primary600
    self.secondSaveButton?.tintColor = text.isEmpty ? UIColor.grey300 : UIColor.grey800
    
  }
  
  @objc func showConfirmDialog(_ sender: UITapGestureRecognizer? = nil) {
    let sb = UIStoryboard.init(name: "Dialog", bundle: nil)
    
    let dialogVC = sb.instantiateViewController(withIdentifier: "FolderSaveCancelDialog") as! FolderSaveCancelDialogViewController
    
    dialogVC.modalPresentationStyle = .overCurrentContext
    dialogVC.modalTransitionStyle = .crossDissolve
    dialogVC.confirmButtonCompletionClosure = {
      self.hideExtensionWithCompletionHandler()
    }
    
    self.present(dialogVC, animated: true, completion: nil)
  }
  
  
  @IBAction func onBackButtonPressed(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func onCompletePressed(_ sender: Any) {
    self.saveFolder(sender)
  }
  
  @IBAction func saveFolder(_ sender: Any) {
    
    let folderName = self.newFolderNameField?.text!
    
    NSLog("\(String(describing: newFolderVisible)) \(String(describing: folderName))")
    
    let visible = newFolderVisible ? 0 : 1
    
    if self.link != nil, !(folderName?.isEmpty ?? true) {
      let result = dbHelper.insertData(name: folderName!, visible: visible, imageLink: imageLink)
      UserDefaultsHelper.saveNewFolder(self.link!, folderName!, self.newFolderVisible)
      
      NSLog("❇️ new folder save result: \(result)")
      
      performSegue(withIdentifier: "saveSuccessSegue", sender: self)
    }
  }
  
  private func hideExtensionWithCompletionHandler() {
    UIView.animate(withDuration: 0.3, animations: {
      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    }, completion: { _ in
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
  }
}
