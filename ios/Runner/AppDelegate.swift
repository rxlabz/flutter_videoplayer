import UIKit
import AVFoundation
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

  var videoPlayer: FlutterVideoPlayer?

  override func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {

    if let controller = self.window.rootViewController as? Flutter.FlutterViewController {
      videoPlayer = FlutterVideoPlayer(controller)
      videoPlayer?.initListeners()
    } else {
      print("no FlutterViewController")
    }

    return true
  }
}

