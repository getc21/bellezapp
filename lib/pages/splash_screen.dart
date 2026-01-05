import 'package:flutter/material.dart';
import 'package:bellezapp/utils/utils.dart';

/// 🎨 Splash Screen - Pantalla de carga personalizada
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo con sombra elegante
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Utils.colorBotones.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/img/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),

            // Marca/Nombre
            Image.asset(
              'assets/img/NOMBRE.png',
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 48),

            // Loading animado
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Utils.colorBotones),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),

            // Texto de carga
            Text(
              'Cargando...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
