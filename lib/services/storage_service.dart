import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';

class StorageService {
  static const _key = 'chachi_reminders_v1';
  static const _counterKey = 'chachi_id_counter_v1';

  Future<List<Reminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null || s.isEmpty) return [];
    try {
      return Reminder.decodeList(s);
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Reminder> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Reminder.encodeList(list));
  }

  Future<int> nextNumericId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_counterKey) ?? 1;
    await prefs.setInt(_counterKey, current + 1);
    return current;
  }
}
