import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  static ApiService get instance => _instance;
  ApiService._();

  // URL base del backend - ahora se detecta automáticamente
  static String get baseUrl => ApiConfig.baseUrl;
  
  String? _authToken;
  
  // Getters
  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null;

  // Headers comunes
  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Headers para multipart
  Map<String, String> get _authHeaders => <String, String>{
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Inicializar (cargar token guardado)
  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Guardar token
  Future<void> _saveToken(String token) async {
    _authToken = token;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Eliminar token
  Future<void> _clearToken() async {
    _authToken = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ==================== AUTH ====================
  
  Future<ApiResponse> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'username': username,
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> login(String username, String password) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );
      
      final ApiResponse result = _handleResponse(response);
      
      if (result.success && result.data != null) {
        final token = result.data['token'];
        if (token != null) {
          await _saveToken(token);
        }
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> getProfile() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<void> logout() async {
    await _clearToken();
  }

  // ==================== CATEGORIES ====================
  
  Future<ApiResponse> getCategories() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> getCategoryById(String id) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> createCategory({
    required String name,
    String? description,
    File? imageFile,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/categories'),
      );
      
      request.headers.addAll(_authHeaders);
      request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', imageFile.path));
      }
      
      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> updateCategory({
    required String id,
    String? name,
    String? description,
    File? imageFile,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/categories/$id'),
      );
      
      request.headers.addAll(_authHeaders);
      if (name != null) request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', imageFile.path));
      }
      
      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> deleteCategory(String id) async {
    try {
      final http.Response response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // ==================== SUPPLIERS ====================
  
  Future<ApiResponse> getSuppliers() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/suppliers'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> getSupplierById(String id) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> createSupplier({
    required String name,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    File? imageFile,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
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
        request.files.add(await http.MultipartFile.fromPath('foto', imageFile.path));
      }
      
      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> updateSupplier({
    required String id,
    String? name,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    File? imageFile,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
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
        request.files.add(await http.MultipartFile.fromPath('foto', imageFile.path));
      }
      
      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> deleteSupplier(String id) async {
    try {
      final http.Response response = await http.delete(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // ==================== PRODUCTS ====================
  
  Future<ApiResponse> getProducts({String? storeId, String? categoryId, bool? lowStock}) async {
    try {
      final Map<String, String> queryParams = <String, String>{};
      if (storeId != null) queryParams['storeId'] = storeId;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (lowStock != null) queryParams['lowStock'] = lowStock.toString();
      
      final Uri uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
      final http.Response response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> getProductById(String id) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> createProduct({
    required String name,
    String? description,
    required double purchasePrice,
    required double salePrice,
    double? weight,
    required String categoryId,
    required String supplierId,
    required String locationId,
    required String storeId,
    required int stock,
    File? imageFile,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products'),
      );
      
      request.headers.addAll(_authHeaders);
      request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      request.fields['purchasePrice'] = purchasePrice.toString();
      request.fields['salePrice'] = salePrice.toString();
      if (weight != null) request.fields['weight'] = weight.toString();
      request.fields['categoryId'] = categoryId;
      request.fields['supplierId'] = supplierId;
      request.fields['locationId'] = locationId;
      request.fields['storeId'] = storeId;
      request.fields['stock'] = stock.toString();
      
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', imageFile.path));
      }
      
      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> updateProduct({
    required String id,
    String? name,
    String? description,
    double? purchasePrice,
    double? salePrice,
    double? weight,
    String? categoryId,
    String? supplierId,
    String? locationId,
    File? imageFile,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/products/$id'),
      );
      
      request.headers.addAll(_authHeaders);
      if (name != null) request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      if (purchasePrice != null) request.fields['purchasePrice'] = purchasePrice.toString();
      if (salePrice != null) request.fields['salePrice'] = salePrice.toString();
      if (weight != null) request.fields['weight'] = weight.toString();
      if (categoryId != null) request.fields['categoryId'] = categoryId;
      if (supplierId != null) request.fields['supplierId'] = supplierId;
      if (locationId != null) request.fields['locationId'] = locationId;
      
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', imageFile.path));
      }
      
      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> deleteProduct(String id) async {
    try {
      final http.Response response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> updateProductStock(String id, int quantity, String operation) async {
    try {
      final http.Response response = await http.patch(
        Uri.parse('$baseUrl/products/$id/stock'),
        headers: _headers,
        body: jsonEncode(<String, Object>{
          'quantity': quantity,
          'operation': operation, // 'add' o 'subtract'
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // ==================== STORES ====================
  
  Future<ApiResponse> getStores() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/stores'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // ==================== CUSTOMERS ====================
  
  Future<ApiResponse> getCustomers({String? search}) async {
    try {
      final Map<String, String> queryParams = <String, String>{};
      if (search != null) queryParams['search'] = search;
      
      final Uri uri = Uri.parse('$baseUrl/customers').replace(queryParameters: queryParams);
      final http.Response response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: _headers,
        body: jsonEncode(<String, String>{
          'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // ==================== ORDERS ====================
  
  Future<ApiResponse> createOrder({
    required String customerId,
    required String storeId,
    required String userId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: jsonEncode(<String, Object>{
          'customerId': customerId,
          'storeId': storeId,
          'userId': userId,
          'paymentMethod': paymentMethod,
          'items': items,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // ==================== HELPERS ====================
  
  ApiResponse _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(body);
      } else {
        final message = body['message'] ?? 'Error desconocido';
        return ApiResponse.error(message);
      }
    } catch (e) {
      return ApiResponse.error('Error procesando respuesta: $e');
    }
  }
}

// Clase para respuestas de API
class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;

  ApiResponse._(this.success, this.message, this.data);

  factory ApiResponse.success(dynamic data) => ApiResponse._(true, null, data);
  factory ApiResponse.error(String message) => ApiResponse._(false, message, null);
}
