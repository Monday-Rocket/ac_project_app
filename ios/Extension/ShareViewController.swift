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
  
  
  @IBOutlet weak var layoutView: UIView?
  @IBOutlet weak var checkImageView: UIImageView!
  @IBOutlet weak var closeButton: UIButton!
  
  @IBOutlet weak var backgroundView: UIView!
  
  @IBOutlet weak var folderListView: UICollectionView!
  
  var dataArray : [Folder] = []
  
  let dbHelper = DBHelper.shared
  var link: String?
  var linkImageUrl: String?
  var selectedFolder: Folder?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.folderListView.delegate = self
    self.folderListView.dataSource = self
    self.layoutView?.layer.cornerRadius = 30
    
    self.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.hideExtensionWithCompletionHandler(_:))))
    
    self.loadFolders()
    self.saveUrl()
  }
  
  @IBAction func closeWindow(_ sender: Any) {
    self.hideExtensionWithCompletionHandler()
  }
  
  
  private func loadFolders() {
    dataArray = dbHelper.readData()
  }
  
  private func saveUrl() {
    if let extensionItem = self.extensionContext?.inputItems[0] as? NSExtensionItem {
      if let itemProviders = extensionItem.attachments{
        for itemProvider in itemProviders{
          if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier){
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil){
              (data, error) in
              let text = (data as! NSURL).absoluteString!
              NSLog("❇️ link: \(text)")
              self.saveLinkWithoutFolder(text)
            }
          } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
              (data, error) in
              let text = data as! String
              NSLog("❇️ link: \(text)")
              self.saveLinkWithoutFolder(text)
            }
          }
        }
      }
    }
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
  
  private func saveLinkWithoutFolder(_ link: String) {
    
    // 링크가 아니면 저장 안함
    guard (link.starts(with: "http://") || link.starts(with: "https://")) else {
      return
    }
    
    self.link = link
    var title: String? = ""
    
    OpenGraph.fetch(url: URL(string: link)!, completion: { result in
      switch result {
        case .success(let og):
          NSLog("🌏 \(String(describing: og[.imageUrl])) \(String(describing: og[.imageSecure_url])) \(String(describing: og[.image]))")
          title = og[.title] ?? ""
          self.linkImageUrl = (og[.image] ?? "")
          let date = Date.ISOStringFromDate(date: Date())
          let jsonData = [
            "image_link": self.linkImageUrl,
            "title": title,
            "created_at": date
          ]
          var jsonString = ""
          
          do {
            let temp = try JSONSerialization.data(withJSONObject: jsonData, options: .withoutEscapingSlashes)
            jsonString = String(data: temp, encoding: .utf8) ?? ""
          } catch {
            NSLog("🚨 json error")
          }
          
          NSLog("❇️ \(jsonString)")
          let sharedDefault = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
          sharedDefault.set(jsonString, forKey: jsonString)
          break
        case .failure(let error):
          NSLog("🚨 open graph error: \(error.localizedDescription)")
      }
    })
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
    let item = dataArray[indexPath.item]
    self.selectedFolder = item
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
    guard let url = item.image_link, !item.image_link!.isEmpty else {
      cell.imageView.image = UIImage(named: "empty_image_folder")
      return cell
    }
    
    do {
      cell.imageView.image = UIImage(data : try Data(contentsOf: URL(string : url)!))
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


//extension ShareViewController: UITableViewDelegate, UITableViewDataSource {
//  func tableView(_ linksTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    self.dataArray.count
//  }
//
//  func tableView(_ linksTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    guard let cell = self.linksTableView.dequeueReusableCell(withIdentifier: "tableViewCell") as? CustomTableViewCell
//    else { fatalError("can't get cell") }
//
//    do{
//      let item = dataArray[indexPath.row]
//      let url = item.image_link ?? ""
//      cell.imageLinkView.image = UIImage(data : try Data(contentsOf: URL(string : url)!))
//      cell.nameView.text = item.name
//      cell.visibleView.image = item.visible == 1 ? nil : UIImage(named: "ic_lock")
//
//    }
//    catch {
//    }
//
//    return cell
//  }
//
//
//}
//
//
//class CustomTableViewCell: UITableViewCell {
//  @IBOutlet weak var imageLinkView: UIImageView!
//  @IBOutlet weak var nameView: UILabel!
//  @IBOutlet weak var visibleView: UIImageView!
//
//  override func awakeFromNib() {
//    super.awakeFromNib()
//    // Initialization code
//  }
//
//  override func setSelected(_ selected: Bool, animated: Bool) {
//    super.setSelected(selected, animated: animated)
//
//    // Configure the view for the selected state
//  }
//
//}
