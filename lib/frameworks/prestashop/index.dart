import 'package:flutter/material.dart';
import 'package:inspireui/widgets/coupon_card.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart';
import '../../services/index.dart' show Services;
import '../frameworks.dart';
import '../product_variant_mixin.dart';
import 'prestashop_variant_mixin.dart';
import 'services/prestashop_service.dart';

class PrestashopWidget extends BaseFrameworks
    with ProductVariantMixin, PrestashopVariantMixin {
  final PrestashopService service;

  PrestashopWidget(this.service);

  @override
  bool get enableProductReview => true;

  Future<Discount?> checkValidCoupon(
      BuildContext context, Coupon coupon, String couponCode) async {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    Discount? discount;
    if (coupon.code != null && coupon.code!.toLowerCase() == couponCode) {
      discount = Discount(coupon: coupon, discountValue: coupon.amount);
    }
    if (discount?.discountValue != null) {
      await cartModel.updateDiscount(discount: discount);
    }

    return discount;
  }

  @override
  Future<void> applyCoupon(context,
      {Coupons? coupons,
      String? code,
      Function? success,
      Function? error}) async {
    var isExisted = false;
    for (var coupon in coupons!.coupons) {
      var discount =
          await checkValidCoupon(context, coupon, code!.toLowerCase());
      if (discount != null) {
        success!(discount);
        isExisted = true;
        break;
      }
    }
    if (!isExisted) {
      error!(S.of(context).couponInvalid);
    }
  }

  @override
  Future<void> doCheckout(context,
      {Function? success, Function? error, Function? loading}) async {
    try {
      success!();
    } catch (e, trace) {
      error!(e.toString());
      printLog(trace.toString());
    }
  }

  @override
  Future<void> createOrder(context,
      {Function? onLoading,
      Function? success,
      Function? error,
      paid = false,
      cod = false,
      bacs = false,
      transactionId = ''}) async {
    var listOrder = [];
    var isLoggedIn = Provider.of<UserModel>(context, listen: false).loggedIn;
    final storage = LocalStorage(LocalStorageKey.dataOrder);
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);

    try {
      final order = await Services().api.createOrder(
          cartModel: cartModel,
          user: userModel,
          paid: paid,
          transactionId: transactionId)!;

      if (!isLoggedIn) {
        var items = storage.getItem('orders');
        if (items != null) {
          listOrder = items;
        }
        listOrder.add(order.toOrderJson(cartModel, null));
        await storage.setItem('orders', listOrder);
      }
      success!(order);
    } catch (e, trace) {
      error!(e.toString());
      printLog(trace.toString());
    }
  }

  @override
  void placeOrder(context,
      {CartModel? cartModel,
      PaymentMethod? paymentMethod,
      Function? onLoading,
      Function? success,
      Function? error}) {
    {
      createOrder(context,
          onLoading: onLoading, success: success, error: error);
    }
  }

  @override
  Map<String, dynamic> getPaymentUrl(context) {
    printLog('----here');
    printLog(Provider.of<CartModel>(context, listen: false).checkout!.webUrl);
    return {
      'headers': {},
      'url': Provider.of<CartModel>(context, listen: false).checkout!.webUrl
    };
  }

  @override
  void updateUserInfo(
      {User? loggedInUser,
      context,
      required onError,
      onSuccess,
      required currentPassword,
      required userDisplayName,
      userEmail,
      userNiceName,
      userUrl,
      userPassword,
      userFirstname,
      userLastname}) {
    onError('Coming soon!!!');
    return;
  }

  @override
  Widget renderVariantCartItem(
      BuildContext context, variation, Map<String, dynamic>? options) {
    var list = <Widget>[];
    for (var att in variation.attributes) {
      list.add(Row(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 50.0, maxWidth: 200),
            child: Text(
              // ignore: prefer_single_quotes
              "${att.name![0].toUpperCase()}${att.name!.substring(1)} ",
            ),
          ),
          Expanded(
            child: Text(
              att.option!,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(
            width: 20,
          )
        ],
      ));
      list.add(const SizedBox(
        height: 5.0,
      ));
    }

    return Column(children: list);
  }

  @override
  void loadShippingMethods(context, CartModel cartModel, bool beforehand) {
//    if (!beforehand) return;
    final cartModel = Provider.of<CartModel>(context, listen: false);
    Future.delayed(Duration.zero, () {
      final token = Provider.of<UserModel>(context, listen: false).user != null
          ? Provider.of<UserModel>(context, listen: false).user!.cookie
          : null;
      final products = cartModel.item;
      final productVariationInCart =
          cartModel.productVariationInCart.keys.toList();
      var productsId = <String?>[];
      var attribute = <String>[];
      var productsQuantity = [];
      for (var key in products.keys.toList()) {
        if (productVariationInCart.toString().contains('$key-')) {
          for (var item in productVariationInCart) {
            if (item.contains('$key-') &&
                cartModel.productsInCart[item] != null) {
              productsId.add(key);
              attribute.add(item.replaceAll('$key-', ''));
              productsQuantity.add(cartModel.productsInCart[item]);
            }
          }
        } else {
          if (cartModel.productsInCart[key!] == null) continue;
          productsId.add(key);
          attribute.add('-1');
          productsQuantity.add(cartModel.productsInCart[key]);
        }
      }
      var langCode = Provider.of<AppModel>(context, listen: false).langCode;
      Provider.of<ShippingMethodModel>(context, listen: false).getShippingMethods(
          cartModel: cartModel,
          token: token,
          checkoutId:
              'products=$productsId&quantity=${productsQuantity.toString()}&attribute=${attribute.toString()}',
          langCode: langCode);
    });
  }

  @override
  String? getPriceItemInCart(Product product, ProductVariation? variation,
      Map<String, dynamic> currencyRate, String? currency,
      {List<AddonsOption>? selectedOptions}) {
    return variation != null && variation.id != null
        ? PriceTools.getVariantPriceProductValue(
            variation,
            currencyRate,
            currency,
            onSale: true,
            selectedOptions: selectedOptions,
          )
        : PriceTools.getPriceProduct(product, currencyRate, currency,
            onSale: true);
  }

  @override
  Future<List<Country>> loadCountries() async {
    var countries = <Country>[];
    if (kDefaultCountry.isNotEmpty) {
      for (var item in kDefaultCountry) {
        countries.add(Country.fromConfig(
            item['iosCode'], item['name'], item['icon'], []));
      }
    } else {
      var listCountries = await service.getCountries();
      for (var item in listCountries) {
        countries.add(Country.fromPrestashop(Map<String, dynamic>.from(item)));
      }
    }
    return countries;
  }

  @override
  Future<List<CountryState>> loadStates(Country country) async {
    final items = await Tools.loadStatesByCountry(country.id!);
    var states = <CountryState>[];
    if (items.isNotEmpty) {
      for (var item in items) {
        states.add(CountryState.fromConfig(item));
      }
    } else {
      var shippingStates = await service.getStates(country.idCountry);
      for (var item in shippingStates) {
        states.add(CountryState.fromPrestashop(item));
      }
    }
    return states;
  }

  @override
  Widget renderOrderTimelineTracking(BuildContext context, Order order) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            S.of(context).status,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 15),
        FutureBuilder(
          future: service.getOrderStatus(order.id),
          builder: (context, snapshots) {
            if (!snapshots.hasData) return Container();
            var list = snapshots.data as List;
            return Column(
              children: List.generate(
                list.length,
                (index) => Row(
                  children: [
                    const Icon(Icons.check_outlined, size: 14),
                    const SizedBox(width: 5),
                    Expanded(child: Text((list)[index]['status'])),
                    Text(DateFormat('yyyy-MM-dd hh:mm')
                        .format(DateTime.parse((list)[index]['date_add'])))
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  @override
  PrestashopService get prestaShopService => service;
}
