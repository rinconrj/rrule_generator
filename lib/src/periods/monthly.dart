import 'package:flutter/material.dart';
import 'package:rrule_generator/localizations/text_delegate.dart';
import 'package:rrule_generator/src/pickers/helpers.dart';
import 'package:rrule_generator/src/pickers/interval.dart';
import 'package:rrule_generator/src/periods/period.dart';

class Monthly extends StatelessWidget implements Period {
  @override
  final RRuleTextDelegate textDelegate;
  @override
  final Function onChange;
  @override
  final String initialRRule;
  @override
  final DateTime initialDate;

  final monthTypeNotifier = ValueNotifier(0);
  final monthDayNotifier = ValueNotifier(1);
  final weekdayNotifier = ValueNotifier(0);
  final dayNotifier = ValueNotifier(1);
  final intervalController = TextEditingController(text: '1');

  Monthly(this.textDelegate, this.onChange, this.initialRRule, this.initialDate,
      {Key? key})
      : super(key: key) {
    if (initialRRule.contains('MONTHLY'))
      handleInitialRRule();
    else {
      dayNotifier.value = initialDate.day;
      weekdayNotifier.value = initialDate.weekday - 1;
    }
  }

  @override
  void handleInitialRRule() {
    if (initialRRule.contains('BYMONTHDAY')) {
      monthTypeNotifier.value = 0;
      int dayIndex = initialRRule.indexOf('BYMONTHDAY=') + 11;
      String day = initialRRule.substring(
          dayIndex, dayIndex + (initialRRule.length > dayIndex + 1 ? 2 : 1));
      if (day.length == 1 || day[1] != ';') {
        dayNotifier.value = int.parse(day);
      } else {
        dayNotifier.value = int.parse(day[0]);
      }

      int intervalIndex = initialRRule.indexOf('INTERVAL=') + 9;
      int intervalEnd = initialRRule.indexOf(';', intervalIndex);
      String interval = initialRRule.substring(
          intervalIndex, intervalEnd == -1 ? initialRRule.length : intervalEnd);
      intervalController.text = interval;
    } else {
      monthTypeNotifier.value = 1;

      int monthDayIndex = initialRRule.indexOf('BYSETPOS=') + 9;
      String monthDay =
          initialRRule.substring(monthDayIndex, monthDayIndex + 1);

      if (monthDay == '-') {
        monthDayNotifier.value = 4;
      } else {
        monthDayNotifier.value = int.parse(monthDay) - 1;
      }

      int weekdayIndex = initialRRule.indexOf('BYDAY=') + 6;
      String weekday = initialRRule.substring(weekdayIndex, weekdayIndex + 2);

      weekdayNotifier.value = weekdaysShort.indexOf(weekday);
    }
  }

  @override
  String getRRule() {
    if (monthTypeNotifier.value == 0) {
      int byMonthDay = dayNotifier.value;
      String interval = intervalController.text;
      return 'FREQ=MONTHLY;BYMONTHDAY=$byMonthDay;INTERVAL=$interval';
    } else {
      String byDay = weekdaysShort[weekdayNotifier.value];
      int bySetPos =
          (monthDayNotifier.value < 4) ? monthDayNotifier.value + 1 : -1;
      int interval = int.tryParse(intervalController.text) ?? 0;
      return 'FREQ=MONTHLY;INTERVAL=${interval > 0 ? interval : 1};'
          'BYDAY=$byDay;BYSETPOS=$bySetPos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildContainer(
          child: buildElement(
            title: textDelegate.every,
            child: Row(
              children: [
                Expanded(child: IntervalPicker(intervalController, onChange)),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(textDelegate.months),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        ValueListenableBuilder(
          valueListenable: monthTypeNotifier,
          builder: (BuildContext context, int monthType, Widget? child) =>
              Column(
            children: [
              buildToggleItem(
                title: textDelegate.byNthDayInMonth,
                value: monthType == 0,
                onChanged: (bool selected) {
                  monthTypeNotifier.value = selected ? 0 : 1;
                },
                child: buildElement(
                  title: textDelegate.on,
                  child: buildDropdown(
                    child: ValueListenableBuilder(
                      valueListenable: dayNotifier,
                      builder: (BuildContext context, int day, _) =>
                          DropdownButton(
                        value: day,
                        onChanged: (int? newDay) {
                          dayNotifier.value = newDay!;
                          onChange();
                        },
                        items: List.generate(
                          31,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              (index + 1).toString(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              buildToggleItem(
                title: textDelegate.byDayInMonth,
                value: monthType == 1,
                onChanged: (bool selected) {
                  monthTypeNotifier.value = selected ? 1 : 0;
                },
                child: Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: monthDayNotifier,
                      builder: (BuildContext context, int dayInMonth, _) => Row(
                        children: [
                          Expanded(
                            child: buildElement(
                              title: textDelegate.on,
                              child: buildDropdown(
                                child: DropdownButton(
                                  value: dayInMonth,
                                  onChanged: (int? dayInMonth) {
                                    monthDayNotifier.value = dayInMonth!;
                                    onChange();
                                  },
                                  items: List.generate(
                                    5,
                                    (index) => DropdownMenuItem(
                                      value: index,
                                      child: Text(
                                        textDelegate.daysInMonth[index],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: buildElement(
                              title: 'Day',
                              child: buildDropdown(
                                child: ValueListenableBuilder(
                                  valueListenable: weekdayNotifier,
                                  builder:
                                      (BuildContext context, int weekday, _) =>
                                          DropdownButton(
                                    value: weekday,
                                    onChanged: (int? newWeekday) {
                                      weekdayNotifier.value = newWeekday!;
                                      onChange();
                                    },
                                    items: List.generate(
                                      7,
                                      (index) => DropdownMenuItem(
                                        value: index,
                                        child: Text(
                                          textDelegate.weekdays[index]
                                              .toString(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
