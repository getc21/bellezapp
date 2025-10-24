import 'dart:developer';
import 'package:get/get.dart';
import '../database/database_helper.dart';
import 'current_store_controller.dart';

class CategoryController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CurrentStoreController _currentStoreController = Get.find<CurrentStoreController>();
  
  final RxList<Map<String, dynamic>> _categories = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en la tienda actual
    ever(_currentStoreController.currentStoreObservable, (_) {
      loadCategories();
    });
    
    // Cargar categorías inicialmente
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      _isLoading.value = true;
      
      final currentStore = _currentStoreController.currentStore;
      if (currentStore == null) {
        log('No hay tienda seleccionada');
        _categories.clear();
        return;
      }

      final categories = await _dbHelper.getCategories(storeId: currentStore.id);
      log('Categorías cargadas para tienda ${currentStore.name}: ${categories.length}');
      
      _categories.value = categories;
      
    } catch (e) {
      log('Error loading categories: $e');
      _categories.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      _isLoading.value = true;
      await _dbHelper.deleteCategory(id);
      await loadCategories(); // Recargar la lista
    } catch (e) {
      log('Error deleting category: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshCategories() async {
    await loadCategories();
  }
}