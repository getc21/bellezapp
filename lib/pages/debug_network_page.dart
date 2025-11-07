import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api_config.dart';

class DebugNetworkPage extends StatefulWidget {
  const DebugNetworkPage({super.key});

  @override
  State<DebugNetworkPage> createState() => _DebugNetworkPageState();
}

class _DebugNetworkPageState extends State<DebugNetworkPage> {
  String _connectionStatus = 'No probado';
  bool _isLoading = false;
  Map<String, dynamic>? _debugInfo;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  void _loadDebugInfo() {
    setState(() {
      _debugInfo = ApiConfig.getDebugInfo();
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Probando...';
    });

    try {
      final http.Response response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: <String, String>{'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      setState(() {
        if (response.statusCode == 405 || response.statusCode == 200) {
          // 405 = Method Not Allowed es esperado para GET en /login
          _connectionStatus = '✅ Conexión exitosa (${response.statusCode})';
        } else {
          _connectionStatus = '⚠️ Respuesta inesperada: ${response.statusCode}';
        }
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug de Red'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Configuración de Red',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('URL Base: ${ApiConfig.baseUrl}'),
                    Text('Plataforma: ${Platform.operatingSystem}'),
                    Text('Es Emulador: ${_debugInfo?['isEmulator'] ?? 'Cargando...'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Prueba de Conexión',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Estado: $_connectionStatus'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testConnection,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Probar Conexión'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_debugInfo != null) ...<Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Información de Debug',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('IP Local: ${_debugInfo!['localIP']}'),
                      Text('IP Emulador: ${_debugInfo!['emulatorIP']}'),
                      const SizedBox(height: 8),
                      const Text(
                        'Variables de Entorno:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ..._debugInfo!['environment'].entries.take(5).map<Widget>((entry) =>
                          Text('${entry.key}: ${entry.value}')
                      ).toList(),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ℹ️ Información',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Emulador: Usa 10.0.2.2 (localhost del host)\n'
                    '• Dispositivo físico: Usa 192.168.0.48 (IP de tu PC)\n'
                    '• Si la conexión falla, verifica que el backend esté corriendo',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}