import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';
import 'package:get/get.dart';
import '../models/customer.dart';
import '../models/discount.dart';
import '../models/user.dart';
import '../models/user_session.dart';
import '../controllers/store_controller.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'beauty_store.db');
    return await openDatabase(
      path,
      version: 12, // Versión 12: Agregar store_id a locations
      onCreate: (db, version) async {
        // Tabla de tiendas
        db.execute('''
          CREATE TABLE stores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            address TEXT,
            phone TEXT,
            email TEXT,
            status TEXT DEFAULT 'active',
            created_at TEXT NOT NULL
          )
        ''');
        
        // Tabla de roles
        db.execute('''
          CREATE TABLE roles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT
          )
        ''');
        
        db.execute('''
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
            store_id INTEGER DEFAULT 1,
            FOREIGN KEY (store_id) REFERENCES stores(id)
          )
        ''');
        db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            foto TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            foto TEXT,
            name TEXT NOT NULL,
            contact_name TEXT,
            contact_email TEXT,
            contact_phone TEXT,
            address TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_date TEXT NOT NULL,
            totalOrden REAL NOT NULL,
            payment_method TEXT DEFAULT 'efectivo',
            customer_id INTEGER,
            store_id INTEGER DEFAULT 1,
            FOREIGN KEY (customer_id) REFERENCES customers (id),
            FOREIGN KEY (store_id) REFERENCES stores(id)
          )
        ''');
        db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            store_id INTEGER DEFAULT 1,
            FOREIGN KEY (store_id) REFERENCES stores(id)
          )
        ''');
        db.execute('''
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
        db.execute('''
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
        db.execute('''
          CREATE TABLE financial_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT,
          type TEXT,
          amount REAL,
          store_id INTEGER DEFAULT 1,
          FOREIGN KEY (store_id) REFERENCES stores(id)
        )
        ''');
        
        // Nuevas tablas para sistema de caja
        db.execute('''
          CREATE TABLE cash_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            order_id INTEGER,
            user_id TEXT,
            store_id INTEGER DEFAULT 1,
            FOREIGN KEY (order_id) REFERENCES orders (id),
            FOREIGN KEY (store_id) REFERENCES stores(id)
          )
        ''');
        
        db.execute('''
          CREATE TABLE cash_registers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            opening_amount REAL NOT NULL,
            closing_amount REAL,
            expected_amount REAL,
            difference REAL,
            status TEXT NOT NULL,
            opening_time TEXT,
            closing_time TEXT,
            user_id TEXT,
            store_id INTEGER DEFAULT 1,
            FOREIGN KEY (store_id) REFERENCES stores(id)
          )
        ''');
        
        db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT,
            address TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            last_purchase TEXT,
            total_spent REAL DEFAULT 0.0,
            total_orders INTEGER DEFAULT 0,
            loyalty_points INTEGER DEFAULT 0
          )
        ''');
        
        db.execute('''
          CREATE TABLE discounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            type TEXT NOT NULL,
            value REAL NOT NULL,
            minimum_amount REAL,
            maximum_discount REAL,
            start_date TEXT,
            end_date TEXT,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');
        
        // Tabla de asignación usuario-tienda
        db.execute('''
          CREATE TABLE user_store_assignments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            store_id INTEGER NOT NULL,
            assigned_at TEXT NOT NULL,
            assigned_by INTEGER,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
            FOREIGN KEY (assigned_by) REFERENCES users(id),
            UNIQUE(user_id, store_id)
          )
        ''');
        
        // Tablas para sistema de usuarios y roles
        db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            last_login_at TEXT,
            profile_image_url TEXT,
            phone TEXT,
            permissions TEXT
          )
        ''');
        
        db.execute('''
          CREATE TABLE user_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            session_token TEXT NOT NULL UNIQUE,
            created_at TEXT NOT NULL,
            expires_at TEXT,
            device_info TEXT NOT NULL,
            ip_address TEXT,
            is_active INTEGER NOT NULL DEFAULT 1,
            ended_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');
        
        // Insertar roles predeterminados
        await db.insert('roles', {
          'id': 1,
          'name': 'admin',
          'description': 'Administrador del sistema con acceso completo',
        });
        await db.insert('roles', {
          'id': 2,
          'name': 'manager',
          'description': 'Gerente de tienda con permisos de gestión',
        });
        await db.insert('roles', {
          'id': 3,
          'name': 'employee',
          'description': 'Empleado con permisos básicos',
        });
        
        // Insertar tienda principal
        await db.insert('stores', {
          'id': 1,
          'name': 'Tienda Principal',
          'address': 'Dirección Principal',
          'phone': '0000000000',
          'email': 'principal@bellezapp.com',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        await _insertTestData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migración v1 -> v2: Añadir tablas de cash register
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cash_movements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              type TEXT NOT NULL,
              amount REAL NOT NULL,
              description TEXT,
              order_id INTEGER,
              user_id TEXT,
              FOREIGN KEY (order_id) REFERENCES orders (id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cash_registers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              opening_amount REAL NOT NULL,
              closing_amount REAL,
              expected_amount REAL,
              difference REAL,
              status TEXT NOT NULL,
              opening_time TEXT,
              closing_time TEXT,
              user_id TEXT
            )
          ''');
        }
        
        // Migración v2 -> v3: Resolver conflictos de schema existente
        if (oldVersion < 3) {
          // Verificar y recrear tablas si hay conflictos de schema
          try {
            await db.execute('SELECT COUNT(*) FROM cash_movements LIMIT 1');
          } catch (e) {
            // La tabla no existe o tiene problemas, recrearla
            await db.execute('DROP TABLE IF EXISTS cash_movements');
            await db.execute('''
              CREATE TABLE cash_movements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                type TEXT NOT NULL,
                amount REAL NOT NULL,
                description TEXT,
                order_id INTEGER,
                user_id TEXT,
                FOREIGN KEY (order_id) REFERENCES orders (id)
              )
            ''');
          }
          
          try {
            await db.execute('SELECT COUNT(*) FROM cash_registers LIMIT 1');
          } catch (e) {
            // La tabla no existe o tiene problemas, recrearla
            await db.execute('DROP TABLE IF EXISTS cash_registers');
            await db.execute('''
              CREATE TABLE cash_registers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                opening_amount REAL NOT NULL,
                closing_amount REAL,
                expected_amount REAL,
                difference REAL,
                status TEXT NOT NULL,
                opening_time TEXT,
                closing_time TEXT,
                user_id TEXT
              )
            ''');
          }
        }
        
        // Migración v3 -> v4: Agregar payment_method a orders
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE orders ADD COLUMN payment_method TEXT DEFAULT \'efectivo\'');
          } catch (e) {
            // La columna ya existe, ignorar error
            print('Column payment_method already exists or error adding: $e');
          }
        }
        
        // Migración v4 -> v5: Agregar tabla customers
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS customers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              phone TEXT NOT NULL,
              email TEXT,
              address TEXT,
              notes TEXT,
              created_at TEXT NOT NULL,
              last_purchase TEXT,
              total_spent REAL DEFAULT 0.0,
              total_orders INTEGER DEFAULT 0,
              loyalty_points INTEGER DEFAULT 0
            )
          ''');
        }
        
        // Migración v5 -> v6: Agregar tabla discounts
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS discounts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              type TEXT NOT NULL,
              value REAL NOT NULL,
              minimum_amount REAL,
              maximum_discount REAL,
              start_date TEXT,
              end_date TEXT,
              is_active INTEGER NOT NULL DEFAULT 1
            )
          ''');
        }
        
        // Migración v6 -> v7: Agregar loyalty_points a customers y customer_id a orders
        if (oldVersion < 7) {
          await db.execute('''
            ALTER TABLE customers ADD COLUMN loyalty_points INTEGER DEFAULT 0
          ''');
          await db.execute('''
            ALTER TABLE orders ADD COLUMN customer_id INTEGER
          ''');
        }
        
        // Migración v7 -> v8: Agregar sistema de usuarios y roles
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE,
              email TEXT NOT NULL UNIQUE,
              first_name TEXT NOT NULL,
              last_name TEXT NOT NULL,
              password_hash TEXT NOT NULL,
              role TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              last_login_at TEXT,
              profile_image_url TEXT,
              phone TEXT,
              permissions TEXT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              session_token TEXT NOT NULL UNIQUE,
              created_at TEXT NOT NULL,
              expires_at TEXT,
              device_info TEXT NOT NULL,
              ip_address TEXT,
              is_active INTEGER NOT NULL DEFAULT 1,
              ended_at TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
          
          // Crear usuario administrador por defecto
          // Hash de "admin123" usando SHA256
          const adminPasswordHash = "240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9";
          
          await db.insert('users', {
            'username': 'admin',
            'email': 'admin@bellezapp.com',
            'first_name': 'Administrador',
            'last_name': 'Sistema',
            'password_hash': adminPasswordHash,
            'role': 'admin',
            'is_active': 1,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // Migración v8 -> v9: Verificar y asegurar usuario admin
        if (oldVersion < 9) {
          // Verificar si el usuario admin existe
          final adminExists = await db.query(
            'users',
            where: 'username = ?',
            whereArgs: ['admin'],
          );
          
          if (adminExists.isEmpty) {
            // Crear usuario admin si no existe
            const adminPasswordHash = "240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9";
            
            await db.insert('users', {
              'username': 'admin',
              'email': 'admin@bellezapp.com',
              'first_name': 'Administrador',
              'last_name': 'Sistema',
              'password_hash': adminPasswordHash,
              'role': 'admin',
              'is_active': 1,
              'created_at': DateTime.now().toIso8601String(),
              'permissions': '{"manage_users":true,"manage_products":true,"manage_orders":true,"manage_customers":true,"manage_discounts":true,"view_reports":true,"manage_inventory":true,"manage_cash":true,"manage_settings":true}',
            });
          }
        }

        // Migración v9 -> v10: Implementar sistema multi-tienda
        if (oldVersion < 10) {
          // Crear tabla de tiendas
          await db.execute('''
            CREATE TABLE IF NOT EXISTS stores (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              address TEXT,
              phone TEXT,
              email TEXT,
              status TEXT DEFAULT 'active',
              created_at TEXT NOT NULL
            )
          ''');
          
          // Crear tabla de roles
          await db.execute('''
            CREATE TABLE IF NOT EXISTS roles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              description TEXT
            )
          ''');
          
          // Crear tabla de asignación usuario-tienda
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_store_assignments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              store_id INTEGER NOT NULL,
              assigned_at TEXT NOT NULL,
              assigned_by INTEGER,
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
              FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
              FOREIGN KEY (assigned_by) REFERENCES users(id),
              UNIQUE(user_id, store_id)
            )
          ''');
          
          // Insertar roles predeterminados
          await db.insert('roles', {
            'id': 1,
            'name': 'admin',
            'description': 'Administrador del sistema con acceso completo',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          
          await db.insert('roles', {
            'id': 2,
            'name': 'manager',
            'description': 'Gerente de tienda con permisos de gestión',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          
          await db.insert('roles', {
            'id': 3,
            'name': 'employee',
            'description': 'Empleado con permisos básicos',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          
          // Insertar tienda principal
          await db.insert('stores', {
            'id': 1,
            'name': 'Tienda Principal',
            'address': 'Dirección Principal',
            'phone': '0000000000',
            'email': 'principal@bellezapp.com',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          
          // Agregar store_id a productos existentes
          try {
            await db.execute('ALTER TABLE products ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)');
          } catch (e) {
            print('Column store_id already exists in products: $e');
          }
          
          // Agregar store_id a orders existentes
          try {
            await db.execute('ALTER TABLE orders ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)');
          } catch (e) {
            print('Column store_id already exists in orders: $e');
          }
          
          // Asignar el usuario admin a la tienda principal
          final adminUser = await db.query('users', where: 'username = ?', whereArgs: ['admin']);
          if (adminUser.isNotEmpty) {
            await db.insert('user_store_assignments', {
              'user_id': adminUser.first['id'],
              'store_id': 1,
              'assigned_at': DateTime.now().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
        
        if (oldVersion < 11) {
          print('🔄 Migrando a versión 11: Agregando store_id a financial_transactions y cash_movements');
          
          // Agregar store_id a financial_transactions
          try {
            await db.execute('ALTER TABLE financial_transactions ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)');
            print('✅ Columna store_id agregada a financial_transactions');
          } catch (e) {
            print('⚠️ Column store_id already exists in financial_transactions: $e');
          }
          
          // Agregar store_id a cash_movements
          try {
            await db.execute('ALTER TABLE cash_movements ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)');
            print('✅ Columna store_id agregada a cash_movements');
          } catch (e) {
            print('⚠️ Column store_id already exists in cash_movements: $e');
          }
          
          // Agregar store_id a cash_registers si existe
          try {
            await db.execute('ALTER TABLE cash_registers ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)');
            print('✅ Columna store_id agregada a cash_registers');
          } catch (e) {
            print('⚠️ Column store_id already exists in cash_registers: $e');
          }
          
          print('✅ Migración a versión 11 completada');
        }
        
        if (oldVersion < 12) {
          print('🔄 Migrando a versión 12: Agregando store_id a locations');
          
          // Agregar store_id a locations
          try {
            await db.execute('ALTER TABLE locations ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)');
            print('✅ Columna store_id agregada a locations');
          } catch (e) {
            print('⚠️ Column store_id already exists in locations: $e');
          }
          
          print('✅ Migración a versión 12 completada');
        }
      },
    );
  }

  // Insert products
  Future<void> _insertTestData(Database db) async {
    final aleatory = Random();
    final ahora = DateTime.now();
    final seisMesesAtras = DateTime(ahora.year, ahora.month - 6, ahora.day);
    for (int i = 1; i <= 20; i++) {
      final expirityDate =
          ahora.add(Duration(days: aleatory.nextInt(60))).toIso8601String();
      final stockAleatorio =
          aleatory.nextInt(160); // Genera un número entre 1 y 20
      final purchasePrice = (i * 2.0) + 5.0; // Precio de compra calculado
    final salePrice = (i * 2.5) + 10.0; // Precio de venta calculado
      await db.insert('products', {
        'name': 'Product $i',
        'description': 'Description $i',
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'weight': '${i}kg',
        'category_id': (i % 3) + 1,
        'supplier_id': (i % 3) + 1,
        'location_id': (i % 3) + 1,
        'foto': 'foto$i.png',
        'stock': stockAleatorio, // Asigna el stock aleatorio
        'expirity_date': expirityDate
      });
      
  final amount = purchasePrice * stockAleatorio;
  // Calcular una fecha aleatoria entre la fecha actual y 6 meses atrás
    final diferenciaDias = ahora.difference(seisMesesAtras).inDays;
    final diasAleatorios = aleatory.nextInt(diferenciaDias);
    final transactionDate = seisMesesAtras.add(Duration(days: diasAleatorios)).toIso8601String();

  print('Inserting financial transaction - Type: Salida, Amount: $amount');
  await db.insert('financial_transactions', {
    'date': transactionDate,
    'type': 'Salida',
    'amount': amount,
    'store_id': 1, // Datos de prueba siempre en tienda 1
  });
    }

    // Insert categories
    await db.insert('categories', {
      'name': 'Category 1',
      'description': 'Description 1',
      'foto': 'foto1.png'
    });
    await db.insert('categories', {
      'name': 'Category 2',
      'description': 'Description 2',
      'foto': 'foto2.png'
    });
    await db.insert('categories', {
      'name': 'Category 3',
      'description': 'Description 3',
      'foto': 'foto3.png'
    });

    // Insert suppliers
    await db.insert('suppliers', {
      'name': 'Supplier 1',
      'contact_name': 'Contact 1',
      'contact_email': 'contact1@example.com',
      'contact_phone': '1234567890',
      'address': 'Address 1',
      'foto': 'foto1.png'
    });
    await db.insert('suppliers', {
      'name': 'Supplier 2',
      'contact_name': 'Contact 2',
      'contact_email': 'contact2@example.com',
      'contact_phone': '1234567891',
      'address': 'Address 2',
      'foto': 'foto2.png'
    });
    await db.insert('suppliers', {
      'name': 'Supplier 3',
      'contact_name': 'Contact 3',
      'contact_email': 'contact3@example.com',
      'contact_phone': '1234567892',
      'address': 'Address 3',
      'foto': 'foto3.png'
    });

    // Insert locations
    await db.insert(
        'locations', {'name': 'Location 1', 'description': 'Description 1'});
    await db.insert(
        'locations', {'name': 'Location 2', 'description': 'Description 2'});
    await db.insert(
        'locations', {'name': 'Location 3', 'description': 'Description 3'});

    // Insert orders and order_items
    final random = Random();
    final now = DateTime.now();
    for (int i = 0; i < 50; i++) {
      final orderDate =
          now.subtract(Duration(days: random.nextInt(180))).toIso8601String();
      final orderId = await db.insert('orders', {
        'order_date': orderDate,
        'totalOrden': 0.0, // Placeholder, will be updated later
      });

      double totalOrden = 0.0;
      final numItems =
          random.nextInt(5) + 1; // Each order has between 1 and 5 items
      for (int j = 0; j < numItems; j++) {
        final productId =
            random.nextInt(20) + 1; // Assuming there are 3 products
        final quantity = random.nextInt(10) + 1;
        final price = (await db
                .query('products', where: 'id = ?', whereArgs: [productId]))
            .first['sale_price'] as double;
        totalOrden += quantity * price;

        await db.insert('order_items', {
          'order_id': orderId,
          'product_id': productId,
          'quantity': quantity,
          'price': price,
        });

        // Update product stock
        await db.rawUpdate('''
          UPDATE products
          SET stock = stock - ?
          WHERE id = ?
        ''', [quantity, productId]);
      }

      // Update totalOrden in orders table
      await db.rawUpdate('''
        UPDATE orders
        SET totalOrden = ?
        WHERE id = ?
      ''', [totalOrden, orderId]);
    }
  }

  Future<List<Map<String, dynamic>>> getProducts({int? storeId}) async {
    final db = await database;
    
    // Usar la tienda especificada o la tienda actual del usuario
    final currentStoreId = storeId ?? _getCurrentStoreId();
    
    // Siempre filtrar por tienda (incluso admin)
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
    ''', [currentStoreId]);
  }
  
  // Helper method para obtener ID de tienda actual
  int _getCurrentStoreId() {
    try {
      // Intentar obtener del StoreController
      final storeController = Get.find<StoreController>();
      return storeController.currentStoreId ?? 1;
    } catch (e) {
      // Si no está disponible, usar tienda por defecto
      return 1;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await database;
    return await db.query('suppliers');
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    final currentStoreId = _getCurrentStoreId();
    
    // Filtrar ubicaciones por tienda actual
    return await db.query(
      'locations',
      where: 'store_id = ?',
      whereArgs: [currentStoreId],
    );
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    
    // Agregar store_id actual si no se especifica
    if (!product.containsKey('store_id')) {
      product['store_id'] = _getCurrentStoreId();
    }
    
    await db.insert('products', product);

    // Registrar la salida de dinero
    final purchasePrice = (product['purchase_price'] as double?) ?? 0.0;
    final quantity = (product['quantity'] as int?) ?? 0;
    final amount = purchasePrice * quantity;
    print('Inserting financial transaction - Type: Salida, Amount: $amount');
    await db.insert('financial_transactions', {
      'date': DateTime.now().toIso8601String(),
      'type': 'Salida',
      'amount': amount,
      'store_id': product['store_id'] ?? _getCurrentStoreId(),
    });
  }

  Future<void> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    
    // Las categorías son globales (compartidas entre tiendas)
    // NO agregar store_id
    
    await db.insert('categories', category);
  }

  Future<void> insertSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    
    // Los proveedores son globales (compartidos entre tiendas)
    // NO agregar store_id
    
    await db.insert('suppliers', supplier);
  }

  Future<void> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    
    // Las ubicaciones son específicas de cada tienda
    // Agregar store_id actual si no se especifica
    if (!location.containsKey('store_id')) {
      location['store_id'] = _getCurrentStoreId();
    }
    
    await db.insert('locations', location);
  }

  Future<void> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    double totalOrden = 0.0;
    for (var product in order['products']) {
      totalOrden += product['quantity'] * product['price'];
    }
    
    // Agregar store_id actual si no se especifica
    final orderData = {
      'order_date': order['date'],
      'totalOrden': totalOrden,
    };
    if (!orderData.containsKey('store_id')) {
      orderData['store_id'] = _getCurrentStoreId();
    }
    
    final orderId = await db.insert('orders', orderData);
    for (var product in order['products']) {
      await db.insert('order_items', {
        'order_id': orderId,
        'product_id': product['id'],
        'quantity': product['quantity'],
        'price': product['price'],
      });
    }
  }

  // Nuevo método para insertar orden con método de pago
  Future<int> insertOrderWithPayment(Map<String, dynamic> order) async {
    final db = await database;
    double totalOrden = order['totalOrden'] ?? 0.0;
    
    // Agregar store_id actual si no se especifica
    if (!order.containsKey('store_id')) {
      order['store_id'] = _getCurrentStoreId();
    }
    
    final orderId = await db.insert('orders', {
      'order_date': order['order_date'],
      'totalOrden': totalOrden,
      'payment_method': order['payment_method'] ?? 'efectivo',
      'customer_id': order['customer_id'],
      'store_id': order['store_id'],
    });
    
    return orderId;
  }

  // Método para insertar order item individual
  Future<void> insertOrderItem(Map<String, dynamic> orderItem) async {
    final db = await database;
    await db.insert('order_items', orderItem);
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<void> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.update(
      'categories',
      category,
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  Future<void> updateSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    await db.update(
      'suppliers',
      supplier,
      where: 'id = ?',
      whereArgs: [supplier['id']],
    );
  }

  Future<void> updateLocation(Map<String, dynamic> location) async {
    final db = await database;
    await db.update(
      'locations',
      location,
      where: 'id = ?',
      whereArgs: [location['id']],
    );
  }

  Future<void> updateProductStock(int productId, int quantity) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE products
      SET stock = stock - ?
      WHERE id = ?
    ''', [quantity, productId]);
  }

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

  Future<List<Map<String, dynamic>>> getProductsByCategory(
      int categoryId) async {
    final db = await database;
    final currentStoreId = _getCurrentStoreId();
    
    return await db.rawQuery('''
    SELECT p.*, 
           c.name as category_name, 
           s.name as supplier_name, 
           l.name as location_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN locations l ON p.location_id = l.id
    WHERE p.category_id = ? AND p.store_id = ?
  ''', [categoryId, currentStoreId]);
  }

  Future<List<Map<String, dynamic>>> getProductsBySupplier(
      int supplierId) async {
    final db = await database;
    final currentStoreId = _getCurrentStoreId();
    
    return await db.rawQuery('''
    SELECT p.*, 
           c.name as category_name, 
           s.name as supplier_name, 
           l.name as location_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN locations l ON p.location_id = l.id
    WHERE p.supplier_id = ? AND p.store_id = ?
  ''', [supplierId, currentStoreId]);
  }

  Future<List<Map<String, dynamic>>> getProductsByLocation(int locationId) async {
  final db = await database;
  final currentStoreId = _getCurrentStoreId();
  
  return await db.rawQuery('''
    SELECT p.*, 
           c.name as category_name, 
           s.name as supplier_name, 
           l.name as location_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN locations l ON p.location_id = l.id
    WHERE p.location_id = ? AND p.store_id = ?
  ''', [locationId, currentStoreId]);
}

  Future<Map<String, dynamic>?> getProductByName(String name) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getOrdersWithItems({int? storeId}) async {
    final db = await database;
    
    // Usar la tienda especificada o la tienda actual del usuario
    final currentStoreId = storeId ?? _getCurrentStoreId();
    
    // Siempre filtrar por tienda (incluso admin)
    final orders = await db.query(
      'orders',
      where: 'store_id = ?',
      whereArgs: [currentStoreId],
    );
    
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

  Future<void> addProductStock(int productId, int quantityToAdd) async {
  final db = await database;
  final product = await db.query('products', where: 'id = ?', whereArgs: [productId]);

  if (product.isNotEmpty) {
    final currentStock = (product.first['stock'] as int?) ?? 0;
    final purchasePrice = (product.first['purchase_price'] as double?) ?? 0.0;
    final newStock = currentStock + quantityToAdd;

    await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );

    // Registrar la salida de dinero
    final amount = purchasePrice * quantityToAdd;
    await db.insert('financial_transactions', {
      'date': DateTime.now().toIso8601String(),
      'type': 'Salida',
      'amount': amount,
      'store_id': _getCurrentStoreId(),
    });
  }
}

  Future<List<Map<String, dynamic>>> getProductsByRotation(
      {required String period, int? storeId}) async {
    final db = await database;
    String dateCondition;
    if (period == 'week') {
      dateCondition =
          DateTime.now().subtract(Duration(days: 7)).toIso8601String();
    } else if (period == 'month') {
      dateCondition =
          DateTime.now().subtract(Duration(days: 30)).toIso8601String();
    } else if (period == 'year') {
      dateCondition =
          DateTime.now().subtract(Duration(days: 365)).toIso8601String();
    } else {
      throw ArgumentError('Invalid period: $period');
    }

    // Usar la tienda especificada o la tienda actual del usuario
    final currentStoreId = storeId ?? _getCurrentStoreId();

    // Siempre filtrar por tienda (incluso admin)
    final query = '''
      SELECT p.*, SUM(oi.quantity) as total_quantity
      FROM products p
      JOIN order_items oi ON p.id = oi.product_id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.order_date >= ? AND o.store_id = ?
      GROUP BY p.id
      ORDER BY total_quantity DESC
    ''';
    final args = [dateCondition, currentStoreId];

    return await db.rawQuery(query, args);
  }

  Future<List<Map<String, dynamic>>> getSalesDataForLastYear({int? storeId}) async {
    final db = await database;
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month);
    
    // Usar la tienda especificada o la tienda actual del usuario
    final currentStoreId = storeId ?? _getCurrentStoreId();

    // Siempre filtrar por tienda (incluso admin)
    final query = '''
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
      WHERE o.order_date >= ? AND o.store_id = ?
      GROUP BY month, year, p.id
      ORDER BY year DESC, month DESC
    ''';
    final args = [lastYear.toIso8601String(), currentStoreId];

    final salesData = await db.rawQuery(query, args);

    Map<String, Map<String, dynamic>> groupedData = {};

    for (var row in salesData) {
      final month = row['month'];
      final year = row['year'];
      final key = '$year-$month';

      if (!groupedData.containsKey(key)) {
        groupedData[key] = {
          'month': month,
          'year': year,
          'totalProfit': 0.0,
          'totalCost': 0.0,
          'products': [],
        };
      }

      groupedData[key]!['totalProfit'] += row['profit'] ?? 0.0;
      groupedData[key]!['totalCost'] += row['total_cost'] ?? 0.0;
      groupedData[key]!['products'].add({
        'name': row['name'],
        'purchase_price': row['purchase_price'],
        'sale_price': row['sale_price'],
        'quantity': row['quantity'],
        'profit': row['profit'],
      });
    }

    return groupedData.values.toList();
  }

  Future<List<Map<String, dynamic>>> getFinancialDataForLastYear({int? storeId}) async {
    final db = await database;
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month);
    
    // Usar la tienda especificada o la tienda actual del usuario
    final currentStoreId = storeId ?? _getCurrentStoreId();

    // Siempre filtrar por tienda (incluso admin)
    final incomeQuery = '''
      SELECT 
        strftime('%m', o.order_date) as month,
        strftime('%Y', o.order_date) as year,
        SUM(oi.quantity * p.sale_price) as totalIncome
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      WHERE o.order_date >= ? AND o.store_id = ?
      GROUP BY month, year
      ORDER BY year DESC, month DESC
    ''';
    final incomeArgs = [lastYear.toIso8601String(), currentStoreId];
    
    final incomeData = await db.rawQuery(incomeQuery, incomeArgs);

    final expenseData = await db.rawQuery('''
      SELECT 
        strftime('%m', t.date) as month,
        strftime('%Y', t.date) as year,
        SUM(t.amount) as totalExpense
      FROM financial_transactions t
      WHERE t.type = 'Salida' AND t.date >= ? AND t.store_id = ?
      GROUP BY month, year
      ORDER BY year DESC, month DESC
    ''', [lastYear.toIso8601String(), currentStoreId]);

    Map<String, Map<String, dynamic>> groupedData = {};

    for (var row in incomeData) {
      final month = row['month'];
      final year = row['year'];
      final key = '$year-$month';

      if (!groupedData.containsKey(key)) {
        groupedData[key] = {
          'month': month,
          'year': year,
          'totalIncome': 0.0,
          'totalExpense': 0.0,
        };
      }

      groupedData[key]!['totalIncome'] += row['totalIncome'] ?? 0.0;
    }

    for (var row in expenseData) {
      final month = row['month'];
      final year = row['year'];
      final key = '$year-$month';

      if (!groupedData.containsKey(key)) {
        groupedData[key] = {
          'month': month,
          'year': year,
          'totalIncome': 0.0,
          'totalExpense': 0.0,
        };
      }

      groupedData[key]!['totalExpense'] += row['totalExpense'] ?? 0.0;
    }

    return groupedData.values.toList();
  }

Future<List<Map<String, dynamic>>> getFinancialDataBetweenDates(DateTime startDate, DateTime endDate, {int? storeId}) async {
  final db = await database;

  // Usar la tienda especificada o la tienda actual del usuario
  final currentStoreId = storeId ?? _getCurrentStoreId();

  // Siempre filtrar por tienda (incluso admin)
  final incomeQuery = '''
    SELECT 
      strftime('%m', o.order_date) as month,
      strftime('%Y', o.order_date) as year,
      SUM(oi.quantity * p.sale_price) as totalIncome
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.order_date BETWEEN ? AND ? AND o.store_id = ?
    GROUP BY month, year
    ORDER BY year DESC, month DESC
  ''';
  final incomeArgs = [startDate.toIso8601String(), endDate.toIso8601String(), currentStoreId];

  final incomeData = await db.rawQuery(incomeQuery, incomeArgs);

  final expenseData = await db.rawQuery('''
    SELECT 
      strftime('%m', t.date) as month,
      strftime('%Y', t.date) as year,
      SUM(t.amount) as totalExpense
    FROM financial_transactions t
    WHERE t.type = 'Salida' AND t.date BETWEEN ? AND ? AND t.store_id = ?
    GROUP BY month, year
    ORDER BY year DESC, month DESC
  ''', [startDate.toIso8601String(), endDate.toIso8601String(), currentStoreId]);

  Map<String, Map<String, dynamic>> groupedData = {};

  for (var row in incomeData) {
    final month = row['month'];
    final year = row['year'];
    final key = '$year-$month';

    if (!groupedData.containsKey(key)) {
      groupedData[key] = {
        'month': month,
        'year': year,
        'totalIncome': 0.0,
        'totalExpense': 0.0,
      };
    }

    groupedData[key]!['totalIncome'] += row['totalIncome'] ?? 0.0;
  }

  for (var row in expenseData) {
    final month = row['month'];
    final year = row['year'];
    final key = '$year-$month';

    if (!groupedData.containsKey(key)) {
      groupedData[key] = {
        'month': month,
        'year': year,
        'totalIncome': 0.0,
        'totalExpense': 0.0,
      };
    }

    groupedData[key]!['totalExpense'] += row['totalExpense'] ?? 0.0;
  }

  return groupedData.values.toList();
}

  // ============= MÉTODOS PARA SISTEMA DE CAJA =============
  
  // Métodos para cash_movements
  Future<void> insertCashMovement(Map<String, dynamic> movement) async {
    final db = await database;
    
    // Agregar store_id actual si no se especifica
    if (!movement.containsKey('store_id')) {
      movement['store_id'] = _getCurrentStoreId();
    }
    
    await db.insert('cash_movements', movement);
  }

  Future<List<Map<String, dynamic>>> getCashMovementsByDate(String date) async {
    final db = await database;
    final currentStoreId = _getCurrentStoreId();
    
    return await db.query(
      'cash_movements',
      where: 'date LIKE ? AND store_id = ?',
      whereArgs: ['$date%', currentStoreId],
      orderBy: 'date DESC',
    );
  }

  Future<double> getTotalCashByTypeAndDate(String type, String date) async {
    final db = await database;
    final currentStoreId = _getCurrentStoreId();
    
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM cash_movements
      WHERE type = ? AND date LIKE ? AND store_id = ?
    ''', [type, '$date%', currentStoreId]);
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalCashSalesToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await getTotalCashByTypeAndDate('venta', today);
  }

  Future<double> getTotalCashIncomesToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM cash_movements
      WHERE type IN ('venta', 'entrada') AND date LIKE ?
    ''', ['$today%']);
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalCashOutcomesToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await getTotalCashByTypeAndDate('salida', today);
  }

  // Métodos para cash_registers
  Future<int> insertCashRegister(Map<String, dynamic> register) async {
    final db = await database;
    
    // Agregar store_id actual si no se especifica
    if (!register.containsKey('store_id')) {
      register['store_id'] = _getCurrentStoreId();
    }
    
    return await db.insert('cash_registers', register);
  }

  Future<void> updateCashRegister(Map<String, dynamic> register) async {
    final db = await database;
    await db.update(
      'cash_registers',
      register,
      where: 'id = ?',
      whereArgs: [register['id']],
    );
  }

  Future<Map<String, dynamic>?> getCashRegisterByDate(String date) async {
    final db = await database;
    final currentStoreId = _getCurrentStoreId();
    
    final result = await db.query(
      'cash_registers',
      where: 'date = ? AND store_id = ?',
      whereArgs: [date, currentStoreId],
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getCurrentCashRegister() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await getCashRegisterByDate(today);
  }

  Future<bool> isCashRegisterOpen() async {
    final currentRegister = await getCurrentCashRegister();
    return currentRegister != null && currentRegister['status'] == 'abierta';
  }

  Future<double> calculateExpectedCashAmount() async {
    final currentRegister = await getCurrentCashRegister();
    
    if (currentRegister == null) return 0.0;
    
    final openingAmount = (currentRegister['opening_amount'] as double?) ?? 0.0;
    final totalIncomes = await getTotalCashIncomesToday();
    final totalOutcomes = await getTotalCashOutcomesToday();
    
    return openingAmount + totalIncomes - totalOutcomes;
  }

  // Método para registrar venta en efectivo automáticamente
  Future<void> registerCashSale(int orderId, double amount) async {
    final now = DateTime.now().toIso8601String();
    await insertCashMovement({
      'date': now,
      'type': 'venta',
      'amount': amount,
      'description': 'Venta en efectivo',
      'order_id': orderId,
    });
  }

  // ============= MÉTODOS PARA CUSTOMERS =============
  
  // Obtener todos los customers
  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Obtener customer por ID
  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // Buscar customers por nombre o teléfono
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Insertar nuevo customer
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  // Actualizar customer
  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // Eliminar customer
  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Actualizar estadísticas del customer después de una compra
  Future<void> updateCustomerPurchaseStats(int customerId, double orderTotal) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      // Calcular puntos ganados (1 punto por cada $10)
      final pointsEarned = Customer.calculatePointsFromPurchase(orderTotal);
      
      final updatedCustomer = customer.copyWith(
        lastPurchase: DateTime.now(),
        totalSpent: customer.totalSpent + orderTotal,
        totalOrders: customer.totalOrders + 1,
        loyaltyPoints: customer.loyaltyPoints + pointsEarned,
      );
      await updateCustomer(updatedCustomer);
    }
  }

  // Obtener top customers por gasto total
  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'total_spent DESC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Obtener top customers por puntos de lealtad
  Future<List<Customer>> getTopCustomersByPoints({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'loyalty_points DESC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Obtener customers recientes (por fecha de registro)
  Future<List<Customer>> getRecentCustomers({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Obtener customers activos (con compras recientes)
  Future<List<Customer>> getActiveCustomers({int daysAgo = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'last_purchase > ?',
      whereArgs: [cutoffDate],
      orderBy: 'last_purchase DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Verificar si existe un customer con el mismo teléfono
  Future<bool> customerExistsByPhone(String phone, {int? excludeId}) async {
    final db = await database;
    
    String whereClause = 'phone = ?';
    List<dynamic> whereArgs = [phone];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return maps.isNotEmpty;
  }

  // ============= MÉTODOS PARA DESCUENTOS =============

  // Obtener todos los descuentos
  Future<List<Discount>> getDiscounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'discounts',
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Discount.fromMap(maps[i]);
    });
  }

  // Obtener descuento por ID
  Future<Discount?> getDiscountById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'discounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Discount.fromMap(maps.first);
    }
    return null;
  }

  // Buscar descuentos por nombre o descripción
  Future<List<Discount>> searchDiscounts(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'discounts',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Discount.fromMap(maps[i]);
    });
  }

  // Insertar descuento
  Future<int> insertDiscount(Discount discount) async {
    final db = await database;
    return await db.insert('discounts', discount.toMap());
  }

  // Actualizar descuento
  Future<void> updateDiscount(Discount discount) async {
    final db = await database;
    await db.update(
      'discounts',
      discount.toMap(),
      where: 'id = ?',
      whereArgs: [discount.id],
    );
  }

  // Eliminar descuento
  Future<void> deleteDiscount(int id) async {
    final db = await database;
    await db.delete(
      'discounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener descuentos activos
  Future<List<Discount>> getActiveDiscounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'discounts',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Discount.fromMap(maps[i]);
    });
  }

  // Obtener descuentos aplicables para un monto específico
  Future<List<Discount>> getApplicableDiscounts(double amount) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'discounts',
      where: '''
        is_active = 1 
        AND (minimum_amount IS NULL OR minimum_amount <= ?)
        AND (start_date IS NULL OR start_date <= ?)
        AND (end_date IS NULL OR end_date >= ?)
      ''',
      whereArgs: [amount, now, now],
      orderBy: 'value DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Discount.fromMap(maps[i]);
    });
  }

  // Verificar si existe un descuento con el mismo nombre
  Future<bool> discountExistsByName(String name, {int? excludeId}) async {
    final db = await database;
    
    String whereClause = 'name = ?';
    List<dynamic> whereArgs = [name];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'discounts',
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return maps.isNotEmpty;
  }

  // ============= MÉTODOS PARA SISTEMA DE USUARIOS =============

  // Obtener todos los usuarios
  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'username ASC',
    );
    
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Obtener usuario por ID
  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Obtener usuario por username
  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Obtener usuario por email
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Buscar usuarios por nombre o username
  Future<List<User>> searchUsers(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username LIKE ? OR first_name LIKE ? OR last_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'username ASC',
    );
    
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Obtener todos los usuarios
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'username ASC');
  }

  // Insertar nuevo usuario
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  // Actualizar usuario
  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Actualizar último login
  Future<void> updateUserLastLogin(int userId) async {
    final db = await database;
    await db.update(
      'users',
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Eliminar usuario
  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener usuarios activos
  Future<List<User>> getActiveUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'username ASC',
    );
    
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Verificar si existe un usuario con el mismo username
  Future<bool> userExistsByUsername(String username, {int? excludeId}) async {
    final db = await database;
    
    String whereClause = 'username = ?';
    List<dynamic> whereArgs = [username];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return maps.isNotEmpty;
  }

  // Verificar si existe un usuario con el mismo email
  Future<bool> userExistsByEmail(String email, {int? excludeId}) async {
    final db = await database;
    
    String whereClause = 'email = ?';
    List<dynamic> whereArgs = [email];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return maps.isNotEmpty;
  }

  // ============= MÉTODOS PARA SESIONES DE USUARIOS =============

  // Insertar nueva sesión
  Future<int> insertUserSession(UserSession session) async {
    final db = await database;
    return await db.insert('user_sessions', session.toMap());
  }

  // Obtener sesión por token
  Future<UserSession?> getSessionByToken(String token) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_sessions',
      where: 'session_token = ?',
      whereArgs: [token],
    );
    
    if (maps.isNotEmpty) {
      return UserSession.fromMap(maps.first);
    }
    return null;
  }

  // Obtener sesiones activas de un usuario
  Future<List<UserSession>> getActiveUserSessions(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_sessions',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return UserSession.fromMap(maps[i]);
    });
  }

  // Actualizar sesión
  Future<void> updateUserSession(UserSession session) async {
    final db = await database;
    await db.update(
      'user_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // Terminar sesión
  Future<void> endUserSession(String token) async {
    final db = await database;
    await db.update(
      'user_sessions',
      {
        'is_active': 0,
        'ended_at': DateTime.now().toIso8601String(),
      },
      where: 'session_token = ?',
      whereArgs: [token],
    );
  }

  // Terminar todas las sesiones de un usuario
  Future<void> endAllUserSessions(int userId) async {
    final db = await database;
    await db.update(
      'user_sessions',
      {
        'is_active': 0,
        'ended_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
    );
  }

  // Limpiar sesiones expiradas
  Future<void> cleanupExpiredSessions() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'user_sessions',
      {
        'is_active': 0,
        'ended_at': now,
      },
      where: 'expires_at < ? AND is_active = 1',
      whereArgs: [now],
    );
  }

  // Obtener todas las sesiones (para administración)
  Future<List<UserSession>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_sessions',
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return UserSession.fromMap(maps[i]);
    });
  }

  // Validar token de sesión
  Future<bool> isValidSession(String token) async {
    final session = await getSessionByToken(token);
    return session != null && session.isValid;
  }

  // ============= MÉTODOS PARA SISTEMA MULTI-TIENDA =============
  
  // Obtener todas las tiendas
  Future<List<Map<String, dynamic>>> getAllStores() async {
    final db = await database;
    return await db.query(
      'stores',
      orderBy: 'name ASC',
    );
  }

  // Obtener tienda por ID
  Future<Map<String, dynamic>?> getStoreById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Obtener tiendas activas
  Future<List<Map<String, dynamic>>> getActiveStores() async {
    final db = await database;
    return await db.query(
      'stores',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'name ASC',
    );
  }

  // Insertar nueva tienda
  Future<int> insertStore(Map<String, dynamic> store) async {
    final db = await database;
    return await db.insert('stores', store);
  }

  // Actualizar tienda
  Future<void> updateStore(Map<String, dynamic> store) async {
    final db = await database;
    await db.update(
      'stores',
      store,
      where: 'id = ?',
      whereArgs: [store['id']],
    );
  }

  // Eliminar tienda (soft delete)
  Future<void> deleteStore(int id) async {
    final db = await database;
    await db.update(
      'stores',
      {'status': 'inactive'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener tiendas asignadas a un usuario
  Future<List<Map<String, dynamic>>> getUserAssignedStores(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*
      FROM stores s
      INNER JOIN user_store_assignments usa ON s.id = usa.store_id
      WHERE usa.user_id = ? AND s.status = 'active'
      ORDER BY s.name ASC
    ''', [userId]);
  }

  // Asignar usuario a tienda
  Future<int> assignUserToStore(int userId, int storeId, {int? assignedBy}) async {
    final db = await database;
    return await db.insert('user_store_assignments', {
      'user_id': userId,
      'store_id': storeId,
      'assigned_at': DateTime.now().toIso8601String(),
      'assigned_by': assignedBy,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Desasignar usuario de tienda
  Future<void> unassignUserFromStore(int userId, int storeId) async {
    final db = await database;
    await db.delete(
      'user_store_assignments',
      where: 'user_id = ? AND store_id = ?',
      whereArgs: [userId, storeId],
    );
  }

  // Obtener usuarios asignados a una tienda
  Future<List<Map<String, dynamic>>> getStoreAssignedUsers(int storeId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT u.*, usa.assigned_at
      FROM users u
      INNER JOIN user_store_assignments usa ON u.id = usa.user_id
      WHERE usa.store_id = ? AND u.is_active = 1
      ORDER BY u.username ASC
    ''', [storeId]);
  }

  // Verificar si un usuario tiene acceso a una tienda
  Future<bool> userHasAccessToStore(int userId, int storeId) async {
    final db = await database;
    
    // Verificar si el usuario es admin
    final user = await getUserById(userId);
    if (user != null && user.role == 'admin') {
      return true;
    }
    
    // Verificar asignación específica
    final List<Map<String, dynamic>> maps = await db.query(
      'user_store_assignments',
      where: 'user_id = ? AND store_id = ?',
      whereArgs: [userId, storeId],
    );
    
    return maps.isNotEmpty;
  }

  // Obtener todos los roles
  Future<List<Map<String, dynamic>>> getRoles() async {
    final db = await database;
    return await db.query('roles', orderBy: 'name ASC');
  }

  // Obtener rol por nombre
  Future<Map<String, dynamic>?> getRoleByName(String roleName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'roles',
      where: 'name = ?',
      whereArgs: [roleName],
    );
    
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

}
