// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teve/Player/models/channel_card_model.dart';
import 'package:teve/Utils/teve_theme.dart';

class ChannelCard extends StatefulWidget {
  ChannelCard(
      {super.key,
      required this.model,
      required this.onFav,
      this.isLive = false,
      this.isPlayable = false,
      required this.onTap});

  ChannelCardModel model;
  VoidCallback onTap;
  bool isLive;
  bool isPlayable;
  VoidCallback onFav;

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _longPressTimer?.cancel();
        setState(() => _isFocused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select) {
          if (event is KeyDownEvent) {
            _longPressTimer =
                Timer(const Duration(milliseconds: 600), widget.onFav);
            return KeyEventResult.handled;
          }
          if (event is KeyUpEvent) {
            if (_longPressTimer?.isActive ?? false) {
              _longPressTimer?.cancel();
              widget.onTap();
            }
            return KeyEventResult.handled;
          }
          if (event is KeyRepeatEvent) {
            return KeyEventResult.handled;
          }
        }
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
              event.logicalKey == LogicalKeyboardKey.info) {
            widget.onFav();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onFav,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: TeveTheme.slightDarkBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? TeveTheme.logoLightColor
                  : TeveTheme.logoDarkColor.withOpacity(0.35),
              width: _isFocused ? 2.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isPlayable
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.isPlayable ? 'Playable' : 'No Stream',
                  style: TeveTheme.appText(
                    size: 10,
                    weight: FontWeight.w700,
                    color: widget.isPlayable
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model.channel_name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TeveTheme.appText(size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isLive
                          ? widget.model.channel_category
                          : widget.model.languages,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TeveTheme.appText(
                        size: 11,
                        weight: FontWeight.w500,
                        color: TeveTheme.whiteColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              ExcludeFocus(
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: TeveTheme.whiteColor),
                  onPressed: widget.onFav,
                  splashRadius: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
