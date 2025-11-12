import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekNavigator extends StatefulWidget {
  final void Function(int) attWeekNumber;
  const WeekNavigator({super.key, required this.attWeekNumber});

  @override
  State<WeekNavigator> createState() => _WeekNavigatorState();
}

class _WeekNavigatorState extends State<WeekNavigator> {
  late DateTime currentMonday;
  late int weekNumber;
  final DateTime baseMonday = DateTime(2025, 1, 5); // primeira segunda-feira após 1/1/1970

  @override
  void initState() {
    super.initState();
    currentMonday = _getCurrentMonday();
    weekNumber = _computeContinuousWeekNumber(currentMonday);
    // Atualiza a callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.attWeekNumber(weekNumber);
    });
  }

  static DateTime _getCurrentMonday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day); // zera hora
  }

  int _computeContinuousWeekNumber(DateTime monday) {
    final daysDiff = monday.difference(baseMonday).inDays;
    return (daysDiff ~/ 7) + 1; // primeira semana é 1
  }

  void previousWeek() {
    setState(() {
      currentMonday = currentMonday.subtract(const Duration(days: 7));
      weekNumber = _computeContinuousWeekNumber(currentMonday);
      widget.attWeekNumber(weekNumber);
    });
  }

  void nextWeek() {
    setState(() {
      currentMonday = currentMonday.add(const Duration(days: 7));
      weekNumber = _computeContinuousWeekNumber(currentMonday);
      widget.attWeekNumber(weekNumber);
    });
  }

  String getWeekRange() {
    final sunday = currentMonday.add(const Duration(days: 6));
    final formatter = DateFormat('dd/MM');
    return '${formatter.format(currentMonday)} - ${formatter.format(sunday)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: previousWeek, icon: const Icon(Icons.arrow_back_ios)),
        Column(
          children: [
            Text('Semana $weekNumber'),
            Text(getWeekRange(), style: TextStyle(fontSize: 13),),
          ],
        ),
        IconButton(onPressed: nextWeek, icon: const Icon(Icons.arrow_forward_ios)),
      ],
    );
  }
}
