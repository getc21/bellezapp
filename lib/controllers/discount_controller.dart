import 'package:get/get.dart';
import '../providers/discount_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class DiscountController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();
  
  DiscountProvider get _discountProvider => DiscountProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _discounts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredDiscounts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _applicableDiscounts = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _searchQuery = ''.obs;

  // Getters
  List<Map<String, dynamic>> get discounts => _discounts;
  List<Map<String, dynamic>> get filteredDiscounts => _filteredDiscounts;
  List<Map<String, dynamic>> get applicableDiscounts => _applicableDiscounts;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    print('DiscountController.onInit - Initializing controller');
    print('DiscountController.onInit - StoreController available: ${Get.isRegistered<StoreController>()}');
    
    if (Get.isRegistered<StoreController>()) {
      final storeController = Get.find<StoreController>();
      print('DiscountController.onInit - Current store: ${storeController.currentStore}');
    }
    
    loadDiscounts();
    ever(_searchQuery, (_) => filterDiscounts());
    print('DiscountController.onInit - Controller initialized');
  }

  // Filtrar descuentos
  void filterDiscounts() {
    print('DiscountController.filterDiscounts - Filtering discounts');
    print('DiscountController.filterDiscounts - Search query: "${_searchQuery.value}"');
    print('DiscountController.filterDiscounts - Total discounts: ${_discounts.length}');
    
    if (_searchQuery.value.isEmpty) {
      _filteredDiscounts.value = _discounts;
      print('DiscountController.filterDiscounts - No search query, showing all ${_discounts.length} discounts');
    } else {
      final query = _searchQuery.value.toLowerCase();
      _filteredDiscounts.value = _discounts.where((discount) {
        final name = discount['name']?.toString().toLowerCase() ?? '';
        final description = discount['description']?.toString().toLowerCase() ?? '';
        return name.contains(query) || description.contains(query);
      }).toList();
      print('DiscountController.filterDiscounts - Filtered to ${_filteredDiscounts.length} discounts');
    }
    
    print('DiscountController.filterDiscounts - Filtered discounts: $_filteredDiscounts');
  }

  // Buscar descuentos
  void searchDiscounts(String query) {
    _searchQuery.value = query;
  }

  // Limpiar búsqueda
  void clearSearch() {
    _searchQuery.value = '';
  }

  // Toggle estado del descuento
  Future<bool> toggleDiscountStatus(String id) async {
    final discount = _discounts.firstWhere((d) => d['_id'] == id);
    final currentStatus = discount['isActive'] ?? false;
    
    return updateDiscount(
      id: id,
      isActive: !currentStatus,
    );
  }

  // Refrescar lista
  Future<void> refresh() async {
    await loadDiscounts();
  }

  // ⭐ MÉTODO PARA REFRESCAR CUANDO CAMBIE LA TIENDA
  Future<void> refreshForStore() async {
    await loadDiscounts();
  }

  // ⭐ MÉTODO DE PRUEBA: Cargar TODOS los descuentos sin filtro de tienda
  Future<void> loadAllDiscountsForTesting() async {
    print('DiscountController.loadAllDiscountsForTesting - Loading ALL discounts without store filter');
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _discountProvider.getDiscounts(
        active: null,
        storeId: null, // ⭐ SIN FILTRO DE TIENDA
      );

      print('DiscountController.loadAllDiscountsForTesting - API result: $result');

      if (result['success']) {
        final discountsData = List<Map<String, dynamic>>.from(result['data']);
        _discounts.value = discountsData;
        print('DiscountController.loadAllDiscountsForTesting - Loaded ${discountsData.length} discounts');
        print('DiscountController.loadAllDiscountsForTesting - Discounts: $discountsData');
        filterDiscounts();
      } else {
        print('DiscountController.loadAllDiscountsForTesting - API error: ${result['message']}');
        _errorMessage.value = result['message'] ?? 'Error cargando descuentos';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      print('DiscountController.loadAllDiscountsForTesting - Exception: $e');
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
      print('DiscountController.loadAllDiscountsForTesting - Finished');
    }
  }

  // Actualizar descuentos aplicables según monto total
  void updateApplicableDiscounts(double totalAmount) {
    print('DiscountController.updateApplicableDiscounts - Total amount: $totalAmount');
    print('DiscountController.updateApplicableDiscounts - Available discounts count: ${_discounts.length}');
    print('DiscountController.updateApplicableDiscounts - All discounts: $_discounts');
    
    final now = DateTime.now();
    final applicableList = _discounts.where((discount) {
      print('DiscountController.updateApplicableDiscounts - Checking discount: ${discount['name']}');
      
      // Verificar si está activo
      if (discount['isActive'] != true) {
        print('  → Rejected: not active (${discount['isActive']})');
        return false;
      }
      
      // Verificar monto mínimo
      final minAmount = discount['minimumAmount'];
      if (minAmount != null && totalAmount < minAmount) {
        print('  → Rejected: total amount $totalAmount < minimum $minAmount');
        return false;
      }
      
      // Verificar fecha de inicio
      final startDateStr = discount['startDate'];
      if (startDateStr != null) {
        final startDate = DateTime.parse(startDateStr);
        if (now.isBefore(startDate)) {
          print('  → Rejected: current date $now < start date $startDate');
          return false;
        }
      }
      
      // Verificar fecha de fin
      final endDateStr = discount['endDate'];
      if (endDateStr != null) {
        final endDate = DateTime.parse(endDateStr);
        if (now.isAfter(endDate)) {
          print('  → Rejected: current date $now > end date $endDate');
          return false;
        }
      }
      
      print('  → Accepted: discount passes all filters');
      return true;
    }).toList();
    
    _applicableDiscounts.value = applicableList;
    print('DiscountController.updateApplicableDiscounts - Final applicable discounts: ${_applicableDiscounts.length}');
    print('DiscountController.updateApplicableDiscounts - Applicable discounts: $applicableList');
  }

  // Cargar descuentos
  Future<void> loadDiscounts({bool? active}) async {
    print('DiscountController.loadDiscounts - Starting, active filter: $active');
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // ⭐ OBTENER EL STORE ID ACTUAL (opcional)
      final currentStoreId = _storeController.currentStore?['_id'];
      print('DiscountController.loadDiscounts - Current store: ${_storeController.currentStore}');
      print('DiscountController.loadDiscounts - Current store ID: $currentStoreId');
      
      // ⭐ PERMITIR CARGAR DESCUENTOS INCLUSO SIN TIENDA SELECCIONADA
      print('DiscountController.loadDiscounts - Making API call with storeId: $currentStoreId');
      final result = await _discountProvider.getDiscounts(
        active: active,
        storeId: currentStoreId, // Puede ser null
      );

      print('DiscountController.loadDiscounts - API result: $result');

      if (result['success']) {
        final discountsData = List<Map<String, dynamic>>.from(result['data']);
        _discounts.value = discountsData;
        print('DiscountController.loadDiscounts - Loaded ${discountsData.length} discounts');
        print('DiscountController.loadDiscounts - Discounts: $discountsData');
        filterDiscounts();
      } else {
        print('DiscountController.loadDiscounts - API error: ${result['message']}');
        _errorMessage.value = result['message'] ?? 'Error cargando descuentos';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      print('DiscountController.loadDiscounts - Exception: $e');
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
      print('DiscountController.loadDiscounts - Finished');
    }
  }

  // Crear descuento
  Future<bool> createDiscount({
    required String name,
    String? description,
    required String type,
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
  }) async {
    print('DiscountController.createDiscount - Starting creation');
    _isLoading.value = true;

    try {
      // ⭐ OBTENER EL STORE ID ACTUAL PARA ASIGNAR AL DESCUENTO
      final currentStoreId = _storeController.currentStore?['_id'];
      print('DiscountController.createDiscount - Current store ID: $currentStoreId');
      
      final result = await _discountProvider.createDiscount(
        name: name,
        description: description,
        type: type,
        value: value,
        minimumAmount: minimumAmount,
        maximumDiscount: maximumDiscount,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        active: active,
        storeId: currentStoreId, // ⭐ AGREGAR STORE ID
      );

      print('DiscountController.createDiscount - API result: $result');

      if (result['success']) {
        Get.snackbar('Éxito', 'Descuento creado correctamente', snackPosition: SnackPosition.TOP);
        await loadDiscounts();
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error creando descuento', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      print('DiscountController.createDiscount - Exception: $e');
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Alias para compatibilidad con add_discount_page
  Future<bool> addDiscount({
    required String name,
    required String description,
    required dynamic type,  // Accept DiscountType enum
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    required bool isActive,
  }) async {
    print('DiscountController.addDiscount - Starting creation');
    
    // Convert DiscountType enum to string if necessary
    final typeStr = type.toString().contains('.') 
        ? type.toString().split('.').last 
        : type.toString();
    
    // ⭐ OBTENER EL STORE ID ACTUAL
    final currentStoreId = _storeController.currentStore?['_id'];
    print('DiscountController.addDiscount - Current store ID: $currentStoreId');
    
    return createDiscount(
      name: name,
      description: description,
      type: typeStr,
      value: value,
      minimumAmount: minimumAmount,
      maximumDiscount: maximumDiscount,
      startDate: startDate,
      endDate: endDate,
      active: isActive,
    );
  }

  // Actualizar descuento
  Future<bool> updateDiscount({
    required String id,
    String? name,
    String? description,
    dynamic type,  // Accept DiscountType enum or String
    double? value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) async {
    print('DiscountController.updateDiscount - Starting update for ID: $id');
    _isLoading.value = true;

    try {
      // Convert DiscountType enum to string if necessary
      String? typeStr;
      if (type != null) {
        typeStr = type.toString().contains('.') 
            ? type.toString().split('.').last 
            : type.toString();
      }

      print('DiscountController.updateDiscount - Update data: name=$name, type=$typeStr, value=$value');

      final result = await _discountProvider.updateDiscount(
        id: id,
        name: name,
        description: description,
        type: typeStr,
        value: value,
        minimumAmount: minimumAmount,
        maximumDiscount: maximumDiscount,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        active: isActive,
      );

      print('DiscountController.updateDiscount - Provider result: $result');

      if (result['success']) {
        print('DiscountController.updateDiscount - Update successful, reloading discounts');
        Get.snackbar('Éxito', 'Descuento actualizado correctamente', snackPosition: SnackPosition.TOP);
        await loadDiscounts();
        return true;
      } else {
        print('DiscountController.updateDiscount - Update failed: ${result['message']}');
        Get.snackbar('Error', result['message'] ?? 'Error actualizando descuento', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      print('DiscountController.updateDiscount - Exception: $e');
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
      print('DiscountController.updateDiscount - Finished');
    }
  }

  // Eliminar descuento
  Future<bool> deleteDiscount(String id) async {
    print('DiscountController.deleteDiscount - Starting deletion for ID: $id');
    _isLoading.value = true;

    try {
      final result = await _discountProvider.deleteDiscount(id);
      print('DiscountController.deleteDiscount - Provider result: $result');

      if (result['success']) {
        print('DiscountController.deleteDiscount - Deletion successful, updating list');
        
        // Remover de la lista local
        final beforeCount = _discounts.length;
        _discounts.removeWhere((d) => d['_id'] == id);
        final afterCount = _discounts.length;
        
        print('DiscountController.deleteDiscount - Discounts before: $beforeCount, after: $afterCount');
        
        // Forzar actualización de filtros
        filterDiscounts();
        
        Get.snackbar('Éxito', 'Descuento eliminado correctamente', snackPosition: SnackPosition.TOP);
        return true;
      } else {
        print('DiscountController.deleteDiscount - Deletion failed: ${result['message']}');
        Get.snackbar('Error', result['message'] ?? 'Error eliminando descuento', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      print('DiscountController.deleteDiscount - Exception: $e');
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
      print('DiscountController.deleteDiscount - Finished');
    }
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
