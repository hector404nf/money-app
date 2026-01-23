package com.example.money_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Open App on Widget Click (General)
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                // Update text
                val remainingBudget = widgetData.getString("remaining_budget", "Gs. ---")
                setTextViewText(R.id.tv_remaining_budget, remainingBudget)

                // Add Expense Button
                // We use a specific URI so Flutter can detect it
                val addExpenseIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("moneyapp://add_expense")
                )
                setOnClickPendingIntent(R.id.btn_add_expense, addExpenseIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
