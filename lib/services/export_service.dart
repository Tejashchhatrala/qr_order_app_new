import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../models/analytics.dart';
import '../models/order.dart';
import 'analytics_service.dart';

class ExportService {
  final AnalyticsService _analyticsService = AnalyticsService();

  Future<void> exportOrderHistory(DateTime startDate, DateTime endDate) async {
    final analytics = await _analyticsService.getAnalytics(
      startDate: startDate,
      endDate: endDate,
    );

    final csvData = [
      ['Order Report', ''],
      ['Period:', '${startDate.toString()} to ${endDate.toString()}'],
      ['Total Orders:', analytics.totalOrders.toString()],
      ['Total Revenue:', '₹${analytics.totalRevenue.toStringAsFixed(2)}'],
      [],
      ['Hour', 'Revenue'],
      ...analytics.hourlyRevenue.entries
          .map((e) => [e.key, '₹${e.value.toStringAsFixed(2)}']),
      [],
      ['Item', 'Quantity Sold'],
      ...analytics.itemsSold.entries.map((e) => [e.key, e.value]),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/order_report_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    await file.writeAsString(csv);
    await Share.shareFiles([file.path], text: 'Order Report');
  }
}
