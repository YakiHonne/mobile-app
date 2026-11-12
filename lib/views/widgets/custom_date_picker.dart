// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../utils/utils.dart';
import 'custom_icon_buttons.dart';

class PickDateTimeWidget extends HookWidget {
  const PickDateTimeWidget({
    super.key,
    required this.focusedDate,
    required this.onDateSelected,
    required this.onClearDate,
    required this.isAfter,
  });

  final DateTime focusedDate;
  final Function(DateTime) onDateSelected;
  final Function() onClearDate;
  final bool isAfter;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final timeOfDay = useState<TimeOfDay>(
      const TimeOfDay(hour: 0, minute: 0),
    );
    final calendarScrollController = useScrollController();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      height: isDesktopPlatform ? 480 : (isMobile ? 60.h : 40.h),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: ListView(
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: Align(
                  child: Text(
                    context.t.selectAdate.capitalizeFirst(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: CustomIconButton(
                  onClicked: () {
                    Navigator.pop(context);
                  },
                  icon: FeatureIcons.closeRaw,
                  size: 20,
                  backgroundColor: Theme.of(context).cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _buildDefaultSingleDatePickerWithValue(
            singleDatePickerValueWithDefaultValue: [focusedDate],
            onValueChanged: (p0) {
              onDateSelected.call(p0.first ?? DateTime.now());
            },
            context: context,
            scrollController: calendarScrollController,
          ),
          _showCalendarRow(timeOfDay, context),
        ],
      ),
    );
  }

  Widget _showCalendarRow(
      ValueNotifier<TimeOfDay> timeOfDay, BuildContext context) {
    final timeButton = Builder(
      builder: (context) {
        final date = DateTime(
          focusedDate.year,
          focusedDate.month,
          focusedDate.day,
          timeOfDay.value.hour,
          timeOfDay.value.minute,
        );
        return _dateButton(context, timeOfDay, date);
      },
    );
    final clearButton = TextButton(
      onPressed: onClearDate,
      child: Text(context.t.clearDate.capitalizeFirst()),
    );
    if (isDesktopPlatform) {
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [timeButton, clearButton],
      );
    }
    return Row(
      children: [
        timeButton,
        const Spacer(),
        clearButton,
      ],
    );
  }

  GestureDetector _dateButton(
      BuildContext context, ValueNotifier<TimeOfDay> timeOfDay, DateTime date) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        final tod = await showTimePicker(
          context: context,
          initialTime: timeOfDay.value,
        );

        if (tod != null) {
          timeOfDay.value = tod;
          onDateSelected.call(
            DateTime(
              focusedDate.year,
              focusedDate.month,
              focusedDate.day,
              timeOfDay.value.hour,
              timeOfDay.value.minute,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 3,
          horizontal: kDefaultPadding / 1.5,
        ),
        child: Text(
          date.toHourMinutes(),
        ),
      ),
    );
  }

  Widget _buildDefaultSingleDatePickerWithValue({
    required List<DateTime> singleDatePickerValueWithDefaultValue,
    required Function(List<DateTime?>) onValueChanged,
    required BuildContext context,
    required ScrollController scrollController,
  }) {
    final config = CalendarDatePicker2Config(
      selectedDayHighlightColor: Theme.of(context).primaryColor,
      weekdayLabels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      weekdayLabelTextStyle: Theme.of(context).textTheme.labelMedium,
      firstDayOfWeek: 1,
      controlsHeight: 50,
      controlsTextStyle: TextStyle(
        color: Theme.of(context).primaryColorDark,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      selectedDayTextStyle: Theme.of(context).textTheme.labelMedium,
      dayTextStyle: Theme.of(context).textTheme.labelMedium,
      disabledDayTextStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).highlightColor,
          ),
      selectableDayPredicate: (day) {
        final isNegative = day.difference(DateTime.now()).isNegative;
        return isAfter ? !isNegative : isNegative;
      },
    );

    final calendar = CalendarDatePicker2(
      config: config,
      value: singleDatePickerValueWithDefaultValue,
      onValueChanged: (dates) {
        onValueChanged.call(dates);
      },
    );
    if (!isDesktopPlatform) {
      return calendar;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumWidth = 360 * MediaQuery.textScalerOf(context).scale(1);
        return ScrollbarTheme(
          data: ScrollbarTheme.of(context).copyWith(
            thumbColor: WidgetStatePropertyAll(Theme.of(context).hintColor),
            thickness: const WidgetStatePropertyAll(6),
          ),
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth < minimumWidth
                    ? minimumWidth
                    : constraints.maxWidth,
                child: calendar,
              ),
            ),
          ),
        );
      },
    );
  }
}
