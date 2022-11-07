//
//  NewFolderViewControll.swift
//  Extension
//
//  Created by 유재선 on 2022/10/30.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class NewFolderViewController : UIViewController {
    
    @IBOutlet weak var insertFolderButton : UIButton?
    @IBOutlet weak var newFolderNameField : UITextField?
    @IBOutlet weak var newFolderVisible : UISwitch?
    @IBOutlet weak var preButton : UIButton?
    
    let dbHelper = DBHelper.shared
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    
    
    @IBAction func insertFolder () {
        
        NSLog("\(String(describing: newFolderVisible!.isOn))   \(String(describing: newFolderNameField!.text!))")
        
        
        let visible = newFolderVisible!.isOn ?  1 : 0
        
        if(newFolderNameField?.text != nil){
            dbHelper.insertData(name:newFolderNameField!.text!, visible: visible, image_link: "'www.naver.com'")
            
        }
    
        NSLog("db data : \(dbHelper.readData()) ")
    }
}
