import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/jobs_controller.dart';
import '../state/notifications_controller.dart';
import '../state/profile_controller.dart';
import '../state/schedules_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'calls/calls_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'schedule/schedule_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  int _index = 0;
  late final NotificationsController _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationsController>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
    _notifications.startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notifications.startPolling();
      _notifications.refresh(silent: true);
      context.read<JobsController>().refresh();
      context.read<SchedulesController>().refresh();
    } else if (state == AppLifecycleState.paused) {
      _notifications.stopPolling();
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<JobsController>().refresh(),
      context.read<SchedulesController>().refresh(),
      context.read<NotificationsController>().refresh(),
      context.read<ProfileController>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsController>().unreadCount;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _index,
        children: const [
          CallsScreen(),
          ScheduleScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        notificationBadge: unread,
      ),
    );
  }
}
