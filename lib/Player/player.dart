// ignore_for_file: non_constant_identifier_names, must_be_immutable

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:teve/Home/service/home_service.dart';
import 'package:teve/Utils/teve_theme.dart';

class Player extends StatefulWidget {
  Player({super.key, required this.video_url});
  String video_url;

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late BetterPlayerController _controller;

  final betterPlayerConfiguration = BetterPlayerConfiguration(
    controlsConfiguration: BetterPlayerControlsConfiguration(
      textColor: Colors.white,
      iconsColor: Colors.white,
      enableFullscreen: false,
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
  void initState() {
    super.initState();
    _controller = BetterPlayerController(betterPlayerConfiguration);
    _controller.setupDataSource(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.video_url,
      ),
    );
    _controller.addEventsListener(_onPlayerEvent);
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType != BetterPlayerEventType.exception) return;

    final details = event.parameters?.toString().toLowerCase() ?? '';
    final seemsBlocked = details.contains('403') ||
        details.contains('forbidden') ||
        details.contains('copyright') ||
        details.contains('geo') ||
        details.contains('denied') ||
        details.contains('blocked');

    if (seemsBlocked) {
      HomeService.markStreamBlocked(widget.video_url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream appears blocked (copyright/geo).'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeEventsListener(_onPlayerEvent);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: SafeArea(
          child: BetterPlayer(controller: _controller),
        ),
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        });
  }
}
