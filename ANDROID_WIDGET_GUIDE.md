# Android Widget Implementation Guide

## Files to Create

### 1. SmallWidgetProvider.kt
**Location:** `android/app/src/main/kotlin/com/money_app/widgets/SmallWidgetProvider.kt`

```kotlin
package com.money_app.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.money_app.R

class SmallWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val balance = prefs.getString("flutter.balance", "₲ 0")
        
        val views = RemoteViews(context.packageName, R.layout.widget_small)
        views.setTextViewText(R.id.widget_balance, balance)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
```

### 2. widget_small.xml
**Location:** `android/app/src/main/res/layout/widget_small.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@drawable/widget_background">

    <TextView
        android:id="@+id/widget_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Saldo Disponible"
        android:textSize="12sp"
        android:textColor="#FFFFFF"
        android:alpha="0.7"/>

    <TextView
        android:id="@+id/widget_balance"
        android:layout_width="wrap_content"
       android:layout_height="wrap_content"
        android:text="₲ 0"
        android:textSize="24sp"
        android:textStyle="bold"
        android:textColor="#FFFFFF"
        android:layout_marginTop="8dp"/>

</LinearLayout>
```

### 3. widget_background.xml
**Location:** `android/app/src/main/res/drawable/widget_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:startColor="#004D40"
        android:endColor="#00BFA5"
        android:angle="135"/>
    <corners android:radius="16dp"/>
</shape>
```

### 4. Update AndroidManifest.xml
**Location:** `android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:

```xml
<receiver
    android:name=".widgets.SmallWidgetProvider"
    android:exported="false">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_small_info"/>
</receiver>
```

### 5. widget_small_info.xml
**Location:** `android/app/src/main/res/xml/widget_small_info.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="120dp"
    android:minHeight="40dp"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/widget_small"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"/>
```

## Similar Implementation for Medium and Large Widgets

Follow the same pattern for:
- `MediumWidgetProvider.kt` + `widget_medium.xml` + `widget_medium_info.xml`
- `LargeWidgetProvider.kt` + `widget_large.xml` + `widget_large_info.xml`

## Testing

1. Build the app: `flutter build apk`
2. Install on device
3. Long-press home screen → Widgets → Find "Money App"
4. Add widgets to home screen
5. Open app and create a transaction
6. Verify widgets update within 5 seconds

## Notes

- Widgets update via SharedPreferences (written by `home_widget` package)
- Update is triggered by `HomeWidget.updateWidget()` calls from Dart
- Android 12+ requires exact permissions for updates (already handled by package)
