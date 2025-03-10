import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/cart.dart';
import '../services/error_handler.dart';
import 'retry_service.dart';

class OrderService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _localStorage = LocalStorageService();
  final _syncService = SyncService();

  Future<String> createOrder(Cart cart, {int retryCount = 3}) async {
    if (cart.isEmpty || cart.vendorId == null) {
      throw 'Invalid cart state';
    }

    for (int i = 0; i < retryCount; i++) {
      try {
        final orderId = const Uuid().v4();
        final order = Order.fromCart(cart, orderId, _auth.currentUser!.uid);

        await _localStorage.saveOrder(order);

        if (await _syncService.isOnline()) {
          await _firestore.collection('orders').doc(orderId).set(order.toMap());

          final db = await _localStorage.database;
          await db.update(
            'orders',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [orderId],
          );
        }

        return orderId;
      } catch (e) {
        if (i == retryCount - 1) throw ErrorHandler.getErrorMessage(e);
        await Future.delayed(Duration(seconds: i + 1));
      }
    }

    throw 'Failed to create order after $retryCount attempts';
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    return RetryService.retry(
      operation: () => _updateStatus(orderId, status),
      maxAttempts: 3,
    );
  }

  Future<void> _updateStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final order = Order.fromMap(orderDoc.data()!, orderId);
        await NotificationService().sendOrderStatusNotification(order);
      }
    } catch (e) {
      throw OrderException('Failed to update order status: $e');
    }
  }

  Stream<Order> getOrderStream(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => Order.fromMap(doc.data()!, doc.id));
  }

  Future<void> checkActiveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final activeOrderIds = prefs.getStringList('activeOrders') ?? [];

    for (final orderId in activeOrderIds) {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) continue;

      final order = Order.fromMap(orderDoc.data()!, orderId);
      if (order.status == OrderStatus.completed ||
          order.status == OrderStatus.cancelled) {
        activeOrderIds.remove(orderId);
      }
    }

    await prefs.setStringList('activeOrders', activeOrderIds);
  }

  Future<void> addActiveOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final activeOrders = prefs.getStringList('activeOrders') ?? [];
    if (!activeOrders.contains(orderId)) {
      activeOrders.add(orderId);
      await prefs.setStringList('activeOrders', activeOrders);
    }
  }
}

class OrderException implements Exception {
  final String message;
  OrderException(this.message);
  @override
  String toString() => message;
}
