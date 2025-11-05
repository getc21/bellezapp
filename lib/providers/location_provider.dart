import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LocationProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  LocationProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Obtener todas las ubicaciones de una tienda
  Future<Map<String, dynamic>> getLocations({String? storeId}) async {
    try {
      final queryParams = <String, String>{};
      if (storeId != null) queryParams['storeId'] = storeId;

      final uri = Uri.parse('$baseUrl/locations').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final locations = data['data']['locations'];
        if (locations is List) {
          return {'success': true, 'data': locations};
        } else {
          return {'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo ubicaciones'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener ubicación por ID
  Future<Map<String, dynamic>> getLocationById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['location']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo ubicación'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear ubicación
  Future<Map<String, dynamic>> createLocation({
    required String storeId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/locations'),
        headers: _headers,
        body: jsonEncode({
          'storeId': storeId,
          'name': name,
          if (description != null) 'description': description,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando ubicación'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar ubicación
  Future<Map<String, dynamic>> updateLocation({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;

      final response = await http.patch(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando ubicación'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar ubicación
  Future<Map<String, dynamic>> deleteLocation(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando ubicación'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
