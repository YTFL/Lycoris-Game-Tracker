import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/secret_crypto.dart';

class SettingsRepository {
  final Box<dynamic> _box;

  static const String keyWorkerProxyUrl = 'worker_proxy_url';
  static const String keyTwitchClientId = 'twitch_client_id';
  static const String keyTwitchBearerToken = 'twitch_bearer_token';
  static const String keyTwitchClientSecretEncrypted = 'twitch_client_secret_encrypted';
  static const String keyPrimaryCurrency = 'primary_currency';
  static const String keyLastSyncedAt = 'last_synced_at';
  static const String keyShelfViewMode = 'shelf_view_mode';
  static const String keyUseDeveloperApi = 'use_developer_api';
  static const String keyBackupDirectoryPath = 'backup_directory_path';
  static const String keyLastOfflineBackupAt = 'last_offline_backup_at';
  static const String keyLastOfflineBackupStatus = 'last_offline_backup_status';
  static const String keyUpdateDeferredUntil = 'update_deferred_until';
  static const String keyLastUpdateCheckAt = 'last_update_check_at';

  SettingsRepository(this._box);

  ValueListenable<Box<dynamic>> listenable() => _box.listenable();

  String get workerProxyUrl {
    final stored = _box.get(keyWorkerProxyUrl) as String?;
    if (stored == null || stored.trim().isEmpty) {
      return ApiConstants.igdbProxyUrl;
    }
    return stored.trim();
  }

  Future<void> setWorkerProxyUrl(String value) => _box.put(keyWorkerProxyUrl, value.trim());

  Future<void> resetWorkerProxyUrl() => _box.put(keyWorkerProxyUrl, ApiConstants.igdbProxyUrl);

  String get twitchClientId => _box.get(keyTwitchClientId, defaultValue: '') as String;
  Future<void> setTwitchClientId(String value) => _box.put(keyTwitchClientId, value.trim());

  bool get hasTwitchClientSecret {
    final encrypted = _box.get(keyTwitchClientSecretEncrypted, defaultValue: '') as String;
    return encrypted.isNotEmpty;
  }

  Future<void> setTwitchClientSecret(String rawSecret) async {
    final trimmed = rawSecret.trim();
    if (trimmed.isEmpty) {
      await _box.delete(keyTwitchClientSecretEncrypted);
    } else {
      final encrypted = SecretCrypto.encrypt(trimmed);
      await _box.put(keyTwitchClientSecretEncrypted, encrypted);
    }
  }

  String? getDecryptedTwitchClientSecret() {
    final encrypted = _box.get(keyTwitchClientSecretEncrypted, defaultValue: '') as String;
    if (encrypted.isEmpty) return null;
    return SecretCrypto.decrypt(encrypted);
  }

  Future<void> clearTwitchCredentials() async {
    await _box.delete(keyTwitchClientId);
    await _box.delete(keyTwitchBearerToken);
    await _box.delete(keyTwitchClientSecretEncrypted);
  }

  String get twitchBearerToken => _box.get(keyTwitchBearerToken, defaultValue: '') as String;
  Future<void> setTwitchBearerToken(String value) => _box.put(keyTwitchBearerToken, value);

  String get primaryCurrency => _box.get(keyPrimaryCurrency, defaultValue: 'USD') as String;
  Future<void> setPrimaryCurrency(String value) => _box.put(keyPrimaryCurrency, value);

  DateTime? get lastSyncedAt {
    final millis = _box.get(keyLastSyncedAt);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis as int) : null;
  }

  Future<void> setLastSyncedAt(DateTime date) =>
      _box.put(keyLastSyncedAt, date.millisecondsSinceEpoch);

  String get shelfViewMode => _box.get(keyShelfViewMode, defaultValue: 'grid') as String;
  Future<void> setShelfViewMode(String mode) => _box.put(keyShelfViewMode, mode);

  bool get useDeveloperApi => _box.get(keyUseDeveloperApi, defaultValue: false) as bool;
  Future<void> setUseDeveloperApi(bool value) => _box.put(keyUseDeveloperApi, value);

  String? get backupDirectoryPath => _box.get(keyBackupDirectoryPath) as String?;
  Future<void> setBackupDirectoryPath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await _box.delete(keyBackupDirectoryPath);
    } else {
      await _box.put(keyBackupDirectoryPath, path.trim());
    }
  }

  DateTime? get lastOfflineBackupAt {
    final millis = _box.get(keyLastOfflineBackupAt);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis as int) : null;
  }

  Future<void> setLastOfflineBackupAt(DateTime date) =>
      _box.put(keyLastOfflineBackupAt, date.millisecondsSinceEpoch);

  String? get lastOfflineBackupStatus => _box.get(keyLastOfflineBackupStatus) as String?;
  Future<void> setLastOfflineBackupStatus(String? status) async {
    if (status == null) {
      await _box.delete(keyLastOfflineBackupStatus);
    } else {
      await _box.put(keyLastOfflineBackupStatus, status);
    }
  }

  DateTime? get updateDeferredUntil {
    final millis = _box.get(keyUpdateDeferredUntil);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis as int) : null;
  }

  Future<void> setUpdateDeferredUntil(DateTime date) =>
      _box.put(keyUpdateDeferredUntil, date.millisecondsSinceEpoch);

  Future<void> clearUpdateDeferral() => _box.delete(keyUpdateDeferredUntil);

  DateTime? get lastUpdateCheckAt {
    final millis = _box.get(keyLastUpdateCheckAt);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis as int) : null;
  }

  Future<void> setLastUpdateCheckAt(DateTime date) =>
      _box.put(keyLastUpdateCheckAt, date.millisecondsSinceEpoch);
}
