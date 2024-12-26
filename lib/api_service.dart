// lib/services/api_service.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ApiService {
  static const String _productsKey = 'products';

  /// Получить все продукты
  Future<List<Product>> fetchProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? productsData = prefs.getString(_productsKey);

    if (productsData != null) {
      // Если данные уже сохранены в SharedPreferences, загрузить их
      List<dynamic> jsonData = json.decode(productsData);
      return jsonData.map((json) => Product.fromJson(json)).toList();
    } else {
      // Иначе загрузить из локального JSON-файла
      String jsonString = await rootBundle.loadString('data/products.json');
      List<dynamic> jsonData = json.decode(jsonString);
      List<Product> products =
      jsonData.map((json) => Product.fromJson(json)).toList();

      // Сохранить загруженные данные в SharedPreferences для дальнейшего использования
      await prefs.setString(
          _productsKey, json.encode(products.map((p) => p.toJson()).toList()));

      return products;
    }
  }

  /// Создать продукт
  Future<void> createProduct(Map<String, dynamic> productData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Product> products = await fetchProducts();

    // Генерация уникального ID (можно улучшить)
    int newProductId = products.isNotEmpty
        ? products.map((p) => p.productId).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    Product newProduct = Product(
      productId: newProductId,
      name: productData['name'],
      description: productData['description'],
      price: (productData['price'] as num).toDouble(),
      stock: productData['stock'],
      imageUrl: productData['image_url'],
    );

    products.add(newProduct);

    // Сохранить обновленный список продуктов
    await prefs.setString(
        _productsKey, json.encode(products.map((p) => p.toJson()).toList()));
  }

  /// Удалить продукт
  Future<void> deleteProduct(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Product> products = await fetchProducts();

    products.removeWhere((product) => product.productId == productId);

    // Сохранить обновленный список продуктов
    await prefs.setString(
        _productsKey, json.encode(products.map((p) => p.toJson()).toList()));
  }
}
