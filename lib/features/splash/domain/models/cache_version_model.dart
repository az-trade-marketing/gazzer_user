class CacheVersionModel {
  List<Data>? data;

  CacheVersionModel({this.data});

  CacheVersionModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

}

class Data {
  String? api;
  String? uuid;

  Data({this.api, this.uuid});

  Data.fromJson(Map<String, dynamic> json) {
    api = json['api'];
    uuid = json['uuid'];
  }
}
