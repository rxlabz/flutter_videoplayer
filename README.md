# Flutter iOS Videoplayer

:warning: this example is not up to date with the last version of flutter platform API. Same principles but somes method names changed.

An example of native ios swift videoplayer on top of a [flutter](http://flutter.io) app using the Platform messaging API.

![screen](screen.png)

## Flutter (Dart)

Using a [PlatformMethodChannel](https://docs.flutter.io/flutter/services/PlatformMethodChannel-class.html), the Flutter app can call methods from the platform "context" (iOS, Android,...) 

```dart
const PlatformMethodChannel videoChannel =
  const PlatformMethodChannel("video", const JSONMethodCodec());

// ...

String response = await config.videoChannel.invokeMethod('playVideo', kVideoUrl);

```

Each message will receive an async response back.
Here, each message receive a json response with a status = 1 || 0 and an optional duration.

```json
{
  "status":1,
  "info":"0:20"
}
```
The Flutter app also listen to the native messages sended from iOS 
via a [PlatformMessageChannel](https://docs.flutter.io/flutter/services/PlatformMessageChannel-class.html). 

```dart
const PlatformMessageChannel progressChannel = const PlatformMessageChannel(
      kProgressChannelName, const JSONMessageCodec());

// ...

@override
void initState() {
  config.progressChannel.setMessageHandler((message) {
        setState(() {
          _videoProgress = message["data"];
        });
      });
}

```

## iOS (Swift)

### [AppDelegate](https://github.com/rxlabz/flutter_videoplayer/blob/master/ios/Runner/AppDelegate.swift) & [FlutterVideoPlayer](https://github.com/rxlabz/flutter_videoplayer/blob/master/ios/Runner/player_listeners.swift)

On iOS side, you find the corresponding channels with attached methodCall handler.

```swift
var playerChannel = FlutterMethodChannel(
    name: name,
    binaryMessenger: controller,
    codec: FlutterJSONMethodCodec.sharedInstance())

// ...

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

```

### Platform to Dart

The FlutterMessageChannel offers a sendMessage() method to pass values with the "dart part" of the flutter app

```swift
var progressChannel = FlutterMessageChannel( name: name, binaryMessenger: controller,
    codec: FlutterJSONMessageCodec())

// ...

self.progressChannel.sendMessage(PlayerMessage(type: 2, data: progress).toMap())
```


### Android, Audio...

For now this example only works on iOS ( ARM64 : iPhone5S+ ), you can find 
an older, sketchier ObjC/Java example [here](https://github.com/rxlabz/flutter-mediaplayer-plugin),
 with more types of player ( activities and audio ) for Android and iOS.
