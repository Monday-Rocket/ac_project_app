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

  @IBOutlet weak var firstSaveButton : UIButton?
  @IBOutlet weak var secondSaveButton: UIButton!
  
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
    self.firstSaveButton?.isEnabled = false
    self.secondSaveButton?.isEnabled = false
    
    self.setNameTextField()
    
    self.visibleToggleButton.isUserInteractionEnabled = true
    self.visibleToggleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTogglePressed(_:))))
    
    NSLog("❇️ link: \(link ?? ""), image: \(imageLink ?? "")")
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let viewController = segue.destination as? FolderSaveSuccessViewController {
      viewController.link = self.link
      viewController.folder = Folder(
        name: newFolderNameField.text!,
        visible: newFolderVisible ? 0 : 1,
        image_link: imageLink
      )
    }
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
      width: newFolderNameField.frame.size.width - 24,
      height: 2
    )
    border.backgroundColor = UIColor.primary600.cgColor
    newFolderNameField.layer.addSublayer(border)
  }
  
  @objc func onFolderNameChange(_ sender: Any?) {
    let text = self.newFolderNameField?.text ?? ""
    
    self.firstSaveButton?.tintColor = text.isEmpty ? UIColor.secondary : UIColor.primary600
    self.secondSaveButton?.tintColor = text.isEmpty ? UIColor.grey300 : UIColor.grey800
    self.firstSaveButton?.isEnabled = !text.isEmpty
    self.secondSaveButton?.isEnabled = !text.isEmpty
    
  }
  
  @objc func showConfirmDialog(_ sender: UITapGestureRecognizer? = nil) {
    //    UIView.animate(withDuration: 0.3, animations: {
    //      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    //    }, completion: { _ in
    //      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    //    })
  }
  
  
  @IBAction func onBackButtonPressed(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func onCompletePressed(_ sender: Any) {
    self.saveFolder(sender)
  }
  
  @IBAction func saveFolder(_ sender: Any) {
    
    NSLog("\(String(describing: newFolderVisible))   \(String(describing: newFolderNameField!.text!))")
    
    let visible = newFolderVisible ? 0 : 1
    
    if(newFolderNameField?.text != nil){
      let result = dbHelper.insertData(name:newFolderNameField!.text!, visible: visible, image_link: imageLink)
      NSLog("❇️ new folder save result: \(result)")
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
