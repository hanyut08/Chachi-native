import 'dart:convert';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/reminder.dart';

/// Each reminder reserves a block of 1000 notification ids:
/// numericId * 1000 .. numericId * 1000 + 999
/// - time-mode slots use offsets 0..499 (one per configured time-of-day)
/// - interval-mode occurrences use offsets 500..999 (rolling window)
const int _kBlockSize = 1000;
const int _kIntervalOffsetStart = 500;
const int _kIntervalOffsetCount = 480; // max scheduled occurrences per reminder

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final String tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // fall back to whatever default the timezone package picked
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'chachi_reminders',
        'یادآورهای چاچی',
        description: 'یادآورهایی که خودت توی چاچی ساختی',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('chime'),
        playSound: true,
      ),
    );

    await requestPermissions();
  }

  static Future<void> requestPermissions() async {
    try {
      await Permission.notification.request();
    } catch (_) {}
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  @pragma('vm:entry-point')
  static void _onResponse(NotificationResponse response) {
    _handleAction(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse response) {
    _handleAction(response);
  }

  static void _handleAction(NotificationResponse response) async {
    if (response.actionId != 'snooze') return;
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      tzdata.initializeTimeZones();
      final fireAt = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5));
      final snoozeId = 900000 + (DateTime.now().millisecondsSinceEpoch % 90000);
      await _plugin.zonedSchedule(
        snoozeId,
        '${data['icon']} ${data['title']}',
        data['msg'] ?? '',
        fireAt,
        _details(data['colorValue'] as int? ?? 0xFF4FA3F7, data),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  static NotificationDetails _details(int colorValue, Map<String, dynamic> payloadData) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'chachi_reminders',
        'یادآورهای چاچی',
        channelDescription: 'یادآورهایی که خودت توی چاچی ساختی',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(colorValue),
        sound: const RawResourceAndroidNotificationSound('chime'),
        playSound: true,
        actions: const [
          AndroidNotificationAction('done', 'انجام شد', showsUserInterface: false, cancelNotification: true),
          AndroidNotificationAction('snooze', 'بعداً', showsUserInterface: false, cancelNotification: true),
        ],
      ),
    );
  }

  static Future<void> cancelAllForReminder(int numericId) async {
    final base = numericId * _kBlockSize;
    for (int i = 0; i < _kBlockSize; i++) {
      await _plugin.cancel(base + i);
    }
  }

  static Future<void> rescheduleAll(List<Reminder> reminders) async {
    for (final r in reminders) {
      await cancelAllForReminder(r.numericId);
      if (!r.enabled) continue;
      final payload = jsonEncode({
        'title': r.title,
        'msg': r.msg,
        'icon': r.icon,
        'colorValue': r.colorValue,
      });
      if (r.mode == 'time') {
        await _scheduleTimeMode(r, payload);
      } else {
        await _scheduleIntervalMode(r, payload);
      }
    }
  }

  static Future<void> _scheduleTimeMode(Reminder r, String payload) async {
    final base = r.numericId * _kBlockSize;
    for (int i = 0; i < r.times.length && i < 500; i++) {
      final parts = r.times[i].split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      var next = _nextInstanceOf(hour, minute);
      try {
        await _plugin.zonedSchedule(
          base + i,
          '${r.icon} ${r.title}',
          r.msg,
          next,
          _details(r.colorValue, jsonDecode(payload)),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } catch (_) {
        // exact alarm permission may be missing on some devices; try inexact
        try {
          await _plugin.zonedSchedule(
            base + i,
            '${r.icon} ${r.title}',
            r.msg,
            next,
            _details(r.colorValue, jsonDecode(payload)),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: payload,
          );
        } catch (_) {}
      }
    }
  }

  static Future<void> _scheduleIntervalMode(Reminder r, String payload) async {
    final base = r.numericId * _kBlockSize + _kIntervalOffsetStart;
    var cursor = tz.TZDateTime.now(tz.local).add(Duration(minutes: r.intervalMinutes));
    int count = 0;
    // safety cap: don't compute further than ~30 days ahead
    final hardStop = tz.TZDateTime.now(tz.local).add(const Duration(days: 30));

    while (count < _kIntervalOffsetCount && cursor.isBefore(hardStop)) {
      final withinRange = !r.useRange || _isWithinRange(cursor, r.rangeStart, r.rangeEnd);
      if (withinRange) {
        try {
          await _plugin.zonedSchedule(
            base + count,
            '${r.icon} ${r.title}',
            r.msg,
            cursor,
            _details(r.colorValue, jsonDecode(payload)),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );
        } catch (_) {
          try {
            await _plugin.zonedSchedule(
              base + count,
              '${r.icon} ${r.title}',
              r.msg,
              cursor,
              _details(r.colorValue, jsonDecode(payload)),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: payload,
            );
          } catch (_) {}
        }
        count++;
      }
      cursor = cursor.add(Duration(minutes: r.intervalMinutes));
    }
  }

  static bool _isWithinRange(tz.TZDateTime dt, String start, String end) {
    final sp = start.split(':');
    final ep = end.split(':');
    final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
    final endMin = int.parse(ep[0]) * 60 + int.parse(ep[1]);
    final curMin = dt.hour * 60 + dt.minute;
    if (startMin <= endMin) {
      return curMin >= startMin && curMin <= endMin;
    }
    return curMin >= startMin || curMin <= endMin; // wraps past midnight
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
