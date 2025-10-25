import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Método para hashear contraseñas
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Método para crear usuario admin
  Future<void> createAdminUser() async {
    final db = await database;
    
    await db.insert('users', {
      'username': 'admin',
      'password_hash': _hashPassword('admin123'),
      'role': 'admin',
      'full_name': 'Administrador Sistema',
      'email': 'admin@bellezapp.com',
      'is_active': 1
    });
  }

  // Método para forzar recreación de la base de datos
  Future<void> recreateDatabase() async {
    await _database?.close();
    _database = null;
    String path = join(await getDatabasesPath(), 'bellezapp.db');
    await deleteDatabase(path);
    print('Database forcefully deleted');
    _database = await _initDatabase();
    print('Database recreated successfully');
  }

  // Cerrar la base de datos
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bellezapp.db');
    
    // Eliminar la base de datos existente para forzar recreación completa
    print('Database path: $path');
    bool exists = await databaseExists(path);
    print('Database exists before delete: $exists');
    
    if (exists) {
      await deleteDatabase(path);
      print('Database deleted successfully');
    }
    
    return await openDatabase(
      path,
      version: 1, // Versión simple sin multi-tienda
      onCreate: (db, version) async {
        print('Creating database version $version');
        
        // Tabla de usuarios (sin store_id)
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL CHECK (role IN ('admin', 'employee')),
            full_name TEXT,
            email TEXT,
            phone TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Tabla de categorías
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Tabla de proveedores
        await db.execute('''
          CREATE TABLE suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            contact_person TEXT,
            phone TEXT,
            email TEXT,
            address TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Tabla de productos (sin store_id)
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            purchase_price REAL,
            sale_price REAL,
            stock INTEGER DEFAULT 0,
            min_stock INTEGER DEFAULT 5,
            category_id INTEGER,
            supplier_id INTEGER,
            barcode TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (category_id) REFERENCES categories (id),
            FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
          )
        ''');

        // Tabla de clientes (sin store_id)
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            email TEXT,
            address TEXT,
            total_spent REAL DEFAULT 0.0,
            total_orders INTEGER DEFAULT 0,
            points INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Tabla de órdenes (sin store_id)
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            total REAL NOT NULL,
            status TEXT DEFAULT 'completed',
            payment_method TEXT DEFAULT 'cash',
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (customer_id) REFERENCES customers (id)
          )
        ''');

        // Tabla de items de orden
        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            subtotal REAL NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders (id),
            FOREIGN KEY (product_id) REFERENCES products (id)
          )
        ''');

        // Tabla de ubicaciones
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Insertar datos iniciales
        await _insertInitialData(db);
      },
    );
  }

  Future<void> _insertInitialData(Database db) async {
    print('Inserting initial data...');

    // Insertar usuario admin por defecto
    await db.insert('users', {
      'username': 'admin',
      'password_hash': _hashPassword('admin123'),
      'role': 'admin',
      'full_name': 'Administrador',
      'email': 'admin@bellezapp.com',
      'is_active': 1,
    });

    // Insertar categorías de ejemplo
    await db.insert('categories', {'name': 'Shampoo', 'description': 'Productos para el cabello'});
    await db.insert('categories', {'name': 'Maquillaje', 'description': 'Productos de belleza'});
    await db.insert('categories', {'name': 'Cuidado de piel', 'description': 'Productos para el cuidado facial'});

    // Insertar proveedores de ejemplo
    await db.insert('suppliers', {
      'name': 'Beauty Supplies Co.',
      'contact_person': 'Juan Pérez',
      'phone': '555-0001',
      'email': 'ventas@beautysupplies.com'
    });

    // Insertar productos de ejemplo
    await db.insert('products', {
      'name': 'Shampoo Nutritivo',
      'description': 'Shampoo para cabello seco',
      'purchase_price': 15.00,
      'sale_price': 25.00,
      'stock': 50,
      'category_id': 1,
      'supplier_id': 1
    });

    await db.insert('products', {
      'name': 'Base de Maquillaje',
      'description': 'Base líquida para todo tipo de piel',
      'purchase_price': 20.00,
      'sale_price': 35.00,
      'stock': 30,
      'category_id': 2,
      'supplier_id': 1
    });

    // Insertar ubicaciones de ejemplo
    await db.insert('locations', {'name': 'Estante A1', 'description': 'Productos para cabello'});
    await db.insert('locations', {'name': 'Estante B1', 'description': 'Productos de maquillaje'});

    print('Initial data inserted successfully');
  }

  // **MÉTODOS DE USUARIOS**
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', where: 'is_active = 1');
  }

  // **MÉTODOS DE PRODUCTOS**
  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      ORDER BY p.name
    ''');
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('products', product);
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.update('products', product, where: 'id = ?', whereArgs: [product['id']]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // **MÉTODOS DE CATEGORÍAS**
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name');
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('categories', category);
  }

  Future<void> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.update('categories', category, where: 'id = ?', whereArgs: [category['id']]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // **MÉTODOS DE PROVEEDORES**
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await database;
    return await db.query('suppliers', orderBy: 'name');
  }

  Future<int> insertSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    return await db.insert('suppliers', supplier);
  }

  Future<void> updateSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    await db.update('suppliers', supplier, where: 'id = ?', whereArgs: [supplier['id']]);
  }

  Future<void> deleteSupplier(int id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // **MÉTODOS DE CLIENTES**
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.query('customers', orderBy: 'name');
  }

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.insert('customers', customer);
  }

  Future<void> updateCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    await db.update('customers', customer, where: 'id = ?', whereArgs: [customer['id']]);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // **MÉTODOS DE ÓRDENES**
  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT o.*, c.name as customer_name
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ORDER BY o.created_at DESC
    ''');
  }

  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('orders', order);
  }

  Future<void> insertOrderItem(Map<String, dynamic> orderItem) async {
    final db = await database;
    await db.insert('order_items', orderItem);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT oi.*, p.name as product_name
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ?
    ''', [orderId]);
  }

  // **MÉTODOS DE UBICACIONES**
  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    return await db.query('locations', orderBy: 'name');
  }

  Future<int> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    return await db.insert('locations', location);
  }

  Future<void> updateLocation(Map<String, dynamic> location) async {
    final db = await database;
    await db.update('locations', location, where: 'id = ?', whereArgs: [location['id']]);
  }

  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  // Método para buscar productos
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, c.name as category_name, s.name as supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.name LIKE ? OR p.description LIKE ? OR p.barcode LIKE ?
      ORDER BY p.name
    ''', ['%$query%', '%$query%', '%$query%']);
  }

  // Método para actualizar stock
  Future<void> updateStock(int productId, int newStock) async {
    final db = await database;
    await db.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [productId]);
  }

  // Cerrar base de datos
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}