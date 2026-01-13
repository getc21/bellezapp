import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class ExpenseController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();

  ExpenseProvider get _expenseProvider => ExpenseProvider(_authController.token);

  // Estados observables
  final RxList<Expense> _expenses = <Expense>[].obs;
  final RxList<ExpenseCategory> _categories = <ExpenseCategory>[].obs;
  final Rx<ExpenseReport?> _report = Rx<ExpenseReport?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  ExpenseReport? get report => _report.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadExpensesForCurrentStore();
    _loadInitialReport();
  }

  // 📊 CARGAR REPORTE INICIAL
  Future<void> _loadInitialReport() async {
    final currentStore = _storeController.currentStore;
    if (currentStore != null) {
      await loadExpenseReport(
        storeId: currentStore['_id'],
        period: 'monthly',
      );
    }
  }

  // 📋 CARGAR GASTOS DE LA TIENDA ACTUAL
  Future<void> loadExpensesForCurrentStore() async {
    final currentStore = _storeController.currentStore;
    if (currentStore != null) {
      await loadExpenses(storeId: currentStore['_id']);
      await loadCategories(storeId: currentStore['_id']);
    }
  }

  // 📋 CARGAR GASTOS
  Future<void> loadExpenses({
    String? storeId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final expenses = await _expenseProvider.getExpenses(
        storeId: storeId,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );

      _expenses.value = expenses;
    } catch (e) {
      _errorMessage.value = 'Error cargando gastos: $e';
      if (kDebugMode) debugPrint('Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // 🏷️ CARGAR CATEGORÍAS
  Future<void> loadCategories({required String storeId}) async {
    try {
      final categories = await _expenseProvider.getExpenseCategories(storeId: storeId);
      _categories.value = categories;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading categories: $e');
    }
  }

  // ➕ CREAR NUEVO GASTO
  Future<bool> createExpense({
    required String storeId,
    required double amount,
    String? description,
    String? categoryId,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final expense = await _expenseProvider.createExpense(
        storeId: storeId,
        amount: amount,
        description: description,
        categoryId: categoryId,
      );

      _expenses.insert(0, expense);

      // Recargar reporte
      await loadExpenseReport(storeId: storeId);

      return true;
    } catch (e) {
      _errorMessage.value = 'Error creando gasto: $e';
      if (kDebugMode) debugPrint('Error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ➕ CREAR CATEGORÍA
  Future<bool> createCategory({
    required String storeId,
    required String name,
    String? icon,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final category = await _expenseProvider.createExpenseCategory(
        storeId: storeId,
        name: name,
        icon: icon,
      );

      _categories.add(category);

      return true;
    } catch (e) {
      _errorMessage.value = 'Error creando categoría: $e';
      if (kDebugMode) debugPrint('Error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // 📊 CARGAR REPORTE DE GASTOS
  Future<void> loadExpenseReport({
    required String storeId,
    String period = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final report = await _expenseProvider.getExpenseReport(
        storeId: storeId,
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      _report.value = report;
    } catch (e) {
      _errorMessage.value = 'Error cargando reporte: $e';
      if (kDebugMode) debugPrint('Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // ✏️ ACTUALIZAR GASTO
  Future<bool> updateExpense({
    required String expenseId,
    String? storeId,
    double? amount,
    String? description,
    String? categoryId,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final expense = await _expenseProvider.updateExpense(
        expenseId: expenseId,
        storeId: storeId,
        amount: amount,
        description: description,
        categoryId: categoryId,
      );

      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        _expenses[index] = expense;
      }

      // Recargar reporte
      if (storeId != null) {
        await loadExpenseReport(storeId: storeId);
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Error actualizando gasto: $e';
      if (kDebugMode) debugPrint('Error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ❌ ELIMINAR GASTO
  Future<bool> deleteExpense({
    required String expenseId,
    required String storeId,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _expenseProvider.deleteExpense(expenseId);

      _expenses.removeWhere((e) => e.id == expenseId);

      // Recargar reporte
      await loadExpenseReport(storeId: storeId);

      return true;
    } catch (e) {
      _errorMessage.value = 'Error eliminando gasto: $e';
      if (kDebugMode) debugPrint('Error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // 📊 COMPARAR PERÍODOS
  Future<ExpensePeriodComparison?> compareExpensePeriods({
    required String storeId,
    DateTime? startDate1,
    DateTime? endDate1,
    DateTime? startDate2,
    DateTime? endDate2,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final result = await _expenseProvider.compareExpensePeriods(
        storeId: storeId,
        startDate1: startDate1,
        endDate1: endDate1,
        startDate2: startDate2,
        endDate2: endDate2,
      );

      return result;
    } catch (e) {
      _errorMessage.value = 'Error comparando períodos: $e';
      if (kDebugMode) debugPrint('Error: $e');
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // 🔄 REFRESCAR CUANDO CAMBIE LA TIENDA
  Future<void> refreshForStore() async {
    await loadExpensesForCurrentStore();
  }
}
