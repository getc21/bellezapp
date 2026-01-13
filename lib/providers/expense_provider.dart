import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/expense.dart';
import '../config/api_config.dart';

class ExpenseProvider {
  final String? token;

  ExpenseProvider(this.token);

  String get _baseUrl => '${ApiConfig.baseUrl}/expenses';

  // Headers con autenticación
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ✅ CREAR GASTO
  Future<Expense> createExpense({
    required String storeId,
    required double amount,
    String? description,
    String? categoryId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'storeId': storeId,
          'amount': amount,
          'description': description,
          'categoryId': categoryId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Expense.fromJson(data['data']['expense'] ?? data['expense']);
      } else {
        throw Exception('Error creating expense: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 📋 OBTENER GASTOS
  Future<List<Expense>> getExpenses({
    String? storeId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{};
      if (storeId != null) params['storeId'] = storeId;
      if (categoryId != null) params['categoryId'] = categoryId;
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse(_baseUrl);
      final response = await http.get(
        params.isEmpty ? uri : uri.replace(queryParameters: params),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final expenses = (data['data']['expenses'] as List)
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
        return expenses;
      } else {
        throw Exception('Error fetching expenses: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 📊 OBTENER REPORTE DE GASTOS
  Future<ExpenseReport> getExpenseReport({
    required String storeId,
    String period = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{
        'storeId': storeId,
        'period': period,
      };
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('$_baseUrl/reports');
      final response = await http.get(
        uri.replace(queryParameters: params),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExpenseReport.fromJson(data['data']['report'] ?? data['report']);
      } else {
        throw Exception('Error fetching expense report: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 🏷️ OBTENER CATEGORÍAS DE GASTOS
  Future<List<ExpenseCategory>> getExpenseCategories({
    String? storeId,
  }) async {
    try {
      final params = <String, String>{};
      if (storeId != null) params['storeId'] = storeId;

      final uri = Uri.parse('$_baseUrl/categories');
      final response = await http.get(
        params.isEmpty ? uri : uri.replace(queryParameters: params),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = (data['data']['categories'] as List)
            .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        return categories;
      } else {
        throw Exception('Error fetching categories: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ➕ CREAR CATEGORÍA DE GASTO
  Future<ExpenseCategory> createExpenseCategory({
    required String storeId,
    required String name,
    String? icon,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/categories'),
        headers: _headers,
        body: jsonEncode({
          'storeId': storeId,
          'name': name,
          'icon': icon,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExpenseCategory.fromJson(data['data']['category'] ?? data['category']);
      } else {
        throw Exception('Error creating category: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ✏️ ACTUALIZAR GASTO
  Future<Expense> updateExpense({
    required String expenseId,
    String? storeId,
    double? amount,
    String? description,
    String? categoryId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/$expenseId'),
        headers: _headers,
        body: jsonEncode({
          if (storeId != null) 'storeId': storeId,
          if (amount != null) 'amount': amount,
          if (description != null) 'description': description,
          if (categoryId != null) 'categoryId': categoryId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Expense.fromJson(data['data']['expense'] ?? data['expense']);
      } else {
        throw Exception('Error updating expense: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ❌ ELIMINAR GASTO
  Future<void> deleteExpense(String expenseId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$expenseId'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error deleting expense: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 📊 COMPARAR PERÍODOS DE GASTOS
  Future<ExpensePeriodComparison> compareExpensePeriods({
    required String storeId,
    DateTime? startDate1,
    DateTime? endDate1,
    DateTime? startDate2,
    DateTime? endDate2,
  }) async {
    try {
      final params = <String, String>{
        'storeId': storeId,
      };
      if (startDate1 != null) params['startDate1'] = startDate1.toIso8601String();
      if (endDate1 != null) params['endDate1'] = endDate1.toIso8601String();
      if (startDate2 != null) params['startDate2'] = startDate2.toIso8601String();
      if (endDate2 != null) params['endDate2'] = endDate2.toIso8601String();

      final uri = Uri.parse('$_baseUrl/reports/compare');
      final response = await http.get(
        uri.replace(queryParameters: params),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExpensePeriodComparison.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Error comparing periods: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
