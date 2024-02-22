import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:http_auth/http_auth.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/tools/parse_xml.dart';
import '../../../models/index.dart';
import '../../../models/product_feature.dart';
import '../../../services/base_services.dart';
import 'prestashop_api.dart';

class PrestashopService extends BaseServices {
  final storage = new FlutterSecureStorage();

  PrestashopService({
    required String domain,
    String? blogDomain,
    required String key,
  })  : prestaApi = PrestashopAPI(url: domain, key: key),
        super(domain: domain, blogDomain: blogDomain);

  final PrestashopAPI prestaApi;

  List<Category>? cats;
  List<Map<String, dynamic>>? productOptions;
  List<Map<String, dynamic>>? productOptionValues;
  List<Map<String, dynamic>>? orderStates;
  List<Map<String, dynamic>>? carriers;
  Map<String, dynamic> orderAddresses = <String, dynamic>{};
  String? idLang;
  String? languageCode;
  ParseXml parsexML = ParseXml();

  String payPalDomain = kPaypalConfig['production'] == true
      ? 'https://api.paypal.com'
      : 'https://api.sandbox.paypal.com';

  void appConfig(appConfig) {
    productOptions = null;
    productOptionValues = null;
    orderStates = null;
    carriers = null;
    cats = null;
    orderAddresses = <String, dynamic>{};
  }

  List<dynamic> downLevelsCategories(dynamic cats) {
    int? parent;
    var categories = <dynamic>[];
    for (var item in cats) {
      if (parent == null || int.parse(item['id_parent'].toString()) < parent) {
        parent = int.parse(item['id_parent'].toString());
      }
    }
    for (var item in cats) {
      if (int.parse(item['id_parent'].toString()) == parent) continue;
      categories.add(item);
    }
    return categories;
  }

  List<dynamic> setParentCategories(dynamic cats) {
    int? parent;
    var categories = <dynamic>[];
    for (var item in cats) {
      if (parent == null || int.parse(item['id_parent'].toString()) < parent) {
        parent = int.parse(item['id_parent'].toString());
      }
    }
    for (var item in cats) {
      if (int.parse(item['id_parent'].toString()) == parent) {
        item['id_parent'] = '0';
      }
      categories.add(item);
    }
    return categories;
  }

  @override
  Future<List<Category>?> getCategories({lang}) async {
    try {
      if (languageCode != lang) await getLanguage(lang: lang);
      if (cats != null) return cats;
      var categoriesId;
      var result = <Category>[];
      categoriesId =
          await prestaApi.getAsync('categories?filter[active]=1&display=full');

      var categories = categoriesId['categories'];
      categories = setParentCategories(categories);
      List<int> selectedCategories = [3, 59, 45, 14];
      for (var item in categories) {
        item['name'] = getValueByLang(item['name']);
        if (int.parse(item["level_depth"]) > 1) {
          result.add(Category.fromJsonPresta(item, prestaApi.apiLink));
        }
      }
      cats ??= result;
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Product>> getProducts({userId}) async {
    try {
      var productsId;
      var products = <Product>[];
      productsId = await prestaApi.getAsync('products');
      for (var item in productsId['products']) {
        var category = await prestaApi.getAsync('products/${item["id"]}');
        if (category['product']['name'].isEmpty) continue;
        products
            .add(Product.fromPresta(category['product'], prestaApi.apiLink));
      }
      return products;
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future<List<Product>> fetchProductsLayout(
      {required config, lang, userId, bool refreshCache = false}) async {
    try {
      var products = <Product>[];
      if (languageCode != lang) await getLanguage(lang: lang);
      if (cats == null) await getCategories();
      if (productOptions == null) {
        await getProductOptions();
      }
      if (productOptionValues == null) {
        await getProductOptionValues();
      }
      var filter = '';
      if (config.containsKey('category')) {
        var childs = getChildCategories([config['category'].toString()]);
        filter = '&id_category=${childs.toString()}';
        filter = filter.replaceAll('[', '');
        filter = filter.replaceAll(']', '');
      }
      if (kAdvanceConfig.hideOutOfStock) {
        filter += '&hide_stock=true';
      }
      var page = config.containsKey('page') ? config['page'] : 1;
      var display = 'full';
      var limit =
          '${(page - 1) * apiPageSize},${config['limit'] ?? apiPageSize}';
      var response = await prestaApi
          .getAsync('products?display=$display&limit=$limit$filter&lang=$lang');
      if (response is Map) {
        for (var item in response['products']) {
          products
              .add(Product.fromPresta(convertProduct(item), prestaApi.apiLink));
        }
      } else {
        return [];
      }
      return products;
    } catch (e, trace) {
      printLog(trace.toString());
      printLog(e.toString());
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      return [];
    }
  }

  //get all attribute_term for selected attribute for filter menu
  @override
  Future<List<SubAttribute>> getSubAttributes({int? id, String? lang}) async {
    try {
      var list = <SubAttribute>[];
      if (productOptionValues == null) await getProductOptions();
      for (var item in productOptionValues!) {
        if (item['id_attribute_group'].toString() == id.toString()) {
          list.add(SubAttribute.fromJson(item));
        }
      }
      return list;
    } catch (e) {
      rethrow;
    }
  }

  //get all attributes for filter menu
  @override
  Future<List<FilterAttribute>> getFilterAttributes({String? lang}) async {
    var list = <FilterAttribute>[];
    if (productOptions == null) await getProductOptions();

    for (var item in productOptions!) {
      list.add(FilterAttribute.fromJson(
          {'id': item['id'], 'name': item['name'], 'slug': item['name']}));
    }
    return list;
  }

  List<String?> getChildCategories(List<String?> categories) {
    // ignore: unnecessary_null_comparison
    var categoriesList = categories != null ? [...categories] : [];
    if (cats?.firstWhereOrNull((e) {
          for (var item in categoriesList) {
            var exist =
                categoriesList.firstWhere((i) => i == e.id, orElse: () => null);
            if (item == e.parent && exist == null) return true;
          }
          return false;
        }) ==
        null) return categories;
    for (var item in categories) {
      var categoryItem = cats?.where((e) => e.parent == item);

      if (categoryItem?.isNotEmpty ?? false) {
        for (var cat in categoryItem!) {
          var exist =
              categories.firstWhere((i) => i == cat.id, orElse: () => null);
          if (exist == null) categoriesList.add(cat.id);
        }
      }
    }
    return getChildCategories(categoriesList as List<String?>);
  }

  Map<String, dynamic> convertProduct(dynamic item) {
    var optionValues = item['associations']?['product_option_values'] as List?;
    if (optionValues != null) {
      var attribute = <String?, dynamic>{};
      for (var option in optionValues) {
        var opt = productOptionValues?.firstWhereOrNull(
            (e) => e['id'].toString() == option['id'].toString());
        if (opt != null) {
          var name = productOptions!.firstWhereOrNull((e) =>
              e['id'].toString() == opt['id_attribute_group'].toString());
          if (name != null) {
            var val = attribute[getValueByLang(name['name'])] ?? [];
            val.add(getValueByLang(opt['name']));
            attribute.update(getValueByLang(name['name']), (value) => val,
                ifAbsent: () => val);
          }
        }
      }
      item['attributes'] = attribute;
    }
    return item;
  }

  @override
  Future<List<Product>?> fetchProductsByCategory(
      {categoryId,
      tagId,
      page = 1,
      minPrice,
      maxPrice,
      orderBy,
      lang,
      order,
      attribute,
      attributeTerm,
      featured,
      onSale,
      listingLocation,
      userId,
      String? include,
      String? search,
      nextCursor}) async {
    try {
      var products = <Product>[];
      if (languageCode != lang) await getLanguage(lang: lang);
      if (cats == null) await getCategories();
      if (productOptions == null) {
        await getProductOptions();
      }
      if (productOptionValues == null) {
        await getProductOptionValues();
      }
      var childs = getChildCategories([categoryId]);
      var filter = '';
      filter = '&id_category=${childs.toString()}';
      filter = filter.replaceAll('[', '');
      filter = filter.replaceAll(']', '');
      if (attributeTerm != null && attributeTerm.isNotEmpty) {
        var attributeId =
            attributeTerm.substring(0, attributeTerm.indexOf(','));
        filter += '&attribute=$attributeId';
      }

      if (onSale ?? false) {
        filter += '&sale=1';
      }
      if (orderBy != null && orderBy == 'date' && !(featured ?? false)) {
        filter += '&date=${order.toUpperCase()}';
      }
      if (kAdvanceConfig.hideOutOfStock) {
        filter += '&hide_stock=true';
      }
      var display = 'full';
      var limit = '${(page - 1) * apiPageSize},$apiPageSize';
      var response = await prestaApi
          .getAsync('product?display=$display&limit=$limit$filter&lang=$lang');
      if (response is Map) {
        for (var item in response['products']) {
          products
              .add(Product.fromPresta(convertProduct(item), prestaApi.apiLink));
        }
      } else {
        return [];
      }
      return products;
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  @override
  Future createReview(
      {String? productId, Map<String, dynamic>? data, String? token}) async {
    try {} catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  Future<void> getProductOptions() async {
    try {
      productOptions = List<Map<String, dynamic>>.from((await prestaApi
              .getAsync('product_options?display=[id,name,group_type]'))[
          'product_options']);
    } catch (e) {
      productOptions = [];
    }
    return;
  }

  Future<void> getProductOptionValues() async {
    try {
      productOptionValues = List<
          Map<String, dynamic>>.from((await prestaApi.getAsync(
              'product_option_values?display=[id,id_attribute_group,color,name]'))[
          'product_option_values']);
    } catch (e) {
      productOptionValues = [];
    }
    return;
  }

  String? getValueByLang(dynamic values) {
    if (values is! List) return values;
    for (var item in values) {
      if (item['id'].toString() == (idLang ?? '1')) {
        return item['value'];
      }
    }
    return 'Error';
  }

  Future<void> getLanguage({lang = 'en'}) async {
    languageCode = lang;
    var res = await prestaApi.getAsync('languages?display=full');
    for (var item in res['languages']) {
      if (item['iso_code'] == lang.toString()) {
        idLang = item['id'].toString();
        return;
      }
    }
    idLang = res['languages'].length > 0
        ? res['languages'][0]['id'].toString()
        : '1';
  }

  @override
  Future<List<ProductVariation>> getProductVariations(Product product,
      {String? lang = 'en'}) async {
    try {
      var productVariantions = <ProductVariation>[];
      // var _product = await prestaApi.getAsync('products/${product.id}');
      // List<dynamic> combinations =
      //     _product['product']['associations']['combinations'];
      if (languageCode != lang) await getLanguage(lang: lang);
      if (productOptions == null) await getProductOptions();
      if (productOptionValues == null) await getProductOptionValues();
      var params = 'id_product=${product.id}&display=full';
      if (product.idShop != null && product.idShop!.isNotEmpty) {
        params += '&id_shop_default=${product.idShop}';
      }
      var combinationRes = await prestaApi.getAsync('attribute?$params');

      for (var i = 0; i < (combinationRes?['combinations']?.length ?? 0); i++) {
        var combination = combinationRes['combinations'][i];
        var options = combination['associations']['product_option_values'];
        var attributes = <Map<String, dynamic>>[];
        for (var option in options) {
          var optionValue = productOptionValues!.firstWhereOrNull(
              (element) => element['id'].toString() == option['id'].toString());
          if (optionValue != null) {
            var name = productOptions!.firstWhereOrNull((e) =>
                e['id'].toString() ==
                optionValue['id_attribute_group'].toString())!;
            attributes.add({
              'id': optionValue['id'],
              'name': getValueByLang(name['name']),
              'option': getValueByLang(optionValue['name'])
            });
          }
        }
        combination['attributes'] = attributes;

        combination['image'] = product.imageFeature;
        productVariantions.add(ProductVariation.fromPrestaJson(combination));
      }
      return productVariantions;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductFeature>> getProductFeatures(
      List<dynamic> productFeatures) async {
    // Realiza una solicitud GET para obtener todos los valores de las características del producto.
    final responseProductFeatureValues =
        await prestaApi.getAsync('product_feature_values');
    final responseProductFeatures =
        await prestaApi.getAsync('product_features');

    // Convierte la respuesta en una lista de mapas de tipo <String, dynamic>.
    final List<dynamic> productFeatureValues =
        responseProductFeatureValues['product_feature_values']
            .cast<Map<String, dynamic>>();

    final List<dynamic> allProductFeatures =
        responseProductFeatures['product_features']
            .cast<Map<String, dynamic>>();

    var productFeaturesComplete =
        _combineFeatureList(allProductFeatures, productFeatureValues);
    // Mapea la lista de datos en una lista de instancias de ProductFeature utilizando el método fromPresta.
    final allFeatures = productFeaturesComplete
        // ignore: unnecessary_lambdas
        .map((f) => ProductFeature.fromPresta(f))
        .toList();
    // ExtIOSNSUnderlineStyles de las características del producto en una lista de enteros.

    // ignore: omit_local_variable_types
    List<int> idList = productFeatures
        .map((e) => int.parse(e['id_feature_value']))
        .toList(); // Cambio realizado aquí
    // Filtra las características del producto para incluir solo aquellas cuyo identificador esté en idList.
    var filtered =
        allFeatures.where((feature) => idList.contains(feature.id)).toList();

    // Devuelve la lista de características del producto filtradas.
    return filtered;
  }

  List<Map<String, dynamic>> _combineFeatureList(
      List<dynamic> features, List<dynamic> featureValues) {
    final featureMap = {for (var e in features) e['id']: e};
    final combinedList = <Map<String, dynamic>>[];

    for (final value in featureValues) {
      final feature = featureMap[int.parse(value['id_feature'])];
      if (feature == null) {
        continue;
      }
      final featureName = feature['name'][0]['value'];
      final featureValue = value['value'][0]['value'];
      final combinedItem = Map<String, dynamic>.from(feature)
        ..['name'] = featureName // Incluir featureName en el mapa
        ..['value'] = [featureValue]
        ..['id'] = value['id'] // Eliminar id de la característica del mapa
        ..['id_feature'] = value['id_feature'];

      combinedList.add(combinedItem);
    }
    return combinedList;
  }

  @override
  Future<List<ShippingMethod>> getShippingMethods(
      {CartModel? cartModel,
      String? token,
      String? checkoutId,
      Store? store,
      String? langCode}) async {
    var address = cartModel!.address!;
    var lists = <ShippingMethod>[];
    var countries = await prestaApi
        .getAsync('countries?filter[iso_code]=${address.country}&display=full');
    var zone = '1';
    if (countries is Map) {
      zone = countries['countries'][0]['id_zone'] ?? 1 as String;
    }
    var shipping = await prestaApi.getAsync(
        'shipping?$checkoutId&zone=$zone&display=full&id_lang=$idLang');
    for (var item in shipping['carriers']) {
      lists.add(ShippingMethod.fromPrestaJson(item));
    }
    return lists;
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods(
      {CartModel? cartModel,
      ShippingMethod? shippingMethod,
      String? token,
      String? langCode}) async {
    var lists = <PaymentMethod>[];
    var payment = await prestaApi.getAsync('payment?display=full');
    for (var item in payment['taxes']) {
      lists.add(PaymentMethod.fromPrestaJson(item));
    }
    return lists;
  }

  Future<void> getOrderStates() async {
    orderStates = List<Map<String, dynamic>>.from((await prestaApi
        .getAsync('order_states?display=full'))['order_states']);
    return;
  }

  Future<void> getCarriers() async {
    carriers = List<Map<String, dynamic>>.from(
        (await prestaApi.getAsync('carriers?display=full'))['carriers']);
    return;
  }

  Future<void> getMyOrderAddress(String id) async {
    if (orderAddresses.containsKey(id)) return;
    var response =
        await prestaApi.getAsync('addresses?filter[id]=$id&display=full');
    if (response is Map && response['addresses'].isNotEmpty) {
      orderAddresses.update(id, (value) => response['addresses'][0],
          ifAbsent: () => response['addresses'][0]);
    } else {
      orderAddresses.update(id, (value) => {'firstname': 'Not found'},
          ifAbsent: () => {'firstname': 'Not found'});
    }
    return;
  }

  @override
  Future<PagingResponse<Order>> getMyOrders({
    User? user,
    dynamic cursor,
    String? cartId,
  }) async {
    try {
      var lists = <Order>[];
      if (orderStates == null) await getOrderStates();
      if (carriers == null) await getCarriers();
      var limit = '${(cursor - 1) * apiPageSize},$apiPageSize';
      var response = await prestaApi.getAsync(
          'orders?sort=[id_DESC]&limit=$limit&filter[id_customer]=${user!.id}&display=full&dummy=${DateTime.now().millisecondsSinceEpoch}');
      if (response['orders']?.isEmpty ?? true) {
        return const PagingResponse(data: []);
      }
      for (var item in response['orders']) {
        var order = item;
        var status = orderStates?.firstWhereOrNull(
            (e) => e['id'].toString() == item['current_state'].toString());
        if (status != null) {
          order['status'] = getValueByLang(status['name']);
        }
        var carrier = carriers?.firstWhereOrNull((element) =>
            element['id'].toString() == item['id_carrier'].toString());
        if (carrier != null) {
          order['shipping_method'] = getValueByLang(carrier['name']);
        }
        await getMyOrderAddress(item['id_address_delivery'].toString());
        var address = orderAddresses[item['id_address_delivery'].toString()];
        order['address'] = address;
        lists.add(Order.fromJson(order));
      }
      return PagingResponse(data: lists);
    } catch (e) {
      return const PagingResponse(data: []);
    }
  }

  Future<String?> getPayPalAccessToken() async {
    try {
      var client =
          BasicAuthClient(kPaypalConfig['clientId'], kPaypalConfig['secret']);
      var response = await client.post(
          '$payPalDomain/v1/oauth2/token?grant_type=client_credentials'
              .toUri()!);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body['access_token'];
      } else {
        throw body['error_description'];
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map> getPayPalPaymentDetail(String payID) async {
    var token = await getPayPalAccessToken();
    var response = await httpGet(
      '$payPalDomain/v1/payments/payment/$payID'.toUri()!,
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    return jsonDecode(response.body);
  }

  @override
  Future<Order> createOrder({
    CartModel? cartModel,
    UserModel? user,
    bool? paid,
    String? transactionId,
  }) async {
    var idCarrier = cartModel!.shippingMethod!.id;
    var idCustomer = user!.user?.id ?? '1';
    var idCurrency = await cartModel.getCurrency();
    var address = await createAddress(cartModel, user);
    var idAddressDelivery = address;
    var idAddressInvoice = address;
    //  Real value is evaluated server size (ex paypal)
    var currentState = '1';
    var payment = cartModel.paymentMethod!.title;
    var module = cartModel.paymentMethod!.id;
    var totalShipping = cartModel.shippingMethod!.cost.toString();
    var totalProducts = cartModel.getSubTotal().toString();
    final products = cartModel.item;
    final productVariationInCart =
        cartModel.productVariationInCart.keys.toList();
    var productsId = <String?>[];
    var attribute = <String>[];
    var productsQuantity = [];
    if (orderStates == null) await getOrderStates();
    var cartRows = [];
    for (var key in products.keys.toList()) {
      if (productVariationInCart.toString().contains('$key-')) {
        for (var item in productVariationInCart) {
          if (item.contains('$key-')) {
            var row = <String, dynamic>{
              'cart_row': {
                'id_product': key,
                'id_product_attribute': item.replaceAll('$key-', ''),
                'quantity': cartModel.productsInCart[item]
              }
            };
            cartRows.add(row);
          }
        }
      } else {
        var row = <String, dynamic>{
          'cart_row': {
            'id_product': key,
            'id_product_attribute': '-1',
            'quantity': cartModel.productsInCart[key!]
          }
        };
        cartRows.add(row);
      }
    }

    var cartBody = {
      'id_currency': idCurrency ?? 1,
      'id_customer': idCustomer,
      'id_address_delivery': idAddressDelivery,
      'id_address_invoice': idAddressInvoice,
      'id_lang': idLang,
      'associations': {'cart_rows': cartRows},
    };
    var cartresponse = await prestaApi.postAsync('carts', cartBody, 'cart');

    var body = {
      'id_carrier': idCarrier,
      'id_lang': idLang,
      'id_cart': cartresponse['cart']['id'],
      'id_customer': idCustomer,
      'id_currency': idCurrency ?? 1,
      'id_address_delivery': idAddressDelivery,
      'id_address_invoice': idAddressInvoice,
      'current_state': currentState,
      'payment': payment,
      'module': module,
      'total_shipping': totalShipping,
      'total_products': totalProducts,
      'notes': cartModel.notes,
      'total_paid': cartModel.getTotal(),
      'total_paid_real': cartModel.getTotal(),
      'total_products_wt': cartModel.getSubTotal(),
      'conversion_rate': 0,
      'transaction_id': transactionId
    };
    if (transactionId != null) {
      var paymentDetail = await getPayPalPaymentDetail(transactionId);
      var transactions = paymentDetail['transactions'];
      if ((transactions as List?)?.isNotEmpty ?? false) {
        var relatedResources = transactions?[0]['related_resources'] as List?;
        var data = {
          'payment_method': paymentDetail['payer']['payment_method'],
          'currency': transactions?[0]['amount']['currency'],
          'total_paid': transactions?[0]['amount']['total'],
          'payment_status': paymentDetail['state'],
          'id_transaction': paymentDetail['id'],
          'id_payment': paymentDetail['id'],
          'method': '',
          'payment_tool': ''
        };

        if (relatedResources?.isNotEmpty ?? false) {
          data['currency'] = relatedResources?[0]['sale']['amount']['currency'];
          data['total_paid'] = relatedResources?[0]['sale']['amount']['total'];
          data['payment_status'] = relatedResources?[0]['state'];
        }
      }
    }

    // var response = await prestaApi.postAsync(
    //   'order?display=full',
    //   body: body,
    // );
    // var response = await prestaApi.getAsync('order?$params');
    //
    // return Order.fromJson(response['orders'][0]);
    if ((cartModel.notes ?? '').isNotEmpty) {
      body['notes'] = cartModel.notes;
    }
    var response = await prestaApi.postAsync('orders', body, 'order');
    return Order.fromJson(response['order']);
  }

  @override
  Future updateOrder(orderId, {status, token}) async {}

  @override
  Future<PagingResponse<Product>> searchProducts({
    name,
    categoryId = '',
    categoryName,
    tag = '',
    attribute = '',
    attributeId = '',
    required page,
    lang,
    listingLocation,
    userId,
  }) async {
    var products = <Product>[];
    if (cats == null) await getCategories();
    if (languageCode != lang) await getLanguage(lang: lang);
    if (productOptions == null) {
      await getProductOptions();
    }
    if (productOptionValues == null) {
      await getProductOptionValues();
    }
    var filter = '&name=$name';
    if (categoryId != null && categoryId.isNotEmpty) {
      var childs = getChildCategories([categoryId]);
      var idCategory = '&id_category=${childs.toString()}';
      idCategory = idCategory.replaceAll('[', '');
      idCategory = idCategory.replaceAll(']', '');
      filter = filter + idCategory;
    }
    if (attributeId != null && attributeId.isNotEmpty) {
      filter += '&attribute=$attributeId';
    }
    if (kAdvanceConfig.hideOutOfStock) {
      filter += '&hide_stock=true';
    }
    var display = 'full';
    var limit = '${(page - 1) * apiPageSize},$apiPageSize';
    var response = await prestaApi
        .getAsync('product?display=$display&limit=$limit$filter&lang=$lang');
    if (response is Map) {
      for (var item in response['products']) {
        products
            .add(Product.fromPresta(convertProduct(item), prestaApi.apiLink));
      }
    } else {
      return const PagingResponse(data: <Product>[]);
    }
    return PagingResponse(data: products);
  }

  @override
  Future<Product> getProduct(id, {lang}) async {
    printLog('::::request getProduct $id');
    var response = await prestaApi
        // created getProduct api because prestashop stock api doesn't provide wholesale_price field
        .getAsync('product?display=full&id_product=$id');
    // .getAsync('products?display=full&limit=5&filter[id]=[$id]&lang=$lang');

    return Product.fromPresta(response['products'][0], prestaApi.apiLink);
  }

  /// Auth
  @override
  Future<User?> getUserInfo(cookie) async {
    return null;
  }

  @override
  Future<Map<String, dynamic>?> updateUserInfo(
      Map<String, dynamic> json, String? token) async {
    return null;
  }

  /// Create a New User
  @override
  Future<User> createUser({
    String? firstName,
    String? lastName,
    String? username,
    String? password,
    String? phoneNumber,
    bool isVendor = false,
  }) async {
    try {
      var body = <String, dynamic>{
        'firstname': firstName,
        'lastname': lastName,
        'email': username,
        'passwd': password,
        //'phone': phoneNumber,
        'is_vendor': isVendor.toString()
      };

      var response = await prestaApi.postAsync('customers', body, 'customer');
      var user; 
      if (response is Map && !response.containsKey("errors")) {
        print(response); 
        user = User.fromPrestaJson(response['customers']);
        await storage.write(key: 'jwtToken', value: response['token']);
      } else {
        throw ('Email already exists!');
      }
      return user;
    } catch (e, trace) {
            printLog(trace.toString());
      // Buscar el rastro del error
      printLog(e);
      rethrow; 
    }
  }

  /// login
  @override
  Future<User> login({username, password}) async {
    try {
      var response = await prestaApi.signin(
          'customers', <String, String>{'email': username, 'password': password});
      if (response is Map && response['customers'][0] is Map) {
        await storage.write(
            key: 'jwtToken', value: response['customers'][0]['secure_key']);
        return User.fromPrestaJson(response['customers'][0]);
      } else {
        return Future.error('No match for E-Mail Address and/or Password');
      }
    } catch (err) {
      rethrow;
    }
  }

  //Get list countries
  @override
  Future<dynamic> getCountries() async {
    try {
      var response =
          await prestaApi.getAsync('countries?filter[active]=1&display=full');
      var countries = response['countries'];
      if (countries != null && countries is List) {
        for (var item in countries) {
          item['name'] = getValueByLang(item['name']);
        }
      }
      return countries;
    } catch (err) {
      return [];
    }
  }

  @override
  Future getStatesByCountryId(countryId) async {
    try {
      var response = await prestaApi.getAsync(
          'states?filter[id_country]=$countryId&filter[active]=1&display=full');
      var states = response['states'];
      if (states != null && states is List) {
        for (var item in states) {
          item['name'] = getValueByLang(item['name']);
        }
      }
      return states;
    } catch (err) {
      return [];
    }
  }

  //Get list states
  Future<dynamic> getStates(String? idCountry) async {
    try {
      var response = await prestaApi.getAsync(
          'states?filter[id_country]=$idCountry&filter[active]=1&display=full');
      var states = response['states'];
      if (states != null && states is List) {
        for (var item in states) {
          item['name'] = getValueByLang(item['name']);
        }
      }
      return states;
    } catch (err) {
      return [];
    }
  }

  //Create user address in order
  Future<String> createAddress(CartModel cartModel, UserModel user) async {
    try {
      var param = '';
      param += 'id_customer=${user.user!.id}';
      param += '&country_iso=${cartModel.address!.country}';
      param += '&id_state=${cartModel.address!.state}';
      param += '&firstname=${cartModel.address!.firstName}';
      param += '&lastname=${cartModel.address!.lastName}';
      param += '&email=${cartModel.address!.email}';
      param += '&address=${cartModel.address!.street}';
      param += '&city=${cartModel.address!.city}';
      param += '&postcode=${cartModel.address!.zipCode}';
      param += '&phone=${cartModel.address!.phoneNumber}';
      param += '&display=full';
      var response = await prestaApi.getAsync('address?$param');
      return response['addresses'][0]['id'].toString();
    } catch (err) {
      // FIXME REMOVE HARDCODED VALUE AND BLOCK APP
      return '1';
    }
  }

  //Get order status
  Future<List<Map<String, dynamic>>> getOrderStatus(String? orderId) async {
    var response = await prestaApi
        .getAsync('order_histories?filter[id_order]=$orderId&display=full');
    var orderHistories = <Map<String, dynamic>>[];
    for (var item in response['order_histories']) {
      var history = Map<String, dynamic>.from(item);
      var status = orderStates!.firstWhereOrNull(
          (e) => e['id'].toString() == history['id_order_state'].toString());
      if (status != null) {
        history['status'] = getValueByLang(status['name']);
      }
      orderHistories.add(history);
    }
    orderHistories.sort((a, b) =>
        DateTime.parse(a['date_add']).compareTo(DateTime.parse(b['date_add'])));
    return orderHistories;
  }

  @override
  Future<Coupons> getCoupons({int page = 1, String search = ''}) async {
    try {
      var response =
          await prestaApi.getAsync('cart_rules?filter[active]=1&display=full');
      if (response is Map) {
        return Coupons.getListCouponsPresta(response['cart_rules']);
      }
      return Coupons.getListCouponsPresta([]);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<String>> getImagesByProductId(String productId) async {
    var response = await prestaApi
        .getAsync('product?display=full&limit=5&id_product=$productId');
    var products = response['products'] as List?;
    if (products?.isNotEmpty ?? false) {
      var product = products?.first;
      var image = product?['id_default_image'] != null
          ? prestaApi.apiLink(
              'images/products/${product['id']}/${product["id_default_image"]}')
          : null;
      if (image != null) {
        return <String>[image];
      }
    }
    return const <String>[];
  }

// @override
// Future<PagingResponse<Blog>> getBlogs(dynamic cursor) async {
//   try {
//     final param = '_embed&page=$cursor';
//     final response =
//         await httpGet('${blogApi!.url}/wp-json/wp/v2/posts?$param'.toUri()!);
//     if (response.statusCode != 200) {
//       return const PagingResponse();
//     }
//     List data = jsonDecode(response.body);
//     return PagingResponse(data: data.map((e) => Blog.fromJson(e)).toList());
//   } on Exception catch (_) {
//     return const PagingResponse();
//   }
// }
}
