import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart' show AppModel, Product;
import '../../../services/service_config.dart';

class ProductPricing extends StatelessWidget {
  final Product product;
  final bool hide;
  final TextStyle? priceTextStyle;

  const ProductPricing({
    Key? key,
    required this.product,
    required this.hide,
    this.priceTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hide) return const SizedBox();

    final currency = Provider.of<AppModel>(context, listen: false).currencyCode;
    final currencyRate = Provider.of<AppModel>(context).currencyRate;

    var priceProduct = PriceTools.getPriceProduct(
            product, currencyRate, currency,
            onSale: false) ??
        '00.00';

    /// Calculate the Sale price
    var isSale = (product.onSale ?? false) &&
        PriceTools.getPriceProductValue(product, currency, onSale: true) !=
            PriceTools.getPriceProductValue(product, currency, onSale: false);

    if (product.isVariableProduct) {
      isSale = product.onSale ?? false;
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: <Widget>[
        Text(
          priceProduct,
          style: Theme.of(context)
              .textTheme
              .headline6!
              .copyWith(
                fontWeight: FontWeight.w600,
              )
              .apply(fontSizeFactor: 0.8)
              .merge(priceTextStyle),
        ),
      ],
    );
  }
}
