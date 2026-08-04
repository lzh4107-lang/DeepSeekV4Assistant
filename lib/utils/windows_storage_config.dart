import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

/// Keeps this application's persistent Windows data off the system drive when
/// a fixed D: drive is available.
class WindowsStorageConfig {
  WindowsStorageConfig._();

  static const String dataRoot = r'D:\DeepSeekV4AssistantData';
  static const String appDirectoryName = 'DeepSeek V4 Assistant';
  static const String _migrationMarkerName = '.d_drive_storage_v1';

  static bool get shouldUseDDrive =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.windows &&
      Directory(r'D:\').existsSync();

  /// Redirects path_provider and both shared_preferences Windows backends.
  /// Returns true when D: storage is active.
  static Future<bool> configure() async {
    if (!shouldUseDDrive) return false;

    final originalPathProvider = PathProviderPlatform.instance;
    final dDriveProvider = DDrivePathProviderWindows();
    String? supportPath;
    try {
      supportPath = await dDriveProvider.getApplicationSupportPath();
      await dDriveProvider.getApplicationCachePath();
      await dDriveProvider.getTemporaryPath();
    } catch (error) {
      debugPrint('Unable to initialize D-drive storage: $error');
      return false;
    }

    if (supportPath != null) {
      try {
        await _migrateLegacyStorage(originalPathProvider, supportPath);
      } catch (error) {
        debugPrint('Unable to migrate legacy Windows storage: $error');
      }
    }

    PathProviderPlatform.instance = dDriveProvider;

    final preferencesStore = SharedPreferencesStorePlatform.instance;
    if (preferencesStore is SharedPreferencesWindows) {
      // The official Windows plugin exposes this for backend substitution.
      // ignore: invalid_use_of_visible_for_testing_member
      preferencesStore.pathProvider = dDriveProvider;
    }

    try {
      final asyncPreferencesStore = SharedPreferencesAsyncPlatform.instance;
      if (asyncPreferencesStore is SharedPreferencesAsyncWindows) {
        // ignore: invalid_use_of_visible_for_testing_member
        asyncPreferencesStore.pathProvider = dDriveProvider;
      }
    } catch (_) {
      // Older shared_preferences versions may not register the async backend.
    }

    return true;
  }

  static Future<void> _migrateLegacyStorage(
    PathProviderPlatform originalPathProvider,
    String targetPath,
  ) async {
    final target = Directory(targetPath);
    await target.create(recursive: true);
    final marker = File(p.join(target.path, _migrationMarkerName));
    if (await marker.exists()) return;

    final legacyPath = await originalPathProvider.getApplicationSupportPath();
    if (legacyPath != null &&
        !_sameWindowsPath(legacyPath, target.path) &&
        _isSafeLegacyDirectory(legacyPath)) {
      final legacy = Directory(legacyPath);
      if (await legacy.exists()) {
        await _copyMissingContents(legacy, target);
        await legacy.delete(recursive: true);
        await _deleteEmptyBrandParent(legacy.parent);
      }
    }

    await marker.writeAsString(
      'Windows storage is managed on D:.\n',
      flush: true,
    );
  }

  static bool _sameWindowsPath(String first, String second) =>
      p.windows.normalize(first).toLowerCase() ==
      p.windows.normalize(second).toLowerCase();

  static bool _isSafeLegacyDirectory(String candidate) {
    final normalized = p.windows.normalize(candidate).toLowerCase();
    final brandedSuffix = p.windows
        .join(appDirectoryName, appDirectoryName)
        .toLowerCase();
    return normalized.endsWith('\\$brandedSuffix') ||
        p.windows.basename(normalized) == 'deepseek_v4_assistant';
  }

  static Future<void> _copyMissingContents(
    Directory source,
    Directory destination,
  ) async {
    await for (final entity in source.list(recursive: true, followLinks: false)) {
      final relative = p.windows.relative(entity.path, from: source.path);
      final targetPath = p.windows.join(destination.path, relative);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        final target = File(targetPath);
        if (!await target.exists()) {
          await target.parent.create(recursive: true);
          await entity.copy(target.path);
        }
      }
    }
  }

  static Future<void> _deleteEmptyBrandParent(Directory parent) async {
    if (p.windows.basename(parent.path).toLowerCase() !=
        appDirectoryName.toLowerCase()) {
      return;
    }
    if (await parent.exists() && await parent.list().isEmpty) {
      await parent.delete();
    }
  }
}

/// Official path_provider_windows implementation with app-owned locations
/// overridden to the D: data root.
class DDrivePathProviderWindows extends PathProviderWindows {
  DDrivePathProviderWindows({this.rootPath = WindowsStorageConfig.dataRoot});

  final String rootPath;

  @override
  Future<String?> getApplicationSupportPath() =>
      _ensureDirectory('Roaming', WindowsStorageConfig.appDirectoryName);

  @override
  Future<String?> getApplicationCachePath() => _ensureDirectory(
    'Local',
    WindowsStorageConfig.appDirectoryName,
    'Cache',
  );

  @override
  Future<String?> getTemporaryPath() => _ensureDirectory('Temp');

  Future<String> _ensureDirectory(
    String first, [
    String? second,
    String? third,
  ]) async {
    final parts = <String>[rootPath, first];
    if (second != null) parts.add(second);
    if (third != null) parts.add(third);
    final directory = Directory(p.joinAll(parts));
    await directory.create(recursive: true);
    return directory.path;
  }
}
