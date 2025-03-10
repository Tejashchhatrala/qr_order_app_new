import 'package:workmanager/workmanager.dart';
import 'sync_service.dart';
import 'export_service.dart';

class BackgroundService {
  static const syncTask = 'syncTask';
  static const orderStatusTask = 'orderStatusTask';
  static const reportTask = 'reportTask';

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await _scheduleTasks();
  }

  static Future<void> _scheduleTasks() async {
    await Workmanager().registerPeriodicTask(
      syncTask,
      syncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );

    await Workmanager().registerPeriodicTask(
      orderStatusTask,
      orderStatusTask,
      frequency: const Duration(minutes: 5),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    // Schedule weekly report generation
    await Workmanager().registerPeriodicTask(
      reportTask,
      reportTask,
      frequency: const Duration(days: 7),
      initialDelay: _getNextSundayMidnight(),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresDeviceIdle: true,
      ),
    );
  }

  static Duration _getNextSundayMidnight() {
    final now = DateTime.now();
    final daysUntilSunday = DateTime.sunday - now.weekday;
    final nextSunday = now.add(Duration(
      days: daysUntilSunday,
      hours: 24 - now.hour,
      minutes: -now.minute,
      seconds: -now.second,
    ));
    return nextSunday.difference(now);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case BackgroundService.syncTask:
        await SyncService().syncPendingOrders();
        break;
      case BackgroundService.orderStatusTask:
        await OrderService().checkActiveOrders();
        break;
      case BackgroundService.reportTask:
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 7));
        await ExportService().exportOrderHistory(startDate, endDate);
        break;
    }
    return true;
  });
}
