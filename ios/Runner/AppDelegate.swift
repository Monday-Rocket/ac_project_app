import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let localPathChannel = FlutterMethodChannel(name: "share_data_provider",
                                                binaryMessenger: controller.binaryMessenger)
    localPathChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      if (call.method == "getNewLinks") {
        let data = self.getNewLinks()
        result(data)
      } else if (call.method == "getNewFolders") {
        let data = self.getNewFolders()
        result(data)
      } else if (call.method == "getShareDBUrl") {
        let dbUrl = self.getShareDBUrl() ?? ""
        result(dbUrl)
      } else if (call.method == "clearData") {
        let clearResult = self.clearData()
        result(clearResult)
      } else {
        result(FlutterMethodNotImplemented)
      }
      
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  func getNewLinks() -> Dictionary<String, Any> {
    let linkStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
    let keyList = linkStorage.dictionaryRepresentation().keys.sorted()
    
    var dict = Dictionary<String, Any>()
    
    for keyData in keyList {
      let key = keyData.description
      if key.contains("http") {
        dict[key] = linkStorage.object(forKey: keyData.description)
      }
    }
    
    return dict
  }
  
  func getNewFolders() -> [Any] {
    let folderStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_folders")!
    return folderStorage.array(forKey: "new_folders") ?? []
  }
  
  func getShareDBUrl() -> String? {
    
    let fileContainer = FileManager
      .default
      .containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.mr.acProjectApp.Share"
      )
    
    return fileContainer?.path
  }
  
  func clearData() -> Bool {
    let folderStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_folders")!
    let linkStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
    
    folderStorage.removeObject(forKey: "new_folders")
    linkStorage.dictionaryRepresentation().keys.forEach(linkStorage.removeObject(forKey:))
    
    return true
  }
  
}
