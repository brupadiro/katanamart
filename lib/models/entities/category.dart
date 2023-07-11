import 'package:html_unescape/html_unescape.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../services/service_config.dart';
import '../serializers/product_category.dart';
import 'product.dart';

class Category {
  String? id;
  String? sku;
  String? name;
  String? image;
  String? parent;
  String? slug;
  int? totalProduct;
  List<Product>? products;
  bool hasChildren = false;
  List<Category> subCategories = [];

  Category({
    this.id,
    this.sku,
    this.name,
    this.image,
    this.parent,
    this.slug,
    this.totalProduct,
    this.products,
    this.hasChildren = false,
    required this.subCategories,
  });

  Category.fromListingJson(Map<String, dynamic>? parsedJson) {
    try {
      id = Tools.getValueByKey(
              parsedJson, DataMapping().kCategoryDataMapping['id'])
          .toString();
      name = HtmlUnescape().convert(Tools.getValueByKey(
          parsedJson, DataMapping().kCategoryDataMapping['name']));
      parent = Tools.getValueByKey(
              parsedJson, DataMapping().kCategoryDataMapping['parent'])
          .toString();
      totalProduct = int.parse(Tools.getValueByKey(
              parsedJson, DataMapping().kCategoryDataMapping['count'])
          .toString());
      var termImage = Tools.getValueByKey(
          parsedJson, DataMapping().kCategoryDataMapping['image']);
      if (termImage is String) {
        image = termImage;
      }
      if (image == null) {
        if (DataMapping().kCategoryImages[id!] != null) {
          image = DataMapping().kCategoryImages[id!];
        } else {
          image = kDefaultImage;
        }
      }
    } catch (err) {
      rethrow;
    }
  }

  Category.fromJson(Map<String, dynamic> parsedJson) {
    if (parsedJson['slug'] == 'uncategorized') {
      return;
    }

    try {
      id = parsedJson['id']?.toString() ?? parsedJson['term_id'].toString();
      name = HtmlUnescape().convert(parsedJson['name']);
      parent = parsedJson['parent'].toString();
      totalProduct = parsedJson['count'];
      slug = parsedJson['slug'];
      final image = parsedJson['image'];
      if (image != null) {
        this.image = image['src'].toString();
      } else {
        this.image = kDefaultImage;
      }
      hasChildren = parsedJson['has_children'] ?? false;
    } catch (e, trace) {
      printLog(e.toString());
      printLog(trace.toString());
    }
  }

  Category copyWith({
    String? id,
    String? sku,
    String? name,
    String? image,
    String? parent,
    String? slug,
    int? totalProduct,
    List<Product>? products,
    bool? hasChildren,
    List<Category>? subCategories,
  }) {
    return Category(
        id: id ?? this.id,
        sku: sku ?? this.sku,
        name: name ?? this.name,
        image: image ?? this.image,
        parent: parent ?? this.parent,
        slug: slug ?? this.slug,
        totalProduct: totalProduct ?? this.totalProduct,
        products: products ?? this.products,
        subCategories: subCategories ?? this.subCategories);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parent': parent,
        'image': {'src': image}
      };

  Category.fromJsonPresta(Map<String, dynamic> parsedJson, apiLink) {
    try {
      id = parsedJson['id'].toString();
      name = HtmlUnescape().convert(parsedJson['name']);
      parent = parsedJson['id_parent'];
      image = apiLink('images/categories/$id');
      totalProduct = parsedJson['nb_products_recursive'] != null
          ? int.parse(parsedJson['nb_products_recursive'].toString())
          : null;
    } catch (e, trace) {
      printLog(e.toString());
      printLog(trace.toString());
    }
  }

  Category.fromWordPress(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'].toString();
    name = parsedJson['name'];
    parent = parsedJson['parent'].toString();
    totalProduct = parsedJson['count'];
    if (kCategoryStaticImages.isNotEmpty) {
      /// prioritize local category images over remote ones
      image = kCategoryStaticImages[parsedJson['id']] ?? kDefaultImage;
    } else {
      /// "Organize my uploads into month- and year-based folders" must be unchecked
      /// at CMS DashBoard > Settings > Media
      /// Automatically get category image by following common format:
      /// https://customer-site.com/wp-content/uploads/category-{category-id}.jpeg
      image = '${Config().url}/wp-content/uploads/category-$id.jpeg';
    }
  }
  // final image = parsedJson['image'];
  // if (image != null) {
  //   this.image = image['src'].toString();
  // } else {
  //   this.image = kCategoryStaticImages[parsedJson['id']] ?? kDefaultImage;
  // }

  bool get isRoot => parent == '0';

  @override
  String toString() => 'Category { id: $id  name: $name}';
}
