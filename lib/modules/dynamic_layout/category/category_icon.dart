import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../config/category_config.dart';
import '../config/category_item_config.dart';
import '../helper/helper.dart';
import 'category_icon_item.dart';

const _defaultSeparateWidth = 14.0;

const _paddingList = 12.0;

class CategoryIcons extends StatelessWidget {
  final CategoryConfig config;
  final int crossAxisCount;
  final Function onShowProductList;
  final Map<String?, String?> listCategoryName;

  const CategoryIcons({
    required this.onShowProductList,
    required this.listCategoryName,
    required this.config,
    this.crossAxisCount = 5,
    Key? key,
  }) : super(key: key);

  String? _getCategoryName({required CategoryItemConfig item}) {
    if (config.commonItemConfig.hideTitle) {
      return '';
    }

    if (item.keepDefaultTitle) {
      return item.title ?? '';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var CategoryItems = [
      {
        "name": "Handmade Katana\nSamurai Swords",
        "id": 59,
        "image": "handmade-katana.png"
      },
      {
        "name": "Handmade Laito\nSamurai Swords",
        "id": 59,
        "image": "handmade-iaito.png"
      },
      {"name": "Handmade\nBokken", "id": 59, "image": "bokken.png"},
      {"name": "Uniforms", "id": 59, "image": "uniforms.png"}
    ];
    var items = <Widget>[];
    for (var item in CategoryItems) {
      items.add(_categoryIcon(item));
    }

    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.expand((element) {
            return [
              element,
            ];
          }).toList()),
    );
  }

  Widget _categoryIcon(Map category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          'assets/icons/categories/${category['image']}',
          height: 48,
          width: 48,
        ),
        Text(
          category['name'],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
