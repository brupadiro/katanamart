import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fstore/menu/maintab.dart';
import 'package:fstore/models/app_model.dart';
import 'package:fstore/models/cart/cart_base.dart';
import 'package:fstore/modules/dynamic_layout/config/app_config.dart';
import 'package:fstore/modules/dynamic_layout/config/app_setting.dart';
import 'package:fstore/modules/dynamic_layout/config/tab_bar_config.dart';
import 'package:fstore/modules/dynamic_layout/tabbar/tab_indicator/dot_indicator.dart';
import 'package:fstore/modules/dynamic_layout/tabbar/tab_indicator/material_indicator.dart';
import 'package:fstore/modules/dynamic_layout/tabbar/tab_indicator/rectangular_indicator.dart';
import 'package:fstore/modules/dynamic_layout/tabbar/tabbar_icon.dart';
import 'package:fstore/routes/route.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/index.dart' show Product, ProductModel, UserModel;
import '../../../services/index.dart';
import '../../../widgets/product/product_bottom_sheet.dart';
import '../../../widgets/product/widgets/heart_button.dart';
import '../../chat/vendor_chat.dart';
import '../product_detail_screen.dart';
import '../widgets/index.dart';
import '../widgets/product_image_slider.dart';

class SimpleLayout extends StatefulWidget {
  final Product product;
  final bool isLoading;

  const SimpleLayout({required this.product, this.isLoading = false});

  @override
  // ignore: no_logic_in_create_state
  State<SimpleLayout> createState() => _SimpleLayoutState(product: product);
}

class _SimpleLayoutState extends State<SimpleLayout>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  int _selectIndex = 0;

  late Product product;

  _SimpleLayoutState({required this.product});

  Map<String, String> mapAttribute = HashMap();
  var _hideController;
  var top = 0.0;
  List<TabBarMenuConfig> get tabData =>
      Provider.of<AppModel>(context, listen: false).appConfig!.tabBar;
  late TabController tabController;

  Decoration _buildIndicator(context) {
    var indicator = appSetting.tabBarConfig.tabBarIndicator;

    switch (appSetting.tabBarConfig.indicatorStyle) {
      case IndicatorStyle.dot:
        return DotIndicator(
            radius: indicator.radius ?? 3,
            color: indicator.color ?? Theme.of(context).primaryColor,
            distanceFromCenter: indicator.distanceFromCenter ?? 20.0,
            strokeWidth: indicator.strokeWidth ?? 1.0,
            paintingStyle: indicator.paintingStyle ?? PaintingStyle.fill);
      case IndicatorStyle.material:
        final indicatorHeight = indicator.height ?? 4;
        if (indicatorHeight <= 0) {
          // What good is a indicator if its height is <= zero?
          break;
        }
        return MaterialIndicator(
            height: indicatorHeight,
            tabPosition: indicator.tabPosition,
            topRightRadius: indicator.topRightRadius ?? 5,
            topLeftRadius: indicator.topLeftRadius ?? 5,
            bottomRightRadius: indicator.bottomRightRadius ?? 0,
            bottomLeftRadius: indicator.bottomLeftRadius ?? 0,
            color: indicator.color ?? Theme.of(context).primaryColor,
            horizontalPadding: indicator.horizontalPadding ?? 0.0,
            strokeWidth: indicator.strokeWidth ?? 1.0,
            paintingStyle: indicator.paintingStyle ?? PaintingStyle.fill);
      case IndicatorStyle.rectangular:
        return RectangularIndicator(
            topRightRadius: indicator.topRightRadius ?? 5,
            topLeftRadius: indicator.topLeftRadius ?? 5,
            bottomRightRadius: indicator.bottomRightRadius ?? 0,
            bottomLeftRadius: indicator.bottomLeftRadius ?? 0,
            color: indicator.color ?? Theme.of(context).primaryColor,
            horizontalPadding: indicator.horizontalPadding ?? 0.0,
            strokeWidth: indicator.strokeWidth ?? 1.0,
            verticalPadding: indicator.verticalPadding ?? 0.0,
            paintingStyle: indicator.paintingStyle ?? PaintingStyle.fill);
      case IndicatorStyle.none:
      default:
        break;
    }

    return const BoxDecoration(color: Colors.transparent);
  }

  Widget _buildTabBar(context) {
    final theme = Theme.of(context);
    final tabConfig = appSetting.tabBarConfig;

    final labelTextStyle = theme.primaryTextTheme.bodyText1;
    final colorIcon = tabConfig.colorIcon ?? theme.colorScheme.secondary;
    final colorActiveIcon = tabConfig.colorActiveIcon ?? theme.primaryColor;

    final position = tabConfig.tabBarFloating.position;
    final floatingIndex = (position != null && position < tabData.length)
        ? position
        : (tabData.length / 2).floor();

    var routes = [
      RouteList.dashboard,
      RouteList.category,
      RouteList.search,
      RouteList.cart,
      RouteList.profile,
    ];

    return Selector<CartModel, int>(
        selector: (_, cartModel) => cartModel.totalCartQuantity,
        builder: (context, totalCart, child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: TabBar(
              key: const Key('mainTabBar'),
              controller: tabController,
              onTap: (index) {
                Navigator.of(context).push(Routes.getRouteGenerate(
                    RouteSettings(
                        name: routes[index], arguments: tabData[index])));
              },
              tabs: [
                for (var i = 0; i < tabData.length; i++)
                  TabBarIcon(
                    key: Key('TabBarIcon-$i'),
                    item: tabData[i],
                    totalCart: totalCart,
                    isActive: i == tabController.index,
                    isEmptySpace: tabConfig.showFloating && i == floatingIndex,
                    config: tabConfig,
                  ),
              ],
              isScrollable: false,
              labelColor: colorActiveIcon,
              unselectedLabelColor: colorIcon,
              indicatorSize: indicatorSize,
              indicatorColor: colorActiveIcon,
              indicator: _buildIndicator(context),
              unselectedLabelStyle: labelTextStyle,
              labelStyle: labelTextStyle,
            ),
          );
        });
  }

  final services = Services();
  Future<List<Map>?>? reviews = Future.value(<Map>[]);
  void getReviews() {
    if (widget.product.features != null) {
      reviews = services.api.getReviews(widget.product.id!);
    } else {
      reviews = Future.value(<Map>[]);
    }
  }

  @override
  void initState() {
    tabController = TabController(length: 5, vsync: this);

    super.initState();
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );
  }

  AppSetting get appSetting =>
      Provider.of<AppModel>(context, listen: false).appConfig!.settings;

  @override
  void didUpdateWidget(SimpleLayout oldWidget) {
    if (oldWidget.product.type != widget.product.type) {
      setState(() {
        product = widget.product;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  /// Render product default: booking, group, variant, simple, booking
  Widget renderProductInfo() {
    var body;

    if (widget.isLoading == true) {
      body = kLoadingWidget(context);
    } else {
      switch (product.type) {
        case 'appointment':
          return Services().getBookingLayout(product: product);
        case 'booking':
          body = ListingBooking(product);
          break;
        case 'grouped':
          body = GroupedProduct(product);
          break;
        default:
          body = ProductVariant(product);
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: body,
      ),
    );
  }

  final indicatorSize = TabBarIndicatorSize.tab;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthHeight = size.height;

    final userModel = Provider.of<UserModel>(context, listen: false);
    return Scaffold(
      bottomNavigationBar: _buildTabBar(context),
      body: Container(
        color: Theme.of(context).backgroundColor,
        child: SafeArea(
          bottom: false,
          top: kProductDetail.safeArea,
          child: ChangeNotifierProvider(
            create: (_) => ProductModel(),
            child: Stack(
              children: <Widget>[
                Scaffold(
                  floatingActionButton: (!Config().isVendorType() ||
                          !kConfigChat['EnableSmartChat'])
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: VendorChat(
                            user: userModel.user,
                            store: product.store,
                          ),
                        ),
                  backgroundColor: Theme.of(context).backgroundColor,
                  body: CustomScrollView(
                    controller: _scrollController,
                    slivers: <Widget>[
                      SliverAppBar(
                        systemOverlayStyle: SystemUiOverlayStyle.light,
                        backgroundColor: Theme.of(context).backgroundColor,
                        elevation: 1.0,
                        expandedHeight:
                            kIsWeb ? 0 : widthHeight * kProductDetail.height,
                        pinned: true,
                        floating: false,
                        leading: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .primaryColorLight
                                .withOpacity(0.7),
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: () {
                                context
                                    .read<ProductModel>()
                                    .clearProductVariations();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          if (widget.isLoading != true)
                            HeartButton(
                              product: product,
                              size: 20.0,
                              color: Theme.of(context).primaryColor,
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .primaryColorLight
                                  .withOpacity(0.7),
                              child: IconButton(
                                icon: const Icon(Icons.more_vert, size: 19),
                                color: Theme.of(context).primaryColor,
                                onPressed: () => ProductDetailScreen.showMenu(
                                  context,
                                  widget.product,
                                  isLoading: widget.isLoading,
                                ),
                              ),
                            ),
                          ),
                        ],
                        flexibleSpace: kIsWeb
                            ? const SizedBox()
                            : ProductImageSlider(
                                product: product,
                                onChange: (index) => setState(() {
                                  _selectIndex = index;
                                }),
                              ),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate(
                          <Widget>[
                            const SizedBox(height: 2),
                            if (kIsWeb)
                              ProductGallery(
                                product: widget.product,
                                selectIndex: _selectIndex,
                              ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 4.0,
                                left: 15,
                                right: 15,
                              ),
                              child: product.type == 'grouped'
                                  ? const SizedBox()
                                  : ProductTitle(product),
                            ),
                          ],
                        ),
                      ),
                      if (Services().widget.enableShoppingCart(
                          product.copyWith(isRestricted: false)))
                        renderProductInfo(),
                      if (!Services().widget.enableShoppingCart(
                              product.copyWith(isRestricted: false)) &&
                          product.shortDescription != null &&
                          product.shortDescription!.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: ProductShortDescription(product),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            // horizontal: 15.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                ),
                                child: Column(
                                  children: [
                                    Services().widget.renderVendorInfo(product),
                                    ProductDescription(product),
                                    if (kProductDetail.showProductCategories)
                                      ProductDetailCategories(product),
                                    if (kProductDetail.showProductTags)
                                      ProductTag(product),
                                    Services()
                                        .widget
                                        .productReviewWidget(product.id!),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    child: RatingBar.builder(
                                      initialRating: 5,
                                      minRating: 1,
                                      direction: Axis.horizontal,
                                      allowHalfRating: true,
                                      itemSize: 20,
                                      itemCount: 5,
                                      itemPadding: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 5),
                                      onRatingUpdate: (rating) {},
                                    ),
                                  ),
                                  const Text(" 5.0 (23 Reviews)",
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey))
                                ],
                              ),
                              Container(
                                height: 20,
                                child: const Divider(
                                  color: Colors.black12,
                                  height: 1,
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 150,
                                padding: EdgeInsets.all(5),
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    review(),
                                    review(),
                                    review(),
                                    review(),
                                  ],
                                ),
                              ),
                              RelatedProduct(product),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget review() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingBar.builder(
            initialRating: 5,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 15,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.orange, size: 5),
            onRatingUpdate: (rating) {},
          ),
          Text(
            "Ronin | Handmade laito Sword",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Container(
            height: 5,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.only(right: 5),
                    child: Container(),
                  )),
              const Expanded(
                flex: 3,
                child: Text(
                  'lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w100,
                      fontSize: 12,
                      color: Colors.grey),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
