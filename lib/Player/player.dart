// ignore_for_file: non_constant_identifier_names, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:teve/Utils/teve_theme.dart';

class Player extends StatefulWidget {
  Player({super.key, required this.video_url});
  String video_url;

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  var betterPlayerConfiguration = BetterPlayerConfiguration(
    autoPlay: true,
    expandToFill: true,
    fit: BoxFit.cover,
    deviceOrientationsOnFullScreen: const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    deviceOrientationsAfterFullScreen: const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    controlsConfiguration: BetterPlayerControlsConfiguration(
      textColor: Colors.white,
      iconsColor: Colors.white,
      enableFullscreen: true,
      overflowModalColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      loadingWidget: Center(
        child: LoadingAnimationWidget.fourRotatingDots(
            color: TeveTheme.logoLightColor, size: 30),
      ),
      showControlsOnInitialize: true,
      showControls: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox.expand(
            child: BetterPlayer.network(widget.video_url,
                betterPlayerConfiguration: betterPlayerConfiguration),
          ),
        ),
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        });
  }
}
