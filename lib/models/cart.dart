import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get total => menuItem.price * quantity;
}

class Cart {
  final Map<String, CartItem> _items = {};
  String? vendorId;

  void add(MenuItem item) {
    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity++;
    } else {
      _items[item.id] = CartItem(menuItem: item);
    }
  }

  void remove(String itemId) {
    _items.remove(itemId);
  }

  void updateQuantity(String itemId, int quantity) {
    if (_items.containsKey(itemId) && quantity > 0) {
      _items[item.id]!.quantity = quantity;
    }
  }

  void clear() {
    _items.clear();
    vendorId = null;
  }

  double get total => _items.values
      .fold(0, (sum, item) => sum + item.menuItem.price * item.quantity);

  List<CartItem> get items => _items.values.toList();

  bool get isEmpty => _items.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'items': _items.map((key, value) => MapEntry(key, {
            'menuItem': value.menuItem.toMap(),
            'quantity': value.quantity,
          })),
    };
  }

  factory Cart.fromMap(Map<String, dynamic> map) {
    final cart = Cart();
    cart.vendorId = map['vendorId'];

    final items = map['items'] as Map<String, dynamic>;
    items.forEach((key, value) {
      cart._items[key] = CartItem(
        menuItem: MenuItem.fromMap(value['menuItem'], key),
        quantity: value['quantity'],
      );
    });

    return cart;
  }
}
