import 'package:get/get.dart';
import '../providers/reports_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class ReportsController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();
  
  ReportsProvider get _reportsProvider => ReportsProvider(_authController.token);

  // Estados observables
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  
  // Datos de reportes
  final RxMap<String, dynamic> _inventoryRotationData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _profitabilityData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _salesTrendsData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _periodsComparisonData = <String, dynamic>{}.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  Map<String, dynamic> get inventoryRotationData => _inventoryRotationData;
  Map<String, dynamic> get profitabilityData => _profitabilityData;
  Map<String, dynamic> get salesTrendsData => _salesTrendsData;
  Map<String, dynamic> get periodsComparisonData => _periodsComparisonData;

  @override
  void onInit() {
    super.onInit();
    print('ReportsController.onInit - Initializing controller');
    print('ReportsController.onInit - StoreController available: ${Get.isRegistered<StoreController>()}');
    
    if (Get.isRegistered<StoreController>()) {
      final storeController = Get.find<StoreController>();
      print('ReportsController.onInit - Current store: ${storeController.currentStore}');
    }
  }

  // Obtener ID de tienda actual
  String? get _currentStoreId {
    final currentStore = _storeController.currentStore;
    return currentStore?['_id'] ?? currentStore?['id'];
  }

  // 📦 Cargar análisis de rotación de inventario
  Future<void> loadInventoryRotationAnalysis({
    required String startDate,
    required String endDate,
    String period = 'monthly',
  }) async {
    final storeId = _currentStoreId;
    if (storeId == null) {
      _errorMessage.value = 'No hay tienda seleccionada';
      return;
    }

    print('ReportsController.loadInventoryRotationAnalysis - Starting...');
    print('ReportsController.loadInventoryRotationAnalysis - StoreId: $storeId');
    print('ReportsController.loadInventoryRotationAnalysis - Period: $startDate to $endDate');

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _reportsProvider.getInventoryRotationAnalysis(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
        period: period,
      );

      print('ReportsController.loadInventoryRotationAnalysis - Result: $result');

      if (result['success']) {
        _inventoryRotationData.value = result['data'];
        print('ReportsController.loadInventoryRotationAnalysis - Data loaded successfully');
        print('ReportsController.loadInventoryRotationAnalysis - Products count: ${_inventoryRotationData['products']?.length ?? 0}');
      } else {
        _errorMessage.value = result['message'];
        print('ReportsController.loadInventoryRotationAnalysis - Error: ${result['message']}');
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      print('ReportsController.loadInventoryRotationAnalysis - Exception: $e');
    } finally {
      _isLoading.value = false;
      print('ReportsController.loadInventoryRotationAnalysis - Finished');
    }
  }

  // 💰 Cargar análisis de rentabilidad
  Future<void> loadProfitabilityAnalysis({
    required String startDate,
    required String endDate,
  }) async {
    final storeId = _currentStoreId;
    if (storeId == null) {
      _errorMessage.value = 'No hay tienda seleccionada';
      return;
    }

    print('ReportsController.loadProfitabilityAnalysis - Starting...');
    print('ReportsController.loadProfitabilityAnalysis - StoreId: $storeId');
    print('ReportsController.loadProfitabilityAnalysis - Period: $startDate to $endDate');

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _reportsProvider.getProfitabilityAnalysis(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
      );

      print('ReportsController.loadProfitabilityAnalysis - Result: $result');

      if (result['success']) {
        _profitabilityData.value = result['data'];
        print('ReportsController.loadProfitabilityAnalysis - Data loaded successfully');
        print('ReportsController.loadProfitabilityAnalysis - Products count: ${_profitabilityData['products']?.length ?? 0}');
      } else {
        _errorMessage.value = result['message'];
        print('ReportsController.loadProfitabilityAnalysis - Error: ${result['message']}');
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      print('ReportsController.loadProfitabilityAnalysis - Exception: $e');
    } finally {
      _isLoading.value = false;
      print('ReportsController.loadProfitabilityAnalysis - Finished');
    }
  }

  // 📈 Cargar análisis de tendencias
  Future<void> loadSalesTrendsAnalysis({
    required String startDate,
    required String endDate,
    String period = 'daily',
  }) async {
    final storeId = _currentStoreId;
    if (storeId == null) {
      _errorMessage.value = 'No hay tienda seleccionada';
      return;
    }

    print('ReportsController.loadSalesTrendsAnalysis - Starting...');
    print('ReportsController.loadSalesTrendsAnalysis - StoreId: $storeId');
    print('ReportsController.loadSalesTrendsAnalysis - Period: $startDate to $endDate ($period)');

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _reportsProvider.getSalesTrendsAnalysis(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
        period: period,
      );

      print('ReportsController.loadSalesTrendsAnalysis - Result: $result');

      if (result['success']) {
        _salesTrendsData.value = result['data'];
        print('ReportsController.loadSalesTrendsAnalysis - Data loaded successfully');
        print('ReportsController.loadSalesTrendsAnalysis - Trends count: ${_salesTrendsData['trends']?.length ?? 0}');
      } else {
        _errorMessage.value = result['message'];
        print('ReportsController.loadSalesTrendsAnalysis - Error: ${result['message']}');
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      print('ReportsController.loadSalesTrendsAnalysis - Exception: $e');
    } finally {
      _isLoading.value = false;
      print('ReportsController.loadSalesTrendsAnalysis - Finished');
    }
  }

  // 🔄 Cargar comparación de períodos
  Future<void> loadPeriodsComparison({
    required String currentStartDate,
    required String currentEndDate,
    required String previousStartDate,
    required String previousEndDate,
  }) async {
    final storeId = _currentStoreId;
    if (storeId == null) {
      _errorMessage.value = 'No hay tienda seleccionada';
      return;
    }

    print('ReportsController.loadPeriodsComparison - Starting...');
    print('ReportsController.loadPeriodsComparison - StoreId: $storeId');
    print('ReportsController.loadPeriodsComparison - Current: $currentStartDate to $currentEndDate');
    print('ReportsController.loadPeriodsComparison - Previous: $previousStartDate to $previousEndDate');

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _reportsProvider.getPeriodsComparison(
        storeId: storeId,
        currentStartDate: currentStartDate,
        currentEndDate: currentEndDate,
        previousStartDate: previousStartDate,
        previousEndDate: previousEndDate,
      );

      print('ReportsController.loadPeriodsComparison - Result: $result');

      if (result['success']) {
        _periodsComparisonData.value = result['data'];
        print('ReportsController.loadPeriodsComparison - Data loaded successfully');
      } else {
        _errorMessage.value = result['message'];
        print('ReportsController.loadPeriodsComparison - Error: ${result['message']}');
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      print('ReportsController.loadPeriodsComparison - Exception: $e');
    } finally {
      _isLoading.value = false;
      print('ReportsController.loadPeriodsComparison - Finished');
    }
  }

  // Limpiar datos
  void clearData() {
    _inventoryRotationData.clear();
    _profitabilityData.clear();
    _salesTrendsData.clear();
    _periodsComparisonData.clear();
    _errorMessage.value = '';
  }

  // Refrescar para nueva tienda
  Future<void> refreshForStore() async {
    clearData();
    // Los datos se cargarán cuando el usuario navegue a las páginas específicas
  }
}