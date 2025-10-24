import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/store.dart';
import '../services/store_service.dart';
import '../utils/utils.dart';

class StoreController extends GetxController {
  final StoreService _storeService = StoreService.instance;

  // Estados observables
  final RxList<Store> _stores = <Store>[].obs;
  final RxList<Store> _filteredStores = <Store>[].obs;
  final Rx<Store?> _selectedStore = Rx<Store?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _searchQuery = ''.obs;

  // Getters
  List<Store> get stores => _stores;
  List<Store> get filteredStores => _filteredStores;
  Store? get selectedStore => _selectedStore.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get searchQuery => _searchQuery.value;

  // Getters de conveniencia
  List<Store> get activeStores => _stores.where((store) => store.isActive).toList();
  int get totalStores => _stores.length;
  int get activeStoresCount => activeStores.length;
  int get inactiveStoresCount => totalStores - activeStoresCount;

  @override
  void onInit() {
    super.onInit();
    loadStores();
  }

  // Cargar todas las tiendas
  Future<void> loadStores() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final stores = await _storeService.getAllStores();
      _stores.value = stores;
      _filterStores();
    } catch (e) {
      _errorMessage.value = 'Error cargando tiendas: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Cargar solo tiendas activas
  Future<void> loadActiveStores() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final stores = await _storeService.getActiveStores();
      _stores.value = stores;
      _filterStores();
    } catch (e) {
      _errorMessage.value = 'Error cargando tiendas activas: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear nueva tienda
  Future<bool> createStore({
    required String name,
    required String code,
    required String address,
    String? phone,
    String? email,
    String? manager,
    Map<String, dynamic>? settings,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final store = Store(
        name: name,
        code: code.toUpperCase(),
        address: address,
        phone: phone,
        email: email,
        manager: manager,
        createdAt: DateTime.now(),
        settings: settings,
      );

      await _storeService.insertStore(store);
      await loadStores();
      return true;
    } catch (e) {
      _errorMessage.value = 'Error creando tienda: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Utils.no.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar tienda
  Future<bool> updateStore(Store store) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _storeService.updateStore(store);
      await loadStores();
      return true;
    } catch (e) {
      _errorMessage.value = 'Error actualizando tienda: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Utils.no.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar tienda (soft delete)
  Future<bool> deleteStore(int id) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _storeService.deleteStore(id);
      
      Get.snackbar(
        'Éxito',
        'Tienda desactivada correctamente',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );

      await loadStores();
      return true;
    } catch (e) {
      _errorMessage.value = 'Error eliminando tienda: $e';
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

  // Cambiar estado de tienda (activar/desactivar)
  Future<bool> toggleStoreStatus(int id) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _storeService.toggleStoreStatus(id);
      
      Get.snackbar(
        'Éxito',
        'Estado de tienda actualizado',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );

      await loadStores();
      return true;
    } catch (e) {
      _errorMessage.value = 'Error cambiando estado: $e';
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

  // Seleccionar tienda
  void selectStore(Store? store) {
    _selectedStore.value = store;
  }

  // Buscar tiendas
  void searchStores(String query) {
    _searchQuery.value = query;
    _filterStores();
  }

  // Filtrar tiendas basado en la búsqueda
  void _filterStores() {
    if (_searchQuery.value.isEmpty) {
      _filteredStores.value = _stores;
    } else {
      final query = _searchQuery.value.toLowerCase();
      _filteredStores.value = _stores.where((store) {
        return store.name.toLowerCase().contains(query) ||
               store.code.toLowerCase().contains(query) ||
               store.address.toLowerCase().contains(query) ||
               (store.manager?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  // Limpiar búsqueda
  void clearSearch() {
    _searchQuery.value = '';
    _filterStores();
  }

  // Validar código de tienda
  Future<bool> isValidStoreCode(String code, {int? excludeId}) async {
    try {
      return await _storeService.isValidStoreCode(code, excludeId: excludeId);
    } catch (e) {
      return false;
    }
  }

  // Obtener tienda por ID
  Future<Store?> getStoreById(int id) async {
    try {
      return await _storeService.getStoreById(id);
    } catch (e) {
      _errorMessage.value = 'Error obteniendo tienda: $e';
      return null;
    }
  }

  // Obtener estadísticas de tiendas
  Future<Map<String, int>> getStoreStats() async {
    try {
      return await _storeService.getStoreStats();
    } catch (e) {
      _errorMessage.value = 'Error obteniendo estadísticas: $e';
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  // Obtener tienda predeterminada
  Future<Store?> getDefaultStore() async {
    try {
      return await _storeService.getDefaultStore();
    } catch (e) {
      _errorMessage.value = 'Error obteniendo tienda predeterminada: $e';
      return null;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage.value = '';
  }

  // Recargar tiendas
  Future<void> refresh() async {
    await loadStores();
  }
}