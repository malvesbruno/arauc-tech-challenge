import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


// Widget da navegação entre semanas

/// [attWeekNumber] função que atualiza o número da semana  
/// [loadDrawing] função que carrega o desenho


class WeekNavigator extends StatefulWidget {
  final void Function(int) attWeekNumber;
  final Future<void> Function(int) loadDrawing;
  const WeekNavigator({super.key, required this.attWeekNumber, required this.loadDrawing});

  @override
  State<WeekNavigator> createState() => _WeekNavigatorState();
}

class _WeekNavigatorState extends State<WeekNavigator> {
  late DateTime currentMonday; // segunda atual
  late int weekNumber; // número da semana
  final DateTime baseMonday = DateTime(2025, 1, 5); // primeira segunda-feira após 1/1/2025

  @override
  void initState() {
    super.initState();
    currentMonday = _getCurrentMonday(); // pega a segunda atual 
    weekNumber = _computeContinuousWeekNumber(currentMonday); // pega o número da semana
    // Atualiza a callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.attWeekNumber(weekNumber); // atualiza o número da semana 
      widget.loadDrawing(weekNumber); // carrega o desenho do dia
    });
  }

  // pega a segunda atual
  static DateTime _getCurrentMonday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day); // zera hora
  }

  // computa as semanas baseado na primeira
  int _computeContinuousWeekNumber(DateTime monday) {
    final daysDiff = monday.difference(baseMonday).inDays;
    return (daysDiff ~/ 7) + 1; // primeira semana é 1
  }

  // volta uma semana
  void previousWeek() {
    setState(() {
      currentMonday = currentMonday.subtract(const Duration(days: 7));
      weekNumber = _computeContinuousWeekNumber(currentMonday);
      widget.attWeekNumber(weekNumber);
      widget.loadDrawing(weekNumber);
    });
  }

  // avança uma semana
  void nextWeek() {
    setState(() {
      currentMonday = currentMonday.add(const Duration(days: 7));
      weekNumber = _computeContinuousWeekNumber(currentMonday);
      widget.attWeekNumber(weekNumber);
      widget.loadDrawing(weekNumber);
    });
  }

  // pega o tamanho da semana e retorna o primeiro e o último dia dela
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
        // passa pra próxima semana
        IconButton(onPressed: previousWeek, icon: const Icon(Icons.arrow_back_ios)),
        Column(
          children: [
            // mostra o número da semana, seu incio e final
            Text('Semana $weekNumber'),
            Text(getWeekRange(), style: TextStyle(fontSize: 13),),
          ],
        ),
        // volta pra semana anterior
        IconButton(onPressed: nextWeek, icon: const Icon(Icons.arrow_forward_ios)),
      ],
    );
  }
}
