import 'dart:math';

import 'package:flutter/material.dart';

import '../../../common/constants.dart';
import '../../../common/tools/image_tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart' show BackDropArguments, Category;
import '../../../routes/flux_navigate.dart';
import '../../../widgets/common/parallax_image.dart';
import '../../../widgets/common/tree_view.dart';
import '../../base_screen.dart';
import '../../index.dart';

class CardCategories extends StatefulWidget {
  static const String type = 'card';
  final bool enableParallax;
  final double? parallaxImageRatio;

  final List<Category>? categories;

  const CardCategories(
      {this.categories, required this.enableParallax, this.parallaxImageRatio});

  @override
  BaseScreen<CardCategories> createState() => _StateCardCategories();
}

class _StateCardCategories extends BaseScreen<CardCategories> {
  ScrollController controller = ScrollController();
  late double page;

  @override
  void initState() {
    page = 0.0;
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    controller.addListener(() {
      setState(() {
        page = _getPage(controller.position, screenSize.width * 0.30 + 10);
      });
    });
  }

  bool hasChildren(id) {
    return widget.categories!.where((o) => o.parent == id).toList().isNotEmpty;
  }

  double _getPage(ScrollPosition position, double width) {
    return position.pixels / width;
  }

  List<Category> getSubCategories(id) {
    return widget.categories!.where((o) => o.parent == id).toList();
  }

  void navigateToBackDrop(Category category) {
    FluxNavigate.pushNamed(
      RouteList.backdrop,
      arguments: BackDropArguments(
        cateId: category.id,
        cateName: category.name,
      ),
    );
  }

  Widget getChildCategoryList(category) {
    return ChildList(
      children: [
        GestureDetector(
          onTap: () => navigateToBackDrop(category),
          child: SubItem(
            category,
            seeAll: S.of(context).seeAll,
          ),
        ),
        for (var category in getSubCategories(category.id))
          Parent(
            callback: (isSelected) {
              if (getSubCategories(category.id).isEmpty) {
                navigateToBackDrop(category);
              }
            },
            parent: SubItem(category),
            childList: ChildList(
              children: [
                for (var cate in getSubCategories(category.id))
                  Parent(
                    callback: (isSelected) {
                      if (getSubCategories(cate.id).isEmpty) {
                        FluxNavigate.pushNamed(
                          RouteList.backdrop,
                          arguments: BackDropArguments(
                            cateId: cate.id,
                            cateName: cate.name,
                          ),
                        );
                      }
                    },
                    parent: SubItem(cate, level: 1),
                    childList: ChildList(
                      children: [
                        for (var cate in getSubCategories(cate.id))
                          Parent(
                            callback: (isSelected) {
                              FluxNavigate.pushNamed(
                                RouteList.backdrop,
                                arguments: BackDropArguments(
                                  cateId: cate.id,
                                  cateName: cate.name,
                                ),
                              );
                            },
                            parent: SubItem(cate, level: 2),
                            childList: const ChildList(children: []),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var categories =
        widget.categories!.where((item) => item.parent == '2').toList();
    if (categories.isEmpty) {
      categories = widget.categories!;
    }

    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.vertical,
      child: TreeView(
        parentList: List.generate(
          categories.length,
          (index) {
            return Parent(
              parent: _CategoryCardItem(categories[index],
                  hasChildren: true, //hasChildren(categories[index].id),
                  offset: page - index,
                  enableParallax: widget.enableParallax,
                  parallaxImageRatio: widget.parallaxImageRatio,
                  subcategories:
                      getChildCategoryList(categories[index]) as ChildList),
              childList: getChildCategoryList(categories[index]) as ChildList,
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCardItem extends StatelessWidget {
  final Category category;
  final bool hasChildren;
  final bool enableParallax;
  final double? parallaxImageRatio;
  final Widget? subcategories;
  final offset;

  const _CategoryCardItem(
    this.category, {
    this.hasChildren = true,
    this.offset,
    this.enableParallax = false,
    this.subcategories,
    this.parallaxImageRatio,
  });

  /// Render category Image support caching on ios/android
  /// also fix loading on Web
  Widget renderCategoryImage(maxWidth) {
    final image = category.image ?? '';
    if (image.isEmpty) return const SizedBox();

    if (image.contains('http') && kIsWeb) {
      return ImageTools.image(
        url: category.image!,
        fit: BoxFit.cover,
        width: maxWidth,
        height: maxWidth * 0.35,
      );
    }

    return image.contains('http')
        ? ImageTools.image(
            url: category.image!,
            fit: BoxFit.cover,
            width: maxWidth,
            height: maxWidth * 0.35,
          )
        : Image.asset(
            category.image!,
            fit: BoxFit.cover,
            width: maxWidth,
            height: maxWidth * 0.35,
            alignment: Alignment(
              0.0,
              (offset >= -1 && offset <= 1)
                  ? offset
                  : (offset > 0)
                      ? 1.0
                      : -1.0,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: hasChildren
          ? () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SubCategoryPopup(
                      categoryTitle: category.name!,
                      subCategories: subcategories)));
            }
          : () {
              FluxNavigate.pushNamed(
                RouteList.backdrop,
                arguments: BackDropArguments(
                  cateId: category.id,
                  cateName: category.name,
                ),
              );
            },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (enableParallax) {
            return Container(
              height: constraints.maxWidth * 0.35,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 10, right: 10),
              margin: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ParallaxImage(
                  image: category.image ?? '',
                  name: category.name ?? '',
                  ratio: 2.2,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fitWidth,
                ),
              ),
            );
          }

          return Container(
            height: constraints.maxWidth * 0.12,
            padding: const EdgeInsets.only(left: 10, right: 10),
            margin: const EdgeInsets.only(bottom: 10),
            child: Stack(
              children: <Widget>[
                Container(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth * 0.15,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        bottom: BorderSide(color: Colors.black26, width: 1)),
                  ),
                  child: SizedBox(
                    width: constraints.maxWidth /
                        (2 / (screenSize.height / constraints.maxWidth)),
                    height: constraints.maxWidth * 0.15,
                    child: Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.name?.toUpperCase() ?? '',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black,
                              size: 16,
                            )
                          ]),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SubCategoryPopup extends StatelessWidget {
  const SubCategoryPopup(
      {Key? key, required this.categoryTitle, this.subCategories})
      : super(key: key);
  final String categoryTitle;
  final Widget? subCategories;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        title: Text(categoryTitle.toUpperCase()),
      ),
      body: SingleChildScrollView(child: subCategories),
    );
  }
}

class SubItem extends StatelessWidget {
  final Category category;
  final String seeAll;
  final int level;

  const SubItem(this.category, {this.seeAll = '', this.level = 0});

  void showProductList() {
    FluxNavigate.pushNamed(
      RouteList.backdrop,
      arguments: BackDropArguments(
        cateId: category.id,
        cateName: category.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SizedBox(
      width: screenSize.width,
      child: FittedBox(
        fit: BoxFit.cover,
        child: Container(
          width:
              screenSize.width / (2 / (screenSize.height / screenSize.width)),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                width: 0.5,
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withOpacity(level == 0 && seeAll == '' ? 0.2 : 0),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 15.0),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).primaryColorLight,
                ),
                child: ImageTools.image(
                  url: category.image ?? '',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              Container(
                width: 20,
              ),
              Expanded(
                child: Text(
                  seeAll != '' ? seeAll : category.name!.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_right,
                  size: 35,
                ),
                onPressed: showProductList,
              )
            ],
          ),
        ),
      ),
    );
  }
}
