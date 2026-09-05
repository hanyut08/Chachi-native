import 'dart:convert';

class Reminder {
  final String id;
  final int numericId;
  String title;
  String msg;
  String icon;
  int colorValue;
  bool enabled;
  String mode; // 'interval' | 'time'
  int intervalMinutes;
  bool useRange;
  String rangeStart; // "HH:mm"
  String rangeEnd;   // "HH:mm"
  List<String> times; // list of "HH:mm"

  Reminder({
    required this.id,
    required this.numericId,
    required this.title,
    this.msg = '',
    this.icon = '💧',
    required this.colorValue,
    this.enabled = true,
    this.mode = 'interval',
    this.intervalMinutes = 60,
    this.useRange = false,
    this.rangeStart = '08:00',
    this.rangeEnd = '23:00',
    List<String>? times,
  }) : times = times ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'numericId': numericId,
        'title': title,
        'msg': msg,
        'icon': icon,
        'colorValue': colorValue,
        'enabled': enabled,
        'mode': mode,
        'intervalMinutes': intervalMinutes,
        'useRange': useRange,
        'rangeStart': rangeStart,
        'rangeEnd': rangeEnd,
        'times': times,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'],
        numericId: j['numericId'],
        title: j['title'] ?? '',
        msg: j['msg'] ?? '',
        icon: j['icon'] ?? '💧',
        colorValue: j['colorValue'],
        enabled: j['enabled'] ?? true,
        mode: j['mode'] ?? 'interval',
        intervalMinutes: j['intervalMinutes'] ?? 60,
        useRange: j['useRange'] ?? false,
        rangeStart: j['rangeStart'] ?? '08:00',
        rangeEnd: j['rangeEnd'] ?? '23:00',
        times: (j['times'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  static String encodeList(List<Reminder> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<Reminder> decodeList(String s) {
    final arr = jsonDecode(s) as List;
    return arr.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
  }
}
