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
    
    
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var btnTest: UIButton!

    @IBOutlet weak var linksTableView: UITableView!

    var dataArray : [Folder] = []

    let dbHelper = DBHelper.shared


    override func viewDidLoad() {
        super.viewDidLoad()

        self.linksTableView.delegate = self
        self.linksTableView.dataSource = self

    }


    func saveUrl(){


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
                        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
                                (data, error) in
                                let text = data as! String

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
