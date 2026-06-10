package com.bpcompanion.bp_companion

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BpHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, id, widgetData))
        }
    }

    companion object {
        fun buildViews(
            context: Context,
            widgetId: Int,
            widgetData: android.content.SharedPreferences,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.bp_widget_layout)
            val sys = widgetData.getInt(BpSharedStore.DRAFT_SYS_KEY, 120)
            val dia = widgetData.getInt(BpSharedStore.DRAFT_DIA_KEY, 80)
            val pulse = widgetData.getInt(BpSharedStore.DRAFT_PULSE_KEY, 72)
            val latest = BpSharedStore.latestRecord(context)

            views.setTextViewText(R.id.widget_title, "轻松血压")
            views.setTextViewText(
                R.id.widget_latest,
                latest?.let { "${it.getInt("systolic")}/${it.getInt("diastolic")}" } ?: "--/--",
            )
            views.setTextViewText(R.id.widget_sys_value, "$sys mmHg")
            views.setTextViewText(R.id.widget_dia_value, "$dia mmHg")
            views.setTextViewText(R.id.widget_pulse_value, "$pulse bpm")
            views.setTextViewText(
                R.id.widget_message,
                widgetData.getString(BpSharedStore.LAST_MESSAGE_KEY, "") ?: "",
            )

            views.setOnClickPendingIntent(
                R.id.widget_sys_minus,
                actionIntent(context, widgetId, "adjust", mapOf("field" to "sys", "delta" to "-1")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_sys_plus,
                actionIntent(context, widgetId, "adjust", mapOf("field" to "sys", "delta" to "1")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_dia_minus,
                actionIntent(context, widgetId, "adjust", mapOf("field" to "dia", "delta" to "-1")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_dia_plus,
                actionIntent(context, widgetId, "adjust", mapOf("field" to "dia", "delta" to "1")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_pulse_minus,
                actionIntent(context, widgetId, "adjust", mapOf("field" to "pulse", "delta" to "-1")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_pulse_plus,
                actionIntent(context, widgetId, "adjust", mapOf("field" to "pulse", "delta" to "1")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_save_button,
                actionIntent(
                    context,
                    widgetId,
                    "save",
                    mapOf("sys" to sys.toString(), "dia" to dia.toString(), "pulse" to pulse.toString()),
                ),
            )
            return views
        }

        private fun actionIntent(
            context: Context,
            widgetId: Int,
            host: String,
            params: Map<String, String>,
        ): PendingIntent {
            val builder = Uri.Builder().scheme("bpwidget").authority(host)
            params.forEach { (k, v) -> builder.appendQueryParameter(k, v) }
            return HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse(builder.build().toString()),
            )
        }
    }
}
