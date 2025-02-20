import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/models/restaurant_model.dart';
import 'package:gazzer_userapp/common/widgets/cart_widget.dart';
import 'package:gazzer_userapp/common/widgets/footer_view_widget.dart';
import 'package:gazzer_userapp/common/widgets/menu_drawer_widget.dart';
import 'package:gazzer_userapp/common/widgets/product_view_widget.dart';
import 'package:gazzer_userapp/common/widgets/veg_filter_widget.dart';
import 'package:gazzer_userapp/common/widgets/web_menu_bar.dart';
import 'package:gazzer_userapp/features/category/controllers/category_controller.dart';
import 'package:gazzer_userapp/features/cuisine/controllers/cuisine_controller.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

class CategoryProductScreen extends StatefulWidget {
  final String? categoryID;
  final String categoryName;

  const CategoryProductScreen({
    super.key,
    required this.categoryID,
    required this.categoryName,
  });

  @override
  CategoryProductScreenState createState() => CategoryProductScreenState();
}

class CategoryProductScreenState extends State<CategoryProductScreen>
    with TickerProviderStateMixin {
  final ScrollController _restaurantScrollController = ScrollController();
  int _selectedCuisineIndex =
      0; // Initialize to select the first item by default

  @override
  void initState() {
    super.initState();
    final categoryController = Get.find<CategoryController>();
    final cuisineController = Get.find<CuisineController>();

    if (widget.categoryID == "1") {
      cuisineController.getCuisineList();
      Get.find<CuisineController>().getCuisineRestaurantList(
        cuisineController.cuisineModel!.cuisines![0].id!,
        1,
        false,
      );
    } else {
      categoryController.getCategoryRestaurantList(
        widget.categoryID,
        1,
        'all',
        false,
      );
      categoryController.getSubCategoryList(widget.categoryID);
    }

    _restaurantScrollController.addListener(() {
      if (_restaurantScrollController.position.pixels ==
          _restaurantScrollController.position.maxScrollExtent) {
        if (!categoryController.isLoading &&
            categoryController.categoryRestaurantList != null) {
          final pageSize = (categoryController.restaurantPageSize! / 10).ceil();
          if (categoryController.offset < pageSize) {
            categoryController.showBottomLoader();
            // categoryController.getCategoryRestaurantList(
            //   categoryController.subCategoryIndex == 0
            //       ? widget.categoryID
            //       : categoryController.subCategoryList?.elementAt(
            //       categoryController.subCategoryIndex)?.id.toString(),
            //   categoryController.offset + 1,
            //   categoryController.type,
            //   false,
            // );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (catController) {
        return GetBuilder<CuisineController>(
          builder: (cuisineController) {
            List<Restaurant>? restaurants;
            if (catController.categoryRestaurantList != null &&
                catController.searchRestaurantList != null) {
              restaurants = [];
              if (catController.isSearching) {
                restaurants.addAll(catController.searchRestaurantList!);
              } else {
                restaurants.addAll(catController.categoryRestaurantList!);
              }
            }

            return Scaffold(
              appBar: ResponsiveHelper.isDesktop(context)
                  ? const WebMenuBar()
                  : AppBar(
                      title: catController.isSearching
                          ? TextField(
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                hintText: 'Search...',
                                border: InputBorder.none,
                              ),
                              style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeLarge),
                              onSubmitted: (String query) =>
                                  catController.searchData(
                                query,
                                catController.subCategoryIndex == 0
                                    ? widget.categoryID
                                    : catController.subCategoryList
                                        ?.elementAt(
                                            catController.subCategoryIndex)
                                        .id
                                        .toString(),
                                catController.type,
                              ),
                            )
                          : Text(
                              widget.categoryName,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color,
                              ),
                            ),
                      centerTitle: true,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                        onPressed: () {
                          if (catController.isSearching) {
                            catController.toggleSearch();
                          } else {
                            Get.back();
                          }
                        },
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      elevation: 0,
                      actions: [
                        IconButton(
                          onPressed: () => catController.toggleSearch(),
                          icon: Icon(
                            catController.isSearching
                                ? Icons.close_sharp
                                : Icons.search,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Get.toNamed(RouteHelper.getCartRoute()),
                          icon: CartWidget(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            size: 25,
                          ),
                        ),
                        VegFilterWidget(
                          type: catController.type,
                          fromAppBar: true,
                          onSelected: (String type) {
                            if (catController.isSearching) {
                              catController.searchData(
                                catController.searchText,
                                catController.subCategoryIndex == 0
                                    ? widget.categoryID
                                    : catController.subCategoryList
                                        ?.elementAt(
                                            catController.subCategoryIndex)
                                        .id
                                        .toString(),
                                type,
                              );
                            } else {
                              ProductViewWidget(
                                isRestaurant: true,
                                products: null,
                                restaurants: catController.subCategoryList
                                            ?.elementAt(0)
                                            .id ==
                                        1
                                    ? cuisineController
                                        .cuisineRestaurantsModel?.restaurants
                                    : restaurants,
                                noDataText: 'no_category_restaurant_found'.tr,
                              );
                            }
                          },
                        ),
                      ],
                    ),
              endDrawer: const MenuDrawerWidget(),
              endDrawerEnableOpenDragGesture: false,
              body: Column(
                children: [
                  (cuisineController.cuisineModel?.cuisines != null &&
                          !catController.isSearching &&
                          widget.categoryID == "1")
                      ? Center(
                          child: Container(
                            height: 40,
                            width: Dimensions.webMaxWidth,
                            color: Theme.of(context).cardColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeExtraSmall),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: cuisineController
                                      .cuisineModel?.cuisines?.length ??
                                  0,
                              padding: const EdgeInsets.only(
                                  left: Dimensions.paddingSizeSmall),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCuisineIndex = index;
                                    });
                                    cuisineController.setCurrentIndex(
                                        index, true);
                                    Get.find<CuisineController>()
                                        .getCuisineRestaurantList(
                                      cuisineController
                                          .cuisineModel!.cuisines![index].id!,
                                      1,
                                      false,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeSmall,
                                      vertical:
                                          Dimensions.paddingSizeExtraSmall,
                                    ),
                                    margin: const EdgeInsets.only(
                                      right: Dimensions.paddingSizeSmall,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusSmall,
                                      ),
                                      color: index == _selectedCuisineIndex
                                          ? Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          cuisineController.cuisineModel!
                                              .cuisines![index].name!,
                                          style: index == _selectedCuisineIndex
                                              ? robotoMedium.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                )
                                              : robotoRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : const SizedBox(),
                  Expanded(
                    child: NotificationListener(
                      onNotification: (dynamic scrollNotification) {
                        if (scrollNotification is ScrollEndNotification) {
                          if ((!catController.isRestaurant) ||
                              (catController.isRestaurant)) {
                            if (catController.isSearching) {
                              catController.searchData(
                                catController.searchText,
                                catController.subCategoryIndex == 0
                                    ? widget.categoryID
                                    : catController.subCategoryList
                                        ?.elementAt(
                                            catController.subCategoryIndex)
                                        .id
                                        .toString(),
                                catController.type,
                              );
                            } else {
                              Get.find<CuisineController>()
                                  .getCuisineRestaurantList(
                                cuisineController.cuisineModel!
                                    .cuisines![_selectedCuisineIndex].id!,
                                1,
                                false,
                              );
                            }
                          }
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        child: FooterViewWidget(
                          child: Center(
                            child: SizedBox(
                              width: Dimensions.webMaxWidth,
                              child: Column(
                                children: [
                                  ProductViewWidget(
                                    isRestaurant: true,
                                    products: null,
                                    restaurants: widget.categoryID == "1"
                                        ? cuisineController
                                            .cuisineRestaurantsModel
                                            ?.restaurants
                                        : restaurants,
                                    noDataText:
                                        'no_category_restaurant_found'.tr,
                                  ),
                                  // if (cuisineController.cuisineRestaurantsModel!
                                  //     .restaurants!.isEmpty)
                                  //   Padding(
                                  //     padding: const EdgeInsets.symmetric(
                                  //         vertical: 200),
                                  //     child: Text(
                                  //       "Empty section",
                                  //       style: robotoMedium.copyWith(
                                  //           fontWeight: FontWeight.bold),
                                  //     ),
                                  //   ),
                                  catController.isLoading
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(
                                                Dimensions.paddingSizeSmall),
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
