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
  @IBOutlet weak var btnTest: UIButton!
  
  @IBOutlet weak var linksTableView: UITableView!
  
  var dataArray : [Folder] = []
  
  let dbHelper = DBHelper.shared
  var link: String?
  var linkImageUrl: String?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.linksTableView.delegate = self
    self.linksTableView.dataSource = self
    self.layoutView?.layer.cornerRadius = 30
//    self.btnTest.
    
    self.loadFolders()
    self.saveUrl()
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
  
  func hideExtensionWithCompletionHandler() {
    UIView.animate(withDuration: 0.3, animations: {
      self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
    }, completion: { _ in
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    })
  }
}

extension ShareViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ linksTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    self.dataArray.count
  }
  
  func tableView(_ linksTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = self.linksTableView.dequeueReusableCell(withIdentifier: "tableViewCell") as? CustomTableViewCell
    else { fatalError("can't get cell") }
    
    do{
      let url : String? = String(dataArray[indexPath.row].name)
      if(url != nil){
        cell.imageLinkView.image = UIImage(data : try Data(contentsOf: URL(string : String(dataArray[indexPath.row].name))!))
        
      }
      cell.nameView.text = String(dataArray[indexPath.row].name)
      if dataArray[indexPath.row].visible == 1 {
        
      }
    }
    catch {
    }
    
    return cell
  }
  
  
}


class CustomTableViewCell: UITableViewCell {
  @IBOutlet weak var imageLinkView: UIImageView!
  @IBOutlet weak var nameView: UILabel!
  @IBOutlet weak var visibleView: UIImageView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
