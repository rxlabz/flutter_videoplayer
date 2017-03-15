//
// Created by rx on 14/03/2017.
// Copyright (c) 2017 The Chromium Authors. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit
import Flutter

class MediaPlayerViewController: FlutterViewController {

  private var player: AVPlayer
  private var layer: AVPlayerLayer?
  var currentUrl: String?

  var isPlaying: Bool = false

  private var progressToken: Any?

  required override init?(project: FlutterDartProject!, nibName: String!, bundle: Bundle!) {
    self.player = AVPlayer()
    super.init(project: project, nibName: nil, bundle: nil)

  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// draw the video layer
  /// need to be called after viewController initialization
  private func initLayer() {
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

  func playVideo(url: String) throws {
    try initUrl(url)
    initLayer()

    NotificationCenter.default.addObserver(
      self, selector: #selector(self.playerDidFinishPlaying(note:)),
      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem
    )
    player.play()
    watchProgress()
    isPlaying = true
  }

  func playerDidFinishPlaying(note: NSNotification) {
    print("playerDidFinishPlaying : \(note.debugDescription)")

    //send(Response(status: 1, info: "Video complete").toJson(), withMessageName: "video")
    send(PlayerMessage(type: 1, data: "Video complete").toJson(), withMessageName: "video")

    stopVideo()
  }

  private func watchProgress() {
    progressToken = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1000), queue: nil){
      (CMTime) -> Void in
      let currentSeconds = CMTimeGetSeconds( self.player.currentTime())
      let timePosition:TimeInterval = currentSeconds
      let timeDuration:TimeInterval = self.getVideoDuration()

      let timeFormatter = DateComponentsFormatter()

      //timeFormatter.timeStyle = DateFormatter.Style.short
      timeFormatter.unitsStyle = .positional
      timeFormatter.allowedUnits = [.minute, .second]
      timeFormatter.zeroFormattingBehavior = [.pad]
      let progress = "\(timeFormatter.string(from: timePosition)!) / \(timeFormatter.string(from: timeDuration)!)"

      self.send(PlayerMessage(type: 2, data: progress).toJson(), withMessageName: "video")
    }
  }

  func pauseVideo() -> Int {
    initLayer()
    player.pause()
    isPlaying = false
    return 1
  }

  func stopVideo() -> Int {
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


  func getVideoPosition() -> String {
    let duration = CMTimeGetSeconds((player.currentItem?.asset.duration)!)
    unwatchProgress()
    return Double(duration).description
  }

  private func unwatchProgress() {
    if let token = progressToken {
      player.removeTimeObserver(token)
    }
  }

  func getVideoDuration() -> Double {
    let duration = CMTimeGetSeconds((player.currentItem?.asset.duration)!)
    return duration
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

}
