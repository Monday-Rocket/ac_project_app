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
  
  @IBOutlet weak var titleTextView: UILabel!
  
  var folder: Folder?
  var saveType: SaveType?
  var link: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSLog("\(String(describing: folder)) \(saveType.debugDescription) \(link ?? "")")
    
    // MARK: - 상단 Round
    layoutView?.layer.cornerRadius = 30
    
    self.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.hideExtensionWithCompletionHandler(_:))))
    
    folderNameTextView.text = folder?.name
    
    let imageLink = folder?.image_link ?? ""
    
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
    visibleImageView.image = folder?.visible == 1 ? nil : UIImage(named: "ic_lock")
    
    titleTextView.text = saveType == SaveType.New ? "새 폴더에 저장 완료!" : "선택한 폴더에 저장 완료!"
  }
  
  @objc func hideExtensionWithCompletionHandler(_ sender: UITapGestureRecognizer? = nil) {
    UIView.animate(withDuration: 0.3, animations: {
      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    }, completion: { _ in
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
  }
  
}
