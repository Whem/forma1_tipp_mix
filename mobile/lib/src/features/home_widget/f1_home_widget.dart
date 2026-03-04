import 'package:home_widget/home_widget.dart';

class F1HomeWidget {
  static const String appWidgetProviderName = 'F1TippWidgetProvider';
  static const String androidWidgetName = 'F1TippWidgetProvider';

  static Future<void> updateWidget({
    required String nextRaceName,
    required String countdown,
    required int userPosition,
    required int totalPoints,
  }) async {
    await HomeWidget.saveWidgetData('nextRace', nextRaceName);
    await HomeWidget.saveWidgetData('countdown', countdown);
    await HomeWidget.saveWidgetData('position', '#$userPosition');
    await HomeWidget.saveWidgetData('points', '$totalPoints pts');
    await HomeWidget.updateWidget(androidName: androidWidgetName);
  }
}
