import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/schedule.dart';
import '../../state/schedules_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/labels.dart';
import '../../utils/regions.dart';
import '../../widgets/empty_state.dart';
import '../calls/job_detail_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SchedulesController>();
    final grouped = ctrl.groupedByDay();
    final days = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('내 일정')),
      body: RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: ctrl.loading && ctrl.items.isEmpty
            ? ListView(children: const [SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))])
            : days.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 360,
                        child: EmptyState(
                          icon: Icons.event_available_outlined,
                          title: '예정된 근무가 없습니다',
                          subtitle: '확정된 근무가 있으면\n여기에서 확인할 수 있습니다.',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: days.length,
                    itemBuilder: (context, i) {
                      final day = days[i];
                      final items = grouped[day]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_dayTitle(day), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 8),
                            ...items.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _ScheduleTile(item: s),
                                )),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _dayTitle(String ymd) {
    final parsed = DateTime.tryParse(ymd);
    if (parsed == null) return ymd;
    return DateFormat('M월 d일 (E)', 'ko').format(parsed);
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.jobRequestId == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: item.jobRequestId!)),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  children: [
                    Text(formatKstTime(item.startsAt), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(formatKstTime(item.endsAt), style: const TextStyle(color: AppColors.body)),
                  ],
                ),
              ),
              Container(width: 1, height: 42, color: AppColors.border),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${serviceTypeLabel(item.serviceType)} · ${scheduleStatusLabel(item.status)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.recipientName != null) item.recipientName!,
                        regionLabel(item.recipientRegionCode),
                        if (item.centerName != null) item.centerName!,
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.body),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
