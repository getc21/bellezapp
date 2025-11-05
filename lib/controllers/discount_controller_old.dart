import 'package:get/get.dart';
import '../providers/discount_provider.dart';
import 'auth_controller.dart';

class DiscountController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
  DiscountProvider get _discountProvider => DiscountProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _discounts = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get discounts => _discounts;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadDiscounts();
  }

  // Cargar descuentos
  Future<void> loadDiscounts({bool? active}) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _discountProvider.getDiscounts(active: active);

      if (result['success']) {
        _discounts.value = List<Map<String, dynamic>>.from(result['data']);
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando descuentos';
        Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar('Error', _errorMessage.value, snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear descuento
  Future<bool> createDiscount({
    required String name,
    String? description,
    required String type,
    required double value,
    String? startDate,
    String? endDate,
    bool? active,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _discountProvider.createDiscount(
        name: name,
        description: description,
        type: type,
        value: value,
        startDate: startDate,
        endDate: endDate,
        active: active,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Descuento creado correctamente', snackPosition: SnackPosition.TOP);
        await loadDiscounts();
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error creando descuento', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar descuento
  Future<bool> updateDiscount({
    required String id,
    String? name,
    String? description,
    String? type,
    double? value,
    String? startDate,
    String? endDate,
    bool? active,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _discountProvider.updateDiscount(
        id: id,
        name: name,
        description: description,
        type: type,
        value: value,
        startDate: startDate,
        endDate: endDate,
        active: active,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Descuento actualizado correctamente', snackPosition: SnackPosition.TOP);
        await loadDiscounts();
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error actualizando descuento', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar descuento
  Future<bool> deleteDiscount(String id) async {
    _isLoading.value = true;

    try {
      final result = await _discountProvider.deleteDiscount(id);

      if (result['success']) {
        Get.snackbar('Éxito', 'Descuento eliminado correctamente', snackPosition: SnackPosition.TOP);
        _discounts.removeWhere((d) => d['_id'] == id);
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error eliminando descuento', snackPosition: SnackPosition.TOP);
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
