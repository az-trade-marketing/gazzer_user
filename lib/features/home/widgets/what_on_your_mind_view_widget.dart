import 'package:gazzer_userapp/common/widgets/custom_ink_well_widget.dart';
import 'package:gazzer_userapp/features/home/widgets/arrow_icon_button_widget.dart';
import 'package:gazzer_userapp/features/language/controllers/localization_controller.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/features/category/controllers/category_controller.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:gazzer_userapp/common/widgets/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class WhatOnYourMindViewWidget extends StatelessWidget {
  const WhatOnYourMindViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (categoryController) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.only(
            top: ResponsiveHelper.isMobile(context)
                ? Dimensions.paddingSizeLarge
                : Dimensions.paddingSizeOverLarge,
            left: Get.find<LocalizationController>().isLtr
                ? Dimensions.paddingSizeExtraSmall
                : 0,
            right: Get.find<LocalizationController>().isLtr
                ? 0
                : Dimensions.paddingSizeExtraSmall,
            bottom: ResponsiveHelper.isMobile(context)
                ? Dimensions.paddingSizeDefault
                : Dimensions.paddingSizeOverLarge,
          ),
          child: ResponsiveHelper.isDesktop(context)
              ? Text('what_on_your_mind'.tr,
              style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  fontWeight: FontWeight.w600))
              : Padding(
            padding: const EdgeInsets.only(
                left: Dimensions.paddingSizeSmall,
                right: Dimensions.paddingSizeDefault),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('what_on_your_mind'.tr,
                    style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        fontWeight: FontWeight.w600)),
                ArrowIconButtonWidget(
                    onTap: () =>
                        Get.toNamed(RouteHelper.getCategoryRoute())),
              ],
            ),
          ),
        ),
        categoryController.categoryList != null
            ? GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.7 : 0.85,
            crossAxisSpacing: Dimensions.paddingSizeSmall,
            mainAxisSpacing: Dimensions.paddingSizeSmall,
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault),
          itemCount: categoryController.categoryList!.length > 16
              ? 16
              : categoryController.categoryList!.length,
          itemBuilder: (context, index) {
            if (index == 15 && categoryController.categoryList!.length > 16) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: CustomInkWellWidget(
                  onTap: () => Get.toNamed(RouteHelper.getCategoryRoute()),
                  radius: Dimensions.radiusSmall,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward,
                            color: Theme.of(context).primaryColor, size: 30),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          'view_all'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: CustomInkWellWidget(
                onTap: () =>
                    Get.toNamed(RouteHelper.getCategoryProductRoute(
                      categoryController.categoryList![index].id,
                      categoryController.categoryList![index].name!,
                    )),
                radius: Dimensions.radiusSmall,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          color: Theme.of(context).disabledColor.withOpacity(0.2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          child: CustomImageWidget(
                            image: '${Get.find<SplashController>().configModel!.baseUrls!.categoryImageUrl}/${categoryController.categoryList![index].image}',
                            height: ResponsiveHelper.isMobile(context) ? 60 : 80,
                            width: ResponsiveHelper.isMobile(context) ? 60 : 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                          child: Text(
                            categoryController.categoryList![index].name!,
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ]),
              ),
            );
          },
        )
            : WebWhatOnYourMindViewShimmer(categoryController: categoryController),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ]);
    });
  }
}

class WebWhatOnYourMindViewShimmer extends StatelessWidget {
  final CategoryController categoryController;

  const WebWhatOnYourMindViewShimmer(
      {super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.7 : 0.85,
          crossAxisSpacing: Dimensions.paddingSizeSmall,
          mainAxisSpacing: Dimensions.paddingSizeSmall,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: Shimmer(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        color: Theme.of(context).shadowColor),
                    height: ResponsiveHelper.isMobile(context) ? 60 : 80,
                    width: ResponsiveHelper.isMobile(context) ? 60 : 80,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: Shimmer(
                  child: Container(
                    height: ResponsiveHelper.isMobile(context) ? 10 : 15,
                    width: 70,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        color: Theme.of(context).shadowColor),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}