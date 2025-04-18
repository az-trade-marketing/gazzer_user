import 'package:gazzer_userapp/common/widgets/custom_loader_widget.dart';
import 'package:gazzer_userapp/features/address/controllers/address_controller.dart';
import 'package:gazzer_userapp/features/address/domain/models/address_model.dart';
import 'package:gazzer_userapp/features/location/controllers/location_controller.dart';
import 'package:gazzer_userapp/features/location/domain/models/zone_response_model.dart';
import 'package:gazzer_userapp/features/address/widgets/address_card_widget.dart';
import 'package:gazzer_userapp/helper/address_helper.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:gazzer_userapp/common/widgets/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressCartBottomSheet extends StatelessWidget {
  const AddressCartBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.paddingSizeExtraLarge),
          topRight: Radius.circular(Dimensions.paddingSizeExtraLarge),
        ),
      ),
      child: GetBuilder<AddressController>(builder: (addressController) {
        AddressModel? selectedAddress =
            AddressHelper.getAddressFromSharedPref();
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                  top: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeDefault),
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                  color: Theme.of(context).highlightColor,
                  borderRadius:
                      BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
            ),
          ),
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: CloseButton(),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeLarge,
                  vertical: Dimensions.paddingSizeSmall),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('please_check_your_address'.tr,
                        style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault)),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    addressController.addressList != null &&
                            addressController.addressList!.isEmpty
                        ? Column(children: [
                            Image.asset(Images.address, width: 150),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            Text(
                              'you_dont_have_any_saved_address_yet'.tr,
                              textAlign: TextAlign.center,
                              style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).hintColor),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                          ])
                        : const SizedBox(),
                    addressController.addressList != null &&
                            addressController.addressList!.isEmpty
                        ? const SizedBox(height: Dimensions.paddingSizeLarge)
                        : const SizedBox(),
                    addressController.addressList != null
                        ? addressController.addressList!.isNotEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeSmall,
                                    vertical: Dimensions.paddingSizeSmall),
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount:
                                      addressController.addressList!.length > 5
                                          ? 5
                                          : addressController
                                              .addressList!.length,
                                  itemBuilder: (context, index) {
                                    bool selected = false;
                                    if (selectedAddress!.id ==
                                        addressController
                                            .addressList![index].id) {
                                      selected = true;
                                    }
                                    return Center(
                                        child: SizedBox(
                                            width: 700,
                                            child: AddressCardWidget(
                                              address: addressController
                                                  .addressList![index],
                                              fromAddress: false,
                                              isSelected: selected,
                                              fromDashBoard: true,
                                              onTap: () {
                                                AddressHelper
                                                    .saveAddressInSharedPref(
                                                        addressController
                                                                .addressList![
                                                            index]);
                                                Get.back();
                                              },
                                            )));
                                  },
                                ),
                              )
                            : const SizedBox()
                        : const Center(child: CircularProgressIndicator()),
                    SizedBox(
                        height: addressController.addressList != null &&
                                addressController.addressList!.isEmpty
                            ? 0
                            : Dimensions.paddingSizeSmall),
                  ]),
            ),
          ),
        ]);
      }),
    );
  }

  void _onCurrentLocationButtonPressed() {
    Get.find<LocationController>().checkPermission(() async {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      AddressModel address =
          await Get.find<LocationController>().getCurrentLocation(true);
      ZoneResponseModel response = await Get.find<LocationController>()
          .getZone(address.latitude, address.longitude, false);
      if (response.isSuccess) {
        Get.find<LocationController>().saveAddressAndNavigate(
          address,
          false,
          '',
          false,
          ResponsiveHelper.isDesktop(Get.context),
        );
      } else {
        Get.back();
        Get.toNamed(
            RouteHelper.getPickMapRoute(RouteHelper.accessLocation, false));
        showCustomSnackBar('service_not_available_in_current_location'.tr);
      }
    });
  }
}
