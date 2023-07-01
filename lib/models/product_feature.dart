import '../../common/constants.dart';
import '../../common/tools.dart';

class ProductFeature {
  int? id;
  int? id_feature;
  String? name;
  String? custom;
  String? slug;
  Map value = {};

  /// For BigCommerce.
  ProductFeature({
    this.id,
    this.id_feature,
    this.name,
    this.custom,
    this.value = const {},
  });

  ProductFeature.fromJson(Map<String, dynamic> parsedJson) {
    id = int.parse(parsedJson['id']);
    id_feature = int.parse(parsedJson['id_feature']);
    custom = parsedJson['custom'];
    value = parsedJson['value'];
  }

  //create method toJson
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'id_feature': id_feature,
      'name': name,
      'value': value,
    };
  }

  ProductFeature.fromPresta(att) {
    try {
      id = att['id'];
      id_feature = int.parse(att['id_feature']);
      name = att['name'];
      value = {"value": att['value'][0]};
    } catch (e) {
      printLog(e.toString() + "aca");
    }
  }

  ProductFeature copyWith({
    int? id,
    int? id_feature,
    String? custom,
    Map? value,
  }) {
    return ProductFeature(
      id: id ?? this.id,
      id_feature: id_feature ?? this.id_feature,
      custom: custom ?? this.custom,
      value: value ?? this.value,
    );
  }
}
