import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/core/services/draft_service.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';

class AppInstallService {
  static const String installIdKey = 'app_install_id';

  final RudnAuthService _authService;
  final DraftService _draftService;
  final Future<SharedPreferences> Function() _sharedPreferencesFactory;
  final String Function() _idGenerator;

  AppInstallService({
    RudnAuthService? authService,
    DraftService? draftService,
    Future<SharedPreferences> Function()? sharedPreferencesFactory,
    String Function()? idGenerator,
  })  : _authService = authService ?? RudnAuthService(),
        _draftService = draftService ?? DraftService(),
        _sharedPreferencesFactory =
            sharedPreferencesFactory ?? SharedPreferences.getInstance,
        _idGenerator = idGenerator ?? _defaultInstallId;

  Future<void> ensureInstallConsistency() async {
    final prefs = await _sharedPreferencesFactory();
    final existingInstallId = prefs.getString(installIdKey);
    if (existingInstallId != null && existingInstallId.isNotEmpty) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'AppInstallService: fresh install detected, clearing secure session data',
      );
    }

    await _authService.clearSecureData();
    await _draftService.clearAllDrafts();
    await prefs.setString(installIdKey, _idGenerator());
  }

  static String _defaultInstallId() {
    final randomPart = Random.secure().nextInt(1 << 32);
    return '${DateTime.now().microsecondsSinceEpoch}-$randomPart';
  }
}
