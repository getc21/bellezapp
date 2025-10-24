import 'dart:developer';
import 'package:get/get.dart';
import '../database/database_helper.dart';
import 'current_store_controller.dart';

class ProductController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CurrentStoreController _currentStoreController = Get.find<CurrentStoreController>();
  
  final RxList<Map<String, dynamic>> _allProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredProducts = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _activeFilter = 'todos'.obs;
  final RxString _searchText = ''.obs;

  // Getters
  List<Map<String, dynamic>> get allProducts => _allProducts;
  List<Map<String, dynamic>> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading.value;
  String get activeFilter => _activeFilter.value;
  String get searchText => _searchText.value;

  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en la tienda actual
    ever(_currentStoreController.currentStoreObservable, (_) {
      loadProducts();
    });
    
    // Cargar productos inicialmente
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      _isLoading.value = true;
      
      final currentStore = _currentStoreController.currentStore;
      if (currentStore == null) {
        log('No hay tienda seleccionada');
        _allProducts.clear();
        _filteredProducts.clear();
        return;
      }

      final products = await _dbHelper.getProducts(storeId: currentStore.id);
      log('Productos cargados para tienda ${currentStore.name}: ${products.length}');
      
      _allProducts.value = products;
      _applyCurrentFilters();
      
    } catch (e) {
      log('Error loading products: $e');
      _allProducts.clear();
      _filteredProducts.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  void filterProducts(String searchText) {
    _searchText.value = searchText;
    _applyCurrentFilters();
  }

  void showAllProducts() {
    _activeFilter.value = 'todos';
    _applyCurrentFilters();
  }

  void showNearExpiryProducts() {
    _activeFilter.value = 'expiry';
    _applyCurrentFilters();
  }

  void showLowStockProducts() {
    _activeFilter.value = 'stock';
    _applyCurrentFilters();
  }

  void _applyCurrentFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allProducts);

    // Aplicar filtro de búsqueda
    if (_searchText.value.isNotEmpty) {
      filtered = filtered.where((product) {
        final name = product['name'].toLowerCase();
        final description = product['description'].toLowerCase();
        final category = product['category_name']?.toLowerCase() ?? '';
        final supplier = product['supplier_name']?.toLowerCase() ?? '';
        final location = product['location_name']?.toLowerCase() ?? '';
        final searchLower = _searchText.value.toLowerCase();
        return name.contains(searchLower) ||
            description.contains(searchLower) ||
            category.contains(searchLower) ||
            supplier.contains(searchLower) ||
            location.contains(searchLower);
      }).toList();
    }

    // Aplicar filtro específico
    switch (_activeFilter.value) {
      case 'expiry':
        filtered = filtered.where((product) {
          final expiryDate = DateTime.tryParse(product['expirity_date'] ?? '');
          return expiryDate != null &&
              expiryDate.difference(DateTime.now()).inDays <= 30;
        }).toList();
        break;
      case 'stock':
        filtered = filtered.where((product) {
          final stock = product['stock'] ?? 0;
          return stock < 10;
        }).toList();
        break;
      case 'todos':
      default:
        // No se aplica filtro adicional
        break;
    }

    _filteredProducts.value = filtered;
  }

  Future<void> deleteProduct(int id) async {
    try {
      _isLoading.value = true;
      await _dbHelper.deleteProduct(id);
      await loadProducts(); // Recargar la lista
    } catch (e) {
      log('Error deleting product: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> addProductStock(int productId, int stockToAdd) async {
    try {
      _isLoading.value = true;
      await _dbHelper.addProductStock(productId, stockToAdd);
      await loadProducts(); // Recargar la lista
    } catch (e) {
      log('Error adding stock: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }
}