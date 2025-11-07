import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../config/api_config.dart';
import '../controllers/store_controller.dart';
import '../controllers/auth_controller.dart';

class CashRegisterProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  CashRegisterProvider(this.token);

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Obtener storeId y userId reales
  Map<String, String> _getRealIds() {
    try {
      final StoreController storeController = Get.find<StoreController>();
      final AuthController authController = Get.find<AuthController>();
      final Map<String, dynamic>? currentStore = storeController.currentStore;
      final Map<String, dynamic>? currentUser = authController.currentUser;

      if (currentStore == null) {
        throw Exception('No hay tienda seleccionada. Selecciona una tienda primero.');
      }

      if (currentUser == null) {
        throw Exception('No hay usuario autenticado.');
      }

      final String? storeId = currentStore['_id']?.toString();
      final String? userId = currentUser['_id']?.toString() ?? currentUser['id']?.toString();

      if (storeId == null || storeId.isEmpty) {
        throw Exception('El ID de la tienda no es válido.');
      }

      if (userId == null || userId.isEmpty) {
        throw Exception('El ID del usuario no es válido.');
      }

      // Validar que sean ObjectIds válidos (24 caracteres hexadecimales)
      final RegExp objectIdRegex = RegExp(r'^[0-9a-fA-F]{24}$');
      
      if (!objectIdRegex.hasMatch(storeId)) {
        throw Exception('El ID de la tienda no tiene formato ObjectId válido.');
      }
      if (!objectIdRegex.hasMatch(userId)) {
        throw Exception('El ID del usuario no tiene formato ObjectId válido.');
      }
      return <String, String>{
        'storeId': storeId,
        'userId': userId,
      };
    } catch (e) {
      rethrow; // Re-lanzar la excepción para manejarla en el método que llama
    }
  }

  // Obtener todas las cajas registradoras
  Future<Map<String, dynamic>> getCashRegisters({String? storeId}) async {
    try {
      // Como el backend no tiene endpoint para listar cajas, simulamos una respuesta
      return <String, dynamic>{
        'success': true, 
        'data': <Map<String, String>>[
          <String, String>{
            '_id': 'default-cash-register',
            'id': 'default-cash-register',
            'name': 'Caja Principal',
            'storeId': storeId ?? 'default-store',
            'status': 'available'
          }
        ]
      };
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener caja por ID
  Future<Map<String, dynamic>> getCashRegisterById(String id) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/cash-registers/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return <String, dynamic>{'success': true, 'data': data['data']['cashRegister']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error obteniendo caja'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener estado actual de la caja
  Future<Map<String, dynamic>> getCurrentCashRegisterStatus() async {
    try {
      final Map<String, String> realIds = _getRealIds();
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/cash/status?storeId=${realIds['storeId']}'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{'success': false, 'message': 'Error obteniendo estado de caja'};
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Cerrar caja registradora
  Future<Map<String, dynamic>> createCashRegister({
    required String storeId,
    required String name,
    required double initialBalance,
  }) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/cash-registers'),
        headers: _headers,
        body: jsonEncode(<String, Object>{
          'storeId': storeId,
          'name': name,
          'initialBalance': initialBalance,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error creando caja'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar caja registradora
  Future<Map<String, dynamic>> updateCashRegister({
    required String id,
    String? name,
    double? initialBalance,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (initialBalance != null) body['initialBalance'] = initialBalance;

      final http.Response response = await http.patch(
        Uri.parse('$baseUrl/cash-registers/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error actualizando caja'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar caja registradora
  Future<Map<String, dynamic>> deleteCashRegister(String id) async {
    try {
      final http.Response response = await http.delete(
        Uri.parse('$baseUrl/cash-registers/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return <String, dynamic>{'success': true};
      } else {
        final data = jsonDecode(response.body);
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error eliminando caja'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Abrir caja (crear sesión)
  Future<Map<String, dynamic>> openCashRegister({
    required String cashRegisterId,
    required double openingBalance,
  }) async {
    try {    
      final Map<String, String> realIds = _getRealIds();
      final Map<String, Object?> requestBody = <String, Object?>{
        'openingAmount': openingBalance,
        'storeId': realIds['storeId'],
        'userId': realIds['userId']
      };      
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/cash/register/open'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );    
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else if (response.statusCode == 400 && data['message']?.toString().contains('already an open cash register') == true) {
        return <String, dynamic>{
          'success': false,
          'message': 'Ya hay una caja abierta en esta tienda',
          'isAlreadyOpen': true,
        };
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error abriendo caja'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Cerrar caja
  Future<Map<String, dynamic>> closeCashRegister({
    required String cashRegisterId,
    required double closingBalance,
  }) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/cash/register/close/$cashRegisterId'),
        headers: _headers,
        body: jsonEncode(<String, double>{'closingAmount': closingBalance}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error cerrando caja'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener movimientos de caja
  Future<Map<String, dynamic>> getCashMovements({
    required String cashRegisterId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final Map<String, String> realIds = _getRealIds();
      final Map<String, String> queryParams = <String, String>{
        'storeId': realIds['storeId']!,
      };
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final Uri uri = Uri.parse('$baseUrl/cash/movements')
          .replace(queryParameters: queryParams);
      final http.Response response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final movements = data['data']['movements'] ?? data['data'] ?? <dynamic>[];
        if (movements.isNotEmpty) {
        }
        return <String, dynamic>{'success': true, 'data': movements};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error obteniendo movimientos'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Registrar movimiento de caja
  Future<Map<String, dynamic>> addCashMovement({
    required String cashRegisterId,
    required String type, // income, expense, withdrawal
    required double amount,
    required String description,
  }) async {
    try {
      final Map<String, String> realIds = _getRealIds();
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/cash/movements'),
        headers: _headers,
        body: jsonEncode(<String, Object>{
          'date': DateTime.now().toIso8601String(),
          'type': type,
          'amount': amount,
          'description': description,
          'storeId': realIds['storeId']!,
          'userId': realIds['userId']!,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error registrando movimiento'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
