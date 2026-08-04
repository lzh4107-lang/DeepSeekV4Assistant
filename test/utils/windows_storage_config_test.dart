import 'dart:io';

import 'package:Kelivo/utils/windows_storage_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'D-drive provider creates app-owned Windows storage directories',
    () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'deepseek_windows_storage_',
      );
      addTearDown(() async {
        if (await temporaryRoot.exists()) {
          await temporaryRoot.delete(recursive: true);
        }
      });

      final provider = DDrivePathProviderWindows(rootPath: temporaryRoot.path);

      expect(
        await provider.getApplicationSupportPath(),
        p.join(
          temporaryRoot.path,
          'Roaming',
          WindowsStorageConfig.appDirectoryName,
        ),
      );
      expect(
        await provider.getApplicationCachePath(),
        p.join(
          temporaryRoot.path,
          'Local',
          WindowsStorageConfig.appDirectoryName,
          'Cache',
        ),
      );
      expect(
        await provider.getTemporaryPath(),
        p.join(temporaryRoot.path, 'Temp'),
      );
    },
  );
}
