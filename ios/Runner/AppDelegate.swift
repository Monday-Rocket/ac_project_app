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
      
      if (call.method == "getShareData") {
        let sharedDefault = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share")!
        let data = sharedDefault.object(forKey: "shareDataList") as! [String]? ?? []
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
  
  func getShareDBUrl() -> String? {
    
    let fileContainer = FileManager
      .default
      .containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.mr.acProjectApp.Share"
      )
    
    return fileContainer?.appendingPathExtension("share.db").path
  }
  
}
