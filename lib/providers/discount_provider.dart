import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DiscountProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  DiscountProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Obtener todos los descuentos
  Future<Map<String, dynamic>> getDiscounts({
    bool? active,
    String? storeId,
  }) async {
    try {
      print('DiscountProvider.getDiscounts - Starting request');
      print('DiscountProvider.getDiscounts - Parameters: active=$active, storeId=$storeId');
      
      final queryParams = <String, String>{};
      if (active != null) queryParams['active'] = active.toString();
      if (storeId != null) queryParams['storeId'] = storeId;

      final uri = Uri.parse('$baseUrl/discounts').replace(queryParameters: queryParams);
      print('DiscountProvider.getDiscounts - Request URI: $uri');
      print('DiscountProvider.getDiscounts - Headers: $_headers');
      
      final response = await http.get(uri, headers: _headers);
      print('DiscountProvider.getDiscounts - Response status: ${response.statusCode}');
      print('DiscountProvider.getDiscounts - Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      print('DiscountProvider.getDiscounts - Decoded data: $data');

      if (response.statusCode == 200) {
        final discounts = data['data']['discounts'];
        print('DiscountProvider.getDiscounts - Extracted discounts: $discounts');
        print('DiscountProvider.getDiscounts - Discounts type: ${discounts.runtimeType}');
        
        if (discounts is List) {
          print('DiscountProvider.getDiscounts - Returning ${discounts.length} discounts');
          return {'success': true, 'data': discounts};
        } else {
          print('DiscountProvider.getDiscounts - Invalid response format');
          return {'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        print('DiscountProvider.getDiscounts - Error response: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo descuentos'
        };
      }
    } catch (e) {
      print('DiscountProvider.getDiscounts - Exception: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener descuento por ID
  Future<Map<String, dynamic>> getDiscountById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/discounts/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['discount']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo descuento'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear descuento
  Future<Map<String, dynamic>> createDiscount({
    required String name,
    String? description,
    required String type, // percentage, fixed
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    String? startDate,
    String? endDate,
    bool? active,
    String? storeId, // ⭐ AGREGAR STOREID
  }) async {
    try {
      print('DiscountProvider.createDiscount - Creating discount with storeId: $storeId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/discounts'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          if (description != null) 'description': description,
          'type': type,
          'value': value,
          if (minimumAmount != null) 'minimumAmount': minimumAmount,
          if (maximumDiscount != null) 'maximumDiscount': maximumDiscount,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (active != null) 'active': active,
          if (storeId != null) 'storeId': storeId, // ⭐ INCLUIR STOREID EN EL BODY
        }),
      );
      
      print('DiscountProvider.createDiscount - Response status: ${response.statusCode}');
      print('DiscountProvider.createDiscount - Response body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando descuento'
        };
      }
    } catch (e) {
      print('DiscountProvider.createDiscount - Exception: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar descuento
  Future<Map<String, dynamic>> updateDiscount({
    required String id,
    String? name,
    String? description,
    String? type,
    double? value,
    double? minimumAmount,
    double? maximumDiscount,
    String? startDate,
    String? endDate,
    bool? active,
  }) async {
    try {
      print('DiscountProvider.updateDiscount - Updating discount: $id');
      
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (type != null) body['type'] = type;
      if (value != null) body['value'] = value;
      if (minimumAmount != null) body['minimumAmount'] = minimumAmount;
      if (maximumDiscount != null) body['maximumDiscount'] = maximumDiscount;
      if (startDate != null) body['startDate'] = startDate;
      if (endDate != null) body['endDate'] = endDate;
      if (active != null) body['active'] = active;

      print('DiscountProvider.updateDiscount - Request body: $body');
      print('DiscountProvider.updateDiscount - Making request to: $baseUrl/discounts/$id');

      final response = await http.patch(
        Uri.parse('$baseUrl/discounts/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      
      print('DiscountProvider.updateDiscount - Response status: ${response.statusCode}');
      print('DiscountProvider.updateDiscount - Response body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('DiscountProvider.updateDiscount - Update successful');
        return {'success': true, 'data': data['data']};
      } else {
        print('DiscountProvider.updateDiscount - Update failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando descuento'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar descuento
  Future<Map<String, dynamic>> deleteDiscount(String id) async {
    try {
      print('DiscountProvider.deleteDiscount - Deleting discount: $id');
      print('DiscountProvider.deleteDiscount - Making request to: $baseUrl/discounts/$id');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/discounts/$id'),
        headers: _headers,
      );

      print('DiscountProvider.deleteDiscount - Response status: ${response.statusCode}');
      print('DiscountProvider.deleteDiscount - Response body: "${response.body}"');

      // Manejar tanto código 200 como 204 para compatibilidad
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Intentar parsear respuesta JSON si hay contenido
        if (response.body.isNotEmpty && response.body.trim().isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            print('DiscountProvider.deleteDiscount - Parsed JSON response: $data');
            return {'success': true, 'data': data, 'message': data['message'] ?? 'Descuento eliminado exitosamente'};
          } catch (e) {
            print('DiscountProvider.deleteDiscount - Failed to parse JSON, but status is success');
            return {'success': true, 'message': 'Descuento eliminado exitosamente'};
          }
        } else {
          print('DiscountProvider.deleteDiscount - Empty response but successful status');
          return {'success': true, 'message': 'Descuento eliminado exitosamente'};
        }
      } else {
        print('DiscountProvider.deleteDiscount - Error status code');
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Error eliminando descuento'
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error eliminando descuento: código ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      print('DiscountProvider.deleteDiscount - Exception: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
