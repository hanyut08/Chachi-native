import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'edit_sheet.dart';

const _uuid = Uuid();

const List<Map<String, dynamic>> kSuggestions = [
  {
    'title': 'آب بخور', 'msg': 'یه لیوان آب سر بکش', 'icon': '💧',
    'colorValue': 0xFF4FA3F7, 'mode': 'interval', 'intervalMinutes': 90,
    'useRange': true, 'rangeStart': '08:00', 'rangeEnd': '23:00',
  },
  {
    'title': 'دندوناتو فشار نده', 'msg': 'فک‌تو شل کن', 'icon': '🦷',
    'colorValue': 0xFFFF6FA5, 'mode': 'interval', 'intervalMinutes': 10,
    'useRange': false,
  },
  {
    'title': 'بلند شو راه برو', 'msg': 'چند قدم بزن', 'icon': '🚶',
    'colorValue': 0xFF34D399, 'mode': 'interval', 'intervalMinutes': 60,
    'useRange': true, 'rangeStart': '09:00', 'rangeEnd': '20:00',
  },
  {
    'title': 'چشماتو استراحت بده', 'msg': 'به یه نقطه‌ی دور نگاه کن', 'icon': '👀',
    'colorValue': 0xFFA78BFA, 'mode': 'interval', 'intervalMinutes': 20,
    'useRange': false,
  },
  {
    'title': 'نفس عمیق بکش', 'msg': 'چند ثانیه آروم باش', 'icon': '🧘',
    'colorValue': 0xFF2DD4BF, 'mode': 'interval', 'intervalMinutes': 45,
    'useRange': false,
  },
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  List<Reminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _storage.load();
    setState(() {
      _reminders = list;
      _loading = false;
    });
  }

  Future<void> _persistAndReschedule() async {
    await _storage.save(_reminders);
    await NotificationService.rescheduleAll(_reminders);
  }

  Future<void> _addFromSuggestion(Map<String, dynamic> s) async {
    final numericId = await _storage.nextNumericId();
    final r = Reminder(
      id: _uuid.v4(),
      numericId: numericId,
      title: s['title'],
      msg: s['msg'] ?? '',
      icon: s['icon'],
      colorValue: s['colorValue'],
      mode: s['mode'],
      intervalMinutes: s['intervalMinutes'] ?? 60,
      useRange: s['useRange'] ?? false,
      rangeStart: s['rangeStart'] ?? '08:00',
      rangeEnd: s['rangeEnd'] ?? '23:00',
    );
    setState(() => _reminders.add(r));
    await _persistAndReschedule();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اضافه شد — می‌تونی از ⋯ ویرایشش کنی')),
      );
    }
  }

  Future<void> _openEditor({Reminder? existing}) async {
    final result = await showModalBottomSheet<EditSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => EditSheet(existing: existing),
    );
    if (result == null) return;

    if (result.delete && existing != null) {
      setState(() => _reminders.removeWhere((x) => x.id == existing.id));
      await _persistAndReschedule();
      return;
    }

    if (existing != null) {
      setState(() {
        existing
          ..title = result.title
          ..msg = result.msg
          ..icon = result.icon
          ..colorValue = result.colorValue
          ..mode = result.mode
          ..intervalMinutes = result.intervalMinutes
          ..useRange = result.useRange
          ..rangeStart = result.rangeStart
          ..rangeEnd = result.rangeEnd
          ..times = result.times;
      });
    } else {
      final numericId = await _storage.nextNumericId();
      setState(() {
        _reminders.add(Reminder(
          id: _uuid.v4(),
          numericId: numericId,
          title: result.title,
          msg: result.msg,
          icon: result.icon,
          colorValue: result.colorValue,
          mode: result.mode,
          intervalMinutes: result.intervalMinutes,
          useRange: result.useRange,
          rangeStart: result.rangeStart,
          rangeEnd: result.rangeEnd,
          times: result.times,
        ));
      });
    }
    await _persistAndReschedule();
  }

  Future<void> _toggle(Reminder r) async {
    setState(() => r.enabled = !r.enabled);
    await _persistAndReschedule();
  }

  String _describe(Reminder r) {
    if (r.mode == 'time') {
      if (r.times.isEmpty) return 'ساعتی تنظیم نشده';
      return 'ساعت ' + r.times.join(' ، ');
    }
    var s = 'هر ${r.intervalMinutes} دقیقه';
    if (r.useRange) s += ' • از ${r.rangeStart} تا ${r.rangeEnd}';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6EC0FA), ChachiColors.accent],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text('💧', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('چاچی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF16233A))),
                        Text('یادآورهای خودت', style: TextStyle(fontSize: 12, color: ChachiColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _reminders.isEmpty ? _buildEmpty() : _buildList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: ChachiColors.accent2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const Text('🫧', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 14),
          const Text('هنوز یادآوری نساختی', style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: Color(0xFF16233A))),
          const SizedBox(height: 6),
          const Text('با دکمه‌ی + یه یادآوری بساز، یا از پیشنهادهای زیر شروع کن',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: ChachiColors.muted, height: 1.8)),
          const SizedBox(height: 22),
          const Text('پیشنهاد چاچی', style: TextStyle(fontSize: 12, color: ChachiColors.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: kSuggestions.map((s) {
              return ActionChip(
                label: Text('${s['icon']} ${s['title']}'),
                backgroundColor: Colors.white,
                side: const BorderSide(color: ChachiColors.line),
                onPressed: () => _addFromSuggestion(s),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _reminders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = _reminders[index];
        final color = Color(r.colorValue);
        return Opacity(
          opacity: r.enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withOpacity(.2)),
              gradient: LinearGradient(
                colors: [color.withOpacity(.09), Colors.white],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: const [BoxShadow(color: Color(0x141E3C6E), blurRadius: 26, offset: Offset(0, 10))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(15)),
                  alignment: Alignment.center,
                  child: Text(r.icon, style: const TextStyle(fontSize: 23)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF16233A))),
                      const SizedBox(height: 3),
                      Text(_describe(r), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: ChachiColors.muted)),
                    ],
                  ),
                ),
                Switch(
                  value: r.enabled,
                  activeColor: ChachiColors.accent,
                  onChanged: (_) => _toggle(r),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: ChachiColors.muted),
                  onPressed: () => _openEditor(existing: r),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
