import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_videoplayer/media_player.dart';

const kVideoChannelName = "flutter/video";
const kProgressChannelName = "flutter/videoProgress";

main() async {
  const PlatformMethodChannel videoChannel =
      const PlatformMethodChannel(kVideoChannelName, const JSONMethodCodec());

  const PlatformMessageChannel progressChannel = const PlatformMessageChannel(
      kProgressChannelName, const JSONMessageCodec());

  runApp(new MediaPlayer(videoChannel, progressChannel));
}
