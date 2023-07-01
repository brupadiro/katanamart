import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../models/index.dart'
    show Product, ProductAttribute, ProductModel, ProductVariation;
import '../../models/product_feature.dart';
import '../../services/index.dart';
import '../../widgets/product/product_variant.dart';
import '../product_variant_mixin.dart';
import 'services/prestashop_service.dart';

mixin PrestashopVariantMixin on ProductVariantMixin {
  PrestashopService get prestaShopService;

  Future<void> getProductVariations({
    BuildContext? context,
    Product? product,
    void Function({
      Product? productInfo,
      List<ProductVariation>? variations,
      List<ProductFeature>? features,
      Map<String?, String?> mapAttribute,
      ProductVariation? variation,
    })?
        onLoad,
  }) async {
    // if (product.attributes.isEmpty) {
    //   return;
    // }

    Map<String?, String?> mapAttribute = HashMap();
    var variations = <ProductVariation>[];
    var features = <ProductFeature>[];
    if (prestaShopService.languageCode == null) {
      await prestaShopService.getLanguage();
    }
    if (prestaShopService.productOptions == null) {
      await prestaShopService.getProductOptions();
    }
    if (prestaShopService.productOptionValues == null) {
      await prestaShopService.getProductOptionValues();
    }
    var productInfo = product;
    if (product!.attributes!.isEmpty) {
      var stockAvailable = (await prestaShopService.prestaApi
          .getAsync('stock_availables/${product.sku}'))?['stock_available'];
      var quantity = int.parse(stockAvailable?['quantity'] ?? '0');
      if (quantity > 0) {
        productInfo!.stockQuantity = quantity;
        productInfo.inStock = true;
      }
    } else {
      await Services().api.getProductVariations(product)!.then((value) {
        variations = value!.toList();
      });
    }

    //get product features
    features = await Services().api.getProductFeatures(product.features!)!;
    // utilizar la lista de características de producto aquí
    if (variations.isEmpty) {
      for (var attr in productInfo!.attributes!) {
        mapAttribute.update(attr.name, (value) => attr.options![0],
            ifAbsent: () => attr.options![0]);
      }
    } else {
      for (var variant in variations) {
        if (variant.price == productInfo!.price) {
          for (var attribute in variant.attributes) {
            mapAttribute.update(attribute.name, (value) => attribute.option,
                ifAbsent: () => attribute.option);
          }
          break;
        }
      }
      if (mapAttribute.isEmpty) {
        for (var attribute in productInfo!.attributes!) {
          mapAttribute.update(attribute.name, (value) => value, ifAbsent: () {
            return attribute.options![0];
          });
        }
      }
    }
    final productVariation = updateVariation(variations, mapAttribute);
    context?.read<ProductModel>().changeProductVariations(variations);
    if (productVariation != null) {
      context?.read<ProductModel>().changeSelectedVariation(productVariation);
    }

    onLoad!(
        productInfo: productInfo,
        variations: variations,
        features: features,
        mapAttribute: mapAttribute,
        variation: productVariation);

    return;
  }

  bool couldBePurchased(
    List<ProductVariation>? variations,
    ProductVariation? productVariation,
    Product product,
    Map<String?, String?>? mapAttribute,
  ) {
    return true;
  }

  List<Widget> getBuyButtonWidget(
    BuildContext context,
    ProductVariation? productVariation,
    Product product,
    Map<String?, String?>? mapAttribute,
    int maxQuantity,
    int quantity,
    Function addToCart,
    Function onChangeQuantity,
    List<ProductVariation>? variations,
  ) {
    String? filter;
    final isAvailable = productVariation != null || product.type != 'variable';
    if (product.groupedProducts != null) {
      var id = <String?>[];
      for (var item in product.groupedProducts!) {
        id.add(item['id']);
      }
      filter = 'filter[id]=${id.toString().replaceAll(', ', '|')}';
    }
    var display =
        '[id,name,description,link_rewrite,price,id_default_image,type,product_option_values[id],stock_availables[id],images[id],product_bundle[id,quantity]]';
    return [
      if (product.type == 'pack' && product.groupedProducts != null)
        FutureBuilder(
          future: prestaShopService.prestaApi
              .getAsync('products?$filter&display=$display'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                children:
                    List.generate(product.groupedProducts!.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.grey.withOpacity(0.2),
                    child: Row(
                      children: [
                        Container(
                          color: Colors.grey.withOpacity(0.4),
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Loading...',
                                style: TextStyle(fontSize: 15),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text('...')
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        const Text('x'),
                        const SizedBox(
                          width: 15,
                        ),
                      ],
                    ),
                  );
                }),
              );
            }
            var products = <Product>[];
            var list = snapshot.data as Map;
            for (var item in list['products']) {
              var bundle = product.groupedProducts!.firstWhere(
                  (e) => e['id'].toString() == item['id'].toString(),
                  orElse: () => null);
              if (bundle != null) {
                item['quantity'] = bundle['quantity'] ?? '0';
              }
              products.add(Product.fromPresta(
                  item, prestaShopService.prestaApi.apiLink));
            }
            return Column(
              children: List.generate(products.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          products[index].imageFeature!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              products[index].name!,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(products[index].regularPrice!)
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Text('x${products[index].stockQuantity}'),
                      const SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ...makeBuyButtonWidget(context, productVariation, product, mapAttribute,
          maxQuantity, quantity, addToCart, onChangeQuantity, isAvailable),
    ];
  }

  List<Widget> getProductAttributeWidget(
    String lang,
    Product product,
    Map<String?, String?>? mapAttribute,
    Function onSelectProductVariant,
    List<ProductVariation> variations,
  ) {
    var listWidget = <Widget>[];

    final checkProductAttribute =
        product.attributes != null && product.attributes!.isNotEmpty;
    if (checkProductAttribute) {
      for (var attr in product.attributes!) {
        if (attr.name != null && attr.name!.isNotEmpty) {
          var options = List<String>.from(attr.options!);

          var selectedValue = mapAttribute![attr.name!] ?? '';

          listWidget.add(
            BasicSelection(
              options: options,
              title: (kProductVariantLanguage[lang] != null &&
                      kProductVariantLanguage[lang][attr.name!.toLowerCase()] !=
                          null)
                  ? kProductVariantLanguage[lang][attr.name!.toLowerCase()]
                  : attr.name!.toLowerCase(),
              type: kProductVariantLayout[attr.name!.toLowerCase()] ?? 'box',
              value: selectedValue,
              onChanged: (val) => onSelectProductVariant(
                  attr: attr,
                  val: val,
                  mapAttribute: mapAttribute,
                  variations: variations),
            ),
          );
          listWidget.add(
            const SizedBox(height: 20.0),
          );
        }
      }
    }
    return listWidget;
  }

  List<Widget> getProductTitleWidget(
      BuildContext context, productVariation, product) {
    final isAvailable =
        productVariation != null ? productVariation.id != null : true;

    return makeProductTitleWidget(
        context, productVariation, product, isAvailable);
  }

  void onSelectProductVariant({
    required ProductAttribute attr,
    String? val,
    required List<ProductVariation> variations,
    required Map<String?, String?> mapAttribute,
    required Function onFinish,
  }) {
    mapAttribute.update(attr.name, (value) => val.toString(),
        ifAbsent: () => val.toString());

    final productVariantion = updateVariation(variations, mapAttribute);

    onFinish(mapAttribute, productVariantion);
  }
}
