import 'dart:developer';
import 'package:get/get.dart';
import '../database/database_helper.dart';
import 'current_store_controller.dart';

class OrderController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CurrentStoreController _currentStoreController = Get.find<CurrentStoreController>();
  
  final RxList<Map<String, dynamic>> _orders = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en la tienda actual
    ever(_currentStoreController.currentStoreObservable, (_) {
      loadOrders();
    });
    
    // Cargar órdenes inicialmente
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      _isLoading.value = true;
      
      final currentStore = _currentStoreController.currentStore;
      if (currentStore == null) {
        log('No hay tienda seleccionada');
        _orders.clear();
        return;
      }

      final orders = await _dbHelper.getOrdersWithItems(storeId: currentStore.id);
      log('Órdenes cargadas para tienda ${currentStore.name}: ${orders.length}');
      
      _orders.value = orders;
      
    } catch (e) {
      log('Error loading orders: $e');
      _orders.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteOrder(int id) async {
    try {
      _isLoading.value = true;
      await _dbHelper.deleteOrder(id);
      await loadOrders(); // Recargar la lista
    } catch (e) {
      log('Error deleting order: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshOrders() async {
    await loadOrders();
  }
}