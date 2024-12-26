// lib/main.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------- Модели ----------------------

// Модель пользователя
class UserModel {
  final String email;
  final String password;

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

// Модель продукта
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
    productId: json['productId'],
    name: json['name'],
    description: json['description'],
    price: json['price'].toDouble(),
    stock: json['stock'],
    imageUrl: json['image_url'],
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'image_url': imageUrl,
  };
}

// Модель заказа
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
    price: json['price'].toDouble(),
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'price': price,
    'status': status,
  };
}

// Модель сообщения
class Message {
  final String sender;
  final String content;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    sender: json['sender'],
    content: json['content'],
    timestamp: DateTime.parse(json['timestamp']),
  );

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };
}

// ---------------------- Провайдеры ----------------------

class AuthProvider extends ChangeNotifier {
  bool isAuthenticated = false;
  String? userEmail;
  List<UserModel> _users = [];

  AuthProvider() {
    _loadUsers();
    _checkAuthentication();
  }

  Future<void> _loadUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usersData = prefs.getString('users');
    if (usersData != null) {
      List<dynamic> usersJson = json.decode(usersData);
      _users = usersJson.map((json) => UserModel.fromJson(json)).toList();
    }
  }

  Future<void> _saveUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> usersJson =
    _users.map((user) => user.toJson()).toList();
    prefs.setString('users', json.encode(usersJson));
  }

  Future<void> _checkAuthentication() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('currentUserEmail');
    if (email != null) {
      isAuthenticated = true;
      userEmail = email;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    // Проверка, существует ли уже пользователь
    bool userExists = _users.any(
            (user) => user.email.toLowerCase() == email.toLowerCase());
    if (userExists) {
      throw Exception("Пользователь с таким email уже существует.");
    }

    // Создание нового пользователя
    UserModel newUser = UserModel(email: email, password: password);
    _users.add(newUser);
    await _saveUsers();

    // Установка текущего пользователя
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('currentUserEmail', email);
    isAuthenticated = true;
    userEmail = email;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    // Поиск пользователя
    try {
      UserModel user = _users.firstWhere((user) =>
      user.email.toLowerCase() == email.toLowerCase() &&
          user.password == password);
      // Установка текущего пользователя
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('currentUserEmail', email);
      isAuthenticated = true;
      userEmail = email;
      notifyListeners();
    } catch (e) {
      throw Exception("Неверный email или пароль.");
    }
  }

  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('currentUserEmail');
    isAuthenticated = false;
    userEmail = null;
    notifyListeners();
  }
}

class FavoritesProvider extends ChangeNotifier {
  List<Product> _favorites = [];

  List<Product> get favorites => List.unmodifiable(_favorites);

  FavoritesProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favoritesData = prefs.getString('favorites');
    if (favoritesData != null) {
      List<dynamic> favoritesJson = json.decode(favoritesData);
      _favorites =
          favoritesJson.map((json) => Product.fromJson(json)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> favoritesJson =
    _favorites.map((product) => product.toJson()).toList();
    prefs.setString('favorites', json.encode(favoritesJson));
  }

  Future<void> addToFavorites(Product product) async {
    if (!_favorites.any((item) => item.productId == product.productId)) {
      _favorites.add(product);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFromFavorites(Product product) async {
    _favorites.removeWhere((item) => item.productId == product.productId);
    await _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(int productId) {
    return _favorites.any((product) => product.productId == productId);
  }
}

class CartProvider extends ChangeNotifier {
  List<Product> _items = [];
  double _totalPrice = 0.0;

  List<Product> get items => List.unmodifiable(_items);
  double get totalPrice => _totalPrice;

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cartData = prefs.getString('cart');
    if (cartData != null) {
      List<dynamic> cartJson = json.decode(cartData);
      _items = cartJson.map((json) => Product.fromJson(json)).toList();
      _totalPrice = _items.fold(0.0, (sum, item) => sum + item.price);
    }
    notifyListeners();
  }

  Future<void> _saveCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> cartJson =
    _items.map((product) => product.toJson()).toList();
    prefs.setString('cart', json.encode(cartJson));
  }

  Future<void> addToCart(Product product) async {
    _items.add(product);
    _totalPrice += product.price;
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeFromCart(Product product) async {
    _items.remove(product);
    _totalPrice -= product.price;
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    _totalPrice = 0.0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('cart');
    notifyListeners();
  }
}

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  OrdersProvider() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ordersData = prefs.getString('orders');
    if (ordersData != null) {
      List<dynamic> ordersJson = json.decode(ordersData);
      _orders = ordersJson.map((json) => Order.fromJson(json)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> ordersJson =
    _orders.map((order) => order.toJson()).toList();
    prefs.setString('orders', json.encode(ordersJson));
  }

  Future<void> addOrder(String productName, double price) async {
    Order newOrder = Order(productName: productName, price: price);
    _orders.add(newOrder);
    await _saveOrders();
    notifyListeners();
  }
}

class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];

  List<Message> get messages => List.unmodifiable(_messages);

  ChatProvider() {
    loadMessages();
  }

  Future<void> loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? messagesData = prefs.getString('messages');
    if (messagesData != null) {
      List<dynamic> messagesJson = json.decode(messagesData);
      _messages = messagesJson.map((json) => Message.fromJson(json)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> messagesJson =
    _messages.map((msg) => msg.toJson()).toList();
    prefs.setString('messages', json.encode(messagesJson));
  }

  Future<void> addMessage(Message message) async {
    _messages.add(message);
    await _saveMessages();
    notifyListeners();
  }

  Future<void> clearMessages() async {
    _messages.clear();
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('messages');
  }
}

// ---------------------- Сервис API ----------------------

class ApiService {
  // Симуляция сети для демонстрации. В реальном приложении замените на реальные HTTP запросы.
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(seconds: 2)); // Симуляция задержки
    // Пример данных
    List<Product> products = [
      Product(
        productId: 1,
        name: 'Товар 1',
        description: 'Описание товара 1',
        price: 100.0,
        stock: 10,
        imageUrl: 'assets/images/product1.png',
      ),
      Product(
        productId: 2,
        name: 'Товар 2',
        description: 'Описание товара 2',
        price: 200.0,
        stock: 5,
        imageUrl: 'assets/images/product2.png',
      ),
      // Добавьте больше продуктов по необходимости
    ];
    return products;
  }

  Future<void> deleteProduct(int productId) async {
    await Future.delayed(const Duration(seconds: 1)); // Симуляция задержки
    // В реальном приложении выполните HTTP DELETE запрос к вашему серверу
    // Здесь мы ничего не делаем, так как это симуляция
  }

  Future<void> createProduct(Map<String, dynamic> productData) async {
    await Future.delayed(const Duration(seconds: 1)); // Симуляция задержки
    // В реальном приложении выполните HTTP POST запрос к вашему серверу
    // Здесь мы ничего не делаем, так как это симуляция
  }
}

// ---------------------- Основная Функция и Виджеты ----------------------

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => FavoritesProvider()),
        ChangeNotifierProvider(create: (context) => OrdersProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()), // Добавление ChatProvider
        Provider(create: (context) => ApiService()), // Добавление ApiService
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Витрина продуктов',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const ProfilePage(), // Стартовая страница
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authProvider.signOut();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: authProvider.isAuthenticated
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Добро пожаловать, ${authProvider.userEmail}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text('Каталог продуктов'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              child: const Text('Корзина'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersPage()),
                );
              },
              child: const Text('Мои заказы'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocalChatPage()),
                );
              },
              child: const Text('Чат'),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Вы не вошли в систему.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('Зарегистрироваться'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;

  void register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        isLoading = true;
      });
      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .signUp(email, password);
        Navigator.pop(context); // Вернуться на страницу профиля
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка регистрации: $e')),
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
          title: const Text('Регистрация'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              // To prevent overflow
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                    const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      email = value!;
                    },
                  ),
                  TextFormField(
                    decoration:
                    const InputDecoration(labelText: 'Пароль'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      if (value.length < 6) {
                        return 'Пароль должен быть не менее 6 символов';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      password = value!;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: register,
                    child: const Text('Зарегистрироваться'),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;

  void login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        isLoading = true;
      });
      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .signIn(email, password);
        Navigator.pop(context); // Вернуться на страницу профиля
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка входа: $e')),
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
          title: const Text('Вход'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              // To prevent overflow
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                    const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      email = value!;
                    },
                  ),
                  TextFormField(
                    decoration:
                    const InputDecoration(labelText: 'Пароль'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      password = value!;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: login,
                    child: const Text('Войти'),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Product>> productsFuture;
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    productsFuture = apiService.fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Обработчик изменений в поле поиска
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((product) {
        return product.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  // Обновить список продуктов
  void refreshProducts() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() {
      productsFuture = apiService.fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск товаров по названию',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Product>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            allProducts = snapshot.data!;
            final displayProducts = _searchController.text.isEmpty
                ? allProducts
                : filteredProducts;

            if (displayProducts.isEmpty) {
              return const Center(child: Text('Нет товаров, соответствующих запросу'));
            }

            return ListView.builder(
              itemCount: displayProducts.length,
              itemBuilder: (context, index) {
                final product = displayProducts[index];
                final isFavorite =
                favoritesProvider.isFavorite(product.productId);
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'Нет описания'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Иконка избранного
                        IconButton(
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () async {
                            if (isFavorite) {
                              await favoritesProvider
                                  .removeFromFavorites(product);
                            } else {
                              await favoritesProvider.addToFavorites(product);
                            }
                            // Обновить состояние
                            setState(() {});
                          },
                        ),
                        // Цена
                        Text('${product.price.toStringAsFixed(2)} ₽'),
                        // Кнопка удаления товара (опционально)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Подтверждение'),
                                content: const Text(
                                    'Вы уверены, что хотите удалить этот товар?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Нет'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Да'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm) {
                              try {
                                await apiService.deleteProduct(
                                    product.productId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '${product.name} удален')),
                                );
                                refreshProducts();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Ошибка удаления товара: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    leading: product.imageUrl.isNotEmpty
                        ? Image.asset(
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
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProductPage()),
          ).then((newProduct) {
            if (newProduct != null && newProduct is Product) {
              refreshProducts();
            }
            Provider.of<FavoritesProvider>(context, listen: false)
                .loadFavorites();
          });
        },
      ),
    );
  }
}

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool isFavorite = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  void checkFavorite() {
    final favoritesProvider =
    Provider.of<FavoritesProvider>(context, listen: false);
    setState(() {
      isFavorite = favoritesProvider.isFavorite(widget.product.productId);
    });
  }

  void toggleFavorite() async {
    setState(() {
      isLoading = true;
    });
    final favoritesProvider =
    Provider.of<FavoritesProvider>(context, listen: false);
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
        SnackBar(
            content: Text(isFavorite
                ? 'Добавлено в избранное'
                : 'Удалено из избранного')),
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
        child: SingleChildScrollView(
          // To prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.product.imageUrl.isNotEmpty
                  ? Image.asset(
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
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(widget.product.description),
              const SizedBox(height: 16),
              Text(
                'Цена: ${widget.product.price.toStringAsFixed(2)} ₽',
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

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final ordersProvider = Provider.of<OrdersProvider>(context);
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
                  subtitle: Text('${product.price.toStringAsFixed(2)} ₽'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      cartProvider.removeFromCart(product);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Итого: ${cartProvider.totalPrice.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (cartItems.isEmpty) return;
                    for (var product in cartItems) {
                      ordersProvider.addOrder(product.name, product.price);
                    }
                    cartProvider.clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Заказ оформлен')),
                    );
                  },
                  child: const Text('Сделать заказ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              subtitle: Text(
                  product.description.isNotEmpty
                      ? product.description
                      : 'Нет описания'),
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
                          SnackBar(
                              content: Text(
                                  '${product.name} удален из избранного')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Ошибка удаления из избранного: $e')),
                        );
                      }
                    },
                  ),
                  // Цена
                  Text('${product.price.toStringAsFixed(2)} ₽'),
                ],
              ),
              leading: product.imageUrl.isNotEmpty
                  ? Image.asset(
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

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
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
        final apiService =
        Provider.of<ApiService>(context, listen: false);
        await apiService.createProduct({
          'name': name,
          'description': description,
          'price': price,
          'stock': stock,
          'image_url': imageUrl,
        });
        final newProduct = Product(
          productId: DateTime.now().millisecondsSinceEpoch, // Временный ID
          name: name,
          description: description,
          price: price,
          stock: stock,
          imageUrl: imageUrl,
        );

        // Возвращаем новый продукт назад на предыдущую страницу
        Navigator.pop(context, newProduct);
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
              // To prevent overflow
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                    const InputDecoration(labelText: 'Название'),
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
                    decoration:
                    const InputDecoration(labelText: 'Описание'),
                    onSaved: (value) {
                      description = value ?? '';
                    },
                  ),
                  TextFormField(
                    decoration:
                    const InputDecoration(labelText: 'Цена'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                    decoration: const InputDecoration(
                        labelText: 'Количество на складе'),
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
                    decoration: const InputDecoration(
                        labelText: 'URL изображения'),
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

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final orders = ordersProvider.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: orders.isEmpty
          ? const Center(child: Text('У вас пока нет заказов'))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(order.productName),
              subtitle: Text(
                'Статус: ${order.status}\nЦена: ${order.price.toStringAsFixed(2)} ₽',
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------- Чат ----------------------

class LocalChatPage extends StatefulWidget {
  const LocalChatPage({super.key});

  @override
  State<LocalChatPage> createState() => _LocalChatPageState();
}

class _LocalChatPageState extends State<LocalChatPage> {
  final TextEditingController _controller = TextEditingController();
  final String user = 'alla@polo.ru';
  final String admin = 'admin@admin.ru';

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Определение текущего пользователя
    String currentUser = authProvider.userEmail == 'admin@admin.ru'
        ? admin
        : user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Очистить чат'),
                  content:
                  const Text('Вы уверены, что хотите очистить все сообщения?'),
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
                await chatProvider.clearMessages();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.messages.isEmpty
                ? const Center(child: Text('Чат пуст'))
                : ListView.builder(
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[index];
                bool isMe = message.sender == currentUser;
                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    margin: const EdgeInsets.symmetric(
                        vertical: 2.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(message.content),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_controller.text.trim().isEmpty) return;
                    final message = Message(
                      sender: currentUser,
                      content: _controller.text.trim(),
                      timestamp: DateTime.now(),
                    );
                    await chatProvider.addMessage(message);
                    _controller.clear();

                    // Автоматический ответ администратора, если пользователь отправил сообщение
                    if (currentUser == user) {
                      Future.delayed(const Duration(seconds: 1), () async {
                        final adminMessage = Message(
                          sender: admin,
                          content: 'Принято, я свяжусь с вами.',
                          timestamp: DateTime.now(),
                        );
                        await chatProvider.addMessage(adminMessage);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
