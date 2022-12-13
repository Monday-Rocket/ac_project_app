//
//  ShareViewController.swift
//  sharetest
//
//  Created by 유재선 on 2022/09/18.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import OpenGraph

class ShareViewController: UIViewController {
  
  
  @IBOutlet weak var layoutView: UIView!
  @IBOutlet weak var checkImageView: UIImageView!
  @IBOutlet weak var closeButton: UIButton!
  
  @IBOutlet weak var backgroundView: UIView!
  
  @IBOutlet weak var folderListView: UICollectionView!
  @IBOutlet weak var emptyFolderButton: UIButton!
  
  @IBOutlet weak var emptyFolderViewConstraints: NSLayoutConstraint!
  var dataArray : [Folder] = []
  
  let dbHelper = DBHelper.shared
  var link: String?
  var linkImageUrl: String?
  var selectedFolder: Folder?
  var titleText: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.getLink()  // link 아니면 에러 팝업으로 이동
    
    self.folderListView.delegate = self
    self.folderListView.dataSource = self
    self.folderListView.backgroundColor = UIColor.white
    self.layoutView?.layer.cornerRadius = 30
    
    self.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.hideExtensionWithCompletionHandler(_:))))
    
    self.loadFolders()
    
    NSLog(UserDefaultsHelper.getNewLinks().description)
    NSLog(UserDefaultsHelper.getNewFolders().description)
  }
  
  @IBAction func closeWindow(_ sender: Any) {
    self.hideExtensionWithCompletionHandler()
  }
  
  @IBAction func addNewFolder(_ sender: Any) {
    performSegue(withIdentifier: "addNewFolderSegue", sender: self)
  }
  
  private func loadFolders() {
    dataArray = dbHelper.readData()
    NSLog("dataArray count: \(dataArray.count)")
    if (dataArray.isEmpty) {
      self.emptyFolderButton.isHidden = false
    } else {
      self.emptyFolderButton.isHidden = true
    }
    
    self.layoutView.layoutIfNeeded()
  }
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if let viewController = segue.destination as? NewFolderViewController {
      viewController.link = self.link
      viewController.imageLink = self.linkImageUrl
    }
    
    if let viewController = segue.destination as? FolderSaveSuccessViewController {
      viewController.link = self.link
      viewController.folder = self.selectedFolder
      viewController.saveType = SaveType.Selected
    }
  }
  
  private func getLink() {
    if let extensionItem = self.extensionContext?.inputItems[0] as? NSExtensionItem {
      if let itemProviders = extensionItem.attachments{
        for itemProvider in itemProviders{
          if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier){
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil){
              (data, error) in
              let text = (data as? NSURL)?.absoluteString ?? ""
              NSLog("❇️ link: \(text)")
              self.saveLink(text)
            }
          } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
              (data, error) in
              let text = data as? String ?? ""
              NSLog("❇️ link: \(text)")
              self.saveLink(text)
            }
          }
        }
      }
    }
  }
  
  
  private func saveLink(_ link: String) {
    
    // 링크가 아니면 저장 안함
    guard (link.starts(with: "http://") || link.starts(with: "https://")) && !link.isEmpty else {
      self.showLinkErrorDialog()
      return
    }
    
    self.link = link
    
    OpenGraph.fetch(url: URL(string: link)!, completion: { result in
      switch result {
        case .success(let og):
          NSLog("🌏 \(String(describing: og[.imageUrl])) \(String(describing: og[.imageSecure_url])) \(String(describing: og[.image]))")
          self.titleText = og[.title] ?? ""
          self.linkImageUrl = (og[.image] ?? "")
          UserDefaultsHelper.saveLinkWithoutFolder(link, self.linkImageUrl, self.titleText)
          break
        case .failure(let error):
          NSLog("🚨 open graph error: \(error.localizedDescription)")
          self.showLinkErrorDialog()
      }
    })
  }
  
  func showLinkErrorDialog() {
    DispatchQueue.main.async {
      self.performSegue(withIdentifier: "linkErrorSegue", sender: self)
    }
  }
  
  @objc func hideExtensionWithCompletionHandler(_ sender: UITapGestureRecognizer? = nil) {
    UIView.animate(withDuration: 0.3, animations: {
      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    }, completion: { _ in
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
  }
}

extension ShareViewController: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    self.dataArray.count
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let width: CGFloat = 95
    let height: CGFloat = 115
    
    return CGSize(width: width, height: height)
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    guard self.link != nil else {
      return
    }
    // , (comma)로 guard 조건 추가할 때 Optional 체크 안하는지 확인 필요
    guard (self.link!.starts(with: "http://") || self.link!.starts(with: "https://")) else {
      return
    }
    
    var item = dataArray[indexPath.item]
    item.imageLink = self.linkImageUrl
    self.selectedFolder = item
    
    UserDefaultsHelper.saveLinkWithFolder(item, self.titleText, self.linkImageUrl, self.link!, self.dbHelper)
    
    performSegue(withIdentifier: "folderSaveSuccess", sender: self)
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = self.folderListView.dequeueReusableCell(
      withReuseIdentifier: "customCell",
      for: indexPath) as? CustomListViewCell else { fatalError("cell init error!") }
    
    let item = dataArray[indexPath.row]
    
    cell.folderNameView.text = item.name
    cell.visibleView.image = item.visible == 1 ? nil : UIImage(named: "ic_lock")
    
    cell.imageView.contentMode = .scaleAspectFill
    guard let imageUrl = item.imageLink, !item.imageLink!.isEmpty else {
      cell.imageView.image = UIImage(named: "empty_image_folder")
      return cell
    }
    
    do {
      NSLog("🌱 \(imageUrl)")
      let url = URL(string : imageUrl)
      if url != nil {
        cell.imageView.image = UIImage(data : try Data(contentsOf: url!))
      } else {
        cell.imageView.image = UIImage(named: "empty_image_folder")
      }
    }
    catch {
      cell.imageView.image = UIImage(named: "empty_image_folder")
    }
    
    return cell
  }
}


class CustomListViewCell: UICollectionViewCell {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var folderNameView: UILabel!
  @IBOutlet weak var visibleView: UIImageView!
  
  override class func awakeFromNib() {
    super.awakeFromNib()
  }
}
