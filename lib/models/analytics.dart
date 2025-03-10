import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsData {
  final int totalOrders;
  final double totalRevenue;
  final Map<String, int> itemsSold;
  final Map<String, double> hourlyRevenue;
  final DateTime startDate;
  final DateTime endDate;

  AnalyticsData({
    required this.totalOrders,
    required this.totalRevenue,
    required this.itemsSold,
    required this.hourlyRevenue,
    required this.startDate,
    required this.endDate,
  });

  factory AnalyticsData.empty(DateTime start, DateTime end) {
    return AnalyticsData(
      totalOrders: 0,
      totalRevenue: 0,
      itemsSold: {},
      hourlyRevenue: {},
      startDate: start,
      endDate: end,
    );
  }
}
