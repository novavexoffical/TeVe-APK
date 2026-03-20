import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teve/Home/models/channel_model.dart';
import 'package:teve/Player/player.dart';
import 'package:teve/Utils/teve_theme.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({
    super.key,
    required this.models,
  });

  final List<ChannelModel> models;

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedEntry {
  const _BlockedEntry({
    required this.key,
    required this.name,
    required this.url,
    required this.category,
  });

  final String key;
  final String name;
  final String url;
  final String category;
}

class _BlockedScreenState extends State<BlockedScreen> {
  static const String _blockedStreamsKey = 'blocked_streams_v1';
  List<_BlockedEntry> _blocked = [];
  int? _focusedBlockedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    const orientations = [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ];
    SystemChrome.setPreferredOrientations(orientations);
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getStringList(_blockedStreamsKey) ?? <String>[];

    final built = <_BlockedEntry>[];
    for (final key in saved) {
      final parts = key.split('|');
      if (parts.isEmpty) continue;
      final name = parts.first.trim().isEmpty ? 'Unknown' : parts.first.trim();
      final url = parts.length > 1 ? parts.sublist(1).join('|').trim() : '';

      String category = 'General';
      for (final ch in widget.models) {
        final n = (ch.name ?? '').trim();
        final u = (ch.url ?? '').trim();
        if (n == name && u == url) {
          if (ch.categories != null && ch.categories!.isNotEmpty) {
            category = ch.categories![0].name ?? 'General';
          }
          break;
        }
      }

      built.add(_BlockedEntry(
        key: key,
        name: name,
        url: url,
        category: category,
      ));
    }

    if (!mounted) return;
    setState(() {
      _blocked = built;
    });
  }

  Future<void> _unblock(_BlockedEntry entry) async {
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getStringList(_blockedStreamsKey) ?? <String>[];
    saved.remove(entry.key);
    await pref.setStringList(_blockedStreamsKey, saved);
    await _loadBlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TeveTheme.teveAppBar(
        child: Text(
          'Blocked Streams',
          style: TeveTheme.appText(size: 18, weight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: FractionalOffset(0.0, 0.0),
                end: FractionalOffset(1.0, 0.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp,
                colors: [TeveTheme.darkBlue, TeveTheme.slightBlue],
              ),
            ),
          ),
          _blocked.isEmpty
              ? Center(
                  child: Text(
                    'No blocked streams',
                    style: TeveTheme.appText(size: 24, weight: FontWeight.w700),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _blocked.length,
                  itemBuilder: (context, index) {
                    final item = _blocked[index];
                    final isFocused = _focusedBlockedIndex == index;
                    return Focus(
                      autofocus: index == 0,
                      onFocusChange: (hasFocus) {
                        setState(() {
                          if (hasFocus) {
                            _focusedBlockedIndex = index;
                          } else if (_focusedBlockedIndex == index) {
                            _focusedBlockedIndex = null;
                          }
                        });
                      },
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                                event.logicalKey == LogicalKeyboardKey.info)) {
                          _showActions(item);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocused
                                ? Colors.white
                                : TeveTheme.logoDarkColor.withOpacity(0.35),
                            width: isFocused ? 2.2 : 1,
                          ),
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: TeveTheme.slightDarkBlue,
                          child: ListTile(
                            leading:
                                const Icon(Icons.block, color: Colors.redAccent),
                            title: Text(
                              item.name,
                              style: TeveTheme.appText(
                                  size: 14, weight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              item.category,
                              style: TeveTheme.appText(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: Colors.white70),
                            ),
                            trailing: ExcludeFocus(
                              child: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'unblock') {
                                    await _unblock(item);
                                  } else if (value == 'watch' &&
                                      item.url.trim().isNotEmpty) {
                                    if (!mounted) return;
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) {
                                      return Player(video_url: item.url);
                                    }));
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'unblock',
                                    child: Text('Unblock stream'),
                                  ),
                                  if (item.url.trim().isNotEmpty)
                                    const PopupMenuItem(
                                      value: 'watch',
                                      child: Text('Play anyway'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showActions(_BlockedEntry item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TeveTheme.slightDarkBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Blocked stream',
            style: TeveTheme.appText(size: 16, weight: FontWeight.w700)),
        content: Text(item.name,
            style: TeveTheme.appText(size: 14, weight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _unblock(item);
              if (!mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
