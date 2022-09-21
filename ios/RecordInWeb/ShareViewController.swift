//
//  ShareViewController.swift
//  RecordInWeb
//
//  Created by Kangmin Jin on 2022/09/13.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    @IBOutlet weak var JustButton: UIButton!
    @IBOutlet weak var JustView: UIView!
    @IBOutlet weak var label11: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        JustView.layer.cornerRadius = 20
    }
    
    func showToast(message : String, font: UIFont = UIFont.systemFont(ofSize: 14.0)) {
            let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: 150, width: 150, height: 150))
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
    
    func hideExtensionWithCompletionHandler(completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
        }, completion: completion)
    }
    

    @IBAction func closeWindow(_ sender: Any) {
//        self.hideExtensionWithCompletionHandler(completion: { _ in
//            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
//        })
        


        if let extensionItem = self.extensionContext?.inputItems[0] as? NSExtensionItem {
            if let itemProviders = extensionItem.attachments{
                for itemProvider in itemProviders{
                    if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier){
                        itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil){
                            (data, error) in

                            let url_link : String = data as! String


                        }
                    }
                }
            }
        }
        
    }
    
}
extension UITextView {
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}
