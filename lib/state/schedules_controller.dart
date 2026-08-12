import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/schedule.dart';
import '../services/api_client.dart';
import '../utils/date_format.dart';

class SchedulesController extends ChangeNotifier {
  SchedulesController(this._api);

  final ApiClient _api;

  List<ScheduleItem> items = [];
  bool loading = false;
  String? error;

  /// 지원 중인 건은 서버가 내려주지 않는다. 확정 근무만 표시.
  List<ScheduleItem> get confirmed =>
      items.where((s) => s.status != 'CANCELLED').toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  Map<String, List<ScheduleItem>> groupedByDay() {
    final map = <String, List<ScheduleItem>>{};
    for (final item in confirmed) {
      final key = ymdKst(item.startsAt);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final all = <ScheduleItem>[];
      var page = 1;
      while (true) {
        final result = await _api.mySchedules(page: page, pageSize: 50);
        all.addAll(result.items);
        if (!result.hasMore) break;
        page += 1;
        if (page > 10) break;
      }
      items = all;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = '일정을 불러오지 못했습니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
