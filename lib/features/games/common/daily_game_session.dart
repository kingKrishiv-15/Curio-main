import 'package:flutter/widgets.dart';

/// A daily run belongs to the date it was opened, including across midnight.
class DailyGameSession extends InheritedWidget {
  const DailyGameSession({
    required this.gameId,
    required this.date,
    required super.child,
    super.key,
  });

  final String gameId;
  final DateTime date;

  static DailyGameSession? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DailyGameSession>();

  @override
  bool updateShouldNotify(DailyGameSession oldWidget) =>
      gameId != oldWidget.gameId || date != oldWidget.date;
}
