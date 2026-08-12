import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/jobs_controller.dart';
import '../state/notifications_controller.dart';
import '../state/profile_controller.dart';
import '../state/schedules_controller.dart';
import '../theme/app_theme.dart';
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
    final invited = context.watch<JobsController>().invitedCount;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CallsScreen(),
          ScheduleScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.primarySoft,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: invited > 0,
              label: Text('$invited'),
              child: const Icon(Icons.campaign_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: invited > 0,
              label: Text('$invited'),
              child: const Icon(Icons.campaign),
            ),
            label: '콜',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '일정',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: '알림',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '내정보',
          ),
        ],
      ),
    );
  }
}
