import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class VersionService {
  static const String _minAppVersionKey = 'min_app_version';
  static const String _forceUpdateUrlKey = 'force_update_url';

  FirebaseRemoteConfig? _remoteConfig;
  
  bool _needsUpdate = false;
  String _updateUrl = '';
  String _currentVersion = '';
  String _minVersion = '';

  bool get needsUpdate => _needsUpdate;
  String get updateUrl => _updateUrl;
  String get currentVersion => _currentVersion;
  String get minVersion => _minVersion;

  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      final config = _remoteConfig!;

      // Set default values
      await config.setDefaults({
        _minAppVersionKey: '1.0.0',
        _forceUpdateUrlKey: 'https://play.google.com/store/apps/details?id=com.maintens.app', // Replace with actual URL
      });

      // Configure settings
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // Fetch and activate
      await config.fetchAndActivate();

      // Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // Get min version from remote config
      _minVersion = config.getString(_minAppVersionKey);
      _updateUrl = config.getString(_forceUpdateUrlKey);

      // Compare versions
      _needsUpdate = _shouldUpdate(_currentVersion, _minVersion);
      
      if (kDebugMode) {
        print('Version Check: Current=$_currentVersion, Min=$_minVersion, NeedsUpdate=$_needsUpdate');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing VersionService: $e');
      }
    }
  }

  bool _shouldUpdate(String current, String min) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = min.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final minPart = i < minParts.length ? minParts[i] : 0;

        if (currentPart < minPart) return true;
        if (currentPart > minPart) return false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing versions: $e');
      }
      return false;
    }
  }
}
