import 'package:gazzer_userapp/common/models/restaurant_model.dart';

class CuisineRestaurantModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Restaurant>? restaurants;

  CuisineRestaurantModel(
      {this.totalSize, this.limit, this.offset, this.restaurants});

  CuisineRestaurantModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    if (json['restaurants'] != null) {
      restaurants = <Restaurant>[];
      json['restaurants'].forEach((v) {
       Restaurant result =  Restaurant.fromJson(v);
        if(!(restaurants!.any((b) => b.id ==result.id))){
          restaurants!.add(result);
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (restaurants != null) {
      data['restaurants'] = restaurants!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
