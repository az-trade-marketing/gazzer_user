import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

class RestOpeningHoursWidget extends StatefulWidget {
  const RestOpeningHoursWidget({super.key, required this.openHour, required this.closeHour});
  final TimeOfDay openHour;
  final TimeOfDay closeHour;

  @override
  State<RestOpeningHoursWidget> createState() => _RestOpeningHoursWidgetState();
}

class _RestOpeningHoursWidgetState extends State<RestOpeningHoursWidget> {
  late int closingAfter;
  Timer? timer;

  int calcClosingAfter(TimeOfDay close) {
    final now = DateTime.now();
    final closinDate = DateTime(
      now.year,
      now.month,
      now.day,
      close.hour,
      close.minute,
    );

    final difference = closinDate.difference(now);
    return difference.inMinutes;
  }

  @override
  void initState() {
    super.initState();
    closingAfter = calcClosingAfter(widget.closeHour);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => closingAfter = calcClosingAfter(widget.closeHour));
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${"opens_at".tr}: ",
                    style: robotoRegular.copyWith(
                      color: Colors.black38,
                    )),
                Text(
                  ' ${widget.openHour.format(context)}',
                  style: robotoMedium.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${"closes_at".tr}: ",
                    style: robotoRegular.copyWith(
                      color: Colors.black38,
                    )),
                Text(
                  ' ${widget.closeHour.format(context)}',
                  style: robotoMedium.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox.shrink(),
          ],
        ),
        if (closingAfter < 30 && closingAfter > 0)
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(180),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
            child: Text(
              "this_restaurant_is_closing_in".trParams({"time": closingAfter.toString()}),
              style: robotoBold.copyWith(
                color: Theme.of(context).cardColor,
                fontSize: Dimensions.fontSizeDefault,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
      ],
    );
  }
}
