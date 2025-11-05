import 'package:get/get.dart';
import '../providers/location_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class LocationController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();
  
  LocationProvider get _locationProvider => LocationProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _locations = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get locations => _locations;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  // Cargar ubicaciones
  Future<void> loadLocations({String? storeId}) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // ⭐ ASEGURAR QUE SIEMPRE SE USE EL STORE ID ACTUAL
      final currentStoreId = storeId ?? _storeController.currentStore?['_id'];
      
      if (currentStoreId == null) {
        _errorMessage.value = 'No hay tienda seleccionada';
        _locations.clear();
        return;
      }

      print('🔍 LocationController: Cargando ubicaciones para tienda: $currentStoreId');
      
      final result = await _locationProvider.getLocations(storeId: currentStoreId);

      if (result['success']) {
        final newLocations = List<Map<String, dynamic>>.from(result['data']);
        _locations.value = newLocations;
        print('✅ LocationController: ${newLocations.length} ubicaciones cargadas para tienda $currentStoreId');
        
        // Verificar que todas las ubicaciones pertenezcan a la tienda correcta
        final wrongStoreLocations = newLocations.where((l) => 
          l['storeId']?['_id'] != null && l['storeId']['_id'] != currentStoreId
        ).toList();
        
        if (wrongStoreLocations.isNotEmpty) {
          print('⚠️ ADVERTENCIA: ${wrongStoreLocations.length} ubicaciones pertenecen a otra tienda!');
          for (var location in wrongStoreLocations) {
            print('   - ${location['name']} pertenece a ${location['storeId']?['_id']}');
          }
        }
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando ubicaciones';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  // ⭐ LIMPIAR UBICACIONES (útil cuando no hay tienda seleccionada)
  void clearLocations() {
    _locations.clear();
    _errorMessage.value = '';
    print('🧹 LocationController: Ubicaciones limpiadas');
  }

  // Crear ubicación
  Future<bool> createLocation({
    required String storeId,
    required String name,
    String? description,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _locationProvider.createLocation(
        storeId: storeId,
        name: name,
        description: description,
      );

      if (result['success']) {
        // No mostrar snackbar aquí, se manejará en la página
        await loadLocations(storeId: storeId);
        return true;
      } else {
        // No mostrar snackbar aquí, se manejará en la página si es necesario
        return false;
      }
    } catch (e) {
      // No mostrar snackbar aquí, se manejará en la página si es necesario
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar ubicación
  Future<bool> updateLocation({
    required String id,
    String? name,
    String? description,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _locationProvider.updateLocation(
        id: id,
        name: name,
        description: description,
      );

      if (result['success']) {
        // No mostrar snackbar aquí, se manejará en la página
        await loadLocations();
        return true;
      } else {
        // No mostrar snackbar aquí, se manejará en la página si es necesario
        return false;
      }
    } catch (e) {
      // No mostrar snackbar aquí, se manejará en la página si es necesario
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar ubicación
  Future<bool> deleteLocation(String id) async {
    _isLoading.value = true;

    try {
      final result = await _locationProvider.deleteLocation(id);

      if (result['success']) {
        // No mostrar snackbar aquí, se manejará en la página
        _locations.removeWhere((l) => l['_id'] == id);
        return true;
      } else {
        // No mostrar snackbar aquí, se manejará en la página si es necesario
        return false;
      }
    } catch (e) {
      // No mostrar snackbar aquí, se manejará en la página si es necesario
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _errorMessage.value = '';
  }

  // Cargar ubicaciones para la tienda actual
  Future<void> loadForCurrentStore() async {
    final currentStoreId = _storeController.currentStore?['_id'];
    if (currentStoreId != null) {
      await loadLocations(storeId: currentStoreId);
    }
  }

  // Refrescar datos para la tienda específica
  Future<void> refreshForStore() async {
    print('🔄 LocationController: Refrescando ubicaciones para nueva tienda');
    await loadForCurrentStore();
  }
}
