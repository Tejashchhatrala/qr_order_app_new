import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'sync_service.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  final SyncService _syncService = SyncService();

  bool get isOnline => _isOnline;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();

    // Trigger sync when coming back online
    if (!wasOnline && _isOnline) {
      await _syncService.syncPendingOrders();
    }
  }
}
