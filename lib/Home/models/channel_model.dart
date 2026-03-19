import 'package:teve/Home/models/categories_model.dart';
import 'package:teve/Home/models/countries_model.dart';
import 'package:teve/Home/models/languages_model.dart';
import 'package:teve/Home/models/tvg_model.dart';

class ChannelModel {
  String? name;
  String? logo;
  String? url;
  List<Categories>? categories;
  List<Countries>? countries;
  List<Languages>? languages;
  Tvg? tvg;
  bool isBlocked;

  ChannelModel(
      {this.name,
      this.logo,
      this.url,
      this.categories,
      this.countries,
      this.languages,
      this.tvg,
      this.isBlocked = false});

  ChannelModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    logo = json['logo'];
    url = json['url'];
    if (json['categories'] != null) {
      categories = <Categories>[];
      json['categories'].forEach((v) {
        categories!.add(Categories.fromJson(v));
      });
    }
    if (json['countries'] != null) {
      countries = <Countries>[];
      json['countries'].forEach((v) {
        countries!.add(Countries.fromJson(v));
      });
    }
    if (json['languages'] != null) {
      languages = <Languages>[];
      json['languages'].forEach((v) {
        languages!.add(Languages.fromJson(v));
      });
    }
    tvg = json['tvg'] != null ? Tvg.fromJson(json['tvg']) : null;
  }

  bool get isPlayable =>
      !isBlocked && url != null && url!.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      "stream_link": url,
      "category": categories![0].name,
      "channel_name": name
    };
  }
}
