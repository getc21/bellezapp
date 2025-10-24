import '../database/database_helper.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DatabaseDebug {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // Hash de contraseña usando SHA256 (igual que en AuthService)
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> resetDatabase() async {
    print('=== RESETEANDO BASE DE DATOS ===');
    
    try {
      // Cerrar cualquier conexión existente
      await _dbHelper.closeDatabase();
      
      // Eliminar base de datos
      if (kIsWeb) {
        // En web, simplemente eliminamos la base de datos por nombre
        await deleteDatabase('bellezapp.db');
      } else {
        // En móvil/desktop, usamos la ruta completa
        final databasesPath = await getDatabasesPath();
        final path = join(databasesPath, 'bellezapp.db');
        await deleteDatabase(path);
      }
      
      print('Base de datos eliminada exitosamente');
    } catch (e) {
      print('Error al eliminar la base de datos: $e');
    }
    
    // Forzar recreación de la base de datos
    await _dbHelper.database;
    print('Base de datos recreada');
    
    // Verificar que el usuario admin se creó correctamente
    await debugUsers();
    
    print('=== RESET COMPLETADO ===');
  }

  static Future<void> debugUsers() async {
    print('=== DEBUG: Verificando estado de usuarios ===');
    
    final db = await _dbHelper.database;
    
    // Obtener todos los usuarios
    final users = await db.query('users');
    print('Total de usuarios encontrados: ${users.length}');
    
    for (var user in users) {
      print('Usuario: ${user['username']} | Email: ${user['email']} | Role: ${user['role']} | Store ID: ${user['store_id']} | Active: ${user['is_active']}');
    }
    
    // Verificar tiendas
    final stores = await db.query('stores');
    print('\nTotal de tiendas encontradas: ${stores.length}');
    
    for (var store in stores) {
      print('Tienda: ${store['name']} | ID: ${store['id']} | Code: ${store['code']} | Active: ${store['is_active']}');
    }
    
    // Verificar hash de contraseña para admin123
    final adminHash = _hashPassword('admin123');
    print('\nHash esperado para "admin123": $adminHash');
    
    // Buscar usuario admin específicamente
    final adminUsers = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    
    if (adminUsers.isNotEmpty) {
      final admin = adminUsers.first;
      print('\nUsuario admin encontrado:');
      print('Hash almacenado: ${admin['password_hash']}');
      print('¿Hash coincide?: ${admin['password_hash'] == adminHash}');
    } else {
      print('\nNo se encontró usuario admin');
    }
    
    print('=== FIN DEBUG ===');
  }

  static Future<void> recreateAdminUser() async {
    print('=== Recreando usuario admin ===');
    
    final db = await _dbHelper.database;
    
    // Eliminar usuario admin existente
    await db.delete(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    
    // Verificar si existe al menos una tienda
    final stores = await db.query('stores', where: 'is_active = 1', limit: 1);
    int storeId;
    
    if (stores.isEmpty) {
      // Crear tienda principal
      storeId = await db.insert('stores', {
        'name': 'Tienda Principal',
        'code': 'MAIN',
        'address': 'Dirección Principal',
        'phone': '+1234567890',
        'email': 'tienda@bellezapp.com',
        'manager': 'Administrador',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Tienda principal creada con ID: $storeId');
    } else {
      storeId = stores.first['id'] as int;
      print('Usando tienda existente con ID: $storeId');
    }
    
    // Crear usuario admin
    const adminPasswordHash = "240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9";
    
    final adminId = await db.insert('users', {
      'username': 'admin',
      'email': 'admin@bellezapp.com',
      'first_name': 'Administrador',
      'last_name': 'Sistema',
      'password_hash': adminPasswordHash,
      'role': 'admin',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'store_id': storeId,
    });
    
    print('Usuario admin recreado con ID: $adminId');
    print('=== Usuario admin recreado exitosamente ===');
  }
}