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
        
        
        let fileManager = FileManager.default

        let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        let directoryURL = documentURL.appendingPathComponent("test")

        do{
            try fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: false, attributes: nil)
        }catch let e {
            print(e.localizedDescription)
        }

        let urlPath = directoryURL.appendingPathComponent("url.txt")

        var text = ""
        
        if let extensionItem = self.extensionContext?.inputItems[0] as? NSExtensionItem {
            if let itemProviders = extensionItem.attachments{
                for itemProvider in itemProviders{
                    if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier){
                        itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil){
                            (data, error) in
                            text = (data as! NSURL).absoluteString!
                            //print(text)
                            
                            //쓰기
                            do{
                                try text.write(to: urlPath, atomically: false, encoding: .utf8)
                                
                                print("text write : \(text)")
                            }catch let error as NSError{
                                print("error : \(error.localizedDescription)")
                            }
                            //읽기
                            do {
                                let txt = try String(contentsOf: urlPath, encoding: .utf8)
                                
                                print("text read : \(txt)")
                            }catch let error as NSError{
                                print("error : \(error.localizedDescription)")
                            }
                            
                            
                        }
                    }
                }
            }
        }
        
        

    
        
    }
}
