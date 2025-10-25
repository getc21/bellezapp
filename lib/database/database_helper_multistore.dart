import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

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
      'id': 1,
      'username': 'admin',
      'password_hash': _hashPassword('admin123'),
      'role': 'admin',
      'full_name': 'Administrador Sistema',
      'email': 'admin@bellezapp.com',
      'is_active': 1
    });
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
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
      version: 17, // Nueva versión con password_hash
      onCreate: (db, version) async {
        print('Creating database version $version');
        
        // Create products table
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,  
            purchase_price REAL,
            sale_price REAL,
            weight TEXT,
            category_id INTEGER NOT NULL,
            supplier_id INTEGER NOT NULL,
            location_id INTEGER NOT NULL,
            foto TEXT,
            stock INTEGER,
            expirity_date TEXT,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            foto TEXT,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            foto TEXT,
            name TEXT NOT NULL,
            contact_name TEXT,
            contact_email TEXT,
            contact_phone TEXT,
            address TEXT,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT,
            phone TEXT,
            address TEXT,
            birth_date TEXT,
            total_purchases REAL DEFAULT 0.0,
            last_purchase_date TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE discounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL CHECK (type IN ('percentage', 'fixed_amount')),
            value REAL NOT NULL,
            min_purchase_amount REAL DEFAULT 0.0,
            start_date TEXT,
            end_date TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');

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

        await db.execute('''
          CREATE TABLE user_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            session_token TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            expires_at TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_date TEXT NOT NULL,
            totalOrden REAL NOT NULL,
            customer_id INTEGER,
            discount_id INTEGER,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (customer_id) REFERENCES customers (id),
            FOREIGN KEY (discount_id) REFERENCES discounts (id),
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders (id),
            FOREIGN KEY (product_id) REFERENCES products (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE cash_sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            payment_method TEXT DEFAULT 'cash',
            transaction_date TEXT DEFAULT CURRENT_TIMESTAMP,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders (id),
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE cash_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
            amount REAL NOT NULL,
            description TEXT,
            category TEXT,
            date TEXT DEFAULT CURRENT_TIMESTAMP,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');

        // Cash registers table for opening/closing cash operations
        await db.execute('''
          CREATE TABLE cash_registers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            opening_amount REAL NOT NULL,
            closing_amount REAL,
            expected_amount REAL,
            difference REAL,
            status TEXT NOT NULL CHECK (status IN ('abierta', 'cerrada')) DEFAULT 'abierta',
            opening_time TEXT,
            closing_time TEXT,
            user_id TEXT,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE financial_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            type TEXT,
            amount REAL,
            store_id INTEGER NOT NULL,
            FOREIGN KEY (store_id) REFERENCES stores (id)
          )
        ''');

        await _insertInitialData(db);
      },
    );
  }

  Future<void> _insertInitialData(Database db) async {
    print('Inserting initial data...');
    
    // Insert initial stores
    await db.insert('stores', {
      'id': 1,
      'name': 'Tienda Principal',
      'address': 'Calle Principal 123',
      'phone': '123-456-7890',
      'email': 'principal@bellezapp.com',
      'manager_name': 'Administrador Principal'
    });
    
    await db.insert('stores', {
      'id': 2,
      'name': 'Sucursal Norte',
      'address': 'Avenida Norte 456',
      'phone': '123-456-7891',
      'email': 'norte@bellezapp.com',
      'manager_name': 'Manager Norte'
    });

    // Insert admin user (sin store_id específico para que pueda acceder a todas)
    await db.insert('users', {
      'id': 1,
      'username': 'admin',
      'password_hash': _hashPassword('admin123'),
      'role': 'admin',
      'full_name': 'Administrador Sistema',
      'email': 'admin@bellezapp.com',
      'is_active': 1,
      'store_id': null
    });

    // Insert sample data for store 1
    await _insertSampleDataForStore(db, 1);
    await _insertSampleDataForStore(db, 2);
    
    print('Initial data inserted successfully');
  }

  Future<void> _insertSampleDataForStore(Database db, int storeId) async {
    print('Inserting sample data for store $storeId');
    
    // Insert categories for this store
    await db.insert('categories', {
      'name': 'Maquillaje',
      'description': 'Productos de maquillaje',
      'foto': 'maquillaje.png',
      'store_id': storeId
    });
    await db.insert('categories', {
      'name': 'Cuidado de la Piel',
      'description': 'Productos para el cuidado de la piel',
      'foto': 'skincare.png',
      'store_id': storeId
    });
    await db.insert('categories', {
      'name': 'Fragancias',
      'description': 'Perfumes y fragancias',
      'foto': 'fragancias.png',
      'store_id': storeId
    });

    // Insert suppliers for this store
    await db.insert('suppliers', {
      'name': 'Beauty Supplier ${storeId}A',
      'contact_name': 'Contacto A',
      'contact_email': 'contactoa@supplier$storeId.com',
      'contact_phone': '123-456-789$storeId',
      'address': 'Dirección Supplier A Store $storeId',
      'foto': 'supplier${storeId}a.png',
      'store_id': storeId
    });
    await db.insert('suppliers', {
      'name': 'Cosmetics Inc ${storeId}B',
      'contact_name': 'Contacto B',
      'contact_email': 'contactob@supplier$storeId.com',
      'contact_phone': '123-456-789${storeId + 10}',
      'address': 'Dirección Supplier B Store $storeId',
      'foto': 'supplier${storeId}b.png',
      'store_id': storeId
    });

    // Insert locations for this store
    await db.insert('locations', {
      'name': 'Estante Principal',
      'description': 'Estante principal de productos',
      'store_id': storeId
    });
    await db.insert('locations', {
      'name': 'Bodega',
      'description': 'Área de almacenamiento',
      'store_id': storeId
    });
    await db.insert('locations', {
      'name': 'Vitrina',
      'description': 'Vitrina de exposición',
      'store_id': storeId
    });

    // Get the IDs of the inserted categories, suppliers, and locations for this store
    final categories = await db.query('categories', where: 'store_id = ?', whereArgs: [storeId]);
    final suppliers = await db.query('suppliers', where: 'store_id = ?', whereArgs: [storeId]);
    final locations = await db.query('locations', where: 'store_id = ?', whereArgs: [storeId]);

    // Insert sample products for this store
    final aleatory = Random();
    for (int i = 1; i <= 10; i++) {
      final expirityDate = DateTime.now().add(Duration(days: aleatory.nextInt(60))).toIso8601String();
      final stockAleatorio = aleatory.nextInt(50) + 10;
      final purchasePrice = (i * 2.0) + 5.0;
      final salePrice = (i * 2.5) + 10.0;
      
      await db.insert('products', {
        'name': 'Producto $storeId-$i',
        'description': 'Descripción del producto $storeId-$i',
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'weight': '${i}g',
        'category_id': categories[i % categories.length]['id'],
        'supplier_id': suppliers[i % suppliers.length]['id'],
        'location_id': locations[i % locations.length]['id'],
        'foto': 'producto${storeId}_$i.png',
        'stock': stockAleatorio,
        'expirity_date': expirityDate,
        'store_id': storeId
      });
    }

    // Insert sample customers for this store
    for (int i = 1; i <= 5; i++) {
      await db.insert('customers', {
        'name': 'Cliente $storeId-$i',
        'email': 'cliente$storeId$i@email.com',
        'phone': '555-000$storeId$i',
        'address': 'Dirección $storeId-$i',
        'birth_date': '1990-0${(i % 9) + 1}-15',
        'total_purchases': 0.0,
        'store_id': storeId
      });
    }

    // Insert sample discounts for this store
    await db.insert('discounts', {
      'name': 'Descuento 10% Store $storeId',
      'description': 'Descuento del 10% en compras mayores a \$50',
      'type': 'percentage',
      'value': 10.0,
      'min_purchase_amount': 50.0,
      'start_date': DateTime.now().toIso8601String(),
      'end_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
      'is_active': 1,
      'store_id': storeId
    });
  }

  // Métodos con filtrado por store_id
  Future<List<Map<String, dynamic>>> getProducts({int? storeId}) async {
    final db = await database;
    if (storeId != null) {
      return await db.rawQuery('''
        SELECT p.*, 
               c.name as category_name, 
               s.name as supplier_name, 
               l.name as location_name
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN suppliers s ON p.supplier_id = s.id
        LEFT JOIN locations l ON p.location_id = l.id
        WHERE p.store_id = ?
        ORDER BY p.name
      ''', [storeId]);
    }
    return await db.rawQuery('''
      SELECT p.*, 
             c.name as category_name, 
             s.name as supplier_name, 
             l.name as location_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN locations l ON p.location_id = l.id
      ORDER BY p.name
    ''');
  }

  Future<List<Map<String, dynamic>>> getCategories({int? storeId}) async {
    final db = await database;
    if (storeId != null) {
      return await db.query('categories', where: 'store_id = ?', whereArgs: [storeId], orderBy: 'name ASC');
    }
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getSuppliers({int? storeId}) async {
    final db = await database;
    if (storeId != null) {
      return await db.query('suppliers', where: 'store_id = ?', whereArgs: [storeId], orderBy: 'name ASC');
    }
    return await db.query('suppliers', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getLocations({int? storeId}) async {
    final db = await database;
    if (storeId != null) {
      return await db.query('locations', where: 'store_id = ?', whereArgs: [storeId], orderBy: 'name ASC');
    }
    return await db.query('locations', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getCustomers({int? storeId}) async {
    final db = await database;
    if (storeId != null) {
      return await db.query('customers', where: 'store_id = ?', whereArgs: [storeId], orderBy: 'name ASC');
    }
    return await db.query('customers', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getDiscounts({int? storeId}) async {
    final db = await database;
    if (storeId != null) {
      return await db.query('discounts', where: 'store_id = ?', whereArgs: [storeId], orderBy: 'name ASC');
    }
    return await db.query('discounts', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getOrdersWithItems({int? storeId}) async {
    final db = await database;
    
    String whereClause = storeId != null ? 'WHERE o.store_id = ?' : '';
    List<dynamic> whereArgs = storeId != null ? [storeId] : [];
    
    final orders = await db.rawQuery('''
      SELECT o.*, c.name as customer_name, d.name as discount_name
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      LEFT JOIN discounts d ON o.discount_id = d.id
      $whereClause
      ORDER BY o.order_date DESC
    ''', whereArgs);
    
    List<Map<String, dynamic>> ordersWithItems = [];
    for (var order in orders) {
      Map<String, dynamic> orderCopy = Map<String, dynamic>.from(order);
      final orderItems = await db.rawQuery('''
        SELECT oi.*, p.name as product_name
        FROM order_items oi
        JOIN products p ON oi.product_id = p.id
        WHERE oi.order_id = ?
      ''', [order['id']]);
      orderCopy['items'] = orderItems;
      ordersWithItems.add(orderCopy);
    }
    return ordersWithItems;
  }

  // Store management methods
  Future<List<Map<String, dynamic>>> getStores() async {
    final db = await database;
    return await db.query('stores', orderBy: 'name ASC');
  }

  Future<void> insertStore(Map<String, dynamic> store) async {
    final db = await database;
    await db.insert('stores', store);
  }

  Future<void> updateStore(Map<String, dynamic> store) async {
    final db = await database;
    await db.update('stores', store, where: 'id = ?', whereArgs: [store['id']]);
  }

  Future<void> deleteStore(int id) async {
    final db = await database;
    await db.delete('stores', where: 'id = ?', whereArgs: [id]);
  }

  // User management methods
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT u.*, s.name as store_name
      FROM users u
      LEFT JOIN stores s ON u.store_id = s.id
      ORDER BY u.username ASC
    ''');
  }

  Future<Map<String, dynamic>?> getUserByCredentials(String username, String password) async {
    final db = await database;
    print('Searching for user: $username with password: $password');
    
    final result = await db.rawQuery('''
      SELECT u.*, s.name as store_name
      FROM users u
      LEFT JOIN stores s ON u.store_id = s.id
      WHERE u.username = ? AND u.password = ? AND u.is_active = 1
    ''', [username, password]);
    
    print('Query result: $result');
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user);
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.update('users', user, where: 'id = ?', whereArgs: [user['id']]);
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Insert methods with store_id
  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert('products', product);
  }

  Future<void> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.insert('categories', category);
  }

  Future<void> insertSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    await db.insert('suppliers', supplier);
  }

  Future<void> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    await db.insert('locations', location);
  }

  Future<void> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    await db.insert('customers', customer);
  }

  Future<void> insertDiscount(Map<String, dynamic> discount) async {
    final db = await database;
    await db.insert('discounts', discount);
  }

  Future<int> insertOrderWithPayment(Map<String, dynamic> order) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Insert order
      final orderId = await txn.insert('orders', {
        'order_date': order['order_date'],
        'totalOrden': order['totalOrden'],
        'customer_id': order['customer_id'],
        'discount_id': order['discount_id'],
        'store_id': order['store_id'],
      });
      
      return orderId;
    });
  }

  Future<void> insertOrderItem(Map<String, dynamic> orderItem) async {
    final db = await database;
    await db.insert('order_items', orderItem);
  }

  // Update methods
  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.update('products', product, where: 'id = ?', whereArgs: [product['id']]);
  }

  Future<void> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.update('categories', category, where: 'id = ?', whereArgs: [category['id']]);
  }

  Future<void> updateSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    await db.update('suppliers', supplier, where: 'id = ?', whereArgs: [supplier['id']]);
  }

  Future<void> updateLocation(Map<String, dynamic> location) async {
    final db = await database;
    await db.update('locations', location, where: 'id = ?', whereArgs: [location['id']]);
  }

  Future<void> updateCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    await db.update('customers', customer, where: 'id = ?', whereArgs: [customer['id']]);
  }

  Future<void> updateDiscount(Map<String, dynamic> discount) async {
    final db = await database;
    await db.update('discounts', discount, where: 'id = ?', whereArgs: [discount['id']]);
  }

  // Delete methods
  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSupplier(int id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteOrder(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Primero eliminar los items de la orden
      await txn.delete('order_items', where: 'order_id = ?', whereArgs: [id]);
      // Luego eliminar la orden
      await txn.delete('orders', where: 'id = ?', whereArgs: [id]);
      // También eliminar los pagos asociados si existen
      await txn.delete('cash_sales', where: 'order_id = ?', whereArgs: [id]);
    });
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDiscount(int id) async {
    final db = await database;
    await db.delete('discounts', where: 'id = ?', whereArgs: [id]);
  }

  // Cash management
  Future<void> registerCashSale(int orderId, double amount) async {
    final db = await database;
    
    // Get the store_id from the order
    final orderResult = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    if (orderResult.isNotEmpty) {
      final storeId = orderResult.first['store_id'];
      
      await db.insert('cash_sales', {
        'order_id': orderId,
        'amount': amount,
        'payment_method': 'cash',
        'transaction_date': DateTime.now().toIso8601String(),
        'store_id': storeId,
      });
    }
  }

  Future<void> updateCustomerPurchaseStats(int customerId, double orderTotal) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE customers 
      SET total_purchases = total_purchases + ?, 
          last_purchase_date = ?
      WHERE id = ?
    ''', [orderTotal, DateTime.now().toIso8601String(), customerId]);
  }

  // Product-related queries with store filtering
  Future<List<Map<String, dynamic>>> getProductsByCategory(int categoryId, {int? storeId}) async {
    final db = await database;
    
    String whereClause = 'WHERE p.category_id = ?';
    List<dynamic> whereArgs = [categoryId];
    
    if (storeId != null) {
      whereClause += ' AND p.store_id = ?';
      whereArgs.add(storeId);
    }
    
    return await db.rawQuery('''
      SELECT p.*, 
             c.name as category_name, 
             s.name as supplier_name, 
             l.name as location_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN locations l ON p.location_id = l.id
      $whereClause
    ''', whereArgs);
  }

  Future<List<Map<String, dynamic>>> getProductsBySupplier(int supplierId, {int? storeId}) async {
    final db = await database;
    
    String whereClause = 'WHERE p.supplier_id = ?';
    List<dynamic> whereArgs = [supplierId];
    
    if (storeId != null) {
      whereClause += ' AND p.store_id = ?';
      whereArgs.add(storeId);
    }
    
    return await db.rawQuery('''
      SELECT p.*, 
             c.name as category_name, 
             s.name as supplier_name, 
             l.name as location_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN locations l ON p.location_id = l.id
      $whereClause
    ''', whereArgs);
  }

  Future<List<Map<String, dynamic>>> getProductsByLocation(int locationId, {int? storeId}) async {
    final db = await database;
    
    String whereClause = 'WHERE p.location_id = ?';
    List<dynamic> whereArgs = [locationId];
    
    if (storeId != null) {
      whereClause += ' AND p.store_id = ?';
      whereArgs.add(storeId);
    }
    
    return await db.rawQuery('''
      SELECT p.*, 
             c.name as category_name, 
             s.name as supplier_name, 
             l.name as location_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN locations l ON p.location_id = l.id
      $whereClause
    ''', whereArgs);
  }

  Future<Map<String, dynamic>?> getProductByName(String name, {int? storeId}) async {
    final db = await database;
    
    String whereClause = 'name = ?';
    List<dynamic> whereArgs = [name];
    
    if (storeId != null) {
      whereClause += ' AND store_id = ?';
      whereArgs.add(storeId);
    }
    
    final result = await db.query('products', where: whereClause, whereArgs: whereArgs);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // ====== MÉTODOS FALTANTES ======

  // Cash register methods
  Future<Map<String, dynamic>?> getCurrentCashRegister() async {
    final db = await database;
    final today = DateTime.now().toString().substring(0, 10);
    final result = await db.query(
      'cash_registers',
      where: 'date = ? AND status = ?',
      whereArgs: [today, 'abierta'],
      orderBy: 'opening_time DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getCashMovementsByDate(String date) async {
    final db = await database;
    return await db.query(
      'cash_movements',
      where: 'date LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'date DESC',
    );
  }

  Future<double> getTotalCashSalesToday() async {
    final db = await database;
    final today = DateTime.now().toString().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM cash_sales
      WHERE transaction_date LIKE ?
    ''', ['$today%']);
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalCashIncomesToday() async {
    final db = await database;
    final today = DateTime.now().toString().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM cash_movements
      WHERE type = 'income' AND date LIKE ?
    ''', ['$today%']);
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalCashOutcomesToday() async {
    final db = await database;
    final today = DateTime.now().toString().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM cash_movements
      WHERE type = 'expense' AND date LIKE ?
    ''', ['$today%']);
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> calculateExpectedCashAmount() async {
    final db = await database;
    final today = DateTime.now().toString().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT 
        (SELECT COALESCE(SUM(amount), 0) FROM cash_movements WHERE type = 'income' AND date LIKE ?) -
        (SELECT COALESCE(SUM(amount), 0) FROM cash_movements WHERE type = 'expense' AND date LIKE ?) as expected
    ''', ['$today%', '$today%']);
    
    return (result.first['expected'] as double?) ?? 0.0;
  }

  Future<void> insertCashRegister(Map<String, dynamic> register) async {
    final db = await database;
    await db.insert('cash_registers', register);
  }

  Future<void> updateCashRegister(Map<String, dynamic> register) async {
    final db = await database;
    await db.update('cash_registers', register, where: 'id = ?', whereArgs: [register['id']]);
  }

  // Get cash registers by date
  Future<List<Map<String, dynamic>>> getCashRegistersByDate(String date) async {
    final db = await database;
    return await db.query(
      'cash_registers',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'opening_time DESC',
    );
  }

  // Get cash register by ID
  Future<Map<String, dynamic>?> getCashRegisterById(int id) async {
    final db = await database;
    final result = await db.query(
      'cash_registers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> insertCashMovement(Map<String, dynamic> movement) async {
    final db = await database;
    await db.insert('cash_movements', movement);
  }

  // Product stock methods
  Future<void> addProductStock(int productId, int quantityToAdd) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE products 
      SET stock = stock + ?
      WHERE id = ?
    ''', [quantityToAdd, productId]);
  }

  Future<void> updateProductStock(int productId, int newStock) async {
    final db = await database;
    await db.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [productId]);
  }

  // Customer search and validation methods
  Future<List<Map<String, dynamic>>> searchCustomers(String query, {int? storeId}) async {
    final db = await database;
    
    String whereClause = '(name LIKE ? OR email LIKE ? OR phone LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%'];
    
    if (storeId != null) {
      whereClause += ' AND store_id = ?';
      whereArgs.add(storeId);
    }
    
    return await db.query('customers', where: whereClause, whereArgs: whereArgs, orderBy: 'name ASC');
  }

  Future<bool> customerExistsByPhone(String phone, {int? excludeId, int? storeId}) async {
    final db = await database;
    
    String whereClause = 'phone = ?';
    List<dynamic> whereArgs = [phone];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    if (storeId != null) {
      whereClause += ' AND store_id = ?';
      whereArgs.add(storeId);
    }
    
    final result = await db.query('customers', where: whereClause, whereArgs: whereArgs);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10, int? storeId}) async {
    final db = await database;
    
    String whereClause = storeId != null ? 'WHERE store_id = ?' : '';
    List<dynamic> whereArgs = storeId != null ? [storeId] : [];
    
    return await db.rawQuery('''
      SELECT * FROM customers
      $whereClause
      ORDER BY total_purchases DESC
      LIMIT ?
    ''', [...whereArgs, limit]);
  }

  Future<List<Map<String, dynamic>>> getRecentCustomers({int limit = 10, int? storeId}) async {
    final db = await database;
    
    String whereClause = storeId != null ? 'WHERE store_id = ?' : '';
    List<dynamic> whereArgs = storeId != null ? [storeId] : [];
    
    return await db.rawQuery('''
      SELECT * FROM customers
      $whereClause
      ORDER BY created_at DESC
      LIMIT ?
    ''', [...whereArgs, limit]);
  }

  Future<List<Map<String, dynamic>>> getActiveCustomers({int daysAgo = 30, int? storeId}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String();
    
    String whereClause = 'WHERE last_purchase_date >= ?';
    List<dynamic> whereArgs = [cutoffDate];
    
    if (storeId != null) {
      whereClause += ' AND store_id = ?';
      whereArgs.add(storeId);
    }
    
    return await db.rawQuery('''
      SELECT * FROM customers
      $whereClause
      ORDER BY last_purchase_date DESC
    ''', whereArgs);
  }

  Future<List<Map<String, dynamic>>> getTopCustomersByPoints({int limit = 10, int? storeId}) async {
    final db = await database;
    
    String whereClause = storeId != null ? 'WHERE store_id = ?' : '';
    List<dynamic> whereArgs = storeId != null ? [storeId] : [];
    
    return await db.rawQuery('''
      SELECT * FROM customers
      $whereClause
      ORDER BY total_purchases DESC
      LIMIT ?
    ''', [...whereArgs, limit]);
  }

  // User management methods
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> userExistsByUsername(String username, {int? excludeId}) async {
    final db = await database;
    
    String whereClause = 'username = ?';
    List<dynamic> whereArgs = [username];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final result = await db.query('users', where: whereClause, whereArgs: whereArgs);
    return result.isNotEmpty;
  }

  Future<bool> userExistsByEmail(String email, {int? excludeId}) async {
    final db = await database;
    
    String whereClause = 'email = ?';
    List<dynamic> whereArgs = [email];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final result = await db.query('users', where: whereClause, whereArgs: whereArgs);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT u.*, s.name as store_name
      FROM users u
      LEFT JOIN stores s ON u.store_id = s.id
      WHERE u.username LIKE ? OR u.full_name LIKE ? OR u.email LIKE ?
      ORDER BY u.username ASC
    ''', ['%$query%', '%$query%', '%$query%']);
  }

  // User session methods
  Future<void> insertUserSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.insert('user_sessions', session);
  }

  Future<void> updateUserLastLogin(int userId) async {
    final db = await database;
    await db.update('users', 
      {'created_at': DateTime.now().toIso8601String()}, 
      where: 'id = ?', 
      whereArgs: [userId]
    );
  }

  Future<void> endUserSession(String sessionToken) async {
    final db = await database;
    await db.update('user_sessions', 
      {'is_active': 0}, 
      where: 'session_token = ?', 
      whereArgs: [sessionToken]
    );
  }

  Future<void> endAllUserSessions(int userId) async {
    final db = await database;
    await db.update('user_sessions', 
      {'is_active': 0}, 
      where: 'user_id = ?', 
      whereArgs: [userId]
    );
  }

  Future<Map<String, dynamic>?> getSessionByToken(String token) async {
    final db = await database;
    final result = await db.query('user_sessions', 
      where: 'session_token = ? AND is_active = 1', 
      whereArgs: [token]
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> cleanupExpiredSessions() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update('user_sessions', 
      {'is_active': 0}, 
      where: 'expires_at < ?', 
      whereArgs: [now]
    );
  }

  // Discount search methods
  Future<List<Map<String, dynamic>>> searchDiscounts(String query, {int? storeId}) async {
    final db = await database;
    
    String whereClause = '(name LIKE ? OR description LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];
    
    if (storeId != null) {
      whereClause += ' AND store_id = ?';
      whereArgs.add(storeId);
    }
    
    return await db.query('discounts', where: whereClause, whereArgs: whereArgs, orderBy: 'name ASC');
  }

  // Financial reporting methods
  Future<List<Map<String, dynamic>>> getFinancialDataForLastYear() async {
    final db = await database;
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month);

    final result = await db.rawQuery('''
      SELECT 
        strftime('%m', date) as month,
        strftime('%Y', date) as year,
        type,
        SUM(amount) as total_amount
      FROM financial_transactions
      WHERE date >= ?
      GROUP BY month, year, type
      ORDER BY year DESC, month DESC
    ''', [lastYear.toIso8601String()]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getFinancialDataBetweenDates(DateTime startDate, DateTime endDate) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        strftime('%m', date) as month,
        strftime('%Y', date) as year,
        type,
        SUM(amount) as total_amount
      FROM financial_transactions
      WHERE date BETWEEN ? AND ?
      GROUP BY month, year, type
      ORDER BY year DESC, month DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getProductsByRotation({required String period, int? storeId}) async {
    final db = await database;
    String dateCondition;
    if (period == 'week') {
      dateCondition = DateTime.now().subtract(Duration(days: 7)).toIso8601String();
    } else if (period == 'month') {
      dateCondition = DateTime.now().subtract(Duration(days: 30)).toIso8601String();
    } else if (period == 'year') {
      dateCondition = DateTime.now().subtract(Duration(days: 365)).toIso8601String();
    } else {
      throw ArgumentError('Invalid period: $period');
    }

    String whereClause = 'WHERE o.order_date >= ?';
    List<dynamic> whereArgs = [dateCondition];
    
    if (storeId != null) {
      whereClause += ' AND p.store_id = ?';
      whereArgs.add(storeId);
    }

    return await db.rawQuery('''
      SELECT p.*, SUM(oi.quantity) as total_quantity
      FROM products p
      JOIN order_items oi ON p.id = oi.product_id
      JOIN orders o ON oi.order_id = o.id
      $whereClause
      GROUP BY p.id
      ORDER BY total_quantity DESC
    ''', whereArgs);
  }

  Future<List<Map<String, dynamic>>> getSalesDataForLastYear({int? storeId}) async {
    final db = await database;
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month);

    String whereClause = 'WHERE o.order_date >= ?';
    List<dynamic> whereArgs = [lastYear.toIso8601String()];
    
    if (storeId != null) {
      whereClause += ' AND o.store_id = ?';
      whereArgs.add(storeId);
    }

    final salesData = await db.rawQuery('''
      SELECT 
        strftime('%m', o.order_date) as month,
        strftime('%Y', o.order_date) as year,
        p.name,
        p.purchase_price,
        p.sale_price,
        SUM(oi.quantity) as quantity,
        SUM((p.sale_price - p.purchase_price) * oi.quantity) as profit,
        SUM(p.purchase_price * oi.quantity) as total_cost
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      $whereClause
      GROUP BY month, year, p.id
      ORDER BY year DESC, month DESC
    ''', whereArgs);

    return salesData;
  }
}