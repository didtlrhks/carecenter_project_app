import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/job_request.dart';
import '../services/api_client.dart';

class JobsController extends ChangeNotifier {
  JobsController(this._api);

  final ApiClient _api;

  List<JobRequest> items = [];
  bool loading = false;
  String? error;

  List<JobRequest> get active =>
      items.where((j) => j.isActive).toList()..sort(_byInvitedDesc);

  List<JobRequest> get past =>
      items.where((j) => j.isPast).toList()..sort(_byInvitedDesc);

  int get invitedCount => items.where((j) => j.isInvited).length;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final all = <JobRequest>[];
      var page = 1;
      while (true) {
        final result = await _api.myJobRequests(page: page, pageSize: 50);
        all.addAll(result.items);
        if (!result.hasMore) break;
        page += 1;
        if (page > 10) break;
      }
      items = all;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = '콜 목록을 불러오지 못했습니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void upsert(JobRequest job) {
    final index = items.indexWhere((j) => j.id == job.id);
    if (index >= 0) {
      items[index] = job;
    } else {
      items.insert(0, job);
    }
    notifyListeners();
  }

  static int _byInvitedDesc(JobRequest a, JobRequest b) {
    final at = a.invitedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b.invitedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  }
}
