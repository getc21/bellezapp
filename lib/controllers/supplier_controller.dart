import 'dart:developer';
import 'package:get/get.dart';
import '../database/database_helper.dart';
import 'current_store_controller.dart';

class SupplierController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CurrentStoreController _currentStoreController = Get.find<CurrentStoreController>();
  
  final RxList<Map<String, dynamic>> _suppliers = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<Map<String, dynamic>> get suppliers => _suppliers;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en la tienda actual
    ever(_currentStoreController.currentStoreObservable, (_) {
      loadSuppliers();
    });
    
    // Cargar proveedores inicialmente
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    try {
      _isLoading.value = true;
      
      final currentStore = _currentStoreController.currentStore;
      if (currentStore == null) {
        log('No hay tienda seleccionada');
        _suppliers.clear();
        return;
      }

      final suppliers = await _dbHelper.getSuppliers(storeId: currentStore.id);
      log('Proveedores cargados para tienda ${currentStore.name}: ${suppliers.length}');
      
      _suppliers.value = suppliers;
      
    } catch (e) {
      log('Error loading suppliers: $e');
      _suppliers.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      _isLoading.value = true;
      await _dbHelper.deleteSupplier(id);
      await loadSuppliers(); // Recargar la lista
    } catch (e) {
      log('Error deleting supplier: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshSuppliers() async {
    await loadSuppliers();
  }
}