import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../pages/store_management_page.dart';
import '../utils/utils.dart';
import 'store_controller.dart';

class AuthController extends GetxController {
  final AuthProvider _authProvider = AuthProvider();

  // Estados observables
  final Rx<Map<String, dynamic>?> _currentUser = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _token = ''.obs;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser.value;
  bool get isLoggedIn => _token.value.isNotEmpty && _currentUser.value != null;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get token => _token.value;
  
  // Getters de información del usuario
  String get userFullName {
    if (currentUser == null) return 'Usuario';
    final firstName = currentUser?['firstName'] ?? '';
    final lastName = currentUser?['lastName'] ?? '';
    return '$firstName $lastName'.trim();
  }
  
  String get userInitials {
    if (currentUser == null) return 'U';
    final firstName = currentUser?['firstName'] ?? '';
    final lastName = currentUser?['lastName'] ?? '';
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();
    return initials.isEmpty ? 'U' : initials;
  }
  
  String get userRoleDisplay {
    final role = currentUser?['role'];
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gerente';
      case 'employee':
        return 'Empleado';
      default:
        return 'Usuario';
    }
  }
  
  // Getters de rol y permisos
  bool get isAdmin => currentUser?['role'] == 'admin';
  bool get isManager => currentUser?['role'] == 'manager';
  bool get isEmployee => currentUser?['role'] == 'employee';
  String? get userRole => currentUser?['role'];
  
  // Permisos de gestión
  bool canManageUsers() => isAdmin;

  @override
  void onInit() {
    super.onInit();
    _loadSavedSession();
  }

  // Cargar sesión guardada
  Future<void> _loadSavedSession() async {
    _isLoading.value = true;
    
    try {
      // Asegurar que el provider esté inicializado
      await _authProvider.loadToken();
      
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserData = prefs.getString('user_data');
      
      if (savedToken != null && savedToken.isNotEmpty) {
        _token.value = savedToken;
        
        // Si hay datos de usuario guardados, usarlos primero
        if (savedUserData != null && savedUserData.isNotEmpty) {
          try {
            final userData = jsonDecode(savedUserData);
            _currentUser.value = userData;
            print('✅ Sesión cargada desde cache para: ${userFullName}');
            
            // ⭐ CARGAR LAS TIENDAS DESPUÉS DE CARGAR EL USUARIO DESDE CACHE
            try {
              final storeController = Get.find<StoreController>();
              await storeController.loadStores();
              print('✅ Tiendas cargadas después de restaurar sesión');
            } catch (e) {
              print('Error al cargar tiendas después de restaurar sesión: $e');
            }
            
            // Verificar token en segundo plano
            _verifyTokenInBackground();
            return;
          } catch (e) {
            print('Error parsando datos de usuario guardados: $e');
          }
        }
        
        // Si no hay datos guardados, cargar desde API
        await _loadUserFromAPI();
      }
    } catch (e) {
      print('Error cargando sesión: $e');
      await logout();
    } finally {
      _isLoading.value = false;
    }
  }

  // Cargar usuario desde API
  Future<void> _loadUserFromAPI() async {
    try {
      final result = await _authProvider.getProfile();
      if (result['success']) {
        _currentUser.value = result['data'];
        await _saveUserData(result['data']);
        print('✅ Sesión cargada desde API para: ${userFullName}');
        
        // ⭐ CARGAR LAS TIENDAS DESPUÉS DE CARGAR EL USUARIO DESDE API
        try {
          final storeController = Get.find<StoreController>();
          await storeController.loadStores();
          print('✅ Tiendas cargadas después de cargar usuario desde API');
        } catch (e) {
          print('Error al cargar tiendas después de cargar usuario desde API: $e');
        }
      } else {
        // Token inválido, limpiar sesión
        print('❌ Token inválido, limpiando sesión');
        await logout();
      }
    } catch (e) {
      print('Error cargando usuario desde API: $e');
      await logout();
    }
  }

  // Verificar token en segundo plano
  Future<void> _verifyTokenInBackground() async {
    try {
      final result = await _authProvider.getProfile();
      if (!result['success']) {
        print('❌ Token expirado, cerrando sesión');
        await logout();
      }
    } catch (e) {
      print('Error verificando token: $e');
      // No hacer logout aquí para evitar interrumpir al usuario si es solo un error de red
    }
  }

  // Guardar datos del usuario
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
    } catch (e) {
      print('Error guardando datos de usuario: $e');
    }
  }

  // Limpiar datos del usuario
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      print('Error limpiando datos de usuario: $e');
    }
  }

  // Cargar perfil del usuario
  Future<void> loadUserProfile() async {
    try {
      final result = await _authProvider.getProfile();
      
      if (result['success']) {
        _currentUser.value = result['data'];
        print('✅ Perfil cargado para: ${userFullName}');
      } else {
        // Token inválido, limpiar sesión
        print('❌ Token inválido al cargar perfil, limpiando sesión');
        await logout();
      }
    } catch (e) {
      print('Error cargando perfil: $e');
      await logout();
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _authProvider.login(username, password);
      
      if (result['success']) {
        _token.value = result['data']['token'];
        _currentUser.value = result['data']['user'];
        
        // Guardar datos del usuario
        await _saveUserData(result['data']['user']);
        
        // Cargar las tiendas después del login exitoso
        try {
          final storeController = Get.find<StoreController>();
          await storeController.loadStores();
          
          // Si es admin y no hay tiendas, mostrar modal para crear la primera tienda
          if (isAdmin && storeController.stores.isEmpty) {
            print('🏪 Admin sin tiendas - mostrando modal de creación');
            _showFirstStoreDialog();
          }
        } catch (e) {
          print('Error al cargar tiendas después del login: $e');
        }
        
        Get.snackbar(
          'Éxito',
          'Bienvenido, ${_currentUser.value?['firstName'] ?? 'Usuario'}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error en el login';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading.value = true;

    try {
      await _authProvider.logout();
      _currentUser.value = null;
      _token.value = '';
      _errorMessage.value = '';
      
      // Limpiar datos guardados
      await _clearUserData();
      
      // ⭐ LIMPIAR TAMBIÉN LA TIENDA SELECCIONADA
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('selected_store_id');
        
        // Limpiar el estado del StoreController
        final storeController = Get.find<StoreController>();
        storeController.clearStores();
      } catch (e) {
        print('Error limpiando datos de tienda: $e');
      }
      
      Get.snackbar(
        'Sesión cerrada',
        'Has cerrado sesión correctamente',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cerrar sesión: $e',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Registrar nuevo usuario
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? role,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // ⭐ Obtener la tienda actual para asignar al usuario
      List<String> storesToAssign = [];
      try {
        final storeController = Get.find<StoreController>();
        final currentStore = storeController.currentStore;
        if (currentStore != null && currentStore['_id'] != null) {
          storesToAssign = [currentStore['_id']];
          print('🏪 Asignando usuario a tienda: ${currentStore['name']}');
        }
      } catch (e) {
        print('⚠️ No se pudo obtener tienda actual: $e');
      }

      final result = await _authProvider.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role ?? 'employee',
        stores: storesToAssign,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Usuario creado correctamente',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error creando usuario';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage.value = '';
  }

  // Obtener todos los usuarios
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final result = await _authProvider.getAllUsers();
      
      print('AuthController.getAllUsers - Result type: ${result.runtimeType}');
      print('AuthController.getAllUsers - Result: $result');
      
      if (result['success']) {
        final data = result['data'];
        print('AuthController.getAllUsers - Data type: ${data.runtimeType}');
        print('AuthController.getAllUsers - Data: $data');
        
        // Manejo robusto del tipo de respuesta
        if (data is List) {
          // Si ya es una lista, convertir cada elemento
          return data.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else {
              print('AuthController.getAllUsers - Converting item: ${item.runtimeType}');
              return Map<String, dynamic>.from(item as Map);
            }
          }).toList();
        } else if (data is Map) {
          // Si es un Map, podría tener una estructura anidada
          print('AuthController.getAllUsers - Data is Map, keys: ${data.keys}');
          
          // Buscar arrays comunes en la respuesta
          if (data.containsKey('users') && data['users'] is List) {
            return List<Map<String, dynamic>>.from(data['users']);
          } else if (data.containsKey('data') && data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          } else if (data.containsKey('items') && data['items'] is List) {
            return List<Map<String, dynamic>>.from(data['items']);
          } else {
            // Si el Map no contiene una lista, intentar convertirlo en lista de un elemento
            return [Map<String, dynamic>.from(data)];
          }
        } else {
          print('AuthController.getAllUsers - Unexpected data type: ${data.runtimeType}');
          return [];
        }
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo usuarios',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return [];
      }
    } catch (e) {
      print('AuthController.getAllUsers - Exception: $e');
      print('AuthController.getAllUsers - Exception type: ${e.runtimeType}');
      
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return [];
    }
  }

  // Obtener tiendas asignadas a un usuario
  Future<List<Map<String, dynamic>>> getUserAssignedStores(String userId) async {
    try {
      final result = await _authProvider.getUserAssignedStores(userId);
      
      if (result['success']) {
        return List<Map<String, dynamic>>.from(result['data'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error obteniendo tiendas del usuario: $e');
      return [];
    }
  }

  // Registrar nuevo usuario (alias para user_management_page)
  Future<bool> registerUser({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? role,
  }) async {
    return await register(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: role,
    );
  }

  // Actualizar usuario existente
  Future<bool> updateUser(Map<String, dynamic> userData) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _authProvider.updateUser(userData);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Usuario actualizado correctamente',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        _errorMessage.value = result['message'] ?? 'Error actualizando usuario';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar usuario
  Future<bool> deleteUser(String userId) async {
    print('AuthController.deleteUser - Starting deletion for user: $userId');
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _authProvider.deleteUser(userId);
      print('AuthController.deleteUser - Provider result: $result');

      if (result['success']) {
        print('AuthController.deleteUser - Deletion successful');
        Get.snackbar(
          'Éxito',
          result['message'] ?? 'Usuario eliminado correctamente',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        print('AuthController.deleteUser - Deletion failed: ${result['message']}');
        _errorMessage.value = result['message'] ?? 'Error eliminando usuario';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      print('AuthController.deleteUser - Exception: $e');
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      _isLoading.value = false;
      print('AuthController.deleteUser - Operation completed');
    }
  }

  // Mostrar diálogo para crear la primera tienda
  void _showFirstStoreDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.store, color: Utils.colorBotones),
            const SizedBox(width: 8),
            const Text('¡Bienvenido Administrador!'),
          ],
        ),
        content: const Text(
          'Para comenzar a usar Bellezapp necesitas registrar tu primera tienda.\n\n'
          'Sin una tienda registrada no podrás acceder a las funciones de caja, '
          'productos, ventas, etc.\n\n'
          '¿Deseas registrar una tienda ahora?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Cerrar diálogo
              // Navegar a la pantalla de gestión de tiendas para crear una
              Get.to(() => const StoreManagementPage());
            },
            style: TextButton.styleFrom(
              backgroundColor: Utils.colorBotones,
              foregroundColor: Colors.white,
            ),
            child: const Text('Registrar Tienda'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Solo cerrar diálogo
              Get.snackbar(
                'Información',
                'Puedes registrar una tienda más tarde desde el menú de configuración',
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 4),
              );
            },
            child: const Text('Después'),
          ),
        ],
      ),
      barrierDismissible: false, // No se puede cerrar tocando afuera
    );
  }
}