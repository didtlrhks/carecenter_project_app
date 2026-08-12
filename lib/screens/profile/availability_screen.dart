import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/caregiver_profile.dart';
import '../../state/profile_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/labels.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late List<_DaySlot> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<ProfileController>().profile?.availabilities ?? const <Availability>[];
    _days = [
      for (var i = 0; i < 7; i++)
        _DaySlot(
          dayOfWeek: i,
          enabled: existing.any((a) => a.dayOfWeek == i),
          start: _parse(_slotFor(existing, i)?.startTime) ?? const TimeOfDay(hour: 9, minute: 0),
          end: _parse(_slotFor(existing, i)?.endTime) ?? const TimeOfDay(hour: 18, minute: 0),
        ),
    ];
  }

  Availability? _slotFor(List<Availability> items, int day) {
    for (final item in items) {
      if (item.dayOfWeek == day) return item;
    }
    return null;
  }

  TimeOfDay? _parse(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(int index, {required bool start}) async {
    final slot = _days[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? slot.start : slot.end,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _days[index].start = picked;
      } else {
        _days[index].end = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final items = [
        for (final d in _days)
          if (d.enabled)
            Availability(dayOfWeek: d.dayOfWeek, startTime: _fmt(d.start), endTime: _fmt(d.end)),
      ];
      await context.read<ProfileController>().saveAvailabilities(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가능 시간을 저장했습니다.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가능 시간')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text('요일별로 근무 가능 시간을 설정합니다. 전체 교체 저장됩니다.', style: TextStyle(color: AppColors.body)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < _days.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  SwitchListTile(
                    title: Text(dowLabels[_days[i].dayOfWeek], style: const TextStyle(fontWeight: FontWeight.w800)),
                    value: _days[i].enabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _days[i].enabled = v),
                    subtitle: _days[i].enabled
                        ? Row(
                            children: [
                              TextButton(
                                onPressed: () => _pick(i, start: true),
                                child: Text(_fmt(_days[i].start)),
                              ),
                              const Text('~'),
                              TextButton(
                                onPressed: () => _pick(i, start: false),
                                child: Text(_fmt(_days[i].end)),
                              ),
                            ],
                          )
                        : const Text('휴무'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '저장 중…' : '저장'),
          ),
        ],
      ),
    );
  }
}

class _DaySlot {
  _DaySlot({
    required this.dayOfWeek,
    required this.enabled,
    required this.start,
    required this.end,
  });

  final int dayOfWeek;
  bool enabled;
  TimeOfDay start;
  TimeOfDay end;
}
