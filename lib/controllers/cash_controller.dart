import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/models/cash_movement.dart';
import 'package:bellezapp/models/cash_register.dart';
import 'package:get/get.dart';

class CashController extends GetxController {
  final DatabaseHelper _db = DatabaseHelper();
  
  // Observables
  final _currentCashRegister = Rxn<CashRegister>();
  final _todayMovements = <CashMovement>[].obs;
  final _isLoading = false.obs;
  final _totalCashInHand = 0.0.obs;
  final _totalSalesToday = 0.0.obs;
  final _totalIncomesToday = 0.0.obs;
  final _totalOutcomesToday = 0.0.obs;
  final _expectedAmount = 0.0.obs;

  // Getters
  CashRegister? get currentCashRegister => _currentCashRegister.value;
  List<CashMovement> get todayMovements => _todayMovements;
  bool get isLoading => _isLoading.value;
  double get totalCashInHand => _totalCashInHand.value;
  double get totalSalesToday => _totalSalesToday.value;
  double get totalIncomesToday => _totalIncomesToday.value;
  double get totalOutcomesToday => _totalOutcomesToday.value;
  double get expectedAmount => _expectedAmount.value;
  
  bool get isCashRegisterOpen => currentCashRegister?.isOpen ?? false;
  bool get isCashRegisterClosed => currentCashRegister?.isClosed ?? false;
  bool get canOpenCashRegister => currentCashRegister == null;
  bool get canCloseCashRegister => isCashRegisterOpen;

  @override
  void onInit() {
    super.onInit();
    // No cargar datos automáticamente para evitar errores de contexto
    print('CashController inicializado correctamente');
  }

  // Inicialización segura para cargar datos cuando sea necesario
  Future<void> initialize() async {
    if (!_hasLoaded) {
      await loadTodayData(showErrorSnackbar: false);
      _hasLoaded = true;
    }
  }

  bool _hasLoaded = false;

  // Cargar datos del día actual
  Future<void> loadTodayData({bool showErrorSnackbar = false}) async {
    try {
      _isLoading.value = true;
      
      // Cargar registro de caja actual
      final registerData = await _db.getCurrentCashRegister();
      if (registerData != null) {
        _currentCashRegister.value = CashRegister.fromMap(registerData);
      } else {
        _currentCashRegister.value = null;
      }

      // Cargar movimientos del día
      await loadTodayMovements();
      
      // Calcular totales
      await calculateTotals();
      
    } catch (e) {
      print('Error al cargar datos de caja: $e'); // Solo imprimir en consola
      if (showErrorSnackbar) {
        Get.snackbar('Error', 'Error al cargar datos de caja: $e');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Cargar movimientos del día
  Future<void> loadTodayMovements() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final movementsData = await _db.getCashMovementsByDate(today);
    
    _todayMovements.clear();
    _todayMovements.addAll(
      movementsData.map((data) => CashMovement.fromMap(data)).toList()
    );
  }

  // Cargar movimientos por fecha específica
  Future<void> loadMovementsByDate(DateTime date) async {
    _isLoading.value = true;
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final movementsData = await _db.getCashMovementsByDate(dateStr);
      
      _todayMovements.clear();
      _todayMovements.addAll(
        movementsData.map((data) => CashMovement.fromMap(data)).toList()
      );
    } catch (e) {
      print('Error al cargar movimientos por fecha: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Calcular totales
  Future<void> calculateTotals() async {
    _totalSalesToday.value = await _db.getTotalCashSalesToday();
    _totalIncomesToday.value = await _db.getTotalCashIncomesToday();
    _totalOutcomesToday.value = await _db.getTotalCashOutcomesToday();
    _expectedAmount.value = await _db.calculateExpectedCashAmount();
    
    // Calcular dinero en mano
    if (currentCashRegister != null) {
      _totalCashInHand.value = currentCashRegister!.openingAmount + 
          _totalIncomesToday.value - _totalOutcomesToday.value;
    } else {
      _totalCashInHand.value = 0.0;
    }
  }

  // Abrir caja
  Future<bool> openCashRegister(double openingAmount) async {
    try {
      if (!canOpenCashRegister) {
        Get.snackbar('Error', 'Ya existe una caja abierta para hoy');
        return false;
      }

      _isLoading.value = true;
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      final register = CashRegister.open(openingAmount, today);
      
      // Insertar registro de caja
      await _db.insertCashRegister(register.toMap());
      
      // Registrar movimiento de apertura
      final openingMovement = CashMovement.apertura(openingAmount, DateTime.now().toIso8601String());
      await _db.insertCashMovement(openingMovement.toMap());
      
      // Recargar datos
      await loadTodayData();
      
      Get.snackbar(
        'Éxito',
        'Caja abierta con \$${openingAmount.toStringAsFixed(2)}',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Error al abrir caja: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Cerrar caja
  Future<bool> closeCashRegister(double actualAmount) async {
    try {
      if (!canCloseCashRegister) {
        Get.snackbar('Error', 'No hay caja abierta para cerrar');
        return false;
      }

      _isLoading.value = true;
      
      final closedRegister = currentCashRegister!.close(actualAmount, expectedAmount);
      await _db.updateCashRegister(closedRegister.toMap());
      
      // Registrar movimiento de cierre
      final closingMovement = CashMovement.cierre(actualAmount, DateTime.now().toIso8601String());
      await _db.insertCashMovement(closingMovement.toMap());
      
      // Recargar datos
      await loadTodayData();
      
      // Mostrar resultado del arqueo
      final difference = closedRegister.difference!;
      String message;
      if (difference.abs() <= 0.01) {
        message = 'Caja cerrada correctamente. Arqueo exacto.';
      } else if (difference < 0) {
        message = 'Caja cerrada. Faltante: \$${difference.abs().toStringAsFixed(2)}';
      } else {
        message = 'Caja cerrada. Sobrante: \$${difference.toStringAsFixed(2)}';
      }
      
      Get.snackbar(
        'Caja Cerrada',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
      
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Error al cerrar caja: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Agregar entrada de dinero
  Future<bool> addCashIncome(double amount, String description) async {
    try {
      if (!isCashRegisterOpen) {
        Get.snackbar('Error', 'Debe abrir la caja primero');
        return false;
      }

      _isLoading.value = true;
      
      final movement = CashMovement.entrada(amount, DateTime.now().toIso8601String(), description);
      await _db.insertCashMovement(movement.toMap());
      
      await loadTodayData();
      
      Get.snackbar(
        'Entrada Registrada',
        '+\$${amount.toStringAsFixed(2)}: $description',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Error al registrar entrada: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Agregar salida de dinero
  Future<bool> addCashOutcome(double amount, String description) async {
    try {
      if (!isCashRegisterOpen) {
        Get.snackbar('Error', 'Debe abrir la caja primero');
        return false;
      }

      if (amount > totalCashInHand) {
        Get.snackbar('Error', 'No hay suficiente dinero en caja');
        return false;
      }

      _isLoading.value = true;
      
      final movement = CashMovement.salida(amount, DateTime.now().toIso8601String(), description);
      await _db.insertCashMovement(movement.toMap());
      
      await loadTodayData();
      
      Get.snackbar(
        'Salida Registrada',
        '-\$${amount.toStringAsFixed(2)}: $description',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Error al registrar salida: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Registrar venta en efectivo (llamado automáticamente desde el sistema de ventas)
  Future<void> registerCashSale(int orderId, double amount) async {
    try {
      if (isCashRegisterOpen) {
        await _db.registerCashSale(orderId, amount);
        await loadTodayData();
      }
    } catch (e) {
      print('Error al registrar venta en efectivo: $e');
    }
  }

  // Obtener resumen del día
  Map<String, dynamic> getDailySummary() {
    return {
      'isOpen': isCashRegisterOpen,
      'openingAmount': currentCashRegister?.openingAmount ?? 0.0,
      'totalSales': totalSalesToday,
      'totalIncomes': totalIncomesToday,
      'totalOutcomes': totalOutcomesToday,
      'cashInHand': totalCashInHand,
      'expectedAmount': expectedAmount,
      'movementsCount': todayMovements.length,
      'openingTime': currentCashRegister?.formattedOpeningTime ?? 'N/A',
    };
  }

  // Formatear moneda
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Refrescar datos
  @override
  Future<void> refresh() async {
    await loadTodayData(showErrorSnackbar: true); // Mostrar errores en refresh manual
  }
}