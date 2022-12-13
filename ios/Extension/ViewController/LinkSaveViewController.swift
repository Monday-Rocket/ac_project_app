//
//  LinkSaveViewController.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/12/13.
//

import UIKit
import UniformTypeIdentifiers
import OpenGraph

class LinkSaveViewController: UIViewController {
  
  var link: String?
  var linkImageUrl: String?
  var titleText: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.getLink()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let viewController = segue.destination as? ShareViewController {
      viewController.link = self.link
      viewController.titleText = self.titleText
      viewController.linkImageUrl = self.linkImageUrl
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
          self.showSuccessView()
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
  
  func showSuccessView() {
    DispatchQueue.main.async {
      self.performSegue(withIdentifier: "linkSaveSuccessSegue", sender: self)
    }
  }
}
