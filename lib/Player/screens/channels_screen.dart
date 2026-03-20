// ignore_for_file: must_be_immutable, unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teve/Home/models/channel_model.dart';
import 'package:teve/Player/models/channel_card_model.dart';
import 'package:teve/Player/player.dart';
import 'package:teve/Player/service/player_service.dart';
import 'package:teve/Player/ui_view/channel_card.dart';

import '../../Utils/teve_theme.dart';

class ChannelScreen extends StatefulWidget {
  ChannelScreen(
      {super.key,
      required this.topWidget,
      required this.models,
      this.isLive = false});
  Widget topWidget;
  List<ChannelModel> models;
  bool isLive;

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  static const String _blockedStreamsKey = 'blocked_streams_v1';

  PlayerService service = PlayerService();
  String selectedCategory = 'All';
  bool playableOnly = true;
  bool listView = false;
  late List<String> categories;
  final FocusNode _firstCategoryFocusNode = FocusNode();
  int? _focusedCategoryIndex;
  final Set<String> _blockedStreamKeys = <String>{};
  final Set<String> _favoriteStreamKeys = <String>{};

  @override
  void initState() {
    super.initState();
    final set = <String>{'All'};
    for (final m in widget.models) {
      if (m.categories != null && m.categories!.isNotEmpty) {
        final name = m.categories![0].name;
        if (name != null && name.isNotEmpty) set.add(name);
      }
    }
    categories = set.toList()..sort();
    categories.remove('All');
    categories.insert(0, 'All');
    _loadBlockedStreams();
    _loadFavoriteStreams();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstCategoryFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _firstCategoryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBlockedStreams() async {
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getStringList(_blockedStreamsKey) ?? <String>[];
    if (!mounted) return;
    setState(() {
      _blockedStreamKeys
        ..clear()
        ..addAll(saved);
    });
  }

  Future<void> _saveBlockedStreams() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setStringList(_blockedStreamsKey, _blockedStreamKeys.toList());
  }

  Future<void> _loadFavoriteStreams() async {
    final favorites = await service.getFavoriteKeys();
    if (!mounted) return;
    setState(() {
      _favoriteStreamKeys
        ..clear()
        ..addAll(favorites);
    });
  }

  String _channelKey(ChannelModel channel) {
    final name = channel.name ?? 'unknown';
    final url = (channel.url ?? '').trim();
    return '$name|$url';
  }

  bool _hasStream(ChannelModel channel) {
    return channel.url != null && channel.url!.trim().isNotEmpty;
  }

  bool _isBlocked(ChannelModel channel) {
    return _blockedStreamKeys.contains(_channelKey(channel));
  }

  bool _isPlayable(ChannelModel channel) {
    return _hasStream(channel) && !_isBlocked(channel);
  }

  bool _isFavorite(ChannelModel channel) {
    return _favoriteStreamKeys.contains(_channelKey(channel));
  }

  void _showToast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: TeveTheme.appText(size: 12, weight: FontWeight.w500),
        ),
        backgroundColor: TeveTheme.slightBlue,
      ),
    );
  }

  Future<void> _markBlocked(ChannelModel channel) async {
    setState(() => _blockedStreamKeys.add(_channelKey(channel)));
    await _saveBlockedStreams();
    _showToast('Stream marked blocked. It is excluded from Playable only.');
  }

  Future<void> _unblock(ChannelModel channel) async {
    setState(() => _blockedStreamKeys.remove(_channelKey(channel)));
    await _saveBlockedStreams();
    _showToast('Stream unblocked.');
  }

  void _openPlayer(ChannelModel channel) {
    if (!_isPlayable(channel)) {
      if (_isBlocked(channel)) {
        _showToast('This stream is marked blocked.');
      } else {
        _showToast('No playable stream found for this channel yet.');
      }
      return;
    }

    final streamUrl = channel.url!.trim();
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return Player(video_url: streamUrl);
    }));
  }

  List<ChannelModel> get filteredModels {
    return widget.models.where((m) {
      final categoryMatch = selectedCategory == 'All' ||
          (m.categories != null &&
              m.categories!.isNotEmpty &&
              m.categories![0].name == selectedCategory);
      final playableMatch = !playableOnly || _isPlayable(m);
      return categoryMatch && playableMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TeveTheme.teveAppBar(child: widget.topWidget),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: FractionalOffset(0.0, 0.0),
                  end: FractionalOffset(1.0, 0.0),
                  stops: [0.0, 1.0],
                  tileMode: TileMode.clamp,
                  colors: [TeveTheme.darkBlue, TeveTheme.slightDarkBlue])),
        ),
        Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final selected = cat == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Focus(
                      focusNode: index == 0 ? _firstCategoryFocusNode : null,
                      autofocus: index == 0,
                      onFocusChange: (hasFocus) {
                        setState(() {
                          if (hasFocus) {
                            _focusedCategoryIndex = index;
                          } else if (_focusedCategoryIndex == index) {
                            _focusedCategoryIndex = null;
                          }
                        });
                      },
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey == LogicalKeyboardKey.select)) {
                          setState(() => selectedCategory = cat);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => selectedCategory = cat);
                        },
                        side: BorderSide(
                          color: _focusedCategoryIndex == index
                              ? TeveTheme.logoLightColor
                              : Colors.transparent,
                          width: _focusedCategoryIndex == index ? 2 : 1,
                        ),
                        selectedColor: TeveTheme.logoLightColor,
                        backgroundColor: TeveTheme.slightDarkBlue,
                        labelStyle: TeveTheme.appText(
                          size: 12,
                          weight: FontWeight.w600,
                          color: TeveTheme.whiteColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(
                      'Playable only',
                      style: TeveTheme.appText(
                        size: 12,
                        weight: FontWeight.w600,
                        color: TeveTheme.whiteColor,
                      ),
                    ),
                    selected: playableOnly,
                    onSelected: (val) {
                      setState(() => playableOnly = val);
                    },
                    selectedColor: TeveTheme.logoLightColor,
                    backgroundColor: TeveTheme.slightDarkBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _blockedStreamKeys.isEmpty
                        ? 'Blocked: 0'
                        : 'Blocked: ${_blockedStreamKeys.length}',
                    style: TeveTheme.appText(size: 11, weight: FontWeight.w500),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: listView ? 'Grid view' : 'List view',
                    onPressed: () => setState(() => listView = !listView),
                    icon: Icon(
                      listView
                          ? Icons.grid_view_rounded
                          : Icons.view_list_rounded,
                      color: TeveTheme.whiteColor,
                    ),
                  ),
                  Text(
                    '${filteredModels.length} shown',
                    style: TeveTheme.appText(size: 12, weight: FontWeight.w500),
                  )
                ],
              ),
            ),
            Expanded(
              child: filteredModels.isEmpty
                  ? Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Lottie.asset('assets/jsons/not_found.json',
                              height: 180, width: 180),
                          Text(
                            "No channels in '$selectedCategory'",
                            style: TeveTheme.appText(
                                size: 20,
                                weight: FontWeight.w600,
                                isShadow: true),
                          ),
                        ],
                      ),
                    )
                  : listView
                      ? ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: filteredModels.length,
                          itemBuilder: (context, index) {
                            final channel = filteredModels[index];
                            final isPlayable = _isPlayable(channel);
                            final isBlocked = _isBlocked(channel);
                            return Focus(
                              autofocus: index == 0,
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey ==
                                          LogicalKeyboardKey.enter ||
                                      event.logicalKey ==
                                          LogicalKeyboardKey.select) {
                                    _openPlayer(channel);
                                    return KeyEventResult.handled;
                                  }
                                  if (event.logicalKey ==
                                          LogicalKeyboardKey.contextMenu ||
                                      event.logicalKey ==
                                          LogicalKeyboardKey.info) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          _buildPopupDialog(context,
                                              model: channel),
                                    );
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Card(
                                color: TeveTheme.slightDarkBlue,
                                child: ListTile(
                                  onTap: () => _openPlayer(channel),
                                  leading: Icon(
                                    isBlocked
                                        ? Icons.block
                                        : isPlayable
                                            ? Icons.play_circle_fill
                                            : Icons.info_outline,
                                    color: isBlocked
                                        ? Colors.redAccent
                                        : isPlayable
                                            ? Colors.greenAccent
                                            : Colors.orangeAccent,
                                  ),
                                  title: Text(
                                    channel.name ?? 'Unknown',
                                    style: TeveTheme.appText(
                                        size: 14, weight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    isBlocked
                                        ? 'Marked blocked'
                                        : (channel.categories != null &&
                                                channel.categories!.isNotEmpty
                                            ? channel.categories![0].name ??
                                                'General'
                                            : 'General'),
                                    style: TeveTheme.appText(
                                        size: 11,
                                        weight: FontWeight.w500,
                                        color: Colors.white70),
                                  ),
                                  trailing: ExcludeFocus(
                                    child: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'fav') {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                _buildPopupDialog(context,
                                                    model: channel),
                                          );
                                        } else if (value == 'block') {
                                          _markBlocked(channel);
                                        } else if (value == 'unblock') {
                                          _unblock(channel);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                            value: 'fav',
                                            child: Text('Add to favorites')),
                                        if (!isBlocked)
                                          const PopupMenuItem(
                                              value: 'block',
                                              child:
                                                  Text('Mark stream blocked')),
                                        if (isBlocked)
                                          const PopupMenuItem(
                                              value: 'unblock',
                                              child: Text('Unblock stream')),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : AnimationLimiter(
                          child: GridView.count(
                            key: const PageStorageKey<String>('GridView'),
                            crossAxisCount: 3,
                            padding: const EdgeInsets.all(10),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.6,
                            physics: const BouncingScrollPhysics(),
                            children:
                                List.generate(filteredModels.length, (index) {
                              final channel = filteredModels[index];
                              return AnimationConfiguration.staggeredGrid(
                                position: index,
                                duration:
                                    const Duration(seconds: 1, milliseconds: 500),
                                columnCount: 3,
                                child: SlideAnimation(
                                  horizontalOffset: 80.0,
                                  child: FadeInAnimation(
                                    child: ChannelCard(
                                        isPlayable: _isPlayable(channel),
                                        onFav: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                _buildPopupDialog(context,
                                                    model: channel),
                                          );
                                        },
                                        onTap: () {
                                          _openPlayer(channel);
                                        },
                                        isLive: widget.isLive,
                                        model: ChannelCardModel(
                                            channel_category: channel
                                                        .categories !=
                                                    null &&
                                                channel.categories!.isNotEmpty
                                                ? channel.categories![0].name!
                                                : 'Entertainment',
                                            channel_name:
                                                channel.name ?? 'Unknown',
                                            code: channel.countries != null &&
                                                    channel.countries!.isNotEmpty
                                                ? channel.countries![0].code!
                                                : 'International',
                                            image_url: channel.logo != null
                                                ? channel.logo!
                                                : 'https://i.imgur.com/rzrOS3N.png',
                                            languages:
                                                channel.languages != null &&
                                                        channel.languages!
                                                            .isNotEmpty
                                                    ? channel.languages![0].name!
                                                    : 'None')),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
            ),
          ],
        )
      ]),
    );
  }

  Widget _remoteDialogButton({
    required Widget child,
    required VoidCallback onPressed,
    required Color color,
    bool autofocus = false,
    double width = 110,
  }) {
    return SizedBox(
      width: width,
      child: Focus(
        autofocus: autofocus,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select)) {
            onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ElevatedButton(
          style: TeveTheme.buttonStyle(backColor: color),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }

  Widget _buildPopupDialog(BuildContext context, {required ChannelModel model}) {
    final bool blocked = _isBlocked(model);
    final bool isFavorite = _isFavorite(model);

    return AlertDialog(
      backgroundColor: TeveTheme.slightDarkBlue,
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Channel options',
            style: TeveTheme.appText(
                size: 16, weight: FontWeight.w700, color: TeveTheme.whiteColor),
          ),
          const SizedBox(height: 8),
          Text(
            model.name ?? 'Unknown channel',
            style: TeveTheme.appText(
                size: 14, weight: FontWeight.w500, color: TeveTheme.whiteColor),
          ),
        ],
      ),
      actions: <Widget>[
        _remoteDialogButton(
          autofocus: true,
          color: TeveTheme.logoLightColor,
          onPressed: () async {
            final value = isFavorite
                ? await service.removeFromFav(context: context, model: model)
                : await service.addToFav(context: context, model: model);
            await _loadFavoriteStreams();
            _showToast(value);
            if (!mounted) return;
            Navigator.of(context).pop();
          },
          child: Text(isFavorite ? 'Unfavorite' : 'Favorite'),
        ),
        _remoteDialogButton(
          color: blocked ? Colors.green : Colors.orange,
          onPressed: () async {
            if (blocked) {
              await _unblock(model);
            } else {
              await _markBlocked(model);
            }
            if (!mounted) return;
            Navigator.of(context).pop();
          },
          child: Text(blocked ? 'Unblock' : 'Blocked'),
        ),
        _remoteDialogButton(
          width: 90,
          color: TeveTheme.logoDarkColor,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

