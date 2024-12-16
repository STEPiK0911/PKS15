import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://10.0.2.2:8080';

  // Получить все продукты
  Future<List<dynamic>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      print('Статус-код: ${response.statusCode}');
      print('Ответ: ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Ошибка загрузки данных: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса: $e');
      throw Exception("Ошибка загрузки данных");
    }
  }

  // Создать продукт
  Future<void> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/products/create"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(productData),
      );
      print('Статус-код создания: ${response.statusCode}');
      print('Ответ создания: ${response.body}');
      if (response.statusCode != 201) {
        throw Exception("Ошибка создания продукта: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса при создании: $e');
      throw Exception("Ошибка создания продукта: $e");
    }
  }

  // Удалить продукт
  Future<void> deleteProduct(int productId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/products/delete/$productId'));
      print('Статус-код удаления: ${response.statusCode}');
      print('Ответ удаления: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception("Ошибка удаления продукта: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса при удалении: $e');
      throw Exception("Ошибка удаления продукта: $e");
    }
  }

  /* ----------------------- Функционал Избранного (Favorites) ----------------------- */

  // Добавить в избранное
  Future<void> addToFavorites(int productId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/add'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"product_id": productId, "user_id": userId}),
      );
      print('Статус-код добавления в избранное: ${response.statusCode}');
      print('Ответ добавления в избранное: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception("Ошибка добавления в избранное: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса при добавлении в избранное: $e');
      throw Exception("Ошибка добавления в избранное: $e");
    }
  }

  // Удалить из избранного
  Future<void> removeFromFavorites(int productId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove/$productId?user_id=$userId'),
      );
      print('Статус-код удаления из избранного: ${response.statusCode}');
      print('Ответ удаления из избранного: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception("Ошибка удаления из избранного: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса при удалении из избранного: $e');
      throw Exception("Ошибка удаления из избранного: $e");
    }
  }

  // Получить избранные товары
  Future<List<dynamic>> fetchFavorites(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/favorites?user_id=$userId'));
      print('Статус-код получения избранного: ${response.statusCode}');
      print('Ответ получения избранного: ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Ошибка загрузки избранных товаров: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса при получении избранного: $e');
      throw Exception("Ошибка загрузки избранных товаров: $e");
    }
  }

  /* ----------------------- Функционал Корзины (Cart) ----------------------- */

  // Добавить в корзину
  Future<void> addToCart(int productId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"product_id": productId, "user_id": userId}),
      );
      print('Статус-код добавления в корзину: ${response.statusCode}');
      print('Ответ добавления в корзину: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception("Ошибка добавления в корзину: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса при добавлении в корзину: $e');
      throw Exception("Ошибка добавления в корзину: $e");
    }
  }

  // Удалить из корзины
  Future<void> removeFromCart(int productId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove/$productId?user_id=$userId'),
      );
      print('Статус-код удаления из корзины: ${response.statusCode}');
      print('Ответ удаления из корзины: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception("Ошибка удаления из корзины: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса при удалении из корзины: $e');
      throw Exception("Ошибка удаления из корзины: $e");
    }
  }

  // Получить корзину
  Future<List<Product>> fetchCart(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart?user_id=$userId'));
      print('Статус-код получения корзины: ${response.statusCode}');
      print('Ответ получения корзины: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception("Ошибка загрузки корзины: ${response.statusCode}");
      }
    } catch (e) {
      print('Ошибка запроса при получении корзины: $e');
      throw Exception("Ошибка загрузки корзины: $e");
    }
  }
}
