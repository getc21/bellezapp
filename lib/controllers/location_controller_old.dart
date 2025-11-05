import 'package:get/get.dart';
import '../providers/location_provider.dart';
import 'auth_controller.dart';

class LocationController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
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
      final result = await _locationProvider.getLocations(storeId: storeId);

      if (result['success']) {
        _locations.value = List<Map<String, dynamic>>.from(result['data']);
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
        Get.snackbar('Éxito', 'Ubicación creada correctamente', snackPosition: SnackPosition.TOP);
        await loadLocations(storeId: storeId);
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error creando ubicación', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
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
        Get.snackbar('Éxito', 'Ubicación actualizada correctamente', snackPosition: SnackPosition.TOP);
        await loadLocations();
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error actualizando ubicación', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
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
        Get.snackbar('Éxito', 'Ubicación eliminada correctamente', snackPosition: SnackPosition.TOP);
        _locations.removeWhere((l) => l['_id'] == id);
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error eliminando ubicación', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
