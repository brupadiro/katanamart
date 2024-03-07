import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../models/app_model.dart';
import '../../models/cart/cart_base.dart';
import '../../models/notification_model.dart';
import '../../modules/dynamic_layout/config/logo_config.dart';
import '../../modules/dynamic_layout/dynamic_layout.dart';
import '../../modules/dynamic_layout/helper/helper.dart';
import '../../modules/dynamic_layout/logo/logo.dart';
import '../../routes/flux_navigate.dart';
import '../../screens/blog/models/list_blog_model.dart';
import '../../screens/common/app_bar_mixin.dart';
import '../../services/index.dart';
import 'preview_overlay.dart';

class HomeLayout extends StatefulWidget {
  final configs;
  final bool isPinAppBar;
  final bool isShowAppbar;
  final bool showNewAppBar;

  const HomeLayout({
    this.configs,
    this.isPinAppBar = false,
    this.isShowAppbar = true,
    this.showNewAppBar = false,
    Key? key,
  }) : super(key: key);

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> with AppBarMixin {
  late List widgetData;

  bool isPreviewingAppBar = false;

  bool cleanCache = false;

  @override
  void initState() {
    /// init config data
    widgetData =
        List<Map<String, dynamic>>.from(widget.configs['HorizonLayout']);
    if (widgetData.isNotEmpty && widget.isShowAppbar && !widget.showNewAppBar) {
      widgetData.removeAt(0);
    }

    /// init single vertical layout
    if (widget.configs['VerticalLayout'] != null &&
        widget.configs['VerticalLayout'].isNotEmpty) {
      Map verticalData =
          Map<String, dynamic>.from(widget.configs['VerticalLayout']);
      verticalData['type'] = 'vertical';
      widgetData.add(verticalData);
    }

    /// init multi vertical layout
    if (widget.configs['VerticalLayouts'] != null) {
      List verticalLayouts = widget.configs['VerticalLayouts'];
      for (var i = 0; i < verticalLayouts.length; i++) {
        Map verticalData = verticalLayouts[i];
        verticalData['type'] = 'vertical';
        widgetData.add(verticalData);
      }
    }

    super.initState();
  }

  @override
  void didUpdateWidget(HomeLayout oldWidget) {
    if (oldWidget.configs != widget.configs) {
      /// init config data
      List data =
          List<Map<String, dynamic>>.from(widget.configs['HorizonLayout']);
      if (data.isNotEmpty && widget.isShowAppbar && !widget.showNewAppBar) {
        data.removeAt(0);
      }

      /// init vertical layout
      if (widget.configs['VerticalLayout'] != null) {
        Map verticalData =
            Map<String, dynamic>.from(widget.configs['VerticalLayout']);
        verticalData['type'] = 'vertical';
        data.add(verticalData);
      }
      setState(() {
        widgetData = data;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> onRefresh() async {
    await Provider.of<ListBlogModel>(context, listen: false).getBlogs();

    // refresh the product request and clean up cache
    setState(() => cleanCache = true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    setState(() => cleanCache = false);

    /// reload app config
    await Provider.of<AppModel>(context, listen: false).loadAppConfig();
  }

  Widget renderAppBar() {
    if (Layout.isDisplayDesktop(context)) {
      return const SliverToBoxAdapter();
    }

    List<dynamic> horizonLayout = widget.configs['HorizonLayout'] ?? [];
    Map logoConfig = horizonLayout.firstWhere(
        (element) => element['layout'] == 'logo',
        orElse: () => Map<String, dynamic>.from({}));
    var config = LogoConfig.fromJson(logoConfig);

    /// customize theme
    // config
    //   ..opacity = 0.9
    //   ..iconBackground = HexColor('DDDDDD')
    //   ..iconColor = HexColor('330000')
    //   ..iconOpacity = 0.8
    //   ..iconRadius = 40
    //   ..iconSize = 24
    //   ..cartIcon = MenuIcon(name: 'cart')
    //   ..showSearch = false
    //   ..showLogo = true
    //   ..showCart = true
    //   ..showMenu = true;

    return SliverAppBar(
      pinned: widget.isPinAppBar,
      snap: true,
      floating: true,
      titleSpacing: 0,
      elevation: 0,
      forceElevated: true,
      backgroundColor: config.color ??
          Theme.of(context).backgroundColor.withOpacity(config.opacity),
      title: PreviewOverlay(
          index: 0,
          config: logoConfig as Map<String, dynamic>?,
          builder: (value) {
            final appModel = Provider.of<AppModel>(context, listen: true);
            return Selector<CartModel, int>(
              selector: (_, cartModel) => cartModel.totalCartQuantity,
              builder: (context, totalCart, child) {
                return Logo(
                  config: config,
                  logo: appModel.themeConfig.logo,
                  notificationCount:
                      Provider.of<NotificationModel>(context).unreadCount,
                  totalCart: totalCart,
                  onSearch: () {
                    FluxNavigate.pushNamed(RouteList.homeSearch);
                  },
                  onCheckout: () {
                    FluxNavigate.pushNamed(RouteList.cart);
                  },
                  onTapNotifications: () {
                    FluxNavigate.pushNamed(RouteList.notify);
                  },
                  onTapDrawerMenu: () =>
                      NavigateTools.onTapOpenDrawerMenu(context),
                );
              },
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.configs == null) return const SizedBox();

    ErrorWidget.builder = (error) {
      if (foundation.kReleaseMode) {
        return const SizedBox();
      }
      return Container(
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(5)),
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

        /// Hide error, if you're developer, enable it to fix error it has
        child: Center(
          child: Text('Error in ${error.exceptionAsString()}'),
        ),
      );
    };
    final isShowAppBar = widget.isShowAppbar && !widget.showNewAppBar;

    return Stack(
      children: [
        CustomScrollView(
          cacheExtent: 2000.0,
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (widget.showNewAppBar) sliverAppBarWidget,
            if (isShowAppBar) renderAppBar(),
            CupertinoSliverRefreshControl(onRefresh: onRefresh),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  var config = widgetData[index];

                  /// if show app bar, the preview should plus +1
                  var previewIndex = widget.isShowAppbar ? index + 1 : index;
                  Widget body;
                  if (config['type'] != null && config['type'] == 'vertical') {
                    body = PreviewOverlay(
                        index: previewIndex,
                        config: config,
                        builder: (value) {
                          return Services().widget.renderVerticalLayout(value);
                        });
                  } else {
                    body = PreviewOverlay(
                      index: previewIndex,
                      config: config,
                      builder: (value) {
                        return DynamicLayout(
                            config: value, cleanCache: cleanCache);
                      },
                    );
                  }

                  /// Use row to limit the drawing area.
                  /// If you delete the row, setting the size for the body will not work.
                  return Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width),
                    child: body,
                  );
                },
                childCount: widgetData.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.only(top: 40),
                alignment: Alignment.bottomCenter,
                height: 200, // Establece el alto que desees aquí
                color: Colors.black,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/icons/footer/exclusivity.png',
                            width: 80,
                          ),
                          const Text(
                            'EXCLUSIVITY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            height: 10,
                          ),
                          const Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              'KATANAMART IS THE EXCLUSIVE DISTRIBUTOR OF YARINOHANZO KATANA SWORD IN UK, THE BEST EUROPEAN CLASSIC MARTIAL ARTS EQUIPMENT BRAND SINCE 2007.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Image.asset(
                            "assets/icons/footer/experience.png",
                            width: 80,
                          ),
                          const Text(
                            'EXPERIENCE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            height: 10,
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: const Text(
                              'LONG EXPERIENCED MARTIAL ARTS INSTRUCTORS CREATE AND PERSONALLY CHECK THE QUALITY OF EACH PRODUCT BY 10 DIFFERENT TESTS.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Image.asset(
                            "assets/icons/footer/quality.png",
                            width: 80,
                          ),
                          const Text(
                            'QUALITY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            height: 10,
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: const Text(
                              'BEST QUALITY-PRICE RATIO. OUR KATANA SWORDS ARE ALL HANDMADE, BATTLE READY AND FULL TANG. WE GUARANTEE A GREAT QUALITY, EXCELLENT BALANCE AND PRACTICALITY.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Image.asset(
                            "assets/icons/footer/warranty.png",
                            width: 80,
                          ),
                          const Text(
                            'WARRANTY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            height: 10,
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: const Text(
                              'AFTER SALE SERVICE: WE OFFER 2 YEAR WARRANTY ON ALL SAMURAI SWORDS, A FAST SHIPPING SERVICE AND AN ACCURATE CUSTOMERCARE.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        const _FakeStatusBar(),
      ],
    );
  }
}

class _FakeStatusBar extends StatelessWidget {
  const _FakeStatusBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: const SafeArea(
          bottom: false,
          child: SizedBox(),
        ),
      ),
    );
  }
}
