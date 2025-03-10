import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vendor.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item.dart';

class VendorMenuScreen extends StatelessWidget {
  final Vendor vendor;

  const VendorMenuScreen({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vendor.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: vendor.categories.length,
        itemBuilder: (context, index) {
          final category = vendor.categories[index];
          return ExpansionTile(
            title: Text(category.name),
            children: category.items
                .map((item) => _buildMenuItem(context, item))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return ListTile(
      leading: item.imageUrl.isNotEmpty
          ? Image.network(item.imageUrl, width: 56, height: 56)
          : const Icon(Icons.fastfood),
      title: Text(item.name),
      subtitle: Text('₹${item.price}'),
      trailing: item.isAvailable
          ? IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                context.read<CartProvider>().addItem(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart')),
                );
              },
            )
          : const Text('Out of stock', style: TextStyle(color: Colors.red)),
    );
  }
}
