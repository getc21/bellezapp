import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/controllers/loading_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/controllers/cash_controller.dart';
import 'package:bellezapp/controllers/auth_controller.dart';
import 'package:bellezapp/pages/home_page.dart';
import 'package:bellezapp/pages/login_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar controladores en el orden correcto
  // AuthController debe ir primero porque otros controladores lo necesitan
  Get.put(AuthController());
  Get.put(StoreController());
  Get.put(ThemeController());
  Get.put(IndexPageController());
  Get.put(LoadingController());
  Get.put(CashController());
  
  runApp(const BeautyStoreApp());
}

class BeautyStoreApp extends StatefulWidget {
  const BeautyStoreApp({super.key});

  @override
  State<BeautyStoreApp> createState() => BeautyStoreAppState();
}

class BeautyStoreAppState extends State<BeautyStoreApp> {
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
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
          
        locale: const Locale('es', 'ES'), // Establecer el idioma predeterminado
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[
          Locale('en', ''), // Inglés
          Locale('es', ''), // Español
        ],
      );
    });
  }

  Widget _buildInitialScreen() {
    final ThemeController themeController = Get.find<ThemeController>();
    final AuthController authController = Get.find<AuthController>();
    
    if (!themeController.isInitialized) {
      return _buildLoadingScreen();
    }
    
    return Obx(() {
      if (authController.isLoading) {
        return _buildLoadingScreen();
      }
      
      if (authController.isLoggedIn) {
        return const HomePage();
      } else {
        return const LoginPage();
      }
    });
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Utils.colorFondo, // Color de fondo por defecto
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Utils.loadingCustom(),
            const SizedBox(height: 24),
            const Text(
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