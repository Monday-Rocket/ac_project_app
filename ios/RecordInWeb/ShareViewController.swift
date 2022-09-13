//
//  ShareViewController.swift
//  RecordInWeb
//
//  Created by Kangmin Jin on 2022/09/13.
//

import UIKit
import Social
import MobileCoreServices

class ShareViewController: UIViewController {
    
    
    @IBOutlet weak var JustButton: UIButton!
    @IBOutlet weak var JustView: UIView!
    
    override func viewDidLoad() {
        
        JustView.layer.cornerRadius = 20
    }
    
    func hideExtensionWithCompletionHandler(completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y:self.navigationController!.view.frame.size.height)
        }, completion: completion)
    }

    @IBAction func closeWindow(_ sender: Any) {
        self.hideExtensionWithCompletionHandler(completion: { _ in
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        })
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
