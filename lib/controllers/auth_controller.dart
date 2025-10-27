import 'package:get/get.dart';
import '../models/user.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService.instance;

  // Estados observables
  final Rx<User?> _currentUser = Rx<User?>(null);
  final Rx<UserSession?> _currentSession = Rx<UserSession?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  User? get currentUser => _currentUser.value;
  UserSession? get currentSession => _currentSession.value;
  bool get isLoggedIn => _currentUser.value != null && _currentSession.value != null;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  
  // Getters de rol y permisos
  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get isManager => currentUser?.isManager ?? false;
  bool get isEmployee => currentUser?.isEmployee ?? false;
  UserRole? get userRole => currentUser?.role;

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  // Inicializar autenticación
  Future<void> _initializeAuth() async {
    _isLoading.value = true;
    
    try {
      await _authService.initialize();
      _updateUserState();
    } catch (e) {
      _errorMessage.value = 'Error inicializando autenticación: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar estado del usuario
  void _updateUserState() {
    _currentUser.value = _authService.currentUser;
    _currentSession.value = _authService.currentSession;
  }

  // Login
  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _authService.login(usernameOrEmail, password);
      
      if (result.success) {
        _updateUserState();
        Get.snackbar(
          'Éxito',
          'Bienvenido, ${currentUser?.fullName}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        _errorMessage.value = result.message ?? 'Error en el login';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error inesperado: $e';
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
      await _authService.logout();
      _currentUser.value = null;
      _currentSession.value = null;
      _errorMessage.value = '';
      
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

  // Registrar nuevo usuario (solo admin)
  Future<bool> registerUser({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required UserRole role,
    String? phone,
    Map<String, dynamic>? customPermissions,
  }) async {
    if (!isAdmin) {
      Get.snackbar(
        'Error',
        'Solo los administradores pueden crear usuarios',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _authService.register(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
        role: role,
        phone: phone,
        customPermissions: customPermissions,
      );

      if (result.success) {
        Get.snackbar(
          'Éxito',
          'Usuario creado correctamente',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        _errorMessage.value = result.message ?? 'Error creando usuario';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error inesperado: $e';
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

  // Cambiar contraseña
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _authService.changePassword(currentPassword, newPassword);

      if (result.success) {
        _updateUserState();
        Get.snackbar(
          'Éxito',
          'Contraseña cambiada correctamente',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        _errorMessage.value = result.message ?? 'Error cambiando contraseña';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error inesperado: $e';
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

  // Actualizar perfil
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImageUrl,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );

      if (result.success) {
        _updateUserState();
        Get.snackbar(
          'Éxito',
          'Perfil actualizado correctamente',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        _errorMessage.value = result.message ?? 'Error actualizando perfil';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error inesperado: $e';
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

  // Métodos de verificación de permisos
  bool hasPermission(String permission) {
    return _authService.hasPermission(permission);
  }

  bool canManageUsers() => _authService.canManageUsers();
  bool canManageProducts() => _authService.canManageProducts();
  bool canManageOrders() => _authService.canManageOrders();
  bool canManageCustomers() => _authService.canManageCustomers();
  bool canManageDiscounts() => _authService.canManageDiscounts();
  bool canViewReports() => _authService.canViewReports();
  bool canManageInventory() => _authService.canManageInventory();
  bool canManageCash() => _authService.canManageCash();

  // Obtener lista de usuarios (solo admin)
  Future<List<User>> getAllUsers() async {
    if (!isAdmin) return [];
    return await _authService.getAllUsers();
  }

  // Buscar usuarios (solo admin)
  Future<List<User>> searchUsers(String query) async {
    if (!isAdmin) return [];
    return await _authService.searchUsers(query);
  }

  // Actualizar usuario (solo admin/manager)
  Future<bool> updateUser(User user) async {
    if (!isAdmin && !isManager) {
      Get.snackbar(
        'Error',
        'No tienes permisos para actualizar usuarios',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isLoading.value = true;
    try {
      final result = await _authService.updateUser(user);
      
      if (result.success) {
        if (user.id == currentUser?.id) {
          _updateUserState();
        }
        Get.snackbar(
          'Éxito',
          'Usuario actualizado correctamente',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          result.message ?? 'Error actualizando usuario',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar usuario (solo admin)
  Future<bool> deleteUser(int userId) async {
    if (!isAdmin) {
      Get.snackbar(
        'Error',
        'No tienes permisos para eliminar usuarios',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isLoading.value = true;
    try {
      final result = await _authService.deleteUser(userId);
      
      if (result.success) {
        Get.snackbar(
          'Éxito',
          'Usuario eliminado correctamente',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          result.message ?? 'Error eliminando usuario',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
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
}