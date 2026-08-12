import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/caregiver_profile.dart';
import '../services/api_client.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._api);

  final ApiClient _api;

  CaregiverProfile? profile;
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _api.myCaregiver();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = '프로필을 불러오지 못했습니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setAccepts({bool? backup, bool? neu}) async {
    final current = profile;
    if (current == null) return;
    profile = current.copyWith(
      acceptsBackup: backup ?? current.acceptsBackup,
      acceptsNew: neu ?? current.acceptsNew,
    );
    notifyListeners();
    try {
      await _api.patchCaregiver(acceptsBackup: backup, acceptsNew: neu);
      await refresh();
    } on ApiException catch (e) {
      error = e.message;
      await refresh();
      rethrow;
    }
  }

  Future<void> setHasVehicle(bool value) async {
    final current = profile;
    if (current == null) return;
    profile = current.copyWith(hasVehicle: value);
    notifyListeners();
    try {
      await _api.patchCaregiver(hasVehicle: value);
      await refresh();
    } on ApiException catch (e) {
      error = e.message;
      await refresh();
      rethrow;
    }
  }

  Future<void> setGender(String gender) async {
    await _api.patchCaregiver(gender: gender);
    await refresh();
  }

  Future<void> saveAvailabilities(List<Availability> items) async {
    await _api.replaceAvailabilities(items);
    await refresh();
  }

  Future<void> saveServiceAreas(List<String> regionCodes) async {
    await _api.replaceServiceAreas(regionCodes);
    await refresh();
  }
}
