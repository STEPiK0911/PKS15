import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

/// Модель данных продукта
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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      imageUrl: json['image_url'] ?? '',
    );
  }
}

/// API сервис для взаимодействия с сервером
class ApiService {
  final String baseUrl = 'http://10.0.2.2:8080'; // Измените на ваш URL сервера

  // Получить все продукты
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception("Ошибка загрузки данных: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Ошибка загрузки данных: $e");
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
      if (response.statusCode != 201) {
        throw Exception("Ошибка создания продукта: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Ошибка создания продукта: $e");
    }
  }

  // Удалить продукт
  Future<void> deleteProduct(int productId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/products/delete/$productId'));
      if (response.statusCode != 200) {
        throw Exception("Ошибка удаления продукта: ${response.statusCode}");
      }
    } catch (e) {
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
      if (response.statusCode != 200) {
        throw Exception("Ошибка добавления в избранное: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Ошибка добавления в избранное: $e");
    }
  }

  // Удалить из избранного
  Future<void> removeFromFavorites(int productId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove/$productId?user_id=$userId'),
      );
      if (response.statusCode != 200) {
        throw Exception("Ошибка удаления из избранного: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Ошибка удаления из избранного: $e");
    }
  }

  // Получить избранные товары
  Future<List<Product>> fetchFavorites(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/favorites?user_id=$userId'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception("Ошибка загрузки избранных товаров: ${response.statusCode}");
      }
    } catch (e) {
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
      if (response.statusCode != 200) {
        throw Exception("Ошибка добавления в корзину: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Ошибка добавления в корзину: $e");
    }
  }

  // Удалить из корзины
  Future<void> removeFromCart(int productId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove/$productId?user_id=$userId'),
      );
      if (response.statusCode != 200) {
        throw Exception("Ошибка удаления из корзины: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Ошибка удаления из корзины: $e");
    }
  }

  // Получить корзину
  Future<List<Product>> fetchCart(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart?user_id=$userId'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception("Ошибка загрузки корзины: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Ошибка загрузки корзины: $e");
    }
  }
}

/// Провайдер для корзины
class CartProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();
  List<Product> _items = [];
  double _totalPrice = 0.0;
  final int userId = 1; // Жестко заданный userId для примера

  List<Product> get items => _items;
  double get totalPrice => _totalPrice;

  // Загрузить корзину из сервера
  Future<void> loadCart() async {
    try {
      _items = await apiService.fetchCart(userId);
      _totalPrice = _items.fold(0.0, (sum, item) => sum + item.price);
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки корзины: $e');
    }
  }

  // Добавить товар в корзину
  Future<void> addToCart(Product product) async {
    try {
      await apiService.addToCart(product.productId, userId);
      _items.add(product);
      _totalPrice += product.price;
      notifyListeners();
    } catch (e) {
      print('Ошибка добавления в корзину: $e');
    }
  }

  // Удалить товар из корзины
  Future<void> removeFromCart(Product product) async {
    try {
      await apiService.removeFromCart(product.productId, userId);
      _items.removeWhere((item) => item.productId == product.productId);
      _totalPrice -= product.price;
      notifyListeners();
    } catch (e) {
      print('Ошибка удаления из корзины: $e');
    }
  }

  // Очистить корзину
  void clearCart() {
    _items.clear();
    _totalPrice = 0.0;
    notifyListeners();
  }
}

/// Провайдер для избранного
class FavoritesProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();
  List<Product> _favorites = [];
  final int userId = 1; // Жестко заданный userId для примера

  List<Product> get favorites => _favorites;

  // Загрузить избранное из сервера
  Future<void> loadFavorites() async {
    try {
      _favorites = await apiService.fetchFavorites(userId);
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки избранного: $e');
    }
  }

  // Добавить в избранное
  Future<void> addToFavorites(Product product) async {
    try {
      await apiService.addToFavorites(product.productId, userId);
      _favorites.add(product);
      notifyListeners();
    } catch (e) {
      print('Ошибка добавления в избранное: $e');
    }
  }

  // Удалить из избранного
  Future<void> removeFromFavorites(Product product) async {
    try {
      await apiService.removeFromFavorites(product.productId, userId);
      _favorites.removeWhere((item) => item.productId == product.productId);
      notifyListeners();
    } catch (e) {
      print('Ошибка удаления из избранного: $e');
    }
  }

  bool isFavorite(int productId) {
    return _favorites.any((product) => product.productId == productId);
  }
}

/// Главная функция
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()..loadCart()),
        ChangeNotifierProvider(create: (context) => FavoritesProvider()..loadFavorites()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Главный виджет приложения
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Витрина продуктов',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

/// Главная страница
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> products;

  @override
  void initState() {
    super.initState();
    products = apiService.fetchProducts();
  }

  // Обновить список продуктов
  void refreshProducts() {
    setState(() {
      products = apiService.fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Витрина продуктов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              ).then((_) => favoritesProvider.loadFavorites());
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = items[index];
              final isFavorite = favoritesProvider.isFavorite(product.productId);
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(product.description.isNotEmpty ? product.description : 'Нет описания'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Иконка избранного
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () async {
                          if (isFavorite) {
                            await favoritesProvider.removeFromFavorites(product);
                          } else {
                            await favoritesProvider.addToFavorites(product);
                          }
                          refreshProducts();
                        },
                      ),
                      // Цена
                      Text('${double.tryParse(product.price.toString()) ?? 0.0} ₽'),
                      // Кнопка удаления товара
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Подтверждение'),
                              content: const Text('Вы уверены, что хотите удалить этот товар?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Нет'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Да'),
                                ),
                              ],
                            ),
                          );
                          if (confirm) {
                            try {
                              await apiService.deleteProduct(product.productId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${product.name} удален')),
                              );
                              refreshProducts();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка удаления товара: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  leading: product.imageUrl.isNotEmpty
                      ? Image.network(
                    product.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported);
                    },
                  )
                      : const Icon(Icons.image),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(
                          product: product,
                          userId: favoritesProvider.userId,
                        ),
                      ),
                    ).then((_) {
                      refreshProducts();
                      favoritesProvider.loadFavorites();
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProductPage()),
          ).then((_) {
            refreshProducts();
            final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
            favoritesProvider.loadFavorites();
          });
        },
      ),
    );
  }
}

/// Страница деталей продукта
class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final int userId;

  const ProductDetailsPage({super.key, required this.product, required this.userId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final ApiService apiService = ApiService();
  bool isFavorite = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  void checkFavorite() {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    setState(() {
      isFavorite = favoritesProvider.isFavorite(widget.product.productId);
    });
  }

  void toggleFavorite() async {
    setState(() {
      isLoading = true;
    });
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    try {
      if (isFavorite) {
        await favoritesProvider.removeFromFavorites(widget.product);
      } else {
        await favoritesProvider.addToFavorites(widget.product);
      }
      setState(() {
        isFavorite = !isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка изменения избранного: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void addToCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    try {
      await cartProvider.addToCart(widget.product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.product.name} добавлен в корзину')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления в корзину: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: isLoading
                ? const CircularProgressIndicator(
              color: Colors.white,
            )
                : Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: isLoading ? null : toggleFavorite,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // To prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.product.imageUrl.isNotEmpty
                  ? Image.network(
                widget.product.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image, size: 200);
                },
              )
                  : const Icon(Icons.image, size: 200),
              const SizedBox(height: 16),
              Text(
                widget.product.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(widget.product.description),
              const SizedBox(height: 16),
              Text(
                'Цена: ${double.tryParse(widget.product.price.toString()) ?? 0.0} ₽',
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: addToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Добавить в корзину'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Страница корзины
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Корзина пуста'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final product = cartItems[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('${double.tryParse(product.price.toString()) ?? 0.0} ₽'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      try {
                        await cartProvider.removeFromCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} удален из корзины')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка удаления из корзины: $e')),
                        );
                      }
                    },
                  ),
                  leading: product.imageUrl.isNotEmpty
                      ? Image.network(
                    product.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported);
                    },
                  )
                      : const Icon(Icons.image),
                  onTap: () {
                    // Можно добавить навигацию к деталям продукта
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Итого: ${cartProvider.totalPrice.toStringAsFixed(2)} ₽',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Страница избранного
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final favorites = favoritesProvider.favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: favorites.isEmpty
          ? const Center(child: Text('Избранных товаров нет'))
          : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final product = favorites[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(product.name),
              subtitle: Text(product.description.isNotEmpty ? product.description : 'Нет описания'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка удаления из избранного
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      try {
                        await favoritesProvider.removeFromFavorites(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} удален из избранного')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка удаления из избранного: $e')),
                        );
                      }
                    },
                  ),
                  // Цена
                  Text('${double.tryParse(product.price.toString()) ?? 0.0} ₽'),
                ],
              ),
              leading: product.imageUrl.isNotEmpty
                  ? Image.network(
                product.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported);
                },
              )
                  : const Icon(Icons.image),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsPage(
                      product: product,
                      userId: favoritesProvider.userId,
                    ),
                  ),
                ).then((_) {
                  favoritesProvider.loadFavorites();
                });
              },
            ),
          );
        },
      ),
    );
  }
}

/// Страница создания продукта
class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String description = '';
  String imageUrl = '';
  double price = 0.0;
  int stock = 0;

  bool isLoading = false;

  void createProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        isLoading = true;
      });
      try {
        await apiService.createProduct({
          "name": name,
          "description": description,
          "price": price,
          "stock": stock,
          "image_url": imageUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Продукт создан успешно')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания продукта: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Создать продукт'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Название'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите название';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      name = value!;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Описание'),
                    onSaved: (value) {
                      description = value ?? '';
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Цена'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите цену';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Введите корректную цену';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      price = double.parse(value!);
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Количество на складе'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите количество';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Введите корректное количество';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      stock = int.parse(value!);
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'URL изображения'),
                    onSaved: (value) {
                      imageUrl = value ?? '';
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: createProduct,
                    child: const Text('Создать'),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
