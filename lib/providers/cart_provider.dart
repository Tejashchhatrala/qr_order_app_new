import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/menu_item.dart';

class CartProvider extends ChangeNotifier {
  final Cart _cart = Cart();

  Cart get cart => _cart;

  void addItem(MenuItem item) {
    _cart.add(item);
    notifyListeners();
  }

  void removeItem(String itemId) {
    _cart.remove(itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    _cart.updateQuantity(itemId, quantity);
    notifyListeners();
  }

  void clear() {
    _cart.clear();
    notifyListeners();
  }
}
