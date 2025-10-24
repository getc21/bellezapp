import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../models/user_session.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;
  AuthService._();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  User? _currentUser;
  UserSession? _currentSession;

  // Getters
  User? get currentUser => _currentUser;
  UserSession? get currentSession => _currentSession;
  bool get isLoggedIn => _currentUser != null && _currentSession != null && _currentSession!.isValid;

  // Hash de contraseña usando SHA256 (en producción usar bcrypt)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generar token de sesión aleatorio
  String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  // Obtener información del dispositivo (simplificada)
  String _getDeviceInfo() {
    // En una implementación real, obtener información real del dispositivo
    return 'Flutter App - ${DateTime.now().millisecondsSinceEpoch}';
  }

  // Login de usuario
  Future<AuthResult> login(String usernameOrEmail, String password) async {
    try {
      print('=== DEBUG LOGIN ===');
      print('Intentando login con: $usernameOrEmail');
      
      // Buscar usuario por username o email
      final userMap = await _dbHelper.getUserByUsername(usernameOrEmail);
      User? user = userMap != null ? User.fromMap(userMap) : null;
      print('Usuario por username: ${user?.username ?? 'null'}');
      
      if (user == null) {
        final emailUserMap = await _dbHelper.getUserByEmail(usernameOrEmail);
        user = emailUserMap != null ? User.fromMap(emailUserMap) : null;
      }
      print('Usuario por email: ${user?.username ?? 'null'}');

      if (user == null) {
        print('ERROR: Usuario no encontrado');
        
        // DEBUG: Listar todos los usuarios
        final db = await _dbHelper.database;
        final allUsers = await db.query('users');
        print('Usuarios en BD:');
        for (var u in allUsers) {
          print('  - ${u['username']} | ${u['email']} | ${u['role']} | active: ${u['is_active']}');
        }
        
        return AuthResult.failure('Usuario no encontrado');
      }

      print('Usuario encontrado: ${user.username} | Role: ${user.role} | Active: ${user.isActive}');

      if (!user.isActive) {
        print('ERROR: Usuario desactivado');
        return AuthResult.failure('Usuario desactivado');
      }

      // Verificar contraseña
      final hashedPassword = _hashPassword(password);
      print('Hash generado: $hashedPassword');
      print('Hash almacenado: ${user.passwordHash}');
      print('¿Contraseñas coinciden?: ${user.passwordHash == hashedPassword}');
      
      if (user.passwordHash != hashedPassword) {
        print('ERROR: Contraseña incorrecta');
        return AuthResult.failure('Contraseña incorrecta');
      }

      print('Login exitoso para: ${user.username}');
      print('=== FIN DEBUG LOGIN ===');

      // Crear nueva sesión
      final sessionToken = _generateSessionToken();
      final session = UserSession(
        userId: user.id!,
        sessionToken: sessionToken,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)), // 30 días
        deviceInfo: _getDeviceInfo(),
        isActive: true,
      );

      await _dbHelper.insertUserSession(session.toMap());
      await _dbHelper.updateUserLastLogin(user.id!);

      // Actualizar estado actual
      _currentUser = user;
      _currentSession = session;

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Error en el login: $e');
    }
  }

  // Registro de nuevo usuario (solo admin puede crear usuarios)
  Future<AuthResult> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required UserRole role,
    String? phone,
    Map<String, dynamic>? customPermissions,
  }) async {
    try {
      // Verificar que el usuario actual es admin
      if (!isLoggedIn || !_currentUser!.isAdmin) {
        return AuthResult.failure('Solo los administradores pueden crear usuarios');
      }

      // Verificar que no exista el username
      if (await _dbHelper.userExistsByUsername(username)) {
        return AuthResult.failure('El nombre de usuario ya existe');
      }

      // Verificar que no exista el email
      if (await _dbHelper.userExistsByEmail(email)) {
        return AuthResult.failure('El email ya existe');
      }

      // Crear nuevo usuario
      final hashedPassword = _hashPassword(password);
      final permissions = customPermissions ?? role.defaultPermissions;
      
      final user = User(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        passwordHash: hashedPassword,
        role: role,
        createdAt: DateTime.now(),
        phone: phone,
        permissions: permissions,
      );

      await _dbHelper.insertUser(user.toMap());
      
      // Buscar el usuario recién creado
      final createdUserMap = await _dbHelper.getUserByUsername(username);
      final createdUser = User.fromMap(createdUserMap!);

      return AuthResult.success(createdUser);
    } catch (e) {
      return AuthResult.failure('Error en el registro: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      if (_currentSession != null) {
        await _dbHelper.endUserSession(_currentSession!.sessionToken);
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
    } finally {
      _currentUser = null;
      _currentSession = null;
    }
  }

  // Verificar sesión por token
  Future<bool> validateSession(String token) async {
    try {
      final sessionMap = await _dbHelper.getSessionByToken(token);
      if (sessionMap == null) {
        return false;
      }
      
      final session = UserSession.fromMap(sessionMap);
      if (!session.isValid) {
        return false;
      }

      final userMap = await _dbHelper.getUserById(session.userId);
      if (userMap == null) {
        return false;
      }
      
      final user = User.fromMap(userMap);
      if (!user.isActive) {
        return false;
      }

      _currentUser = user;
      _currentSession = session;
      return true;
    } catch (e) {
      print('Error validando sesión: $e');
      return false;
    }
  }

  // Cambiar contraseña
  Future<AuthResult> changePassword(String currentPassword, String newPassword) async {
    try {
      if (!isLoggedIn) {
        return AuthResult.failure('Usuario no autenticado');
      }

      // Verificar contraseña actual
      final hashedCurrentPassword = _hashPassword(currentPassword);
      if (_currentUser!.passwordHash != hashedCurrentPassword) {
        return AuthResult.failure('Contraseña actual incorrecta');
      }

      // Actualizar contraseña
      final hashedNewPassword = _hashPassword(newPassword);
      final updatedUser = _currentUser!.copyWith(passwordHash: hashedNewPassword);
      
      await _dbHelper.updateUser(updatedUser.toMap());
      _currentUser = updatedUser;

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure('Error cambiando contraseña: $e');
    }
  }

  // Actualizar perfil del usuario actual
  Future<AuthResult> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      if (!isLoggedIn) {
        return AuthResult.failure('Usuario no autenticado');
      }

      // Verificar que el email no esté en uso por otro usuario
      if (email != null && email != _currentUser!.email) {
        if (await _dbHelper.userExistsByEmail(email)) {
          return AuthResult.failure('El email ya está en uso');
        }
      }

      final updatedUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );

      await _dbHelper.updateUser(updatedUser.toMap());
      _currentUser = updatedUser;

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure('Error actualizando perfil: $e');
    }
  }

  // Actualizar usuario (solo admin)
  Future<AuthResult> updateUser(User user) async {
    try {
      if (!isLoggedIn || !_currentUser!.isAdmin) {
        return AuthResult.failure('Solo los administradores pueden actualizar usuarios');
      }

      await _dbHelper.updateUser(user.toMap());

      // Si es el usuario actual, actualizar el estado
      if (user.id == _currentUser!.id) {
        _currentUser = user;
      }

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Error actualizando usuario: $e');
    }
  }

  // Eliminar usuario (solo admin)
  Future<AuthResult> deleteUser(int userId) async {
    try {
      if (!isLoggedIn || !_currentUser!.isAdmin) {
        return AuthResult.failure('Solo los administradores pueden eliminar usuarios');
      }

      if (userId == _currentUser!.id) {
        return AuthResult.failure('No puedes eliminar tu propia cuenta');
      }

      // Terminar todas las sesiones del usuario
      await _dbHelper.endAllUserSessions(userId);
      
      // Eliminar usuario
      await _dbHelper.deleteUser(userId);

      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure('Error eliminando usuario: $e');
    }
  }

  // Obtener todos los usuarios (solo admin)
  Future<List<User>> getAllUsers() async {
    if (!isLoggedIn || !_currentUser!.isAdmin) {
      return [];
    }

    final userMaps = await _dbHelper.getUsers();
    return userMaps.map((map) => User.fromMap(map)).toList();
  }

  // Buscar usuarios (solo admin)
  Future<List<User>> searchUsers(String query) async {
    if (!isLoggedIn || !_currentUser!.isAdmin) {
      return [];
    }

    final userMaps = await _dbHelper.searchUsers(query);
    return userMaps.map((map) => User.fromMap(map)).toList();
  }

  // Verificar permisos
  bool hasPermission(String permission) {
    if (!isLoggedIn) return false;
    return _currentUser!.hasPermission(permission);
  }

  // Métodos de conveniencia para permisos
  bool canManageUsers() => hasPermission('manage_users');
  bool canManageProducts() => hasPermission('manage_products');
  bool canManageOrders() => hasPermission('manage_orders');
  bool canManageCustomers() => hasPermission('manage_customers');
  bool canManageDiscounts() => hasPermission('manage_discounts');
  bool canViewReports() => hasPermission('view_reports');
  bool canManageInventory() => hasPermission('manage_inventory');
  bool canManageCash() => hasPermission('manage_cash');

  // Limpiar sesiones expiradas (ejecutar periódicamente)
  Future<void> cleanupExpiredSessions() async {
    await _dbHelper.cleanupExpiredSessions();
  }

  // Inicializar servicio (cargar sesión guardada si existe)
  Future<void> initialize() async {
    // En una implementación real, aquí cargarías el token guardado localmente
    // y validarías la sesión
  }
}

// Clase para resultados de autenticación
class AuthResult {
  final bool success;
  final String? message;
  final User? user;

  AuthResult._(this.success, this.message, this.user);

  factory AuthResult.success(User? user) => AuthResult._(true, null, user);
  factory AuthResult.failure(String message) => AuthResult._(false, message, null);
}