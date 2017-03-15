//
// Created by rx on 14/03/2017.
// Copyright (c) 2017 The Chromium Authors. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit
import Flutter
import UIKit


/// player commands response
///

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


/// player commands listener base
///
class PlayerCommandListener: NSObject, FlutterMessageListener {
  var messageName: String = ""

  fileprivate var controller: MediaPlayerViewController

  var currentUrl: URL?

  init(messageName: String, controller: MediaPlayerViewController) {
    self.messageName = messageName
    self.controller = controller
  }

  public func didReceive(_ message: String!) -> String! {
    return ""
  }
}

class OnPlayVideo: PlayerCommandListener {
  override public func didReceive(_ message: String!) -> String! {

    guard URL(string: message) != nil else {
      return Response(status: 0, info: "ERROR ! invalid URL ! -> \(message)").toJson()
    }

    var res: Response
    do {
      try controller.playVideo(url: message)
      res = Response(
        status: 1, info: controller.getVideoDuration().description
      )
    } catch PlayerError.invalidUrl {
      res = Response(status: 0, info: "Invalid Url : \(message!)")
    } catch {
      res = Response(status: 0, info: "Unknown Error")
    }

    return res.toJson()
  }
}


class OnStopVideo: PlayerCommandListener {
  override public func didReceive(_ message: String!) -> String! {
    let status = controller.stopVideo()
    return Response(status: status, info: "swift -> stopped...").toJson()
  }
}

class OnPauseVideo: PlayerCommandListener {

  override public func didReceive(_ message: String!) -> String! {
    let status = controller.pauseVideo()
    return Response(status: status, info: "swift -> paused...").toJson()
  }
}
