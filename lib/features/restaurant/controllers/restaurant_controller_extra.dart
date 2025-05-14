part of 'restaurant_controller.dart';

extension RestaurantControllerExtra on RestaurantController {
  (TimeOfDay?, TimeOfDay?)? todaySchedulte(List<Schedules>? schedules) {
    if (schedules?.isNotEmpty != true) return null;
    int weekday = DateTime.now().weekday;
    if (weekday == 7) {
      weekday = 0;
    }
    for (int index = 0; index < schedules!.length; index++) {
      if (weekday == schedules[index].day) {
        final start = schedules[index].openingTime?.split(':');
        final end = schedules[index].closingTime?.split(':');
        final startHour = (TimeOfDay(hour: int.parse(start?[0] ?? '0'), minute: int.parse(start?[1] ?? '0')));
        final endHour = (TimeOfDay(hour: int.parse(end?[0] ?? '0'), minute: int.parse(end?[1] ?? '0')));
        return (startHour, endHour);
      }
    }
    return null;
  }

  int closingAfter(TimeOfDay close) {
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
}
