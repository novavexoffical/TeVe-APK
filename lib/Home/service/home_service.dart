// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teve/Home/models/channel_model.dart';
import 'package:teve/Home/models/fav_model.dart';
import 'package:teve/Utils/teve_theme.dart';
import 'package:teve/common/api.dart';

class HomeService {
  ApiService apiService = ApiService();

  static const List<String> _channelSources = [
    "https://iptv-org.github.io/api/channels.json",
    "https://cdn.jsdelivr.net/gh/iptv-org/iptv@master/channels.json",
  ];

  Future<List<ChannelModel>> fetchChannels(BuildContext context) async {
    Object? lastError;

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
          return payload.map((e) => ChannelModel.fromJson(e)).toList();
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

    TeveTheme.moveToErrorPage(
      context: context,
      text: "Unable to load channels right now. Please try again in a minute.",
    );
    debugPrint("fetchChannels failed: $lastError");
    return [];
  }

  Future<List<FavModel>> fetchFavChannels(BuildContext context) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final session = pref.getString('session');
    if (session == null || session == 'guest') {
      return [];
    }

    String endpoint = "fav/";
    var response = await apiService.getAllData(endpoint, isDb: true);
    if (response.isLeft) {
      return [];
    } else {
      return response.right.map((e) => FavModel.fromJson(e)).toList();
    }
  }

  Future<String> deleteFavChannel(
      {required BuildContext context, required FavModel model}) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final session = pref.getString('session');
    if (session == null || session == 'guest') {
      return "Sign in to manage favorites";
    }

    String endpoint = "fav/delete";
    var response =
        await apiService.deleteData(endpoint, model.toJson(), isDb: true);
    if (response.isLeft) {
      return "Cannot delete this channel";
    } else {
      return "Removed from your favorite's";
    }
  }
}
