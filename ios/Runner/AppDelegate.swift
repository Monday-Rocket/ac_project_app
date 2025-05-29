import UIKit
import Flutter
import NidThirdPartyLogin
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
      
      // Retrieve the link from parameters
    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
          // We have a link, propagate it to your Flutter app or not
        AppLinks.shared.handleLink(url: url)
        return true // Returning true will stop the propagation to other packages
    }
      
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
    
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.absoluteString.hasPrefix("kakao"){
      super.application(app, open:url, options: options)
      return true
    } else if (NidOAuth.shared.handleURL(url) == true) { // If the URL was passed from the Naver app
        return true
    } else {
      return true
    }
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
    
    let path = fileContainer?.path
    NSLog("🍀 \(path!)")
    return path
  }
  
  func clearData() -> Bool {
    let folderStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_folders")!
    let linkStorage = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share.new_links")!
    
    folderStorage.removeObject(forKey: "new_folders")
    linkStorage.dictionaryRepresentation().keys.forEach(linkStorage.removeObject(forKey:))
    
    return true
  }
  
}
