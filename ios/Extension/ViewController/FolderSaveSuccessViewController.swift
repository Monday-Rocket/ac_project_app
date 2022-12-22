//
//  FolderSaveSuccessViewController.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/10.
//

import Foundation
import UIKit

class FolderSaveSuccessViewController: UIViewController {
  
  @IBOutlet weak var folderNameTextView: PaddingLabel!
  
  @IBOutlet weak var layoutView: UIView!
  @IBOutlet weak var backgroundView: UIView!
  @IBOutlet weak var visibleImageView: UIImageView!
  @IBOutlet weak var folderImageView: UIImageView!
  
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var titleTextView: UILabel!
  
  var folder: Folder?
  var saveType: SaveType?
  var link: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSLog("\(String(describing: folder)) \(saveType.debugDescription) \(link ?? "")")
    
    // MARK: - 상단 Round
    layoutView?.layer.cornerRadius = 30
    layoutView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
    self.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.hideExtensionWithCompletionHandler(_:))))
    
    folderNameTextView.text = folder?.name
    
    let imageLink = folder?.imageLink ?? ""
    
    if (imageLink.isEmpty) {
      folderImageView.image = UIImage(named: "empty_image_folder")
    } else {
      do {
        let url = URL(string : imageLink)
        if url != nil {
          folderImageView.image = UIImage(data : try Data(contentsOf: url!))
        } else {
          folderImageView.image = UIImage(named: "empty_image_folder")
        }
      }
      catch {
        folderImageView.image = UIImage(named: "empty_image_folder")
      }
    }
    visibleImageView.image = folder?.visible == 1 ? nil : UIImage(named: "ic_lock_png")
    
    titleTextView.text = saveType == SaveType.New ? "새 폴더에 저장 완료!" : "선택한 폴더에 저장 완료!"
  }
  
  @IBAction func onClose(_ sender: Any) {
    self.hideExtensionWithCompletionHandler()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let viewController = segue.destination as? CommentViewController {
      viewController.link = self.link
      viewController.saveType = self.saveType
    }
  }
  
  @objc func hideExtensionWithCompletionHandler(_ sender: UITapGestureRecognizer? = nil) {
    UIView.animate(withDuration: 0.3, animations: {
      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    }, completion: { _ in
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
  }
  
  @IBAction func goToApp(_ sender: Any) {
    self.hideExtensionWithCompletionHandler()
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
}
