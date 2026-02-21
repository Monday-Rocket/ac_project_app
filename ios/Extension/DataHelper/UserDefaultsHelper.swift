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
    let sharedDefault = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!

    // Read existing entry and update folder_name (preserves OG data)
    var jsonData: [String: Any] = [:]
    if let savedData = sharedDefault.string(forKey: link),
       let data = savedData.data(using: .utf8),
       let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      jsonData = existing
    } else {
      // No existing data - create fresh entry
      jsonData["image_link"] = imageUrl
      jsonData["title"] = title
      jsonData["created_at"] = Date.ISOStringFromDate(date: Date())
    }

    jsonData["folder_name"] = item.name

    do {
      let temp = try JSONSerialization.data(withJSONObject: jsonData, options: .withoutEscapingSlashes)
      let jsonString = String(data: temp, encoding: .utf8) ?? ""
      sharedDefault.set(jsonString, forKey: link)
      sharedDefault.synchronize()
    } catch {
      NSLog("🚨 json error")
    }

    // DB 폴더 썸네일 최신화
    dbHelper.updateFolderImage(item.name, imageUrl)
  }
  
  static func saveLinkWithoutFolder(_ link: String, _ imageUrl: String?, _ titleText: String?) {
    let sharedDefault = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!

    // Read existing entry and update OG fields (preserves folder_name if already set)
    var jsonData: [String: Any] = [:]
    if let savedData = sharedDefault.string(forKey: link),
       let data = savedData.data(using: .utf8),
       let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      jsonData = existing
    }

    jsonData["image_link"] = imageUrl
    jsonData["title"] = titleText
    if jsonData["created_at"] == nil {
      jsonData["created_at"] = Date.ISOStringFromDate(date: Date())
    }

    do {
      let temp = try JSONSerialization.data(withJSONObject: jsonData, options: .withoutEscapingSlashes)
      let jsonString = String(data: temp, encoding: .utf8) ?? ""
      NSLog("❇️ \(jsonString)")
      sharedDefault.set(jsonString, forKey: link)
      sharedDefault.synchronize()
    } catch {
      NSLog("🚨 json error")
    }
  }
  
  static func saveNewFolder(_ link: String, _ folderName: String) {

    // 1. folder array 추가

    let folderData = [
      "name": folderName,
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
      folderStorage.synchronize()
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
        linkStorage.synchronize()
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
          linkStorage.synchronize()
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
