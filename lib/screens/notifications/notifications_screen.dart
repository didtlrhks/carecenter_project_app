import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_item.dart';
import '../../state/jobs_controller.dart';
import '../../state/notifications_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/labels.dart';
import '../../widgets/empty_state.dart';
import '../calls/job_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ctrl.refresh(),
            context.read<JobsController>().refresh(),
          ]);
        },
        child: ctrl.loading && ctrl.items.isEmpty
            ? ListView(children: const [SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))])
            : ctrl.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 360,
                        child: EmptyState(
                          icon: Icons.notifications_none,
                          title: '알림이 없습니다',
                          subtitle: '알림이 오면 여기에 표시됩니다.',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: ctrl.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _Tile(item: ctrl.items[i]),
                  ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final copy = notificationCopy(item.type, item.title);
    return Card(
      color: item.isUnread ? AppColors.primarySoft : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await context.read<NotificationsController>().markRead(item);
          final jobId = item.targetJobRequestId;
          if (jobId == null || !context.mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: jobId)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon(item.type), color: item.isUnread ? AppColors.primaryDark : AppColors.body),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copy, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.body, style: const TextStyle(color: AppColors.body, height: 1.35)),
                    ],
                    const SizedBox(height: 6),
                    Text(formatRelativeKst(item.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              if (item.isUnread)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 8),
                  child: CircleAvatar(radius: 5, backgroundColor: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'JOB_REQUEST_INVITED':
        return Icons.campaign_outlined;
      case 'ASSIGNED':
        return Icons.check_circle_outline;
      case 'NOT_SELECTED':
        return Icons.event_busy_outlined;
      case 'JOB_REQUEST_CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
