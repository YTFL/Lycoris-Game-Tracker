import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/text_field_helper.dart';
import '../../../search/data/igdb_cache_service.dart';
import '../../../search/data/igdb_service.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';
import '../../data/offline_backup_service.dart';
import '../../data/saf_storage_service.dart';
import '../controllers/settings_notifier.dart';
import '../../../update/presentation/controllers/update_notifier.dart';
import 'markdown_viewer_screen.dart';
import 'tab_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _proxyUrlController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientSecretController;

  bool _isTestingConnection = false;
  String? _testConnectionResult;
  bool? _testConnectionSuccess;
  bool _isSyncingRates = false;
  bool _useDeveloperApi = false;
  bool _isEditingSecret = false;

  int _cacheSizeBytes = 0;
  bool _isClearingCache = false;

  void _showNotification(
    String message, {
    bool isError = false,
    IconData? icon,
  }) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isError
                  ? colorScheme.error.withAlpha(120)
                  : colorScheme.primary.withAlpha(80),
            ),
          ),
          content: Row(
            children: [
              Icon(
                icon ?? (isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded),
                size: 20,
                color: isError ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _useDeveloperApi = settings.useDeveloperApi;
    _proxyUrlController = TextEditingController(
      text: settings.workerProxyUrl.isNotEmpty ? settings.workerProxyUrl : ApiConstants.igdbProxyUrl,
    );
    _clientIdController = TextEditingController(text: settings.twitchClientId);
    _clientSecretController = TextEditingController();
    _loadCacheStats();
  }

  @override
  void dispose() {
    _proxyUrlController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _loadCacheStats() async {
    final cacheService = ref.read(igdbCacheServiceProvider);
    final bytes = await cacheService.getSizeBytes();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = bytes;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testConnectionResult = null;
      _testConnectionSuccess = null;
    });

    final service = IGDBService(
      workerProxyUrl: _proxyUrlController.text.trim(),
      cacheService: ref.read(igdbCacheServiceProvider),
    );
    final success = await service.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _testConnectionSuccess = success;
        _testConnectionResult = success
            ? 'Proxy operational'
            : 'Connection failed';
      });
    }
  }

  Future<void> _saveSettings() async {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    await notifier.updateUseDeveloperApi(_useDeveloperApi);
    if (!_useDeveloperApi) {
      final proxyUrl = _proxyUrlController.text.trim();
      await notifier.updateWorkerProxyUrl(proxyUrl);
    } else {
      await notifier.updateTwitchCredentials(
        clientId: _clientIdController.text.trim(),
        clientSecret: _clientSecretController.text.trim().isNotEmpty
            ? _clientSecretController.text.trim()
            : null,
      );
      _clientSecretController.clear();
      _isEditingSecret = false;
    }

    if (mounted) {
      setState(() {});
      _showNotification('Settings saved successfully.');
    }
  }

  Future<void> _resetProxyToDefault() async {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    await notifier.resetWorkerProxyUrl();
    _proxyUrlController.text = ApiConstants.igdbProxyUrl;
    if (mounted) {
      setState(() {});
      _showNotification('Proxy URL reset to default.', icon: Icons.restart_alt_rounded);
    }
  }

  Future<void> _confirmClearCache() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 28),
            const SizedBox(width: 10),
            const Text('Clear Metadata Cache?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clearing the local metadata cache will permanently delete all stored game details and search indexes.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.error.withAlpha(90)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Warning:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Future searches will need to query IGDB over the network, causing slower searches.\n'
                    '• Sending frequent queries without cache may trigger IGDB rate limits (Too Many Requests / HTTP 429).\n'
                    '• Offline search for uncached titles will be unavailable.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to proceed?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isClearingCache = true);
      await ref.read(igdbCacheServiceProvider).clearCache();
      await _loadCacheStats();
      if (mounted) {
        setState(() => _isClearingCache = false);
        _showNotification('Metadata cache successfully cleared.');
      }
    }
  }

  Future<void> _handleFileImport() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFiles.isNotEmpty) {
        final file = pickedFiles.first;
        final fileBytes = await file.readAsBytes();
        final content = utf8.decode(fileBytes);

        if (content.isNotEmpty) {
          final count = await ref.read(settingsNotifierProvider.notifier).importFromJson(content);
          if (mounted) {
            _showNotification('Imported $count entries via LWW merge!');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotification('Import failed: $e', isError: true);
      }
    }
  }

  Future<void> _handleSyncRates({bool force = false}) async {
    setState(() => _isSyncingRates = true);
    final success = await ref
        .read(exchangeRatesNotifierProvider.notifier)
        .manualSync(force: force);

    if (mounted) {
      setState(() => _isSyncingRates = false);
      if (success) {
        _showNotification('Exchange rates updated successfully!');
      } else {
        final rates = ref.read(exchangeRatesNotifierProvider);
        final remaining = ExchangeRateService.timeUntilNextSync(rates: rates);
        final cooldownText = ExchangeRateService.formatCooldownRemaining(remaining);
        _showNotification(
          ExchangeRateService.canSync(rates: rates)
              ? 'Failed to fetch live exchange rates. Check connection.'
              : '24-hour sync cooldown active. Next sync in $cooldownText.',
          isError: true,
          icon: Icons.schedule_rounded,
        );
      }
    }
  }

  Future<void> _showCurrencyPicker(BuildContext context, String currentCurrency) async {
    await CurrencyHelper.showCurrencyPicker(
      context,
      currentCurrency: currentCurrency,
      onSelected: (code) async {
        await ref.read(settingsNotifierProvider.notifier).updatePrimaryCurrency(code);
      },
    );
  }

  String _formatDirectoryDisplay(String rawPath) {
    if (rawPath.startsWith('content://')) {
      final segments = rawPath.split('%3A');
      if (segments.length > 1) {
        final decoded = Uri.decodeComponent(segments.last);
        return decoded.isNotEmpty ? decoded : 'Root Storage';
      }
      return 'Selected Folder';
    }
    return rawPath;
  }

  Future<void> _handlePickBackupDirectory() async {
    try {
      String? selectedDirectory;

      if (!kIsWeb && Platform.isAndroid) {
        final result = await SafStorageService.pickFolder();
        if (result != null) {
          selectedDirectory = result.uri;
        }
      } else {
        selectedDirectory = await FilePicker.getDirectoryPath(
          dialogTitle: 'Select Lycoris Backup Folder',
        );
      }

      if (selectedDirectory != null && selectedDirectory.trim().isNotEmpty) {
        final success = await ref
            .read(settingsNotifierProvider.notifier)
            .setBackupDirectory(selectedDirectory.trim());

        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: success
                      ? colorScheme.primary.withAlpha(80)
                      : colorScheme.error.withAlpha(120),
                ),
              ),
              content: Row(
                children: [
                  Icon(
                    success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                    size: 20,
                    color: success ? colorScheme.primary : colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      success
                          ? 'Backup folder configured! Initial 2-stage backup created.'
                          : 'Failed to access folder. Ensure write permission or choose another folder.',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.error.withAlpha(120)),
            ),
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 20, color: colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Error selecting folder: $e',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleClearBackupDirectory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Backup Folder?'),
        content: const Text(
          'Automated 2-stage offline backups will be paused until a folder is selected again. Existing backup files in the folder will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(settingsNotifierProvider.notifier).clearBackupDirectory();
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
          ),
          content: Row(
            children: [
              Icon(Icons.folder_off_outlined, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Backup folder disconnected.',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleManualOfflineBackup() async {
    final settings = ref.read(settingsNotifierProvider);
    if (settings.backupDirectoryPath == null || settings.backupDirectoryPath!.isEmpty) {
      await _handlePickBackupDirectory();
      return;
    }

    final success = await ref
        .read(settingsNotifierProvider.notifier)
        .triggerOfflineBackupNow();

    if (mounted) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: success
                  ? colorScheme.primary.withAlpha(80)
                  : colorScheme.error.withAlpha(120),
            ),
          ),
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                size: 20,
                color: success ? colorScheme.primary : colorScheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'Backup created successfully!'
                      : 'Failed to create offline backup.',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _showRestoreFromFolderDialog(
    OfflineBackupInfo info,
    String folderPath,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!info.hasAnyBackup) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Backups Found'),
          content: Text('No backup files were found in:\n$folderPath\n\nCreate a backup first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    String selectedFileName = info.hasCurrent
        ? OfflineBackupService.currentBackupFileName
        : OfflineBackupService.previousBackupFileName;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.history_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Restore from Folder'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select which backup file to restore into your library:',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: selectedFileName,
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedFileName = val);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (info.hasCurrent)
                      RadioListTile<String>(
                        value: OfflineBackupService.currentBackupFileName,
                        title: const Text(
                          'Current Backup',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${info.currentModified != null ? DateFormat.yMMMd().add_jms().format(info.currentModified!) : "Unknown date"} • ${_formatFileSize(info.currentSizeBytes)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    if (info.hasPrevious)
                      RadioListTile<String>(
                        value: OfflineBackupService.previousBackupFileName,
                        title: const Text(
                          'Previous Backup',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${info.previousModified != null ? DateFormat.yMMMd().add_jms().format(info.previousModified!) : "Unknown date"} • ${_formatFileSize(info.previousSizeBytes)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data will be merged via Last-Write-Wins (newer entries take precedence).',
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant.withAlpha(180)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selectedFileName),
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      final fullPath = folderPath.startsWith('content://')
          ? folderPath
          : p.join(folderPath, selected);
      final count = await ref
          .read(settingsNotifierProvider.notifier)
          .restoreFromOfflineFile(fullPath, fileName: selected, folderUri: folderPath);

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.primary.withAlpha(80)),
            ),
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Restored $count entries from $selected!',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  static String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showNotification('Could not open $urlString', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showNotification('Error opening link: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsNotifierProvider);
    final exchangeRates = ref.watch(exchangeRatesNotifierProvider);
    final updateState = ref.watch(updateNotifierProvider);
    final currentCurrencyOption = CurrencyHelper.getOption(settings.primaryCurrency);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings_outlined, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Home Tabs & Categories Customization
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, color: colorScheme.primary, size: 22),
                ),
                title: const Text(
                  'Customize Tabs & Categories',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Mix, match, reorder tabs, or manage custom categories',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TabManagementScreen()),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Game Metadata (Proxy vs Developer API)
          _buildCard(
            context: context,
            title: 'Game Metadata',
            subtitle: 'Source for game covers and details.',
            icon: Icons.cloud_outlined,
            children: [
              // Segmented Button Toggle
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Proxy'),
                      icon: Icon(Icons.cloud_outlined),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Developer API'),
                      icon: Icon(Icons.vpn_key_rounded),
                    ),
                  ],
                  selected: {_useDeveloperApi},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _useDeveloperApi = newSelection.first;
                      _testConnectionResult = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),

              if (!_useDeveloperApi) ...[
                // Proxy Configuration
                TextField(
                  controller: _proxyUrlController,
                  onTap: () => TextFieldHelper.selectAll(_proxyUrlController),
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    context,
                    label: 'Proxy URL',
                    hint: 'https://lycoris-proxy.workers.dev',
                    icon: Icons.link_rounded,
                  ),
                ),
                if (_proxyUrlController.text.trim() != ApiConstants.igdbProxyUrl) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('Reset to Default'),
                      onPressed: _resetProxyToDefault,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Action Buttons in the SAME ROW: Test & Save
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isTestingConnection
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.network_check_rounded, size: 16),
                        label: const Text('Test'),
                        onPressed: _isTestingConnection ? null : _testConnection,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save'),
                        onPressed: _saveSettings,
                      ),
                    ),
                  ],
                ),
                if (_testConnectionResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _testConnectionSuccess == true
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.errorContainer.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _testConnectionSuccess == true
                            ? colorScheme.primary.withAlpha(80)
                            : colorScheme.error.withAlpha(120),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testConnectionSuccess == true
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          size: 16,
                          color: _testConnectionSuccess == true
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testConnectionResult!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _testConnectionSuccess == true
                                  ? colorScheme.onSurface
                                  : colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Developer API Configuration
                TextField(
                  controller: _clientIdController,
                  onTap: () => TextFieldHelper.selectAll(_clientIdController),
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    context,
                    label: 'Client ID',
                    hint: 'Twitch Client ID',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 10),
                if (settings.hasTwitchClientSecret && !_isEditingSecret) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Secret: ••••••••••••',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isEditingSecret = true),
                          child: const Text('Change'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          tooltip: 'Remove',
                          onPressed: () async {
                            await ref.read(settingsNotifierProvider.notifier).clearTwitchCredentials();
                            _clientIdController.clear();
                            _clientSecretController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _clientSecretController,
                    onTap: () => TextFieldHelper.selectAll(_clientSecretController),
                    obscureText: true,
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      context,
                      label: 'Client Secret',
                      hint: 'Twitch Client Secret',
                      icon: Icons.password_rounded,
                    ),
                  ),
                  if (settings.hasTwitchClientSecret) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _isEditingSecret = false),
                        child: const Text('Cancel changing secret'),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 14),
                // Only Save button for Developer API
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Save'),
                    onPressed: _saveSettings,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // 2. Metadata Cache Management Card
          _buildCard(
            context: context,
            title: 'Metadata Cache',
            subtitle: 'Offline storage for searched games.',
            icon: Icons.storage_rounded,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Size: ${IGDBCacheService.formatBytes(_cacheSizeBytes)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withAlpha(120)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: _isClearingCache
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.error,
                            ),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Clear'),
                    onPressed: _isClearingCache ? null : _confirmClearCache,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Display Currency & Live FX Rates
          _buildCard(
            context: context,
            title: 'Display Currency & FX Rates',
            subtitle: 'Base currency and live exchange rates.',
            icon: Icons.currency_exchange_rounded,
            children: [
              // Primary Currency Tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CurrencySymbolBox(
                  currencyCode: currentCurrencyOption.code,
                  size: 38,
                  backgroundColor: colorScheme.primaryContainer.withAlpha(120),
                  textColor: colorScheme.primary,
                ),
                title: const Text(
                  'Primary Currency',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${currentCurrencyOption.name} (${currentCurrencyOption.symbol})',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => _showCurrencyPicker(context, settings.primaryCurrency),
              ),

              Divider(color: colorScheme.outlineVariant.withAlpha(50), height: 24),

              // Exchange Rates Sync Tile
              Builder(
                builder: (context) {
                  final canSync = ExchangeRateService.canSync(rates: exchangeRates);
                  final remaining = ExchangeRateService.timeUntilNextSync(rates: exchangeRates);
                  final cooldownText = ExchangeRateService.formatCooldownRemaining(remaining);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.sync_rounded, color: colorScheme.primary, size: 22),
                    ),
                    title: const Text(
                      'Live Exchange Rates',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      exchangeRates.isSeed
                          ? 'Using baseline offline rates. Tap to sync live rates.'
                          : 'Synced: ${DateFormat.yMMMd().add_jm().format(exchangeRates.lastUpdated)} ${canSync ? "• Ready to sync" : "• Next in $cooldownText"}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: _isSyncingRates
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: canSync ? 'Fetch live FX rates' : 'Cooldown active ($cooldownText)',
                            onPressed: () => _handleSyncRates(),
                          ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4. Google Drive AppData Sync
          _buildCard(
            context: context,
            title: 'Google Drive Sync',
            subtitle: 'Cloud backup with user-owned Google Drive storage.',
            icon: Icons.cloud_sync_rounded,
            children: [
              // Google Account Status - Clean email display with small logout icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        settings.isGoogleDriveSignedIn
                            ? (settings.googleUserEmail ?? 'Connected')
                            : 'Not signed in',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: settings.isGoogleDriveSignedIn
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (settings.isGoogleDriveSignedIn)
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        tooltip: 'Logout',
                        visualDensity: VisualDensity.compact,
                        color: colorScheme.onSurfaceVariant,
                        onPressed: () => ref.read(settingsNotifierProvider.notifier).signOutGoogleDrive(),
                      )
                    else
                      TextButton(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () => ref.read(settingsNotifierProvider.notifier).signInGoogleDrive(),
                        child: const Text('Sign In'),
                      ),
                  ],
                ),
              ),

              if (settings.lastSyncedAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Last Cloud Sync: ${DateFormat.yMMMd().add_jms().format(settings.lastSyncedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],

              if (settings.syncStatusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  settings.syncStatusMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: settings.isSyncing
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Backup'),
                      onPressed: settings.isSyncing
                          ? null
                          : () => ref.read(settingsNotifierProvider.notifier).backupToDrive(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: settings.isSyncing
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.cloud_download_outlined, size: 18),
                      label: const Text('Restore'),
                      onPressed: settings.isSyncing
                          ? null
                          : () => ref.read(settingsNotifierProvider.notifier).restoreFromDrive(),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 5. Offline JSON File Backup & Portability
          _buildCard(
            context: context,
            title: 'Offline JSON Backup',
            subtitle: 'Automated 2-stage rotating local backup.',
            icon: Icons.folder_copy_outlined,
            children: [
              if (settings.backupDirectoryPath != null) ...[
                // Folder Status Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_open_rounded, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDirectoryDisplay(settings.backupDirectoryPath!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Change Folder',
                            onPressed: _handlePickBackupDirectory,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Disconnect Folder',
                            onPressed: _handleClearBackupDirectory,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Current and Previous status details
                      Builder(
                        builder: (context) {
                          final info = settings.offlineBackupInfo ?? OfflineBackupInfo.empty;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• Current: ${info.hasCurrent ? "${info.currentModified != null ? DateFormat.yMMMd().add_jm().format(info.currentModified!) : "Ready"} (${_formatFileSize(info.currentSizeBytes)})" : "None yet"}',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '• Previous: ${info.hasPrevious ? "${info.previousModified != null ? DateFormat.yMMMd().add_jm().format(info.previousModified!) : "Saved"} (${_formatFileSize(info.previousSizeBytes)})" : "None yet"}',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: settings.isOfflineBackingUp
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.backup_rounded, size: 18),
                        label: const Text('Backup Now'),
                        onPressed: settings.isOfflineBackingUp ? null : _handleManualOfflineBackup,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.history_rounded, size: 18),
                        label: const Text('Restore...'),
                        onPressed: () {
                          final info = settings.offlineBackupInfo ?? OfflineBackupInfo.empty;
                          _showRestoreFromFolderDialog(
                            info,
                            settings.backupDirectoryPath!,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Unconfigured State Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_special_outlined, size: 28, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select a folder on your phone to automatically keep 2 rotating JSON backups and cloud sync on database changes.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Select Folder'),
                        onPressed: _handlePickBackupDirectory,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.backup_rounded, size: 18),
                        label: const Text('Backup Now'),
                        onPressed: _handleManualOfflineBackup,
                      ),
                    ),
                  ],
                ),
              ],

              if (settings.offlineBackupStatusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  settings.offlineBackupStatusMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Divider(color: colorScheme.outlineVariant.withAlpha(40), height: 1),
              const SizedBox(height: 12),

              // Manual Portability - Import File Only (Copy JSON removed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_open_rounded, size: 18),
                  label: const Text('Import'),
                  onPressed: _handleFileImport,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 6. Data Management (Danger Zone)
          _buildCard(
            context: context,
            title: 'Reset Library',
            subtitle: 'Permanently delete all local game records.',
            icon: Icons.delete_outline_rounded,
            isDestructive: true,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Clear All Game Records'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer.withAlpha(70),
                  foregroundColor: colorScheme.error,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear All Game Records?'),
                      content: const Text(
                        'This will delete all games, DLCs, and playtime logs from your local database. This cannot be undone unless you have a backup.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete Everything'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(libraryNotifierProvider.notifier).clearAll();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 7. About & Legal
          _buildCard(
            context: context,
            title: 'About & Legal',
            subtitle: 'Release notes, developer showcase, and terms.',
            icon: Icons.info_outline_rounded,
            children: [
              // 1. What's New
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary, size: 20),
                ),
                title: const Text(
                  "What's New",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Release notes and latest changes',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarkdownViewerScreen(
                        title: "What's New",
                        assetPath: 'RELEASE_NOTES.md',
                      ),
                    ),
                  );
                },
              ),

              Divider(color: colorScheme.outlineVariant.withAlpha(50), height: 16),

              // 2. View More Apps by Me
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.apps_rounded, color: colorScheme.primary, size: 20),
                ),
                title: const Text(
                  'View More Apps by Me',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'https://ytfl.github.io/',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                onTap: () => _launchUrl('https://ytfl.github.io/'),
              ),

              Divider(color: colorScheme.outlineVariant.withAlpha(50), height: 16),

              // 3. Terms and Conditions
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_outlined, color: colorScheme.primary, size: 20),
                ),
                title: const Text(
                  'Terms and Conditions',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'AGPL-3.0 License & terms of service',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarkdownViewerScreen(
                        title: 'Terms and Conditions',
                        assetPath: 'docs/terms.md',
                      ),
                    ),
                  );
                },
              ),

              Divider(color: colorScheme.outlineVariant.withAlpha(50), height: 16),

              // 4. Privacy Policy
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.privacy_tip_outlined, color: colorScheme.primary, size: 20),
                ),
                title: const Text(
                  'Privacy Policy',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Zero telemetry & local data sovereignty',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarkdownViewerScreen(
                        title: 'Privacy Policy',
                        assetPath: 'docs/privacy.md',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 8. About Lycoris
          Center(
            child: Column(
              children: [
                Icon(Icons.sports_esports_rounded, size: 28, color: colorScheme.primary),
                const SizedBox(height: 6),
                Text(
                  'Lycoris',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v${updateState.currentVersion} • com.ytfl.lycoris',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: updateState.isChecking
                      ? null
                      : () async {
                          final update = await ref
                              .read(updateNotifierProvider.notifier)
                              .checkForUpdatesManual(context);
                          if (!context.mounted) return;
                          if (update == null) {
                            _showNotification('You are on the latest version.', icon: Icons.check_circle_outline_rounded);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: updateState.availableUpdate != null
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  icon: updateState.isChecking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          updateState.availableUpdate != null
                              ? Icons.system_update_rounded
                              : Icons.refresh_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                  label: Text(
                    updateState.isChecking
                        ? 'Checking...'
                        : updateState.availableUpdate != null
                            ? 'Update Available (${updateState.availableUpdate!.versionInfo})'
                            : 'Check for Updates',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: updateState.availableUpdate != null
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDestructive
              ? colorScheme.error.withAlpha(60)
              : colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? colorScheme.errorContainer.withAlpha(60)
                        : colorScheme.primaryContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: colorScheme.onSurfaceVariant) : null,
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}
