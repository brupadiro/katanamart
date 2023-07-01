import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../generated/l10n.dart';
import '../../../models/brand_layout_model.dart';
import '../../../models/entities/brand.dart';
import '../../../models/index.dart' show Product;
import '../../../models/product_feature.dart';
import '../../../services/index.dart';
import '../../../widgets/common/index.dart';
import 'additional_information.dart';

class ProductDescription extends StatefulWidget {
  final Product? product;

  const ProductDescription(this.product);

  @override
  _ProductDescriptionState createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends State<ProductDescription> {
  bool _enableBrand = kProductDetail.showBrand;
  final services = Services();
  Future<List<ProductFeature>> features = Future.value(<ProductFeature>[]);
  Brand? get _brand {
    if (widget.product?.brands.isNotEmpty ?? false) {
      return widget.product?.brands.first;
    }
    return null;
  }

  void getFeatures() {
    features = services.api.getProductFeatures(widget.product!.features!)!;
  }

  @override
  void initState() {
    getFeatures();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 15),
        if (widget.product!.description != null &&
            widget.product!.description!.isNotEmpty)
          ExpansionInfo(
            title: S.of(context).description,
            expand: false,
            children: <Widget>[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Services().widget.renderProductDescription(
                    context, widget.product!.description!),
              ),
              const SizedBox(height: 20),
            ],
          ),
        if (_enableBrand) ...[
          buildBrand(context),
        ],
        if (features != null)
          ExpansionInfo(
            expand: false,
            title: S.of(context).additionalInformation,
            children: <Widget>[
              buildFeatures(),
            ],
          ),
      ],
    );
  }

  Widget buildFeatures() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Características:',
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          FutureBuilder(
              future: features,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var featuresList = snapshot.data as List<ProductFeature>;
                  return Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(
                      color: Colors.grey[300]!,
                      width: 1.0,
                    ),
                    columnWidths: {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                    },
                    children: featuresList.map((feature) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              feature.name.toString(),
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              feature.value['value'],
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }
                {
                  return const LoadingWidget();
                }
              }),
        ],
      ),
    );
  }

  Widget buildBrand(context) {
    final brand = this._brand;
    if (brand == null) {
      return const SizedBox();
    }
    return Selector<BrandLayoutModel, Brand?>(
      selector: (BuildContext context, _) => _.brands.firstWhere(
        (item) => item.id == brand.id,
        orElse: () => brand,
      ),
      builder: (BuildContext context, Brand? brand, _) {
        if (brand == null) {
          return const SizedBox();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  S.of(context).brand,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              if (brand.image?.isNotEmpty ?? true)
                FluxImage(
                  imageUrl: brand.image ?? '',
                  fit: BoxFit.cover,
                  height: 56.0,
                ),
              if (brand.image?.isEmpty ?? true)
                Text(
                  brand.name ?? '',
                  textAlign: TextAlign.left,
                ),
            ],
          ),
        );
      },
    );
  }
}
