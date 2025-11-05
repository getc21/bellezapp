import 'package:get/get.dart';
import '../providers/cash_register_provider.dart';
import 'auth_controller.dart';

class CashController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
  CashRegisterProvider get _cashProvider => CashRegisterProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _cashRegisters = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _movements = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> _currentRegister = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get cashRegisters => _cashRegisters;
  List<Map<String, dynamic>> get movements => _movements;
  Map<String, dynamic>? get currentRegister => _currentRegister.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  // Cargar cajas registradoras
  Future<void> loadCashRegisters({String? storeId}) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _cashProvider.getCashRegisters(storeId: storeId);

      if (result['success']) {
        _cashRegisters.value = List<Map<String, dynamic>>.from(result['data']);
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando cajas';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear caja registradora
  Future<bool> createCashRegister({
    required String storeId,
    required String name,
    required double initialBalance,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.createCashRegister(
        storeId: storeId,
        name: name,
        initialBalance: initialBalance,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Caja creada correctamente', snackPosition: SnackPosition.TOP);
        await loadCashRegisters(storeId: storeId);
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error creando caja', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Abrir caja
  Future<bool> openCashRegister({
    required String cashRegisterId,
    required double openingBalance,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.openCashRegister(
        cashRegisterId: cashRegisterId,
        openingBalance: openingBalance,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Caja abierta correctamente', snackPosition: SnackPosition.TOP);
        _currentRegister.value = result['data'];
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error abriendo caja', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Cerrar caja
  Future<bool> closeCashRegister({
    required String cashRegisterId,
    required double closingBalance,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.closeCashRegister(
        cashRegisterId: cashRegisterId,
        closingBalance: closingBalance,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Caja cerrada correctamente', snackPosition: SnackPosition.TOP);
        _currentRegister.value = null;
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error cerrando caja', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Cargar movimientos de caja
  Future<void> loadCashMovements({
    required String cashRegisterId,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.getCashMovements(
        cashRegisterId: cashRegisterId,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        _movements.value = List<Map<String, dynamic>>.from(result['data']);
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error cargando movimientos', snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  // Agregar movimiento de caja
  Future<bool> addCashMovement({
    required String cashRegisterId,
    required String type,
    required double amount,
    required String description,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.addCashMovement(
        cashRegisterId: cashRegisterId,
        type: type,
        amount: amount,
        description: description,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Movimiento registrado correctamente', snackPosition: SnackPosition.TOP);
        await loadCashMovements(cashRegisterId: cashRegisterId);
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error registrando movimiento', snackPosition: SnackPosition.TOP);
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
