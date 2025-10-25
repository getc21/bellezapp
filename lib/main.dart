import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/controllers/loading_controller.dart';
import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/controllers/cash_controller.dart';
import 'package:bellezapp/controllers/auth_controller.dart';
import 'package:bellezapp/pages/home_page.dart';
import 'package:bellezapp/pages/login_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/utils/admin_user_setup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar controladores
  Get.put(ThemeController());
  Get.put(IndexPageController());
  Get.put(LoadingController());
  Get.put(CashController()); // Cambiar de lazyPut a put directo
  Get.put(AuthController()); // Agregar controlador de autenticación
  
  // Verificar y crear usuario admin si no existe
  await AdminUserSetup.checkDatabaseIntegrity();
  
  runApp(BeautyStoreApp());
}

class BeautyStoreApp extends StatefulWidget {
  const BeautyStoreApp({super.key});

  @override
  State<BeautyStoreApp> createState() => BeautyStoreAppState();
}

class BeautyStoreAppState extends State<BeautyStoreApp> {
  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Control de Almacenes - Belleza',
        
        // Configuración de temas dinámicos
        theme: themeController.isInitialized 
          ? themeController.currentTheme.lightTheme 
          : ThemeData.light(),
        darkTheme: themeController.isInitialized 
          ? themeController.currentTheme.darkTheme 
          : ThemeData.dark(),
        themeMode: themeController.isInitialized 
          ? themeController.themeMode 
          : ThemeMode.system,
        
        home: _buildInitialScreen(),
          
        locale: Locale('es', 'ES'), // Establecer el idioma predeterminado
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', ''), // Inglés
          const Locale('es', ''), // Español
        ],
      );
    });
  }

  Widget _buildInitialScreen() {
    final themeController = Get.find<ThemeController>();
    final authController = Get.find<AuthController>();
    
    if (!themeController.isInitialized) {
      return _buildLoadingScreen();
    }
    
    return Obx(() {
      if (authController.isLoading) {
        return _buildLoadingScreen();
      }
      
      if (authController.isLoggedIn) {
        return HomePage();
      } else {
        return LoginPage();
      }
    });
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Color(0xFFF8BBD0), // Color de fondo por defecto
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Utils.loadingCustom(),
            SizedBox(height: 24),
            Text(
              'Cargando temas...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF616161),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}