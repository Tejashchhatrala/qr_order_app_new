class Vendor {
  final String id;
  final String name;
  final String upiId;
  final String address;
  final Map<String, dynamic> menu;

  Vendor({
    required this.id,
    required this.name,
    required this.upiId,
    required this.address,
    required this.menu,
  });

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'],
      name: map['name'],
      upiId: map['upiId'],
      address: map['address'],
      menu: Map<String, dynamic>.from(map['menu']),
    );
  }
}

class Category {
  final String id;
  final String name;
  final List<Product> products;

  Category({
    required this.id,
    required this.name,
    required this.products,
  });
}

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String? imageUrl;
  bool isAvailable;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,
    this.isAvailable = true,
  });
}
