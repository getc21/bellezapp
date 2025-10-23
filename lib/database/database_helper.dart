import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';

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
      version: 1,
      onCreate: (db, version) async {
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
            expirity_date TEXT
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
            totalOrden REAL NOT NULL
          )
        ''');
        db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT
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
          amount REAL
        )
        ''');
        await _insertTestData(db);
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

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT p.*, 
           c.name as category_name, 
           s.name as supplier_name, 
           l.name as location_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN locations l ON p.location_id = l.id
  ''');
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
    return await db.query('locations');
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
  final db = await database;
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
  });
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

  Future<void> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    double totalOrden = 0.0;
    for (var product in order['products']) {
      totalOrden += product['quantity'] * product['price'];
    }
    final orderId = await db.insert('orders', {
      'order_date': order['date'],
      'totalOrden': totalOrden,
    });
    for (var product in order['products']) {
      await db.insert('order_items', {
        'order_id': orderId,
        'product_id': product['id'],
        'quantity': product['quantity'],
        'price': product['price'],
      });
    }
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
    return await db.rawQuery('''
    SELECT p.*, 
           c.name as category_name, 
           s.name as supplier_name, 
           l.name as location_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN locations l ON p.location_id = l.id
    WHERE p.category_id = ?
  ''', [categoryId]);
  }

  Future<List<Map<String, dynamic>>> getProductsBySupplier(
      int supplierId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT p.*, 
           c.name as category_name, 
           s.name as supplier_name, 
           l.name as location_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN locations l ON p.location_id = l.id
    WHERE p.supplier_id = ?
  ''', [supplierId]);
  }

  Future<List<Map<String, dynamic>>> getProductsByLocation(int locationId) async {
  final db = await database;
  return await db.rawQuery('''
    SELECT p.*, 
           c.name as category_name, 
           s.name as supplier_name, 
           l.name as location_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN locations l ON p.location_id = l.id
    WHERE p.location_id = ?
  ''', [locationId]);
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

  Future<List<Map<String, dynamic>>> getOrdersWithItems() async {
    final db = await database;
    final orders = await db.query('orders');
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
    });
  }
}

  Future<List<Map<String, dynamic>>> getProductsByRotation(
      {required String period}) async {
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

    return await db.rawQuery('''
      SELECT p.*, SUM(oi.quantity) as total_quantity
      FROM products p
      JOIN order_items oi ON p.id = oi.product_id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.order_date >= ?
      GROUP BY p.id
      ORDER BY total_quantity DESC
    ''', [dateCondition]);
  }

  Future<List<Map<String, dynamic>>> getSalesDataForLastYear() async {
    final db = await database;
    final now = DateTime.now();
    final lastYear = DateTime(now.year - 1, now.month);

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
    WHERE o.order_date >= ?
    GROUP BY month, year, p.id
    ORDER BY year DESC, month DESC
  ''', [lastYear.toIso8601String()]);

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

  Future<List<Map<String, dynamic>>> getFinancialDataForLastYear() async {
  final db = await database;
  final now = DateTime.now();
  final lastYear = DateTime(now.year - 1, now.month);

  final incomeData = await db.rawQuery('''
    SELECT 
      strftime('%m', o.order_date) as month,
      strftime('%Y', o.order_date) as year,
      SUM(oi.quantity * p.sale_price) as totalIncome
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.order_date >= ?
    GROUP BY month, year
    ORDER BY year DESC, month DESC
  ''', [lastYear.toIso8601String()]);

  final expenseData = await db.rawQuery('''
    SELECT 
      strftime('%m', t.date) as month,
      strftime('%Y', t.date) as year,
      SUM(t.amount) as totalExpense
    FROM financial_transactions t
    WHERE t.type = 'Salida' AND t.date >= ?
    GROUP BY month, year
    ORDER BY year DESC, month DESC
  ''', [lastYear.toIso8601String()]);

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

Future<List<Map<String, dynamic>>> getFinancialDataBetweenDates(DateTime startDate, DateTime endDate) async {
  final db = await database;

  final incomeData = await db.rawQuery('''
    SELECT 
      strftime('%m', o.order_date) as month,
      strftime('%Y', o.order_date) as year,
      SUM(oi.quantity * p.sale_price) as totalIncome
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.order_date BETWEEN ? AND ?
    GROUP BY month, year
    ORDER BY year DESC, month DESC
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

  final expenseData = await db.rawQuery('''
    SELECT 
      strftime('%m', t.date) as month,
      strftime('%Y', t.date) as year,
      SUM(t.amount) as totalExpense
    FROM financial_transactions t
    WHERE t.type = 'Salida' AND t.date BETWEEN ? AND ?
    GROUP BY month, year
    ORDER BY year DESC, month DESC
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

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

}
