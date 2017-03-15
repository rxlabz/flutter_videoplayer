import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String kVideoUrl = "http://techslides.com/demos/sample-videos/small.mp4";

/// message from native video player
class PlayerMessage {
  /**
   * 1 complete
   * 2 progress,
   */
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

class MediaPlayer extends StatefulWidget {
  @override
  _MediaplayerState createState() => new _MediaplayerState();
}

class _MediaplayerState extends State<MediaPlayer> {
  String _videoProgress = "";
  static const _channel = "video";
  static const PlatformMessageChannel<String> platform =
      const PlatformMessageChannel<String>(_channel, const StringCodec());

  bool isPlaying = false;

  @override
  void initState() {
    platform.setMessageHandler((String rawResponse) async {
      final msg = parseMessage(rawResponse);

      switch (msg.type) {
        case 1: // video complete
          setState(() => isPlaying = false);
          break;
        case 2: // video progress
          setState(() => _videoProgress = msg.data);
          break;
        default:
          print("Unknown message type : $rawResponse");
      }

      return '';
    });
  }

  PlayerMessage parseMessage(String raw) => new PlayerMessage.fromString(raw);
  //JSON.decode(raw) as Map<String, dynamic>;

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
                              child: new Text(_videoProgress, style: new TextStyle(fontSize: 24.0)))
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
    String response = await PlatformMessages.sendString('playVideo', kVideoUrl);
    final data = parseResponse(response);
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
        parseResponse(await PlatformMessages.sendString('pauseVideo', ''));
    if (response['status'] == 1)
      setState(() {
        isPlaying = false;
      });
  }

  Future<Null> _stop() async {
    Map response =
        parseResponse(await PlatformMessages.sendString('stopVideo', ''));
    if (response['status'] == 1)
      setState(() {
        isPlaying = false;
      });
  }
}
