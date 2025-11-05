// ARCHIVO DESHABILITADO - YA NO SE USA CON REST API
// Este archivo era parte del sistema SQLite anterior
// Ahora la autenticación se maneja vía REST API (backend)

/*
import 'dart:developer';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/utils/admin_user_setup.dart';

/// Script de prueba para verificar el usuario admin
void main() async {
  log('=== Verificando usuario admin ===');
  
  try {
    // Ejecutar verificación
    await AdminUserSetup.checkDatabaseIntegrity();
    
    // Verificar que el usuario existe
    final dbHelper = DatabaseHelper();
    final adminUser = await dbHelper.getUserByUsername('admin');
    
    if (adminUser != null) {
      log('✅ Usuario admin encontrado:');
      log('  - ID: ${adminUser.id}');
      log('  - Username: ${adminUser.username}');
      log('  - Email: ${adminUser.email}');
      log('  - Nombre: ${adminUser.fullName}');
      log('  - Rol: ${adminUser.role}');
      log('  - Activo: ${adminUser.isActive}');
    } else {
      log('❌ Usuario admin NO encontrado');
    }
    
    // Probar que el usuario existe y obtener su hash
    if (adminUser != null) {
      log('🔐 Hash de contraseña almacenado: ${adminUser.passwordHash}');
      log('🔐 Hash esperado para "admin123": 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9');
      
      final hashMatches = adminUser.passwordHash == '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9';
      log('🔐 Hashes coinciden: ${hashMatches ? "✅ SÍ" : "❌ NO"}');
    }
    
  } catch (e) {
    log('❌ Error durante la verificación: $e');
  }
  
  log('=== Verificación completada ===');
}
*/