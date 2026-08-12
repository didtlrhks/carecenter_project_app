import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/notification_item.dart';
import '../services/api_client.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController(this._api);

  final ApiClient _api;

  List<NotificationItem> items = [];
  bool loading = false;
  String? error;
  Timer? _poll;

  int get unreadCount => items.where((n) => n.isUnread).length;

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 25), (_) {
      unawaited(refresh(silent: true));
    });
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final result = await _api.notifications(page: 1, pageSize: 50);
      items = result.items;
    } on ApiException catch (e) {
      if (!silent) error = e.message;
    } catch (_) {
      if (!silent) error = '알림을 불러오지 못했습니다.';
    } finally {
      if (!silent) loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(NotificationItem item) async {
    if (!item.isUnread) return;
    try {
      final updated = await _api.markNotificationRead(item.id);
      final index = items.indexWhere((n) => n.id == item.id);
      if (index >= 0) items[index] = updated;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
