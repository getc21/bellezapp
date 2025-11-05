// ARCHIVO DESHABILITADO - YA NO SE USA CON REST API
// Este archivo era parte del sistema SQLite anterior
// Ahora la autenticación y gestión de usuarios se maneja vía REST API

/*
import 'dart:developer';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AdminUserSetup {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Verificar y crear el usuario admin si no existe
  static Future<void> ensureAdminUserExists() async {
    log('🔍 Iniciando verificación del usuario admin...');
    try {
      // Verificar si el usuario admin ya existe
      final existingAdmin = await _dbHelper.getUserByUsername('admin');
      
      if (existingAdmin == null) {
        log('❌ Usuario admin no encontrado. Creando usuario admin...');
        
        // Crear usuario admin
        final adminUser = User(
          username: 'admin',
          email: 'admin@bellezapp.com',
          firstName: 'Administrador',
          lastName: 'Sistema',
          passwordHash: '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', // Hash de "admin123"
          role: UserRole.admin,
          isActive: true,
          createdAt: DateTime.now(),
          permissions: UserRole.admin.defaultPermissions,
        );

        final userId = await _dbHelper.insertUser(adminUser);
        
        if (userId > 0) {
          log('✅ Usuario admin creado exitosamente con ID: $userId');
        } else {
          log('❌ Error al crear el usuario admin');
        }
      } else {
        log('✅ Usuario admin ya existe con ID: ${existingAdmin.id}');
        log('📋 Detalles: ${existingAdmin.username} - ${existingAdmin.email} - ${existingAdmin.role}');
      }
    } catch (e) {
      log('❌ Error al verificar/crear usuario admin: $e');
      
      // Intentar crear las tablas de usuarios si no existen
      try {
        log('🔧 Intentando crear tablas de usuarios...');
        await _createUserTablesIfNotExist();
        
        // Intentar crear el usuario admin nuevamente
        final adminUser = User(
          username: 'admin',
          email: 'admin@bellezapp.com',
          firstName: 'Administrador',
          lastName: 'Sistema',
          passwordHash: '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
          role: UserRole.admin,
          isActive: true,
          createdAt: DateTime.now(),
          permissions: UserRole.admin.defaultPermissions,
        );

        final userId = await _dbHelper.insertUser(adminUser);
        
        if (userId > 0) {
          log('✅ Usuario admin creado exitosamente después de crear tablas con ID: $userId');
        } else {
          log('❌ Error al crear el usuario admin después de crear tablas');
        }
      } catch (e2) {
        log('❌ Error al crear tablas y usuario admin: $e2');
      }
    }
  }

  /// Crear las tablas de usuarios si no existen
  static Future<void> _createUserTablesIfNotExist() async {
    final db = await _dbHelper.database;
    
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
    
    log('Tablas de usuarios creadas exitosamente');
  }

  /// Verificar la integridad de la base de datos
  static Future<void> checkDatabaseIntegrity() async {
    log('🚀 Iniciando verificación de integridad de la base de datos...');
    try {
      final db = await _dbHelper.database;
      
      // Verificar si las tablas existen
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users', 'user_sessions', 'stores', 'roles', 'user_store_assignments')"
      );
      
      log('📊 Tablas encontradas: ${result.map((r) => r['name']).toList()}');
      
      if (result.length < 2) {
        log('⚠️ Algunas tablas de usuarios no existen. Creándolas...');
        await _createUserTablesIfNotExist();
      }
      
      // Verificar usuario admin
      await ensureAdminUserExists();
      
      // Verificar tiendas
      await _ensureStoreExists();
      
      log('✅ Verificación de integridad completada exitosamente');
      
    } catch (e) {
      log('❌ Error al verificar integridad de la base de datos: $e');
    }
  }
  
  /// Verificar y crear la tienda principal si no existe
  static Future<void> _ensureStoreExists() async {
    log('🏪 Verificando tiendas...');
    try {
      final db = await _dbHelper.database;
      
      // Verificar si existe la tabla stores
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='stores'"
      );
      
      if (tableExists.isEmpty) {
        log('⚠️ Tabla stores no existe. Creando tabla...');
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
      }
      
      // Verificar si existe al menos una tienda
      final stores = await db.query('stores');
      
      if (stores.isEmpty) {
        log('❌ No hay tiendas registradas. Creando Tienda Principal...');
        await db.insert('stores', {
          'id': 1,
          'name': 'Tienda Principal',
          'address': 'Dirección Principal',
          'phone': '0000000000',
          'email': 'principal@bellezapp.com',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        });
        log('✅ Tienda Principal creada exitosamente');
      } else {
        log('✅ Se encontraron ${stores.length} tienda(s) registrada(s)');
      }
      
      // Verificar tabla roles
      final rolesTableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='roles'"
      );
      
      if (rolesTableExists.isEmpty) {
        log('⚠️ Tabla roles no existe. Creando tabla...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS roles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT
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
      }
      
      // Verificar tabla user_store_assignments
      final assignmentsTableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_store_assignments'"
      );
      
      if (assignmentsTableExists.isEmpty) {
        log('⚠️ Tabla user_store_assignments no existe. Creando tabla...');
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
      }
      
      // Asignar el usuario admin a la tienda principal si no está asignado
      final adminUser = await db.query('users', where: 'username = ?', whereArgs: ['admin']);
      if (adminUser.isNotEmpty) {
        final adminId = adminUser.first['id'] as int;
        final assignment = await db.query(
          'user_store_assignments',
          where: 'user_id = ? AND store_id = ?',
          whereArgs: [adminId, 1],
        );
        
        if (assignment.isEmpty) {
          await db.insert('user_store_assignments', {
            'user_id': adminId,
            'store_id': 1,
            'assigned_at': DateTime.now().toIso8601String(),
          });
          log('✅ Usuario admin asignado a Tienda Principal');
        }
      }
      
    } catch (e) {
      log('❌ Error al verificar/crear tiendas: $e');
    }
  }
}
*/