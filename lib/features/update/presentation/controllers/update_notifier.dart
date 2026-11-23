import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../tracker/presentation/controllers/library_notifier.dart';
import '../../data/update_service.dart';
import '../../domain/models/app_update_model.dart';
import '../screens/update_screen.dart';

class UpdateState {
  final bool isChecking;
  final bool isDownloading;
  final double downloadProgress;
  final AppUpdate? availableUpdate;
  final String currentVersion;
  final int currentBuildNumber;
  final bool hasChecked;
  final String? errorMessage;

  const UpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.availableUpdate,
    this.currentVersion = '1.0.0',
    this.currentBuildNumber = 1,
    this.hasChecked = false,
    this.errorMessage,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    double? downloadProgress,
    AppUpdate? availableUpdate,
    bool clearAvailableUpdate = false,
    String? currentVersion,
    int? currentBuildNumber,
    bool? hasChecked,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      availableUpdate: clearAvailableUpdate ? null : (availableUpdate ?? this.availableUpdate),
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      hasChecked: hasChecked ?? this.hasChecked,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  try {
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    return UpdateService(settingsRepo);
  } catch (_) {
    return UpdateService(null);
  }
});

final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final service = ref.watch(updateServiceProvider);
  return UpdateNotifier(service);
});

class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _service;

  UpdateNotifier(this._service) : super(const UpdateState()) {
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = state.copyWith(
        currentVersion: info.version,
        currentBuildNumber: int.tryParse(info.buildNumber) ?? 1,
      );
    } catch (e) {
      debugPrint('UpdateNotifier: Error loading package info: $e');
    }
  }

  /// Automatically check for updates on cold start (respects 24h deferral)
  Future<void> checkSilentlyOnLaunch(BuildContext context) async {
    try {
      await _loadPackageInfo();
      final update = await _service.checkForUpdate(respectDeferral: true);
      if (update != null && context.mounted) {
        state = state.copyWith(availableUpdate: update, hasChecked: true);
        _navigateToUpdateScreen(context, update);
      }
    } catch (e) {
      debugPrint('UpdateNotifier: Silent launch update check error: $e');
    }
  }

  /// Triggered manually from Settings screen
  Future<AppUpdate?> checkForUpdatesManual(BuildContext context) async {
    state = state.copyWith(isChecking: true, clearErrorMessage: true);

    try {
      await _loadPackageInfo();
      final update = await _service.checkForUpdate(respectDeferral: false);

      state = state.copyWith(
        isChecking: false,
        hasChecked: true,
        availableUpdate: update,
        clearAvailableUpdate: update == null,
      );

      if (update != null && context.mounted) {
        _navigateToUpdateScreen(context, update);
      }

      return update;
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        hasChecked: true,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void _navigateToUpdateScreen(BuildContext context, AppUpdate update) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UpdateScreen(update: update),
      ),
    );
  }

  /// Download and install the update APK
  Future<void> downloadAndInstall({
    required BuildContext context,
    required AppUpdate update,
  }) async {
    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    try {
      final file = await _service.downloadAPK(
        update.version,
        downloadUrl: update.downloadUrl,
        onProgress: (progress) {
          state = state.copyWith(downloadProgress: progress);
        },
      );

      if (file == null) {
        state = state.copyWith(
          isDownloading: false,
          errorMessage: 'Failed to download APK package.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download update package.')),
          );
        }
        return;
      }

      state = state.copyWith(isDownloading: false, downloadProgress: 1.0);

      // Trigger installation
      final result = await _service.installAPK(file);
      if (!context.mounted) return;

      switch (result) {
        case InstallResult.installerStarted:
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Package installer opened. Complete update to continue.')),
          );
          break;
        case InstallResult.permissionRequired:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permission required: Allow installation from this source.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => _service.openInstallPermissionSettings(),
              ),
              duration: const Duration(seconds: 6),
            ),
          );
          break;
        case InstallResult.installerUnavailable:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No package installer found on this device.')),
          );
          break;
        case InstallResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to launch installer. APK preserved in downloads.')),
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        errorMessage: e.toString(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e')),
        );
      }
    }
  }

  /// Defer update prompt for 24 hours
  Future<void> deferUpdate(BuildContext context) async {
    await _service.deferUpdate();
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update deferred for 24 hours.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
