import 'dart:developer';
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
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users', 'user_sessions')"
      );
      
      log('📊 Tablas encontradas: ${result.map((r) => r['name']).toList()}');
      
      if (result.length < 2) {
        log('⚠️ Algunas tablas de usuarios no existen. Creándolas...');
        await _createUserTablesIfNotExist();
      }
      
      // Verificar usuario admin
      await ensureAdminUserExists();
      
      log('✅ Verificación de integridad completada exitosamente');
      
    } catch (e) {
      log('❌ Error al verificar integridad de la base de datos: $e');
    }
  }
}