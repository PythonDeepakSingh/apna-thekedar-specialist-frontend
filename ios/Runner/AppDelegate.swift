import UIKit
import Flutter
import GoogleMaps // Yeh line zaroori hai

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // API Key ko yahan daalein
    GMSServices.provideAPIKey("AIzaSyCNMGxpTs6Ln-E0r-sMMmX46gFrUx6jY_Y") 
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
