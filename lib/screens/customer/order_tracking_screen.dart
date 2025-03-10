import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  final _orderService = OrderService();

  OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: StreamBuilder<Order>(
        stream: _orderService.getOrderStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data!;
          return Column(
            children: [
              _buildStatusTimeline(order.status),
              const Divider(),
              _buildOrderDetails(order),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusTimeline(OrderStatus status) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: OrderStatus.values
            .where((s) => s != OrderStatus.cancelled)
            .map((s) => _buildStatusStep(s, status))
            .toList(),
      ),
    );
  }

  Widget _buildStatusStep(OrderStatus step, OrderStatus currentStatus) {
    final isCompleted = currentStatus.index >= step.index;
    final isCurrent = currentStatus == step;

    return ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle : Icons.circle_outlined,
        color: isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(
        step.toString().split('.').last,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildOrderDetails(Order order) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Order #${order.id}'),
          const SizedBox(height: 8),
          ...order.items.map((item) => ListTile(
                title: Text(item.name),
                trailing: Text('${item.quantity}x ₹${item.price}'),
              )),
          const Divider(),
          ListTile(
            title: const Text('Total'),
            trailing: Text('₹${order.total}'),
          ),
        ],
      ),
    );
  }
}
