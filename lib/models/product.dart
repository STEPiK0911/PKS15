// lib/models/product.dart

class Product {
  final int productId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    productId: json['product_id'],
    name: json['name'],
    description: json['description'],
    price: (json['price'] as num).toDouble(),
    stock: json['stock'],
    imageUrl: json['image_url'],
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'image_url': imageUrl,
  };
}

class Order {
  final String productName;
  final double price;
  final String status;

  Order({
    required this.productName,
    required this.price,
    this.status = 'В обработке',
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    productName: json['productName'],
    price: (json['price'] as num).toDouble(),
    status: json['status'] ?? 'В обработке',
  );

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'price': price,
    'status': status,
  };
}

class UserModel {
  final String email;
  final String password; // В реальных приложениях храните хэши паролей

  UserModel({required this.email, required this.password});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    email: json['email'],
    password: json['password'],
  );

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}
