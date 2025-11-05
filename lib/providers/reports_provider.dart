import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportsProvider {
  final String baseUrl = 'http://192.168.0.48:3000/api';
  final String token;

  ReportsProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // 📦 Análisis de Rotación de Inventario
  Future<Map<String, dynamic>> getInventoryRotationAnalysis({
    required String storeId,
    required String startDate,
    required String endDate,
    String period = 'monthly',
  }) async {
    try {
      print('ReportsProvider.getInventoryRotationAnalysis - StoreId: $storeId');
      print('ReportsProvider.getInventoryRotationAnalysis - Period: $startDate to $endDate');
      
      final response = await http.get(
        Uri.parse('$baseUrl/financial/analysis/inventory-rotation?storeId=$storeId&startDate=$startDate&endDate=$endDate&period=$period'),
        headers: _headers,
      );
      
      print('ReportsProvider.getInventoryRotationAnalysis - Status: ${response.statusCode}');
      print('ReportsProvider.getInventoryRotationAnalysis - Response: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo análisis de rotación'
        };
      }
    } catch (e) {
      print('ReportsProvider.getInventoryRotationAnalysis - Exception: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // 💰 Análisis de Rentabilidad por Producto
  Future<Map<String, dynamic>> getProfitabilityAnalysis({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      print('ReportsProvider.getProfitabilityAnalysis - StoreId: $storeId');
      print('ReportsProvider.getProfitabilityAnalysis - Period: $startDate to $endDate');
      
      final response = await http.get(
        Uri.parse('$baseUrl/financial/analysis/profitability?storeId=$storeId&startDate=$startDate&endDate=$endDate'),
        headers: _headers,
      );
      
      print('ReportsProvider.getProfitabilityAnalysis - Status: ${response.statusCode}');
      print('ReportsProvider.getProfitabilityAnalysis - Response: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo análisis de rentabilidad'
        };
      }
    } catch (e) {
      print('ReportsProvider.getProfitabilityAnalysis - Exception: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // 📈 Análisis de Tendencias de Ventas
  Future<Map<String, dynamic>> getSalesTrendsAnalysis({
    required String storeId,
    required String startDate,
    required String endDate,
    String period = 'daily',
  }) async {
    try {
      print('ReportsProvider.getSalesTrendsAnalysis - StoreId: $storeId');
      print('ReportsProvider.getSalesTrendsAnalysis - Period: $startDate to $endDate ($period)');
      
      final response = await http.get(
        Uri.parse('$baseUrl/financial/analysis/sales-trends?storeId=$storeId&startDate=$startDate&endDate=$endDate&period=$period'),
        headers: _headers,
      );
      
      print('ReportsProvider.getSalesTrendsAnalysis - Status: ${response.statusCode}');
      print('ReportsProvider.getSalesTrendsAnalysis - Response: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo análisis de tendencias'
        };
      }
    } catch (e) {
      print('ReportsProvider.getSalesTrendsAnalysis - Exception: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // 🔄 Comparación de Períodos
  Future<Map<String, dynamic>> getPeriodsComparison({
    required String storeId,
    required String currentStartDate,
    required String currentEndDate,
    required String previousStartDate,
    required String previousEndDate,
  }) async {
    try {
      print('ReportsProvider.getPeriodsComparison - StoreId: $storeId');
      print('ReportsProvider.getPeriodsComparison - Current: $currentStartDate to $currentEndDate');
      print('ReportsProvider.getPeriodsComparison - Previous: $previousStartDate to $previousEndDate');
      
      final response = await http.get(
        Uri.parse('$baseUrl/financial/analysis/periods-comparison?storeId=$storeId&currentStartDate=$currentStartDate&currentEndDate=$currentEndDate&previousStartDate=$previousStartDate&previousEndDate=$previousEndDate'),
        headers: _headers,
      );
      
      print('ReportsProvider.getPeriodsComparison - Status: ${response.statusCode}');
      print('ReportsProvider.getPeriodsComparison - Response: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo comparación de períodos'
        };
      }
    } catch (e) {
      print('ReportsProvider.getPeriodsComparison - Exception: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }
}