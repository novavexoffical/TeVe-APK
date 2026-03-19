// ignore_for_file: must_be_immutable, avoid_print, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teve/Home/models/channel_model.dart';
import 'package:teve/Player/screens/channels_screen.dart';
import 'package:teve/Utils/constants.dart';
import 'package:teve/Utils/teve_theme.dart';

class SelectScreen extends StatefulWidget {
  SelectScreen({super.key, required this.topWidget, required this.models});
  Widget topWidget;
  List<ChannelModel> models;

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _CountryEntry {
  const _CountryEntry({
    required this.code,
    required this.name,
    required this.channels,
  });

  final String code;
  final String name;
  final List<ChannelModel> channels;

  int get totalChannels => channels.length;

  int get playableChannels =>
      channels.where((c) => c.url != null && c.url!.trim().isNotEmpty).length;
}

class _SelectScreenState extends State<SelectScreen> {
  static const String _visibleCountriesKey = 'visible_countries_v1';

  bool _playableOnly = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _firstCountryFocusNode = FocusNode();
  int? _focusedCountryIndex;
  Set<String>? _visibleCountryCodes;

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  List<_CountryEntry> get _countryEntries {
    final iconSet = countryIcons.toSet();
    final Map<String, List<ChannelModel>> byCountry = {};

    for (final ch in widget.models) {
      if (ch.countries == null || ch.countries!.isEmpty) continue;
      final code = (ch.countries![0].code ?? '').toLowerCase().trim();
      if (code.isEmpty || !iconSet.contains(code)) continue;
      byCountry.putIfAbsent(code, () => []).add(ch);
    }

    final entries = byCountry.entries.map((entry) {
      String countryName = entry.key.toUpperCase();
      for (final ch in entry.value) {
        if (ch.countries != null &&
            ch.countries!.isNotEmpty &&
            (ch.countries![0].name ?? '').isNotEmpty) {
          countryName = ch.countries![0].name!;
          break;
        }
      }
      return _CountryEntry(
        code: entry.key,
        name: countryName,
        channels: entry.value,
      );
    }).toList();

    entries.sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }

  List<_CountryEntry> get _filteredCountries {
    return _countryEntries.where((entry) {
      final visibilityMatch = _visibleCountryCodes == null ||
          _visibleCountryCodes!.contains(entry.code.toLowerCase());
      final queryMatch = _searchQuery.isEmpty ||
          entry.name.toLowerCase().contains(_searchQuery) ||
          entry.code.toLowerCase().contains(_searchQuery);
      final playableMatch = !_playableOnly || entry.playableChannels > 0;
      return visibilityMatch && queryMatch && playableMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadVisibleCountries();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstCountryFocusNode.requestFocus();
    });
  }

  Future<void> _loadVisibleCountries() async {
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getStringList(_visibleCountriesKey);
    if (!mounted) return;
    if (saved == null || saved.isEmpty) {
      setState(() => _visibleCountryCodes = {'us', 'pl'});
      return;
    }
    setState(() {
      _visibleCountryCodes = saved.map((e) => e.toLowerCase()).toSet();
    });
  }

  Future<void> _saveVisibleCountries(Set<String>? codes) async {
    final pref = await SharedPreferences.getInstance();
    if (codes == null || codes.isEmpty) {
      await pref.remove(_visibleCountriesKey);
    } else {
      await pref.setStringList(_visibleCountriesKey, codes.toList()..sort());
    }
  }

  Future<void> _openCountryVisibilitySettings() async {
    final all = _countryEntries;
    final initial = _visibleCountryCodes == null
        ? all.map((e) => e.code.toLowerCase()).toSet()
        : {..._visibleCountryCodes!};
    Set<String> temp = {...initial};

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: TeveTheme.slightDarkBlue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Visible countries',
              style: TeveTheme.appText(size: 16, weight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 460,
              height: 420,
              child: Column(
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setModalState(() {
                          temp = all.map((e) => e.code.toLowerCase()).toSet();
                        }),
                        child: const Text('All'),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          temp = <String>{};
                        }),
                        child: const Text('None'),
                      ),
                      const Spacer(),
                      Text(
                        '${temp.length}/${all.length}',
                        style: TeveTheme.appText(
                            size: 12,
                            weight: FontWeight.w600,
                            color: Colors.white70),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: all.length,
                      itemBuilder: (context, index) {
                        final entry = all[index];
                        final code = entry.code.toLowerCase();
                        final selected = temp.contains(code);
                        return CheckboxListTile(
                          value: selected,
                          dense: true,
                          secondary: CircleAvatar(
                            radius: 12,
                            backgroundImage:
                                AssetImage('assets/images/${entry.code}.png'),
                          ),
                          title: Text(
                            entry.name,
                            style: TeveTheme.appText(
                                size: 13, weight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${entry.totalChannels} streams',
                            style: TeveTheme.appText(
                                size: 11,
                                weight: FontWeight.w500,
                                color: Colors.white70),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                temp.add(code);
                              } else {
                                temp.remove(code);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final allSet = all.map((e) => e.code.toLowerCase()).toSet();
                  final next = temp.length == allSet.length ? null : temp;
                  setState(() {
                    _visibleCountryCodes = next;
                  });
                  await _saveVisibleCountries(next);
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstCountryFocusNode.dispose();
    super.dispose();
  }

  void _openCountry(_CountryEntry entry) {
    Navigator.push(context, MaterialPageRoute(builder: ((context) {
      return ChannelScreen(
          isLive: true,
          models: entry.channels,
          topWidget:
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            widget.topWidget,
            const SizedBox(width: 5),
            Text(
              entry.name,
              style: TeveTheme.appText(
                  size: 14,
                  weight: FontWeight.w500,
                  color: TeveTheme.logoDarkColor),
            )
          ]));
    })));
  }

  Widget _countryCard(_CountryEntry entry, int index) {
    return Focus(
      focusNode: index == 0 ? _firstCountryFocusNode : null,
      autofocus: index == 0,
      onFocusChange: (hasFocus) {
        setState(() {
          if (hasFocus) {
            _focusedCountryIndex = index;
          } else if (_focusedCountryIndex == index) {
            _focusedCountryIndex = null;
          }
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          _openCountry(entry);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openCountry(entry),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: TeveTheme.slightDarkBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focusedCountryIndex == index
                  ? TeveTheme.logoLightColor
                  : TeveTheme.logoDarkColor.withOpacity(0.35),
              width: _focusedCountryIndex == index ? 2.4 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/${entry.code}.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TeveTheme.appText(size: 15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.totalChannels} streams · ${entry.playableChannels} playable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TeveTheme.appText(
                          size: 12,
                          weight: FontWeight.w500,
                          color: TeveTheme.whiteColor.withOpacity(0.75)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: TeveTheme.whiteColor),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countries = _filteredCountries;

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
                  colors: [TeveTheme.darkBlue, TeveTheme.slightBlue])),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Focus(
                        skipTraversal: true,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: TeveTheme.appText(
                              size: 14, weight: FontWeight.w500),
                          decoration: TeveTheme.waInputDecoration(
                            hint: 'Search country (e.g. US, India, Brazil)',
                            prefixIcon: Icons.search,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: Text(
                        'Playable only',
                        style:
                            TeveTheme.appText(size: 12, weight: FontWeight.w600),
                      ),
                      selected: _playableOnly,
                      onSelected: (val) {
                        setState(() {
                          _playableOnly = val;
                        });
                      },
                      selectedColor: TeveTheme.logoLightColor,
                      backgroundColor: TeveTheme.slightDarkBlue,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Country display settings',
                      onPressed: _openCountryVisibilitySettings,
                      icon: const Icon(
                        Icons.settings,
                        color: TeveTheme.logoLightColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: countries.isEmpty
                    ? Center(
                        child: Text(
                          'No countries match your filters',
                          style:
                              TeveTheme.appText(size: 16, weight: FontWeight.w600),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          top: 4,
                          bottom: MediaQuery.of(context).padding.bottom + 88,
                        ),
                        itemCount: countries.length,
                        itemBuilder: (context, index) {
                          return _countryCard(countries[index], index);
                        },
                      ),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.only(bottom: 8, right: 8),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: TeveTheme.darkBlue,
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tv,
                    color: TeveTheme.whiteColor,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    'Countries',
                    style: TeveTheme.appText(size: 15, weight: FontWeight.w600),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Text(
                    countries.length.toString(),
                    style: TeveTheme.appText(size: 15, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        )
      ]),
    );
  }
}
