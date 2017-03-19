//
// Created by rx on 19/03/2017.
// Copyright (c) 2017 The Chromium Authors. All rights reserved.
//

import Foundation
import AVFoundation
import Flutter

func getFlutterJsonMethod(withName name: String, forController controller: FlutterViewController)
    -> FlutterMethodChannel {
  return FlutterMethodChannel(
    name: name,
    binaryMessenger: controller,
    codec: FlutterJSONMethodCodec.sharedInstance())
}

func getFlutterJsonStream(withName name: String, forController controller: FlutterViewController)
    -> FlutterMessageChannel {
  return FlutterMessageChannel(
    name: name,
    binaryMessenger: controller,
    codec: FlutterJSONMessageCodec())
}

class FlutterVideoPlayer {

  let videoChannelName = "flutter/video"

  var viewController: Flutter.FlutterViewController
  var playerChannel: FlutterMethodChannel?
  var progressChannel: FlutterMessageChannel

  var isPlaying: Bool = false

  var currentProgress = ""

  private var player: AVPlayer

  private var layer: AVPlayerLayer?

  var currentUrl: String?

  private var progressWatcher: Any?

  private var timeFormatter: DateComponentsFormatter

  var view: UIView {
    get {
      return viewController.view
    }
  }

  init(_ viewController: FlutterViewController) {
    self.viewController = viewController
    player = AVPlayer()
    playerChannel = getFlutterJsonMethod(withName: videoChannelName, forController: viewController)
    progressChannel = getFlutterJsonStream(withName: "flutter/videoProgress", forController: viewController)
    timeFormatter = DateComponentsFormatter()
    timeFormatter.unitsStyle = .positional
    timeFormatter.allowedUnits = [.minute, .second]
    timeFormatter.zeroFormattingBehavior = [.pad]
  }

  func initListeners() {
    playerChannel?.setMethodCallHandler {
      (call: FlutterMethodCall?, result: FlutterResultReceiver?) -> Void in
      print("Swift-> methodCallHandler \(call!.method)")

      switch (call!.method) {
      case "playVideo":
        let res = try! self.playVideo(url: call!.arguments! as! String)
        result!("{\"status\":\(res),\"info\":\"\(self.timeFormatter.string(from: self.getVideoDuration())!)\"}", nil)
      case "pauseVideo":
        result!("{\"status\":\(self.pauseVideo())}", nil)
      case "stopVideo":
        result!("{\"status\":\(self.stopVideo())}", nil)
      default:
        print("Error !!! Unknown method -> \(call!.method)")
      }
    }
  }

  func initLayer() {
    guard layer == nil else {
      return
    }
    let _layer: AVPlayerLayer
    _layer = AVPlayerLayer(player: player)
    layer = _layer
    let playerView = UIView()
    playerView.layer.addSublayer(_layer)
    _layer.frame = CGRect(x: 0, y: 100, width: view.frame.size.width, height: view.frame.size.height / 1.5)
    view.layer.addSublayer(_layer)
  }

  private func initUrl(_ url: String) throws {
    print("initUrl \(url)")
    if currentUrl != url {
      guard let _url = URL(string: url) else {
        throw PlayerError.invalidUrl(url: url)
      }
      currentUrl = url
      if currentUrl != nil {
        player.replaceCurrentItem(with: AVPlayerItem(url: _url))
      } else {
        player = AVPlayer(playerItem: AVPlayerItem(url: _url))
      }
    }
  }

  private func playVideo(url: String) throws -> Int {
    try initUrl(url)
    initLayer()

    NotificationCenter.default.addObserver(
      self, selector: #selector(self.playerDidFinishPlaying(note:)),
      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem
    )
    player.play()
    watchProgress()
    isPlaying = true
    return 1
  }

  private func watchProgress() {
    progressWatcher = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1000), queue: nil) {
      (CMTime) -> Void in
      let currentSeconds = CMTimeGetSeconds(self.player.currentTime())
      let timePosition: TimeInterval = currentSeconds
      let timeDuration: TimeInterval = self.getVideoDuration()

      let progress = "\(self.timeFormatter.string(from: timePosition)!) / \(self.timeFormatter.string(from: timeDuration)!)"

      if progress != self.currentProgress {
        self.progressChannel.sendMessage(PlayerMessage(type: 2, data: progress).toMap())
        self.currentProgress = progress
      }
    }
  }

  @objc func playerDidFinishPlaying(note: NSNotification) {
    print("playerDidFinishPlaying : \(note.debugDescription)")

    playerChannel?.invokeMethod("onVideoComplete", arguments: nil)

    stopVideo()
  }

  private func pauseVideo() -> Int {
    initLayer()
    player.pause()
    isPlaying = false
    return 1
  }

  private func stopVideo() -> Int {
    initLayer()
    player.pause()
    player.seek(to: CMTimeMake(0, 1000))
    isPlaying = false
    NotificationCenter.default.removeObserver(
      self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem
    )
    unwatchProgress()
    return 1
  }

  private func getVideoDuration() -> Double {
    let duration = CMTimeGetSeconds((player.currentItem?.asset.duration)!)
    return duration
  }

  private func unwatchProgress() {
    if let token = progressWatcher {
      player.removeTimeObserver(token)
    }
  }

}


struct Response {
  let status: Int
  let info: String

  func toJson() -> String {
    let data = try! JSONSerialization.data(withJSONObject: toMap())
    return String(data: data, encoding: .utf8)!
  }

  func toMap() -> [String: Any] {
    return ["status": status, "info": info]
  }
}

struct PlayerMessage {
  let type: Int
  let data: Any?

  func toJson() -> String {
    let data = try! JSONSerialization.data(withJSONObject: toMap())
    return String(data: data, encoding: .utf8)!
  }

  func toMap() -> [String: Any] {
    return ["type": type, "data": data ?? ""]
  }
}

enum PlayerError: Error {
  case invalidUrl(url: String)
  case noController
}
