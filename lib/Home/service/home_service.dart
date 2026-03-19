// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teve/Home/models/categories_model.dart';
import 'package:teve/Home/models/channel_model.dart';
import 'package:teve/Home/models/countries_model.dart';
import 'package:teve/Home/models/fav_model.dart';
import 'package:teve/Home/models/languages_model.dart';
import 'package:teve/Utils/teve_theme.dart';
import 'package:teve/common/api.dart';

class HomeService {
  ApiService apiService = ApiService();
  static const String _channelsCacheKey = 'channels_cache_v1';

  static const List<String> _channelSources = [
    "https://iptv-org.github.io/api/channels.json",
    "https://cdn.jsdelivr.net/gh/iptv-org/iptv@master/channels.json",
    "https://raw.githubusercontent.com/iptv-org/iptv/master/channels.json",
  ];

  static const List<String> _streamSources = [
    "https://iptv-org.github.io/api/streams.json",
    "https://cdn.jsdelivr.net/gh/iptv-org/iptv@master/streams.json",
    "https://raw.githubusercontent.com/iptv-org/iptv/master/streams.json",
  ];

  Future<List<ChannelModel>> fetchChannels(BuildContext context) async {
    Object? lastError;
    final streamMaps = await _fetchStreamMaps();
    final streamByChannelId = streamMaps[0];
    final streamByTitle = streamMaps[1];

    for (final source in _channelSources) {
      final uri = Uri.parse(source);

      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final response = await http
              .get(uri, headers: {"accept": "application/json"})
              .timeout(const Duration(seconds: 30));

          if (response.statusCode != 200) {
            lastError = "HTTP ${response.statusCode} from ${uri.host}";
            continue;
          }

          final List<dynamic> payload =
              jsonDecode(response.body) as List<dynamic>;
          final channels = payload
              .whereType<Map<String, dynamic>>()
              .map((json) => _channelFromAnyJson(
                    json,
                    streamByChannelId: streamByChannelId,
                    streamByTitle: streamByTitle,
                  ))
              .whereType<ChannelModel>()
              .toList();

          if (channels.isNotEmpty) {
            final pref = await SharedPreferences.getInstance();
            await pref.setString(_channelsCacheKey, jsonEncode(payload));
            return channels;
          }

          lastError = "Parsed 0 channels from ${uri.host}";
        } on TimeoutException {
          lastError = "Request timed out from ${uri.host}";
          if (attempt == 1) {
            await Future.delayed(const Duration(milliseconds: 700));
          }
        } catch (e) {
          lastError = e;
        }
      }
    }

    final pref = await SharedPreferences.getInstance();
    final cachedRaw = pref.getString(_channelsCacheKey);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final List<dynamic> payload = jsonDecode(cachedRaw) as List<dynamic>;
        final cachedChannels = payload
            .whereType<Map<String, dynamic>>()
            .map((json) => _channelFromAnyJson(
                  json,
                  streamByChannelId: streamByChannelId,
                  streamByTitle: streamByTitle,
                ))
            .whereType<ChannelModel>()
            .toList();
        if (cachedChannels.isNotEmpty) {
          debugPrint('fetchChannels fallback: using cached channels');
          return cachedChannels;
        }
      } catch (_) {}
    }

    TeveTheme.moveToErrorPage(
      context: context,
      text: "Unable to load channels right now. Please try again in a minute.",
    );
    debugPrint("fetchChannels failed: $lastError");
    return [];
  }

  Future<List<Map<String, String>>> _fetchStreamMaps() async {
    final byChannelId = <String, String>{};
    final byTitle = <String, String>{};

    for (final source in _streamSources) {
      final uri = Uri.parse(source);
      try {
        final response = await http
            .get(uri, headers: {"accept": "application/json"})
            .timeout(const Duration(seconds: 25));
        if (response.statusCode != 200) continue;

        final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
        for (final item in payload) {
          if (item is! Map<String, dynamic>) continue;
          final url = item['url']?.toString();
          if (url == null || url.isEmpty) continue;

          final channelId = item['channel']?.toString();
          if (channelId != null && channelId.isNotEmpty) {
            byChannelId.putIfAbsent(channelId, () => url);
          }

          final title = item['title']?.toString().toLowerCase().trim();
          if (title != null && title.isNotEmpty) {
            byTitle.putIfAbsent(title, () => url);
          }
        }

        if (byChannelId.isNotEmpty || byTitle.isNotEmpty) {
          break;
        }
      } catch (_) {
        continue;
      }
    }

    return [byChannelId, byTitle];
  }

  ChannelModel? _channelFromAnyJson(
    Map<String, dynamic> json, {
    required Map<String, String> streamByChannelId,
    required Map<String, String> streamByTitle,
  }) {
    try {
      final categoriesRaw = json['categories'];
      final countriesRaw = json['countries'];
      final languagesRaw = json['languages'];
      final country = json['country'];

      final categories = <Categories>[];
      if (categoriesRaw is List) {
        for (final item in categoriesRaw) {
          if (item is Map<String, dynamic>) {
            categories.add(Categories.fromJson(item));
          } else if (item is String && item.isNotEmpty) {
            categories.add(Categories(name: item, slug: item));
          }
        }
      }

      final countries = <Countries>[];
      if (countriesRaw is List) {
        for (final item in countriesRaw) {
          if (item is Map<String, dynamic>) {
            countries.add(Countries.fromJson(item));
          } else if (item is String && item.isNotEmpty) {
            countries.add(Countries(name: item, code: item));
          }
        }
      } else if (country is String && country.isNotEmpty) {
        countries.add(Countries(name: country, code: country));
      }

      final languages = <Languages>[];
      if (languagesRaw is List) {
        for (final item in languagesRaw) {
          if (item is Map<String, dynamic>) {
            languages.add(Languages.fromJson(item));
          } else if (item is String && item.isNotEmpty) {
            languages.add(Languages(name: item, code: item));
          }
        }
      }

      final channelName = (json['name'] ?? '').toString();
      final channelId = json['id']?.toString();
      final directUrl =
          (json['url'] ?? json['stream'] ?? json['stream_url'])?.toString();
      final resolvedUrl = (directUrl != null && directUrl.isNotEmpty)
          ? directUrl
          : (channelId != null ? streamByChannelId[channelId] : null) ??
              streamByTitle[channelName.toLowerCase().trim()];

      return ChannelModel(
        name: channelName,
        logo: (json['logo'] ?? json['logo_url'])?.toString(),
        url: resolvedUrl,
        categories: categories,
        countries: countries,
        languages: languages,
      );
    } catch (_) {
      return null;
    }
  }

  static const String _favoritesKey = 'local_favorites';

  Future<List<FavModel>> fetchFavChannels(BuildContext context) async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => FavModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> deleteFavChannel(
      {required BuildContext context, required FavModel model}) async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) {
      return "Nothing to remove";
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      decoded.removeWhere((e) {
        if (e is! Map) return false;
        return (e['channel_name'] ?? '').toString().trim() ==
                (model.channelName ?? '').trim() &&
            (e['stream_link'] ?? '').toString().trim() ==
                (model.streamLink ?? '').trim();
      });
      await pref.setString(_favoritesKey, jsonEncode(decoded));
      return "Removed from favorites";
    } catch (_) {
      return "Cannot delete this channel";
    }
  }
}

