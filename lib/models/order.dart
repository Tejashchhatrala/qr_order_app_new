import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart.dart';

enum OrderStatus { pending, paid, preparing, ready, completed, cancelled }

class Order {
  final String id;
  final String customerId;
  final String vendorId;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromCart(Cart cart, String orderId, String customerId) {
    return Order(
      id: orderId,
      customerId: customerId,
      vendorId: cart.vendorId!,
      items: cart.items.map((item) => OrderItem.fromCartItem(item)).toList(),
      total: cart.total,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      customerId: map['customerId'],
      vendorId: map['vendorId'],
      items: (map['items'] as List)
          .map((item) => OrderItem.fromMap(item))
          .toList(),
      total: map['total'].toDouble(),
      status: OrderStatus.values.firstWhere(
        (s) => s.toString() == map['status'],
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'vendorId': vendorId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class OrderItem {
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromCartItem(CartItem item) {
    return OrderItem(
      name: item.menuItem.name,
      price: item.menuItem.price,
      quantity: item.quantity,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'],
      price: map['price'].toDouble(),
      quantity: map['quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}
