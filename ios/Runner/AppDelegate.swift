import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let localPathChannel = FlutterMethodChannel(name: "ios_local_path",
                                                    binaryMessenger: controller.binaryMessenger)
        localPathChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            guard call.method == "getShareData" else {
                result(FlutterMethodNotImplemented)
                return
            }
            let sharedDefault = UserDefaults(suiteName: "group.com.mr.acProjectApp.Share")!
            let data = sharedDefault.object(forKey: "shareDataList") as! [String]? ?? []
            result(data)
            
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func sharedDirectoryURL() -> URL? {
        
        let fileManager = FileManager.default
        return fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mr.acProjectApp.Share")
    }
}
