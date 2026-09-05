import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../theme.dart';

class EditSheetResult {
  final bool delete;
  final String title;
  final String msg;
  final String icon;
  final int colorValue;
  final String mode;
  final int intervalMinutes;
  final bool useRange;
  final String rangeStart;
  final String rangeEnd;
  final List<String> times;

  EditSheetResult({
    this.delete = false,
    this.title = '',
    this.msg = '',
    this.icon = '💧',
    this.colorValue = 0xFF4FA3F7,
    this.mode = 'interval',
    this.intervalMinutes = 60,
    this.useRange = false,
    this.rangeStart = '08:00',
    this.rangeEnd = '23:00',
    List<String>? times,
  }) : times = times ?? [];
}

class EditSheet extends StatefulWidget {
  final Reminder? existing;
  const EditSheet({super.key, this.existing});

  @override
  State<EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<EditSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _msgCtrl;
  late TextEditingController _intervalCtrl;
  late String _icon;
  late int _colorValue;
  late String _mode;
  late bool _useRange;
  late String _rangeStart;
  late String _rangeEnd;
  late List<String> _times;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _msgCtrl = TextEditingController(text: e?.msg ?? '');
    _intervalCtrl = TextEditingController(text: (e?.intervalMinutes ?? 60).toString());
    _icon = e?.icon ?? '💧';
    _colorValue = e?.colorValue ?? kColorSwatches[0]['value'];
    _mode = e?.mode ?? 'interval';
    _useRange = e?.useRange ?? false;
    _rangeStart = e?.rangeStart ?? '08:00';
    _rangeEnd = e?.rangeEnd ?? '23:00';
    _times = List.from(e?.times ?? []);
  }

  Future<void> _pickTime(int index) async {
    final parts = _times[index].split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _times[index] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickRange(bool isStart) async {
    final current = isStart ? _rangeStart : _rangeEnd;
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        final v = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _rangeStart = v;
        } else {
          _rangeEnd = v;
        }
      });
    }
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context, EditSheetResult(
      title: title,
      msg: _msgCtrl.text.trim(),
      icon: _icon,
      colorValue: _colorValue,
      mode: _mode,
      intervalMinutes: int.tryParse(_intervalCtrl.text) ?? 60,
      useRange: _useRange,
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
      times: _times,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: ChachiColors.line, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text(widget.existing != null ? 'ویرایش یادآوری' : 'یادآوری جدید',
                    style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: Color(0xFF16233A))),
                const SizedBox(height: 18),

                _label('عنوان'),
                _textField(_titleCtrl, 'مثلاً آب بخور'),
                const SizedBox(height: 16),

                _label('توضیح کوتاه (اختیاری)'),
                _textField(_msgCtrl, 'مثلاً یه لیوان آب سر بکش'),
                const SizedBox(height: 16),

                _label('آیکون'),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: kEmojiChoices.map((em) {
                    final selected = em == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = em),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: selected ? ChachiColors.accent.withOpacity(.14) : const Color(0xFFF3F6FB),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: selected ? ChachiColors.accent : ChachiColors.line),
                        ),
                        alignment: Alignment.center,
                        child: Text(em, style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                _label('رنگ'),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: kColorSwatches.map((c) {
                    final selected = c['value'] == _colorValue;
                    return GestureDetector(
                      onTap: () => setState(() => _colorValue = c['value']),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Color(c['value']),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: selected
                              ? [const BoxShadow(color: Color(0xFF16233A), blurRadius: 0, spreadRadius: 2)]
                              : [BoxShadow(color: ChachiColors.line, blurRadius: 0, spreadRadius: 1)],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                _label('نوع زمان‌بندی'),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF3F6FB), borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _segButton('تکرار فاصله‌ای', 'interval'),
                      _segButton('ساعت مشخص', 'time'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_mode == 'interval') ...[
                  _label('هر چند دقیقه یک‌بار یادآوری کنه'),
                  _textField(_intervalCtrl, 'مثلاً 90', isNumber: true),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _useRange,
                    activeColor: ChachiColors.accent,
                    title: const Text('محدود به یک بازه‌ی زمانی خاص از روز', style: TextStyle(fontSize: 13.5)),
                    onChanged: (v) => setState(() => _useRange = v),
                  ),
                  if (_useRange)
                    Row(
                      children: [
                        Expanded(child: _rangePicker('از ساعت', _rangeStart, () => _pickRange(true))),
                        const SizedBox(width: 10),
                        Expanded(child: _rangePicker('تا ساعت', _rangeEnd, () => _pickRange(false))),
                      ],
                    ),
                ] else ...[
                  _label('ساعت‌های یادآوری (مثل آلارم)'),
                  ..._times.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickTime(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(color: const Color(0xFFF3F6FB), borderRadius: BorderRadius.circular(14), border: Border.all(color: ChachiColors.line)),
                                child: Text(_times[i], style: const TextStyle(fontSize: 14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: ChachiColors.muted),
                            onPressed: () => setState(() => _times.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton(
                    onPressed: () => setState(() => _times.add('08:00')),
                    child: const Text('+ افزودن ساعت', style: TextStyle(color: ChachiColors.accent2, fontWeight: FontWeight.w700)),
                  ),
                ],

                const SizedBox(height: 22),
                Row(
                  children: [
                    if (widget.existing != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, EditSheetResult(delete: true)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF4595F),
                            side: BorderSide.none,
                            backgroundColor: const Color(0xFFFEEBEC),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('حذف'),
                        ),
                      ),
                    if (widget.existing != null) const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ChachiColors.text,
                          side: const BorderSide(color: ChachiColors.line),
                          backgroundColor: const Color(0xFFF3F6FB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ChachiColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _segButton(String label, String value) {
    final selected = _mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? ChachiColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : ChachiColors.muted)),
        ),
      ),
    );
  }

  Widget _rangePicker(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF3F6FB), borderRadius: BorderRadius.circular(14), border: Border.all(color: ChachiColors.line)),
              child: Text(value, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text, style: const TextStyle(fontSize: 12.5, color: ChachiColors.muted)),
      );

  Widget _textField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F6FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
