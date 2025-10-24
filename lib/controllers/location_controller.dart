import 'dart:developer';
import 'package:get/get.dart';
import '../database/database_helper.dart';
import 'current_store_controller.dart';

class LocationController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CurrentStoreController _currentStoreController = Get.find<CurrentStoreController>();
  
  final RxList<Map<String, dynamic>> _locations = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<Map<String, dynamic>> get locations => _locations;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en la tienda actual
    ever(_currentStoreController.currentStoreObservable, (_) {
      loadLocations();
    });
    
    // Cargar ubicaciones inicialmente
    loadLocations();
  }

  Future<void> loadLocations() async {
    try {
      _isLoading.value = true;
      
      final currentStore = _currentStoreController.currentStore;
      if (currentStore == null) {
        log('No hay tienda seleccionada');
        _locations.clear();
        return;
      }

      final locations = await _dbHelper.getLocations(storeId: currentStore.id);
      log('Ubicaciones cargadas para tienda ${currentStore.name}: ${locations.length}');
      
      _locations.value = locations;
      
    } catch (e) {
      log('Error loading locations: $e');
      _locations.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteLocation(int id) async {
    try {
      _isLoading.value = true;
      await _dbHelper.deleteLocation(id);
      await loadLocations(); // Recargar la lista
    } catch (e) {
      log('Error deleting location: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshLocations() async {
    await loadLocations();
  }
}