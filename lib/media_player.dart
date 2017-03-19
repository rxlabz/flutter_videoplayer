import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String kVideoUrl = "http://techslides.com/demos/sample-videos/small.mp4";

class MediaPlayer extends StatefulWidget {
  final PlatformMethodChannel videoChannel;
  final PlatformMessageChannel progressChannel;

  MediaPlayer(this.videoChannel, this.progressChannel);

  @override
  _MediaplayerState createState() => new _MediaplayerState();
}

class _MediaplayerState extends State<MediaPlayer> {
  String _videoProgress = "";

  bool isPlaying = false;


  @override
  void initState() {
    super.initState();
    initChannels();
  }

  void initChannels() {
    config.videoChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "onVideoComplete") setState(() => isPlaying = false);
      return null;
    });
    config.progressChannel.setMessageHandler((message) {
      setState(() {
        _videoProgress = message["data"];
      });
    });
  }

  PlayerMessage parseMessage(String raw) => new PlayerMessage.fromString(raw);

  Map<String, dynamic> parseResponse(String response) =>
      JSON.decode(response) as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    return new Material(
        child: new Align(
            alignment: FractionalOffset.bottomCenter,
            child: new Padding(
                padding: const EdgeInsets.all(28.0),
                child: new Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          getButton(
                              icon: Icons.play_arrow,
                              onPressed: isPlaying ? null : _play,
                              backgroundColor: Colors.cyan[400]),
                          getButton(
                              icon: Icons.pause,
                              onPressed: !isPlaying ? null : _pause,
                              backgroundColor: Colors.grey[500]),
                          getButton(
                              icon: Icons.stop,
                              onPressed: !isPlaying ? null : _stop,
                              backgroundColor: Colors.grey[500]),
                          new Padding(
                              padding:
                                  new EdgeInsets.symmetric(horizontal: 12.0),
                              child: new Text(_videoProgress,
                                  style: new TextStyle(fontSize: 24.0)))
                        ],
                      ),
                    ]))));
  }

  Widget getButton({
    IconData icon,
    VoidCallback onPressed,
    Color backgroundColor,
    Color textColor = Colors.white,
  }) =>
      new Padding(
          padding: new EdgeInsets.symmetric(horizontal: 8.0),
          child: new RaisedButton(
              color: backgroundColor,
              child: new Icon(icon, color: textColor),
              onPressed: onPressed));

  Future<Null> _play() async {
    String response =
        await config.videoChannel.invokeMethod('playVideo', kVideoUrl);
    final data = parseResponse(response);
    print('_MediaplayerState._play... ${data['status']}');
    if (data['status'] == 1) {
      setState(() {
        isPlaying = true;
        updateProgress("0:00 / ${data['info']}");
      });
    }
  }

  void updateProgress(String progress) {
    setState(() {
      _videoProgress = progress;
    });
  }

  Future<Null> _pause() async {
    Map response =
        parseResponse(await config.videoChannel.invokeMethod('pauseVideo'));
    if (response['status'] == 1)
      setState(() {
        isPlaying = false;
      });
  }

  Future<Null> _stop() async {
    Map response =
        parseResponse(await config.videoChannel.invokeMethod('stopVideo'));
    if (response['status'] == 1)
      setState(() {
        isPlaying = false;
      });
  }
}

/// message from native video player
class PlayerMessage {
  int type;
  dynamic data;

  PlayerMessage(this.type, this.data);

  factory PlayerMessage.fromString(String raw) {
    final msg = JSON.decode(raw);
    return new PlayerMessage(msg['type'], msg['data']);
  }

  @override
  String toString() {
    return 'PlayerMessage{type: $type, data: $data}';
  }
}