import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CustomerProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  CustomerProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Obtener todos los clientes
  Future<Map<String, dynamic>> getCustomers({String? storeId}) async {
    try {
      final uri = Uri.parse('$baseUrl/customers');
      final queryParams = <String, String>{};
      
      if (storeId != null) {
        queryParams['storeId'] = storeId;
      }
      
      print('🔍 CustomerProvider: Solicitando clientes para tienda: $storeId');
      
      final response = await http.get(
        uri.replace(queryParameters: queryParams),
        headers: _headers,
      );
      
      print('📋 CustomerProvider: Status Code: ${response.statusCode}');
      print('📋 CustomerProvider: Response: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // El backend devuelve: { status: 'success', data: { customers: [...] } }
        try {
          if (data is Map && data.containsKey('data')) {
            final dataSection = data['data'];
            
            if (dataSection is Map && dataSection.containsKey('customers')) {
              final customers = dataSection['customers'];
              
              if (customers is List) {
                print('✅ CustomerProvider: Recibidos ${customers.length} clientes');
                return {'success': true, 'data': customers};
              } else {
                print('❌ CustomerProvider: customers no es una lista, es: ${customers.runtimeType}');
                print('Customers recibido: $customers');
                return {'success': false, 'message': 'customers no es una lista'};
              }
            } else {
              print('❌ CustomerProvider: data no contiene customers');
              print('DataSection: $dataSection');
              
              // Verificar si data contiene directamente una lista
              if (dataSection is List) {
                print('⚠️ CustomerProvider: data es una lista directa');
                return {'success': true, 'data': dataSection};
              }
              
              return {'success': false, 'message': 'Estructura de data inválida'};
            }
          } else {
            print('❌ CustomerProvider: Respuesta no contiene data');
            print('Respuesta completa: $data');
            return {'success': false, 'message': 'Respuesta sin data'};
          }
        } catch (e) {
          print('❌ CustomerProvider: Error procesando respuesta: $e');
          return {'success': false, 'message': 'Error procesando respuesta: $e'};
        }
      } else {
        print('❌ CustomerProvider: Error del servidor: ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo clientes'
        };
      }
    } catch (e) {
      print('❌ CustomerProvider: Excepción: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener cliente por ID
  Future<Map<String, dynamic>> getCustomerById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['customer']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo cliente'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear cliente
  Future<Map<String, dynamic>> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    required String storeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'storeId': storeId,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando cliente'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar cliente
  Future<Map<String, dynamic>> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;
      if (address != null) body['address'] = address;
      if (notes != null) body['notes'] = notes;

      final response = await http.patch(
        Uri.parse('$baseUrl/customers/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando cliente'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar cliente
  Future<Map<String, dynamic>> deleteCustomer(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customers/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando cliente'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
