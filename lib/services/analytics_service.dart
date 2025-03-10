import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/analytics.dart';
import '../models/order.dart';

class AnalyticsService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<AnalyticsData> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final querySnapshot = await _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: _auth.currentUser!.uid)
        .where('status', whereIn: [
          OrderStatus.completed.toString(),
          OrderStatus.cancelled.toString(),
        ])
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    final analytics = AnalyticsData.empty(startDate, endDate);
    var totalOrders = 0;
    var totalRevenue = 0.0;
    final itemsSold = <String, int>{};
    final hourlyRevenue = <String, double>{};

    for (var doc in querySnapshot.docs) {
      final order = Order.fromMap(doc.data(), doc.id);
      if (order.status == OrderStatus.completed) {
        totalOrders++;
        totalRevenue += order.total;

        final hour = DateTime.fromMillisecondsSinceEpoch(
          order.createdAt.millisecondsSinceEpoch,
        ).hour.toString().padLeft(2, '0');

        hourlyRevenue[hour] = (hourlyRevenue[hour] ?? 0) + order.total;

        for (var item in order.items) {
          itemsSold[item.name] = (itemsSold[item.name] ?? 0) + item.quantity;
        }
      }
    }

    return AnalyticsData(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      itemsSold: itemsSold,
      hourlyRevenue: hourlyRevenue,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
