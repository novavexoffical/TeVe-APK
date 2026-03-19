// ignore_for_file: must_be_immutable, avoid_print, non_constant_identifier_names
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
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

  int get playableChannels => channels
      .where((c) => c.url != null && c.url!.trim().isNotEmpty)
      .length;
}

class _SelectScreenState extends State<SelectScreen> {
  int _current = 0;
  int? _focusedCountryIndex;
  bool _playableOnly = false;
  final TextEditingController _searchController = TextEditingController();
  final CarouselController buttonCarouselController = CarouselController();

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
      final queryMatch = _searchQuery.isEmpty ||
          entry.name.toLowerCase().contains(_searchQuery) ||
          entry.code.toLowerCase().contains(_searchQuery);
      final playableMatch = !_playableOnly || entry.playableChannels > 0;
      return queryMatch && playableMatch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countries = _filteredCountries;
    final int currentIndex = countries.isEmpty
        ? 0
        : (_current >= countries.length ? countries.length - 1 : _current);

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
          child: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {
                          _current = 0;
                        }),
                        style: TeveTheme.appText(
                            size: 14, weight: FontWeight.w500),
                        decoration: TeveTheme.waInputDecoration(
                          hint: 'Search country (e.g. US, India, Brazil)',
                          prefixIcon: Icons.search,
                          fontSize: 14,
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
                          _current = 0;
                        });
                      },
                      selectedColor: TeveTheme.logoLightColor,
                      backgroundColor: TeveTheme.slightDarkBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.5,
                child: countries.isEmpty
                    ? Center(
                        child: Text(
                          'No countries match your filters',
                          style:
                              TeveTheme.appText(size: 16, weight: FontWeight.w600),
                        ),
                      )
                    : CarouselSlider.builder(
                        carouselController: buttonCarouselController,
                        itemCount: countries.length,
                        itemBuilder: ((context, index, realIndex) {
                          final entry = countries[index];
                          final isCurrent = index == currentIndex;

                          return Column(
                            children: [
                              Focus(
                                onFocusChange: (hasFocus) {
                                  setState(() {
                                    if (hasFocus) {
                                      _focusedCountryIndex = index;
                                    } else if (_focusedCountryIndex == index) {
                                      _focusedCountryIndex = null;
                                    }
                                  });
                                },
                                child: InkWell(
                                  autofocus: index == 0,
                                  borderRadius: BorderRadius.circular(70),
                                  onTap: () {
                                    setState(() => _current = index);
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: ((context) {
                                      return ChannelScreen(
                                          isLive: true,
                                          models: entry.channels,
                                          topWidget: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                widget.topWidget,
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Text(
                                                  entry.name,
                                                  style: TeveTheme.appText(
                                                      size: 14,
                                                      weight: FontWeight.w500,
                                                      color: TeveTheme
                                                          .logoDarkColor),
                                                )
                                              ]));
                                    })));
                                  },
                                  child: Container(
                                    height: 120,
                                    width: 120,
                                    decoration: (isCurrent ||
                                            _focusedCountryIndex == index)
                                        ? BoxDecoration(
                                            border: Border.all(
                                                color: TeveTheme.whiteColor,
                                                width: 5),
                                            borderRadius:
                                                BorderRadius.circular(70))
                                        : null,
                                    child: Image.asset(
                                      "assets/images/${entry.code}.png",
                                      fit: BoxFit.fill,
                                      height: 120,
                                      width: 120,
                                    ),
                                  ),
                                ),
                              ),
                              isCurrent
                                  ? Column(
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 500,
                                              child: Text(
                                                entry.name,
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                style: TeveTheme.appText(
                                                    size: 20,
                                                    weight: FontWeight.w600),
                                              ),
                                            ),
                                            Text(
                                              _playableOnly
                                                  ? "${entry.playableChannels} Playable"
                                                  : "${entry.totalChannels} Channels · ${entry.playableChannels} Playable",
                                              style: TeveTheme.appText(
                                                  size: 15,
                                                  weight: FontWeight.w500),
                                            )
                                          ],
                                        ),
                                      ],
                                    )
                                  : const SizedBox()
                            ],
                          );
                        }),
                        options: CarouselOptions(
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            },
                            aspectRatio: 1,
                            viewportFraction: 0.2,
                            autoPlay: false,
                            enlargeCenterPage: true,
                            initialPage: currentIndex,
                            scrollPhysics: const BouncingScrollPhysics())),
              ),
              const SizedBox(
                height: 10,
              ),
              if (countries.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 14),
                  child: ElevatedButton(
                    onLongPress: () {
                      buttonCarouselController.animateToPage(currentIndex + 20);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: TeveTheme.logoLightColor),
                    onPressed: () => buttonCarouselController.nextPage(
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.linear),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 24,
                    ),
                  ),
                )
            ],
          ),
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
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Icon(
                    Icons.tv,
                    color: TeveTheme.whiteColor,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    "Countries",
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
