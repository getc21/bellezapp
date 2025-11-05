import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SupplierProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  SupplierProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $token',
  };

  // Obtener todos los proveedores
  Future<Map<String, dynamic>> getSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/suppliers'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final suppliers = data['data']['suppliers'];
        if (suppliers is List) {
          return {'success': true, 'data': suppliers};
        } else {
          return {'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo proveedores'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener proveedor por ID
  Future<Map<String, dynamic>> getSupplierById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['supplier']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo proveedor'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear proveedor
  Future<Map<String, dynamic>> createSupplier({
    required String name,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/suppliers'),
      );

      request.headers.addAll(_authHeaders);
      request.fields['name'] = name;
      if (contactName != null) request.fields['contactName'] = contactName;
      if (contactEmail != null) request.fields['contactEmail'] = contactEmail;
      if (contactPhone != null) request.fields['contactPhone'] = contactPhone;
      if (address != null) request.fields['address'] = address;

      if (imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('foto', imageFile.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando proveedor'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar proveedor
  Future<Map<String, dynamic>> updateSupplier({
    required String id,
    String? name,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/suppliers/$id'),
      );

      request.headers.addAll(_authHeaders);
      if (name != null) request.fields['name'] = name;
      if (contactName != null) request.fields['contactName'] = contactName;
      if (contactEmail != null) request.fields['contactEmail'] = contactEmail;
      if (contactPhone != null) request.fields['contactPhone'] = contactPhone;
      if (address != null) request.fields['address'] = address;

      if (imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('foto', imageFile.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando proveedor'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar proveedor
  Future<Map<String, dynamic>> deleteSupplier(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando proveedor'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
