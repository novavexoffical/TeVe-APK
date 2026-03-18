// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:teve/Home/models/channel_model.dart';
import 'package:teve/Home/models/fav_model.dart';
import 'package:teve/Utils/teve_theme.dart';
import 'package:teve/common/api.dart';

class HomeService {
  ApiService apiService = ApiService();

  Future<List<ChannelModel>> fetchChannels(BuildContext context) async {
    try {
      final uri = Uri.parse("${TeveTheme.iptvURl}api/channels.json");
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        TeveTheme.moveToErrorPage(
            context: context,
            text: "Unable to load channels (HTTP ${response.statusCode})");
        return [];
      }

      final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
      return payload.map((e) => ChannelModel.fromJson(e)).toList();
    } catch (e) {
      TeveTheme.moveToErrorPage(
          context: context,
          text: "Unable to load channels. Check internet and try again.");
      return [];
    }
  }

  Future<List<FavModel>> fetchFavChannels(BuildContext context) async {
    String endpoint = "fav/";
    var response = await apiService.getAllData(endpoint, isDb: true);
    if (response.isLeft) {
      TeveTheme.moveToErrorPage(context: context, text: response.left.message!);
      return [];
    } else {
      return response.right.map((e) => FavModel.fromJson(e)).toList();
    }
  }

  Future<String> deleteFavChannel(
      {required BuildContext context, required FavModel model}) async {
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
