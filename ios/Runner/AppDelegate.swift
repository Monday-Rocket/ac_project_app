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
      } else {
        result(FlutterMethodNotImplemented)
      }
      
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  func getNewLinks() -> [String] {
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
  
}
