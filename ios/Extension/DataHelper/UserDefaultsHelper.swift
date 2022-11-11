//
//  UserDefaultsHelper.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/11.
//

import Foundation

class UserDefaultsHelper {
  
  static func getNewLinks() -> [String] {
    let linkStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
    let keyList = linkStorage.dictionaryRepresentation().keys.sorted()
    
    var result: [String] = []
    
    for keyData in keyList {
      if keyData.description.contains("http") {
        result.append(keyData.description)
      }
    }
    
    return result
  }
  
  static func getNewFolders() -> [Any] {
    let folderStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_folders")!
    return folderStorage.array(forKey: "new_folders") ?? []
  }
  
  static func saveLinkWithFolder(_ item: Folder, _ title: String?, _ imageUrl: String?, _ link: String, _ dbHelper: DBHelper) {
    
    // 1. 링크 UserDefaults에 저장
    var jsonString = ""
    let jsonData = [
      "image_link": imageUrl,
      "title": title,
      "created_at": Date.ISOStringFromDate(date: Date()),
      "folder_name": item.name
    ]
    
    do {
      let temp = try JSONSerialization.data(withJSONObject: jsonData, options: .withoutEscapingSlashes)
      jsonString = String(data: temp, encoding: .utf8) ?? ""
    } catch {
      NSLog("🚨 json error")
    }
    let sharedDefault = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
    sharedDefault.set(jsonString, forKey: link)
    
    // 2. DB 폴더 썸네일 최신화
    dbHelper.updateFolderImage(item.name, imageUrl)
  }
  
  static func saveLinkWithoutFolder(_ link: String, _ imageUrl: String?, _ titleText: String?) {
    
    let jsonData = [
      "image_link": imageUrl,
      "title": titleText,
      "created_at": Date.ISOStringFromDate(date: Date())
    ]
    
    do {
      let temp = try JSONSerialization.data(withJSONObject: jsonData, options: .withoutEscapingSlashes)
      let jsonString = String(data: temp, encoding: .utf8) ?? ""
      NSLog("❇️ \(jsonString)")
      let sharedDefault = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
      sharedDefault.set(jsonString, forKey: link)
    } catch {
      NSLog("🚨 json error")
    }
    
  }
  
  static func saveNewFolder(_ link: String, _ folderName: String, _ visible: Bool) {
    
    // 1. folder array 추가
    
    let folderData = [
      "name": folderName,
      "visible": visible,
      "created_at": Date.ISOStringFromDate(date: Date())
    ] as [String : Any]
    
    do {
      let temp = try JSONSerialization.data(withJSONObject: folderData, options: .withoutEscapingSlashes)
      let jsonString = String(data: temp, encoding: .utf8) ?? ""
      NSLog("❇️ \(jsonString)")
      let folderStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_folders")!
      
      var array = folderStorage.array(forKey: "new_folders") ?? []
      array.append(jsonString)
      folderStorage.set(array, forKey: "new_folders")
    } catch {
      NSLog("🚨 json error")
    }
    
    // 2. link 정보 꺼내서 폴더 이름 추가하기
    
    let linkStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
    let savedData = linkStorage.string(forKey: link) ?? ""
    
    do {
      var jsonData = try JSONSerialization.jsonObject(with: Data(savedData.utf8), options: []) as! Dictionary<String, Any>
      jsonData["folder_name"] = folderName
      
      do {
        let temp = try JSONSerialization.data(withJSONObject: jsonData, options: .withoutEscapingSlashes)
        let jsonString = String(data: temp, encoding: .utf8) ?? ""
        NSLog("❇️ \(jsonString)")
        
        linkStorage.set(jsonString, forKey: link)
      } catch {
        NSLog("🚨 json error")
        return
      }
      
    } catch {
      NSLog("🚨 saved data error")
      return
    }
  }
  
  static func saveComment(_ link: String, _ comment: String) {
    let linkStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
    
    do {
      if let savedData = linkStorage.string(forKey: link) {
        var jsonData = try JSONSerialization.jsonObject(with: Data(savedData.utf8), options: []) as! Dictionary<String, Any>
        jsonData["comment"] = comment
        
        do {
          let temp = try JSONSerialization.data(withJSONObject: jsonData, options: .withoutEscapingSlashes)
          let jsonString = String(data: temp, encoding: .utf8) ?? ""
          NSLog("❇️ \(jsonString)")
          
          linkStorage.set(jsonString, forKey: link)
        } catch {
          NSLog("🚨 json error")
          return
        }
      }
    } catch {
      NSLog("🚨 saved data error")
      return
    }
  }
}
