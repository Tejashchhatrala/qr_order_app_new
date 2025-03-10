import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/payment_service.dart';
import '../../services/order_service.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/connectivity_banner.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>().cart;

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Your cart is empty'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        title: Text(item.menuItem.name),
                        subtitle: Text('₹${item.menuItem.price}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => context
                                  .read<CartProvider>()
                                  .updateQuantity(
                                      item.menuItem.id, item.quantity - 1),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => context
                                  .read<CartProvider>()
                                  .updateQuantity(
                                      item.menuItem.id, item.quantity + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty ? null : _buildCheckoutBar(context),
    );
  }

  Widget _buildCheckoutBar(BuildContext context) {
    final cart = context.watch<CartProvider>().cart;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text('Total: ₹${cart.total}',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _handleCheckout(context),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context) async {
    final isOnline = context.read<ConnectivityService>().isOnline;

    try {
      final orderService = OrderService();
      final paymentService = PaymentService();

      // Create pending order
      final orderId =
          await orderService.createOrder(context.read<CartProvider>().cart);

      if (!isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Order saved offline. Will be processed when online.'),
          ),
        );
        context.read<CartProvider>().clear();
        return;
      }

      // Initialize UPI payment
      final success = await paymentService.initiateUpiPayment(
        context.read<CartProvider>().cart.total,
        orderId,
      );

      if (success) {
        // Update order status and clear cart
        await orderService.updateOrderStatus(orderId, 'paid');
        context.read<CartProvider>().clear();

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(orderId: orderId),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
