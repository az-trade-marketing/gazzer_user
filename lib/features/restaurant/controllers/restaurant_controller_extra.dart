part of 'restaurant_controller.dart';

extension RestaurantControllerExtra on RestaurantController {
  (TimeOfDay?, TimeOfDay?)? todaySchedulte(List<Schedules>? schedules) {
    if (schedules?.isNotEmpty != true) return null;
    int weekday = DateTime.now().weekday;
    if (weekday == 7) {
      weekday = 0;
    }
    final todaySchedules = <Schedules>[];
    for (int index = 0; index < schedules!.length; index++) {
      if (weekday == schedules[index].day) {
        todaySchedules.add(schedules[index]);
      }
    }
    if (todaySchedules.isEmpty) return null;
    final startHour = _getTodayStartTime(todaySchedules);
    final endHour = _getTodayEndTime(todaySchedules);
    return (startHour, endHour);
  }

  TimeOfDay? _getTodayStartTime(List<Schedules> schedules) {
    // start time will be the first open time after 8:59 am
    TimeOfDay? openTime;
    for (var schedule in schedules) {
      if (schedule.openingTimeAsTimeOfDay.hour > 8) {
        openTime ??= schedule.openingTimeAsTimeOfDay;
        openTime = openTime.isBefore(schedule.openingTimeAsTimeOfDay) ? openTime : schedule.openingTimeAsTimeOfDay;
      }
    }
    return openTime;
  }

  TimeOfDay? _getTodayEndTime(List<Schedules> schedules) {
    // end time will be the last close time before 11:00 pm
    TimeOfDay? nightCloseTime;
    TimeOfDay? dawnCloseTime;
    for (var schedule in schedules) {
      if (schedule.closingTimeAsTimeOfDay.hour < 9) {
        dawnCloseTime ??= schedule.closingTimeAsTimeOfDay;
        dawnCloseTime =
            dawnCloseTime.isAfter(schedule.closingTimeAsTimeOfDay) ? dawnCloseTime : schedule.closingTimeAsTimeOfDay;
      } else {
        nightCloseTime ??= schedule.closingTimeAsTimeOfDay;
        nightCloseTime =
            nightCloseTime.isAfter(schedule.closingTimeAsTimeOfDay) ? nightCloseTime : schedule.closingTimeAsTimeOfDay;
      }
    }
    return dawnCloseTime ?? nightCloseTime;
  }
}
