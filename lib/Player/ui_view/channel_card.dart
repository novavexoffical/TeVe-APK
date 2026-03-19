// ignore_for_file: must_be_immutable, prefer_const_constructors, sized_box_for_whitespace
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Stack(
        children: [
          Focus(
            onFocusChange: (hasFocus) {
              setState(() => _isFocused = hasFocus);
            },
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select)) {
                widget.onTap();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  border: _isFocused
                      ? Border.all(color: TeveTheme.logoLightColor, width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(children: [
              Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                    color: TeveTheme.slightDarkBlue,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25))),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25)),
                    child: CachedNetworkImage(
                      imageUrl: widget.model.image_url,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      placeholder: (context, url) =>
                          LoadingAnimationWidget.fourRotatingDots(
                              color: TeveTheme.whiteColor, size: 20),
                      errorWidget: (context, url, error) => Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  width: 200,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: const FractionalOffset(0.0, 0.0),
                          end: const FractionalOffset(1.0, 0.0),
                          stops: const [0.0, 1.0],
                          tileMode: TileMode.clamp,
                          colors: [
                            TeveTheme.logoDarkColor,
                            TeveTheme.logoDarkColor.withOpacity(0.4)
                          ]),
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 180,
                        child: Text(
                          widget.model.channel_name,
                          overflow: TextOverflow.ellipsis,
                          style: TeveTheme.appText(
                              size: 15, weight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        widget.isLive
                            ? widget.model.channel_category
                            : widget.model.languages,
                        overflow: TextOverflow.ellipsis,
                        style: TeveTheme.appText(
                            size: 12,
                            weight: FontWeight.w500,
                            color: TeveTheme.whiteColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              )
            ]),
          ),
        ),
      ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isPlayable
                    ? Colors.green.withOpacity(0.9)
                    : Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.isPlayable ? 'Playable' : 'No Stream',
                style: TeveTheme.appText(
                    size: 10,
                    weight: FontWeight.w700,
                    color: TeveTheme.whiteColor),
              ),
            ),
          ),
          Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: TeveTheme.whiteColor,
                ),
                onPressed: widget.onFav,
              )),
        ],
      ),
    );
  }
}
