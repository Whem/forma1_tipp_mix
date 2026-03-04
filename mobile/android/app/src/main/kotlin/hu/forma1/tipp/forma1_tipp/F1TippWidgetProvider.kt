package hu.forma1.tipp.forma1_tipp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class F1TippWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.f1_widget).apply {
                setTextViewText(R.id.tv_next_race, widgetData.getString("nextRace", "Loading..."))
                setTextViewText(R.id.tv_countdown, widgetData.getString("countdown", "--:--:--"))
                setTextViewText(R.id.tv_position, widgetData.getString("position", "#-"))
                setTextViewText(R.id.tv_points, widgetData.getString("points", "0 pts"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
