import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  // Verificar el hash correcto para 'admin123'
  final password = 'admin123';
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  final hash = digest.toString();
  
  print('Contraseña: $password');
  print('Hash SHA256: $hash');
  
  // Comparar con el hash que tenemos en la base de datos
  const hashEnBaseDatos = "240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9";
  print('Hash en BD: $hashEnBaseDatos');
  print('¿Coinciden?: ${hash == hashEnBaseDatos}');
}