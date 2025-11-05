import 'package:get/get.dart';
import '../models/store.dart';
import '../services/auth_service.dart';
import '../database/database_helper.dart';

class StoreController extends GetxController {
  final Rx<Store?> currentStore = Rx<Store?>(null);
  final RxList<Store> availableStores = <Store>[].obs;
  final RxBool isAdmin = false.obs;
  final RxBool isLoading = false.obs;

  final AuthService _authService = AuthService.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    // No cargar tiendas automáticamente, esperar a que el usuario esté autenticado
  }

  /// Inicializar tiendas después del login
  Future<void> initializeAfterLogin() async {
    await _loadUserStores();
  }

  /// Cargar tiendas del usuario actual
  Future<void> _loadUserStores() async {
    isLoading.value = true;
    try {
      isAdmin.value = _authService.isAdmin;
      print('🔍 Cargando tiendas para usuario: ${_authService.currentUser?.username}');
      print('👤 Es admin: $isAdmin');
      
      if (_authService.isAdmin) {
        // Admin: cargar todas las tiendas
        final stores = await _dbHelper.getAllStores();
        availableStores.value = stores.map((s) => Store.fromMap(s)).toList();
        print('📦 Admin - Tiendas cargadas: ${availableStores.length}');
      } else if (_authService.currentUser != null) {
        // Otros roles: cargar solo tiendas asignadas
        print('🔑 Usuario ID: ${_authService.currentUser!.id}');
        final stores = await _dbHelper.getUserAssignedStores(_authService.currentUser!.id!);
        availableStores.value = stores.map((s) => Store.fromMap(s)).toList();
        print('📦 Empleado - Tiendas asignadas: ${availableStores.length}');
        if (availableStores.isNotEmpty) {
          print('   Tiendas: ${availableStores.map((s) => s.name).join(", ")}');
        }
      }
      
      // Establecer tienda por defecto
      if (availableStores.isNotEmpty) {
        if (_authService.currentStore != null) {
          currentStore.value = _authService.currentStore;
          print('✅ Tienda actual (desde auth): ${currentStore.value?.name}');
        } else {
          currentStore.value = availableStores.first;
          await _authService.switchStore(availableStores.first);
          print('✅ Tienda actual (primera disponible): ${currentStore.value?.name}');
        }
      } else {
        print('⚠️ No se encontraron tiendas disponibles');
      }
    } catch (e) {
      print('❌ Error cargando tiendas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Cambiar tienda actual
  Future<void> switchStore(Store store) async {
    try {
      // Verificar que el usuario tenga acceso a esta tienda
      if (!isAdmin.value) {
        final hasAccess = availableStores.any((s) => s.id == store.id);
        if (!hasAccess) {
          Get.snackbar(
            'Acceso denegado',
            'No tienes permisos para acceder a esta tienda',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
          return;
        }
      }
      
      await _authService.switchStore(store);
      currentStore.value = store;
      
      // Notificar a otros controladores que recarguen sus datos
      _notifyStoreChanged();
      
      Get.snackbar(
        'Tienda cambiada',
        'Ahora estás viendo: ${store.name}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo cambiar de tienda: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Notificar a todos los controladores que la tienda cambió
  void _notifyStoreChanged() {
    print('🔄 Tienda cambiada a: ${currentStore.value?.name}');
    print('📢 Notificando a los controladores para recargar datos...');
    
    // Disparar actualización en todos los observadores
    // Los controladores que necesiten reaccionar al cambio deben
    // usar ever() en su onInit() para escuchar currentStore
    update(); // Notifica a todos los widgets que usan GetBuilder
  }

  /// Refrescar lista de tiendas
  Future<void> refreshStores() async {
    await _loadUserStores();
  }

  /// Crear nueva tienda (solo admin)
  Future<bool> createStore({
    required String name,
    String? address,
    String? phone,
    String? email,
  }) async {
    if (!isAdmin.value) {
      Get.snackbar('Error', 'Solo los administradores pueden crear tiendas');
      return false;
    }

    try {
      final store = Store(
        name: name,
        address: address,
        phone: phone,
        email: email,
        status: 'active',
      );

      await _dbHelper.insertStore(store.toMap());
      await refreshStores();
      
      Get.snackbar(
        'Éxito',
        'Tienda creada correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear la tienda: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Actualizar tienda (solo admin)
  Future<bool> updateStore(Store store) async {
    if (!isAdmin.value) {
      Get.snackbar('Error', 'Solo los administradores pueden actualizar tiendas');
      return false;
    }

    try {
      await _dbHelper.updateStore(store.toMap());
      await refreshStores();
      
      Get.snackbar(
        'Éxito',
        'Tienda actualizada correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar la tienda: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Eliminar tienda (solo admin)
  Future<bool> deleteStore(int storeId) async {
    if (!isAdmin.value) {
      Get.snackbar('Error', 'Solo los administradores pueden eliminar tiendas');
      return false;
    }

    try {
      await _dbHelper.deleteStore(storeId);
      await refreshStores();
      
      Get.snackbar(
        'Éxito',
        'Tienda eliminada correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar la tienda: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Asignar usuario a tienda (solo admin)
  Future<bool> assignUserToStore(int userId, int storeId) async {
    if (!isAdmin.value) {
      Get.snackbar('Error', 'Solo los administradores pueden asignar usuarios');
      return false;
    }

    try {
      await _dbHelper.assignUserToStore(
        userId,
        storeId,
        assignedBy: _authService.currentUser?.id,
      );
      
      Get.snackbar(
        'Éxito',
        'Usuario asignado a la tienda correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo asignar el usuario: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Desasignar usuario de tienda (solo admin)
  Future<bool> unassignUserFromStore(int userId, int storeId) async {
    if (!isAdmin.value) {
      Get.snackbar('Error', 'Solo los administradores pueden desasignar usuarios');
      return false;
    }

    try {
      await _dbHelper.unassignUserFromStore(userId, storeId);
      
      Get.snackbar(
        'Éxito',
        'Usuario desasignado de la tienda correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo desasignar el usuario: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Obtener ID de la tienda actual
  int? get currentStoreId => currentStore.value?.id;

  /// Verificar si hay una tienda seleccionada
  bool get hasStoreSelected => currentStore.value != null;

  /// Obtener nombre de la tienda actual
  String get currentStoreName => currentStore.value?.name ?? 'Sin tienda';
}

// Stub para ProductController (si no existe)
class ProductController extends GetxController {
  void loadProducts() {
    // Implementar carga de productos filtrados por tienda
  }
}
