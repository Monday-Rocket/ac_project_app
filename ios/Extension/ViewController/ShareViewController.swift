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
import WebKit

class ShareViewController: UIViewController {
  
  
  @IBOutlet weak var layoutView: UIView!
  @IBOutlet weak var checkImageView: UIImageView!
  @IBOutlet weak var closeButton: UIButton!
  
  @IBOutlet weak var backgroundView: UIView!
  
  @IBOutlet weak var folderListView: UICollectionView!
  @IBOutlet weak var emptyFolderButton: UIButton!
  
  @IBOutlet weak var emptyFolderViewConstraints: NSLayoutConstraint!
  @IBOutlet weak var blockingView: UIView!
  
  var webView: WKWebView = WKWebView()
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
    self.layoutView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
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
        for itemProvider in itemProviders {
          
          let isUrl = itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
          let isText = itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
          
          if itemProviders.count > 1 && !isUrl {
            continue
          }
          
          if isUrl == true {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) {
              (data, error) in
              let text = (data as? NSURL)?.absoluteString ?? ""
              NSLog("❇️ link: \(text)")
              self.saveLink(text)
            }
          } else if isText == true {
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
  
  fileprivate func saveOpenGraphData(_ link: String, _ rawTitle: String, _ og: OpenGraph) {
    let safeTitle = String(htmlEncodedString: rawTitle) ?? ""
    
    self.titleText = Data(safeTitle.utf8).base64EncodedString()
    self.linkImageUrl = (og[.image] ?? "")
    UserDefaultsHelper.saveLinkWithoutFolder(link, self.linkImageUrl, self.titleText)
  }
  
  // webview에서 새로운 redirect url 기다린다.
  fileprivate func waitSecondUrl(_ originalLink: String) async {
    for i in 0...10 {
      try? await Task.sleep(nanoseconds: 0_300_000_000)
      if self.webView.isLoading == false {
        
        let changed = self.webView.url!.absoluteString.removingPercentEncoding ?? ""
        NSLog("changed: \(changed)")
        guard let queryItems = URLComponents(string: changed)!.queryItems else {
          return
        }
        var found = false
        for item in queryItems {
          if item.name == "url" {
            if let newLink = URL(string: item.value!) {
              OpenGraph.fetch(url: newLink, headers: ["User-Agent": "facebookexternalhit/1.1"], completion: { secondResult in
                switch secondResult {
                  case .success(let og2):
                    self.saveOpenGraphData(originalLink, og2[.title] ?? "", og2)
                    DispatchQueue.main.sync {
                      self.blockingView.isHidden = true
                      self.layoutView.layoutIfNeeded()
                    }
                    break
                  default:
                    break
                }
              })
              found = true
            }
            break
          }
        }
        // for YouTube
        if found == false {
          
          // only first url
          let realLast = String(changed.split(separator: "&")[0])
          NSLog("realLast: \(realLast)")
          
          if let newLink = URL(string: realLast) {
            OpenGraph.fetch(url: newLink, headers: ["User-Agent": "facebookexternalhit/1.1"], completion: { secondResult in
              switch secondResult {
                case .success(let og2):
                  self.saveOpenGraphData(originalLink, og2[.title] ?? "", og2)
                  DispatchQueue.main.sync {
                    self.blockingView.isHidden = true
                    self.layoutView.layoutIfNeeded()
                  }
                  break
                default:
                  break
              }
            })
          }
        }
        
        
        break
      } else {
        NSLog("🌏 sleep!: \(i)")
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
    
    // 만약을 위한 웹뷰 로딩
    let url = URL(string: link)
    let request = URLRequest(url: url!)
    self.webView.load(request)
    
    OpenGraph.fetch(url: URL(string: link)!, headers: ["User-Agent": "facebookexternalhit/1.1"], completion: { result in
      switch result {
        case .success(let og):
          if og[.title] == nil {
            Task {
              await self.waitSecondUrl(link)
            }
          } else {
            self.saveOpenGraphData(link, og[.title] ?? "", og)
            DispatchQueue.main.sync {
              self.blockingView.isHidden = true
              self.layoutView.layoutIfNeeded()
            }
          }
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
    let folderName = item.name
    if folderName.count > 7 {
      cell.folderNameView.text = String(folderName.prefix(7)) + "..."
    } else {
      cell.folderNameView.text = folderName
    }
    cell.visibleView.image = item.visible == 1 ? nil : UIImage(named: "ic_lock_png")
    
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
