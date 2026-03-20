// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teve/Home/models/fav_model.dart';
import 'package:teve/Player/player.dart';
import 'package:teve/Utils/teve_theme.dart';

class FavCard extends StatefulWidget {
  FavCard({super.key, required this.model, required this.index,required this.onTap});
  FavModel model;
  int index;
  VoidCallback onTap;

  @override
  State<FavCard> createState() => _FavCardState();
}

class _FavCardState extends State<FavCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            Navigator.push(context, MaterialPageRoute(builder: (_) {
              return Player(video_url: widget.model.streamLink!);
            }));
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
              event.logicalKey == LogicalKeyboardKey.info) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0.3, 0.1),
                  spreadRadius: 2,
                  blurRadius: 1)
            ],
            color: TeveTheme.slightDarkBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused ? TeveTheme.logoLightColor : Colors.transparent,
              width: _isFocused ? 2.2 : 1,
            )),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.index.toString(),
                  style: TeveTheme.appText(
                      size: 40,
                      weight: FontWeight.bold,
                      color: TeveTheme.logoDarkColor),
                ),
                const SizedBox(
                  width: 15,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Text(
                        widget.model.channelName!,
                        overflow: TextOverflow.ellipsis,
                        style: TeveTheme.appText(
                            size: 20, weight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      widget.model.category!,
                      style: TeveTheme.appText(
                          size: 14,
                          weight: FontWeight.w600,
                          color: TeveTheme.whiteColor.withOpacity(0.5)),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) {
                        return Player(video_url: widget.model.streamLink!);
                      }));
                    },
                    style: TeveTheme.buttonStyle(
                        backColor: TeveTheme.logoLightColor, fontSize: 13),
                    child: const Text("Watch"),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                IconButton(
                    onPressed: widget.onTap,
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ))
              ],
            )
          ],
        ),
      ),
    );
  }
}
