import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class CategoryProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  CategoryProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $token',
  };

  // Obtener todas las categorías
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final categories = data['data']['categories'];
        if (categories is List) {
          return {'success': true, 'data': categories};
        } else {
          return {'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo categorías'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener categoría por ID
  Future<Map<String, dynamic>> getCategoryById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['category']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo categoría'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear categoría
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/categories'),
      );

      request.headers.addAll(_authHeaders);
      request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;

      if (imageFile != null) {
        // Determinar el tipo MIME basado en la extensión
        String mimeType = 'image/jpeg'; // Default
        String extension = imageFile.path.split('.').last.toLowerCase();
        
        switch (extension) {
          case 'png':
            mimeType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
        }

        print('� Subiendo imagen: $extension -> $mimeType');
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto', 
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          )
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        print('✅ Categoría creada exitosamente');
        return {'success': true, 'data': data['data']};
      } else {
        print('❌ Error del servidor: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando categoría'
        };
      }
    } catch (e) {
      print('💥 Error de conexión: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar categoría
  Future<Map<String, dynamic>> updateCategory({
    required String id,
    String? name,
    String? description,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/categories/$id'),
      );

      request.headers.addAll(_authHeaders);
      if (name != null) request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;

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
          'message': data['message'] ?? 'Error actualizando categoría'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar categoría
  Future<Map<String, dynamic>> deleteCategory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando categoría'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
