import 'database_helper.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  /// Checks the server for a new version. 
  /// Downloads and saves if different. Returns true if content was updated.
  Future<bool> checkAndSync() async {
    try {
      final localVersion = await DatabaseHelper.instance.getSyncedVersion();
      final manifest = await ApiService().fetchManifest();
      final serverVersion = manifest['version'] as int;

      if (serverVersion > localVersion) {
        // print('Sync: Downloading...');
        await DatabaseHelper.instance.syncDataFromApi();
        await DatabaseHelper.instance.updateSyncMeta(serverVersion);
        return true;
      } else {
        // print('Sync: Up to date');
        // Update the timestamp so the UI shows a fresh sync time
        await DatabaseHelper.instance.updateSyncMeta(localVersion);
        return false;
      }
    } catch (e) {
      // print('Sync: Failed/Offline');
      return false; // Fall back to local SQLite data
    }
  }
}
