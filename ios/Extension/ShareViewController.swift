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

class ShareViewController: UIViewController {
    
    
    @IBOutlet weak var btnTest: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func showToast(message : String, font: UIFont = UIFont.systemFont(ofSize: 14.0)) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: 150, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 10.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    @IBAction func test(){
        if let extensionItem = self.extensionContext?.inputItems[0] as? NSExtensionItem {
            if let itemProviders = extensionItem.attachments{
                for itemProvider in itemProviders{
                    if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier){
                        itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil){
                            (data, error) in
                            let text = (data as! NSURL).absoluteString!
                            
                            let sharedDefault = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share")!
                            var savedData = sharedDefault.object(forKey: "shareDataList") as! [String]? ?? []
                            savedData.append(text)
                            sharedDefault.set(savedData, forKey: "shareDataList")
                            
                            self.hideExtensionWithCompletionHandler()
                        }
                    }
                }
            }
        }
    }
    
    func hideExtensionWithCompletionHandler() {
        UIView.animate(withDuration: 0.3, animations: {
            self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
        }, completion: { _ in
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        })
    }
    
    func sharedDirectoryURL() -> URL {
        let fileManager = FileManager.default
        return fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mr.acProjectApp.Share")!
    }
}
