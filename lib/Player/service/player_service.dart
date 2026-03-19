// ignore_for_file: use_build_context_synchronously, prefer_final_fields

import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:teve/Home/models/channel_model.dart';

class PlayerService {
  static const String _favoritesKey = 'local_favorites';

  Future<String> addToFav(
      {required BuildContext context, required ChannelModel model}) async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getString(_favoritesKey);
    final List<dynamic> decoded =
        raw == null || raw.isEmpty ? [] : (jsonDecode(raw) as List<dynamic>);

    final payload = model.toJson();
    final name = (payload['channel_name'] ?? '').toString().trim();
    final link = (payload['stream_link'] ?? '').toString().trim();

    final exists = decoded.any((e) {
      if (e is! Map) return false;
      return (e['channel_name'] ?? '').toString().trim() == name &&
          (e['stream_link'] ?? '').toString().trim() == link;
    });

    if (exists) {
      return "This channel is already in your favorites.";
    }

    decoded.add(payload);
    await pref.setString(_favoritesKey, jsonEncode(decoded));
    return "Added to favorites";
  }
}
