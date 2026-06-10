package com.bpcompanion.bp_companion

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.format.DateTimeFormatter
import kotlin.random.Random

object BpSharedStore {
    const val PREFS_NAME = "HomeWidgetPreferences"
    const val RECORDS_KEY = "bp_records_v1"
    const val DRAFT_SYS_KEY = "widget_draft_sys"
    const val DRAFT_DIA_KEY = "widget_draft_dia"
    const val DRAFT_PULSE_KEY = "widget_draft_pulse"
    const val LAST_MESSAGE_KEY = "widget_last_message"

    fun loadRecords(context: Context): JSONArray {
        val raw = prefs(context).getString(RECORDS_KEY, null) ?: return JSONArray()
        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    fun latestRecord(context: Context): JSONObject? {
        val records = loadRecords(context)
        if (records.length() == 0) return null
        var latest: JSONObject? = null
        for (i in 0 until records.length()) {
            val item = records.getJSONObject(i)
            if (latest == null || item.getString("time") > latest.getString("time")) {
                latest = item
            }
        }
        return latest
    }

    fun appendRecord(context: Context, systolic: Int, diastolic: Int, pulse: Int?) {
        require(systolic in 50..300 && diastolic in 30..200)
        val records = loadRecords(context)
        val now = Instant.now()
        val hour = now.atZone(java.time.ZoneId.systemDefault()).hour
        val measureContext = when {
            hour < 12 -> 0
            hour >= 21 -> 1
            else -> 4
        }
        val record = JSONObject()
            .put("id", "${System.currentTimeMillis()}_${Random.nextInt(0, 99999)}")
            .put("systolic", systolic)
            .put("diastolic", diastolic)
            .put("pulse", pulse)
            .put("time", DateTimeFormatter.ISO_INSTANT.format(now))
            .put("context", measureContext)
            .put("note", "")
        records.put(record)
        prefs(context).edit()
            .putString(RECORDS_KEY, records.toString())
            .putString(LAST_MESSAGE_KEY, "已保存 $systolic/$diastolic")
            .apply()
    }

    fun getDraft(context: Context, key: String, default: Int): Int =
        prefs(context).getInt(key, default)

    fun setDraft(context: Context, key: String, value: Int) {
        prefs(context).edit().putInt(key, value).apply()
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
