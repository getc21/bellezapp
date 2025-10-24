import '../database/database_helper.dart';
import '../models/store.dart';

class StoreService {
  static final StoreService _instance = StoreService._internal();
  factory StoreService() => _instance;
  StoreService._internal();

  static StoreService get instance => _instance;

  // Obtener todas las tiendas
  Future<List<Store>> getAllStores() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Store.fromMap(maps[i]));
  }

  // Obtener tiendas activas
  Future<List<Store>> getActiveStores() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Store.fromMap(maps[i]));
  }

  // Obtener tienda por ID
  Future<Store?> getStoreById(int id) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Store.fromMap(maps.first);
    }
    return null;
  }

  // Obtener tienda por código
  Future<Store?> getStoreByCode(String code) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'code = ?',
      whereArgs: [code],
    );

    if (maps.isNotEmpty) {
      return Store.fromMap(maps.first);
    }
    return null;
  }

  // Insertar nueva tienda
  Future<int> insertStore(Store store) async {
    final db = await DatabaseHelper().database;
    
    // Verificar si el código ya existe
    final existing = await getStoreByCode(store.code);
    if (existing != null) {
      throw Exception('Ya existe una tienda con el código ${store.code}');
    }

    final storeMap = store.toMap();
    storeMap.remove('id'); // Remove ID for insertion
    
    return await db.insert('stores', storeMap);
  }

  // Actualizar tienda
  Future<int> updateStore(Store store) async {
    if (store.id == null) {
      throw Exception('No se puede actualizar una tienda sin ID');
    }

    final db = await DatabaseHelper().database;
    
    // Verificar si otro registro tiene el mismo código
    final existing = await getStoreByCode(store.code);
    if (existing != null && existing.id != store.id) {
      throw Exception('Ya existe otra tienda con el código ${store.code}');
    }

    final storeMap = store.copyWith(updatedAt: DateTime.now()).toMap();
    
    return await db.update(
      'stores',
      storeMap,
      where: 'id = ?',
      whereArgs: [store.id],
    );
  }

  // Eliminar tienda (soft delete)
  Future<int> deleteStore(int id) async {
    final db = await DatabaseHelper().database;
    
    return await db.update(
      'stores',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Eliminar tienda permanentemente
  Future<int> deleteStorePermanently(int id) async {
    final db = await DatabaseHelper().database;
    
    return await db.delete(
      'stores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Buscar tiendas
  Future<List<Store>> searchStores(String query) async {
    if (query.isEmpty) return await getAllStores();

    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'name LIKE ? OR code LIKE ? OR address LIKE ? OR manager LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Store.fromMap(maps[i]));
  }

  // Obtener estadísticas de tiendas
  Future<Map<String, int>> getStoreStats() async {
    final db = await DatabaseHelper().database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM stores');
    final activeResult = await db.rawQuery('SELECT COUNT(*) as count FROM stores WHERE is_active = 1');
    final inactiveResult = await db.rawQuery('SELECT COUNT(*) as count FROM stores WHERE is_active = 0');
    
    return {
      'total': totalResult.first['count'] as int,
      'active': activeResult.first['count'] as int,
      'inactive': inactiveResult.first['count'] as int,
    };
  }

  // Activar/Desactivar tienda
  Future<int> toggleStoreStatus(int id) async {
    final store = await getStoreById(id);
    if (store == null) {
      throw Exception('Tienda no encontrada');
    }

    final db = await DatabaseHelper().database;
    
    return await db.update(
      'stores',
      {
        'is_active': store.isActive ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Validar código de tienda (debe ser único y válido)
  Future<bool> isValidStoreCode(String code, {int? excludeId}) async {
    if (code.isEmpty || code.length < 2) return false;
    
    final existing = await getStoreByCode(code);
    if (existing == null) return true;
    
    // Si estamos excluyendo un ID (edición), verificar que no sea el mismo
    return excludeId != null && existing.id == excludeId;
  }

  // Obtener la tienda predeterminada (primera activa)
  Future<Store?> getDefaultStore() async {
    final activeStores = await getActiveStores();
    return activeStores.isNotEmpty ? activeStores.first : null;
  }
}