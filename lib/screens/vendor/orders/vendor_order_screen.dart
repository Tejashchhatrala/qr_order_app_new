import 'package:flutter/material.dart';
import '../../../models/order.dart';
import '../../../services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorOrderScreen extends StatelessWidget {
  final _orderService = OrderService();

  VendorOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(isCompleted: false),
            _OrderList(isCompleted: true),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final bool isCompleted;

  const _OrderList({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final vendorId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .where('status',
              whereIn: isCompleted
                  ? [OrderStatus.completed.toString()]
                  : [
                      OrderStatus.paid.toString(),
                      OrderStatus.preparing.toString(),
                      OrderStatus.ready.toString()
                    ])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return Center(
            child:
                Text(isCompleted ? 'No completed orders' : 'No active orders'),
          );
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = Order.fromMap(
              orders[index].data() as Map<String, dynamic>,
              orders[index].id,
            );
            return _OrderCard(order: order);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final _orderService = OrderService();

  _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('₹${order.total}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.name}'),
                      Text('₹${item.price * item.quantity}'),
                    ],
                  ),
                )),
            const Divider(),
            if (order.status != OrderStatus.completed)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildActionButtons(context),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final nextStatus = {
      OrderStatus.paid: OrderStatus.preparing,
      OrderStatus.preparing: OrderStatus.ready,
      OrderStatus.ready: OrderStatus.completed,
    };

    final buttonText = {
      OrderStatus.paid: 'Start Preparing',
      OrderStatus.preparing: 'Mark Ready',
      OrderStatus.ready: 'Complete Order',
    };

    if (!nextStatus.containsKey(order.status)) return [];

    return [
      ElevatedButton(
        onPressed: () async {
          try {
            await _orderService.updateOrderStatus(
              order.id,
              nextStatus[order.status]!,
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        child: Text(buttonText[order.status]!),
      ),
    ];
  }
}
