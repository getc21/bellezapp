import 'package:get/get.dart';
import '../providers/store_provider.dart';
import 'auth_controller.dart';

class StoreController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
  StoreProvider get _storeProvider => StoreProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _stores = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> _currentStore = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get stores => _stores;
  Map<String, dynamic>? get currentStore => _currentStore.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadStores();
  }

  // Cargar tiendas
  Future<void> loadStores() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _storeProvider.getStores();

      if (result['success']) {
        _stores.value = List<Map<String, dynamic>>.from(result['data']);
        
        // Si no hay tienda seleccionada y hay tiendas disponibles, seleccionar la primera
        if (_currentStore.value == null && _stores.isNotEmpty) {
          _currentStore.value = _stores.first;
        }
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando tiendas';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Seleccionar tienda actual
  void selectStore(Map<String, dynamic> store) {
    _currentStore.value = store;
  }

  // Obtener tienda por ID
  Future<Map<String, dynamic>?> getStoreById(String id) async {
    _isLoading.value = true;

    try {
      final result = await _storeProvider.getStoreById(id);

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo tienda',
          snackPosition: SnackPosition.TOP,
        );
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear tienda (solo admin)
  Future<bool> createStore({
    required String name,
    required String address,
    String? phone,
    String? email,
  }) async {
    if (!_authController.isAdmin) {
      Get.snackbar(
        'Error',
        'No tienes permisos para crear tiendas',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isLoading.value = true;

    try {
      final result = await _storeProvider.createStore(
        name: name,
        address: address,
        phone: phone,
        email: email,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Tienda creada correctamente',
          snackPosition: SnackPosition.TOP,
        );
        await loadStores();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error creando tienda',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar tienda (solo admin)
  Future<bool> updateStore({
    required String id,
    String? name,
    String? address,
    String? phone,
    String? email,
  }) async {
    if (!_authController.isAdmin) {
      Get.snackbar(
        'Error',
        'No tienes permisos para actualizar tiendas',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isLoading.value = true;

    try {
      final result = await _storeProvider.updateStore(
        id: id,
        name: name,
        address: address,
        phone: phone,
        email: email,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Tienda actualizada correctamente',
          snackPosition: SnackPosition.TOP,
        );
        await loadStores();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando tienda',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar tienda (solo admin)
  Future<bool> deleteStore(String id) async {
    if (!_authController.isAdmin) {
      Get.snackbar(
        'Error',
        'No tienes permisos para eliminar tiendas',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isLoading.value = true;

    try {
      final result = await _storeProvider.deleteStore(id);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Tienda eliminada correctamente',
          snackPosition: SnackPosition.TOP,
        );
        _stores.removeWhere((s) => s['_id'] == id);
        
        // Si eliminamos la tienda actual, seleccionar otra
        if (_currentStore.value?['_id'] == id && _stores.isNotEmpty) {
          _currentStore.value = _stores.first;
        }
        
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error eliminando tienda',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
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
