import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class OrderProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  OrderProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Crear orden
  Future<Map<String, dynamic>> createOrder({
    required String storeId,
    String? customerId,
    required List<Map<String, dynamic>> items, // [{productId, quantity, price}]
    required String paymentMethod,
    String? cashRegisterId,
    String? discountId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode({
          'storeId': storeId,
          if (customerId != null) 'customerId': customerId,
          'items': items,
          'paymentMethod': paymentMethod,
          if (cashRegisterId != null) 'cashRegisterId': cashRegisterId,
          if (discountId != null) 'discountId': discountId,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando orden'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener todas las órdenes con filtros opcionales
  Future<Map<String, dynamic>> getOrders({
    String? storeId,
    String? customerId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (storeId != null) queryParams['storeId'] = storeId;
      if (customerId != null) queryParams['customerId'] = customerId;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final orders = data['data']['orders'];
        if (orders is List) {
          return {'success': true, 'data': orders};
        } else {
          return {'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo órdenes'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener orden por ID
  Future<Map<String, dynamic>> getOrderById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['order']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo orden'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar estado de orden
  Future<Map<String, dynamic>> updateOrderStatus({
    required String id,
    required String status, // pending, completed, cancelled
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$id'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando orden'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener reporte de ventas
  Future<Map<String, dynamic>> getSalesReport({
    String? storeId,
    String? startDate,
    String? endDate,
    String? groupBy, // day, week, month
  }) async {
    try {
      final queryParams = <String, String>{};
      if (storeId != null) queryParams['storeId'] = storeId;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (groupBy != null) queryParams['groupBy'] = groupBy;

      final uri = Uri.parse('$baseUrl/orders/reports/sales')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo reporte'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar orden
  Future<Map<String, dynamic>> deleteOrder(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/orders/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando orden'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
