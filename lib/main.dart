import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Инициализация Firebase
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

// Главный виджет приложения
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Витрина автомобилей',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

// Модель автомобиля
class Car {
  final String name;
  final String shortDescription;
  final String longDescription;
  final String imagePath;
  final double price;

  Car({
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.imagePath,
    required this.price,
  });

  factory Car.fromMap(Map<String, dynamic> data) {
    return Car(
      name: data['name'] ?? 'Неизвестно',
      shortDescription: data['shortDescription'] ?? 'Нет описания',
      longDescription: data['longDescription'] ?? 'Нет описания',
      imagePath: data['imagePath'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
    );
  }
}

// Провайдер для корзины
class CartProvider extends ChangeNotifier {
  final List<Car> _items = [];

  List<Car> get items => _items;

  void addToCart(Car car) {
    _items.add(car);
    notifyListeners();
  }

  void removeFromCart(Car car) {
    _items.remove(car);
    notifyListeners();
  }

  double get totalPrice {
    return _items.fold(0.0, (sum, car) => sum + car.price);
  }
}

// Главная страница
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Stream<List<Car>> getCars() {
    return FirebaseFirestore.instance
        .collection('cars') // Коллекция "cars" в Firestore
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final car = Car.fromMap(doc.data());
        return car;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Витрина автомобилей'),
        actions: [
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
      body: StreamBuilder<List<Car>>(
        stream: getCars(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет данных для отображения'));
          }

          final cars = snapshot.data!;

          return ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CarDetailsPage(car: car),
                      ),
                    );
                  },
                  leading: car.imagePath.isNotEmpty
                      ? Image.network(
                    car.imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported);
                    },
                  )
                      : const Icon(Icons.car_repair),
                  title: Text(car.name),
                  subtitle: Text(car.shortDescription),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false)
                          .addToCart(car);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${car.name} добавлен в корзину')),
                      );
                    },
                    child: const Text('Добавить'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Детальная страница автомобиля
class CarDetailsPage extends StatelessWidget {
  final Car car;

  const CarDetailsPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(car.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            car.imagePath.isNotEmpty
                ? Image.network(
              car.imagePath,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported, size: 200);
              },
            )
                : const SizedBox(
              height: 200,
              child: Icon(Icons.car_repair, size: 100),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Цена: ${car.price.toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontSize: 20, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    car.longDescription,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false)
                          .addToCart(car);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${car.name} добавлен в корзину')),
                      );
                    },
                    child: const Text('Добавить в корзину'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Страница корзины
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Ваша корзина пуста'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final car = cart.items[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: car.imagePath.isNotEmpty
                        ? Image.network(
                      car.imagePath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                            Icons.image_not_supported);
                      },
                    )
                        : const Icon(Icons.car_repair),
                    title: Text(car.name),
                    subtitle: Text('${car.price} ₽'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        cart.removeFromCart(car);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Итого: ${cart.totalPrice.toStringAsFixed(2)} ₽',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
