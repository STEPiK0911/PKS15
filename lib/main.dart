import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p; // Алиас для provider
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final SupabaseClient supabase = Supabase.instance.client;

  // Получить текущий JWT токен
  String? get jwtToken => supabase.auth.currentSession?.accessToken;



  // Получить все продукты
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          "Content-Type": "application/json",
          if (jwtToken != null) "Authorization": "Bearer $jwtToken",
        },
      );
      print('Статус-код: ${response.statusCode}');
      print('Ответ: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
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
        headers: {
          "Content-Type": "application/json",
          if (jwtToken != null) "Authorization": "Bearer $jwtToken",
        },
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
      final response = await http.delete(
        Uri.parse('$baseUrl/products/delete/$productId'),
        headers: {
          if (jwtToken != null) "Authorization": "Bearer $jwtToken",
        },
      );
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
  Future<void> addToFavorites(int productId) async {
    if (supabase.auth.currentSession == null) {
      throw Exception("Пользователь не аутентифицирован");
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/add'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: json.encode({"product_id": productId}),
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
  Future<void> removeFromFavorites(int productId) async {
    if (supabase.auth.currentSession == null) {
      throw Exception("Пользователь не аутентифицирован");
    }
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove/$productId'),
        headers: {
          "Authorization": "Bearer $jwtToken",
        },
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
  Future<List<Product>> fetchFavorites() async {
    if (supabase.auth.currentSession == null) {
      throw Exception("Пользователь не аутентифицирован");
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
      );
      print('Статус-код получения избранного: ${response.statusCode}');
      print('Ответ получения избранного: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
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
  Future<void> addToCart(int productId) async {
    if (supabase.auth.currentSession == null) {
      throw Exception("Пользователь не аутентифицирован");
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: json.encode({"product_id": productId}),
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
  Future<void> removeFromCart(int productId) async {
    if (supabase.auth.currentSession == null) {
      throw Exception("Пользователь не аутентифицирован");
    }
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove/$productId'),
        headers: {
          "Authorization": "Bearer $jwtToken",
        },
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
  Future<List<Product>> fetchCart() async {
    if (supabase.auth.currentSession == null) {
      throw Exception("Пользователь не аутентифицирован");
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
      );
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

/// Провайдер для аутентификации
class AuthProvider extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isAuthenticated = false;
  String? userId;
  String? email;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      isAuthenticated = true;
      userId = session.user?.id;
      email = session.user?.email;
    }
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn) {
        isAuthenticated = true;
        userId = session?.user?.id;
        email = session?.user?.email;
      } else if (event == AuthChangeEvent.signedOut) {
        isAuthenticated = false;
        userId = null;
        email = null;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(email: email, password: password);
      if (response.user != null) {
        isAuthenticated = true;
        userId = response.user?.id;
        this.email = response.user?.email;
        notifyListeners();
      } else {
        throw Exception("Не удалось зарегистрировать пользователя.");
      }
    } catch (e) {
      throw Exception("Ошибка регистрации: $e");
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(email: email, password: password);
      if (response.session != null) {
        isAuthenticated = true;
        userId = response.session?.user.id;
        this.email = response.session?.user.email;
        notifyListeners();
      } else {
        throw Exception("Не удалось войти в систему.");
      }
    } catch (e) {
      throw Exception("Ошибка входа: $e");
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    isAuthenticated = false;
    userId = null;
    email = null;
    notifyListeners();
  }
}


/// Провайдер для корзины
class CartProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();
  List<Product> _items = [];
  double _totalPrice = 0.0;

  List<Product> get items => _items;
  double get totalPrice => _totalPrice;

  CartProvider() {
    loadCart();
  }

  // Загрузить корзину из сервера
  Future<void> loadCart() async {
    try {
      _items = await apiService.fetchCart();
      _totalPrice = _items.fold(0.0, (sum, item) => sum + item.price);
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки корзины: $e');
    }
  }

  // Добавить товар в корзину
  Future<void> addToCart(Product product) async {
    try {
      await apiService.addToCart(product.productId);
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
      await apiService.removeFromCart(product.productId);
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

  List<Product> get favorites => _favorites;

  FavoritesProvider() {
    loadFavorites();
  }

  // Загрузить избранное из сервера
  Future<void> loadFavorites() async {
    try {
      _favorites = await apiService.fetchFavorites();
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки избранного: $e');
    }
  }

  // Добавить в избранное
  Future<void> addToFavorites(Product product) async {
    try {
      await apiService.addToFavorites(product.productId);
      _favorites.add(product);
      notifyListeners();
    } catch (e) {
      print('Ошибка добавления в избранное: $e');
    }
  }

  // Удалить из избранного
  Future<void> removeFromFavorites(Product product) async {
    try {
      await apiService.removeFromFavorites(product.productId);
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

// Глобальный ключ навигатора для доступа к контексту из провайдеров
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Главная функция
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qugoviarpvhouwmlmexj.supabase.co', // Замените на ваш Project URL
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF1Z292aWFycHZob3V3bWxtZXhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNTgwOTAsImV4cCI6MjA0OTkzNDA5MH0.RpHyb39LpTPTrW3XiKGl8a_E3Xwe0h3DJaaQzPdscjI', // Замените на ваш anon public ключ
  );

  runApp(
    p.MultiProvider(
      providers: [
        p.ChangeNotifierProvider(create: (context) => AuthProvider()),
        p.ChangeNotifierProvider(create: (context) => CartProvider()),
        p.ChangeNotifierProvider(create: (context) => FavoritesProvider()),
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
      navigatorKey: navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const ProfilePage(), // Стартовая страница
    );
  }
}

/// Страница профиля
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = p.Provider.of<AuthProvider>(context); // Используем алиас
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Center(
        child: authProvider.isAuthenticated
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Вы вошли как: ${authProvider.email ?? 'Неизвестный пользователь'}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await authProvider.signOut();
              },
              child: const Text('Выйти'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text('Перейти к продуктам'),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Войти'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Страница регистрации
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
        await p.Provider.of<AuthProvider>(context, listen: false).signUp(email, password);
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
      appBar: AppBar(title: const Text('Регистрация')),
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
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    email = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Пароль'),
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
      ),
    );
  }
}

/// Страница входа
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
        await p.Provider.of<AuthProvider>(context, listen: false).signIn(email, password);
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
      appBar: AppBar(title: const Text('Вход')),
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
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    email = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Пароль'),
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
      ),
    );
  }
}

/// Главная страница с продуктами
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> productsFuture;
  List<Product> allProducts = []; // Все продукты
  List<Product> filteredProducts = []; // Отфильтрованные продукты
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    setState(() {
      productsFuture = apiService.fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = p.Provider.of<FavoritesProvider>(context);
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          allProducts = snapshot.data!;
          // Если есть поисковый запрос, используем отфильтрованный список, иначе все продукты
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
                      Text('${product.price.toStringAsFixed(2)} ₽'),
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
          ).then((newProduct) {
            if (newProduct != null && newProduct is Product) {
              setState(() {
                allProducts.add(newProduct); // Добавляем в общий список
                _searchController.text = newProduct.name; // Устанавливаем поисковый запрос
                _onSearchChanged(); // Обновляем фильтр
              });
            }
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

  const ProductDetailsPage({super.key, required this.product});

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
    final favoritesProvider = p.Provider.of<FavoritesProvider>(context, listen: false);
    setState(() {
      isFavorite = favoritesProvider.isFavorite(widget.product.productId);
    });
  }

  void toggleFavorite() async {
    setState(() {
      isLoading = true;
    });
    final favoritesProvider = p.Provider.of<FavoritesProvider>(context, listen: false);
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
    final cartProvider = p.Provider.of<CartProvider>(context, listen: false);
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

/// Страница корзины
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = p.Provider.of<CartProvider>(context);
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
    final favoritesProvider = p.Provider.of<FavoritesProvider>(context);
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
                  Text('${product.price.toStringAsFixed(2)} ₽'),
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

// Создаем локальный объект продукта
        final newProduct = Product(
          productId: DateTime.now().millisecondsSinceEpoch, // Временный ID
          name: name,
          description: description,
          price: price,
          stock: stock,
          imageUrl: imageUrl,
        );

// Добавляем товар в список
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
