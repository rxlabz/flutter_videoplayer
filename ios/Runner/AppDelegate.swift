import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

  override func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {

    let project = FlutterDartProject(fromDefaultSourceForConfiguration: ())

    window = UIWindow(frame: UIScreen.main.bounds)

    if let flutterController = MediaPlayerViewController(project: project, nibName: nil, bundle: nil) {
      initListeners(flutterController)

      window.rootViewController = flutterController
      window.makeKeyAndVisible()
    }

    return true
  }

  func initListeners(_ controller: MediaPlayerViewController) {
    let playVideoListener = OnPlayVideo(messageName: "playVideo", controller: controller)
    controller.add(playVideoListener)

    let pauseVideoListener = OnPauseVideo(messageName: "pauseVideo", controller: controller)
    controller.add(pauseVideoListener)

    let stopVideoListener = OnStopVideo(messageName: "stopVideo", controller: controller)
    controller.add(stopVideoListener)
  }
}
