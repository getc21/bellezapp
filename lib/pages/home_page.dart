import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/controllers/loading_controller.dart';
import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/controllers/auth_controller.dart';
import 'package:bellezapp/pages/cash_register_page.dart';
import 'package:bellezapp/pages/category_list_page.dart';
import 'package:bellezapp/pages/customer_list_page.dart';
import 'package:bellezapp/pages/discount_list_page.dart';
import 'package:bellezapp/pages/financial_report_page.dart';
import 'package:bellezapp/pages/location_list_page.dart';
import 'package:bellezapp/pages/order_list_page.dart';
import 'package:bellezapp/pages/product_list_page.dart';
import 'package:bellezapp/pages/report_page.dart';
import 'package:bellezapp/pages/sales_history_page.dart';
import 'package:bellezapp/pages/supplier_list_page.dart';
import 'package:bellezapp/pages/theme_settings_page.dart';
import 'package:bellezapp/pages/user_management_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ipc = Get.find<IndexPageController>();
  final loadingC = Get.find<LoadingController>();
  final themeController = Get.find<ThemeController>();
  final authController = Get.find<AuthController>();
  
  // Función para mostrar confirmación de salida
  Future<bool> _showExitConfirmation() async {
    final bool shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Utils.colorFondoCards,
            title: Text('¿Desea salir de la aplicación?'),
            content: Text('Presione Confirmar para salir'),
            actions: [
              Utils.elevatedButton('Cancelar', Utils.no, () {
                Navigator.pop(context, false);
              }),
              Utils.elevatedButton('Confirmar', Utils.yes, () {
                Navigator.pop(context, true);
              }),
            ],
          ),
        ) ??
        false;
    return shouldExit;
  }
  
  // Función para mostrar confirmación de logout
  Future<void> _showLogoutConfirmation() async {
    final bool shouldLogout = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Utils.colorFondoCards,
            title: Text('¿Desea cerrar sesión?'),
            content: Text('Presione Confirmar para cerrar sesión'),
            actions: [
              Utils.elevatedButton('Cancelar', Utils.no, () {
                Navigator.pop(context, false);
              }),
              Utils.elevatedButton('Confirmar', Utils.yes, () {
                Navigator.pop(context, true);
              }),
            ],
          ),
        ) ??
        false;
    
    if (shouldLogout) {
      await authController.logout();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    List<Widget> widgetOptions = <Widget>[
      ProductListPage(),
      CategoryListPage(),
      SupplierListPage(),
      LocationListPage(),
      OrderListPage()
    ];
    
    return Obx(() => PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _showExitConfirmation();
        if (shouldPop) {
          exit(0);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Utils.colorGnav,
                  Utils.colorBotones,
                ],
              ),
            ),
          ),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BellezApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Control de Almacenes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Botón de notificaciones
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      // TODO: Mostrar notificaciones
                    },
                    tooltip: 'Notificaciones',
                  ),
                  // Badge de notificaciones
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Botón de configuración de temas
            Container(
              margin: EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  Get.to(() => ThemeSettingsPage());
                },
                tooltip: 'Configurar Temas',
              ),
            ),
            // Botón del drawer de estadísticas
            Builder(
              builder: (context) {
                return Container(
                  margin: EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    tooltip: 'Panel de Control',
                  ),
                );
              },
            ),
          ],
        ),
        endDrawer: Container(
          width: 320,
          child: Drawer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Utils.colorGnav.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Header del drawer
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Utils.colorGnav,
                          Utils.colorBotones,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.analytics_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Panel de Control',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Gestión y Estadísticas',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Contenido del drawer
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        // Sección de Gestión Principal
                        _buildSectionHeader('Gestión Principal'),
                        _buildModernDrawerTile(
                          'Sistema de Caja',
                          'Control de ventas y pagos',
                          Icons.account_balance_wallet_outlined,
                          Colors.green,
                          () {
                            Navigator.pop(context);
                            Get.to(() => CashRegisterPage());
                          },
                        ),
                        _buildModernDrawerTile(
                          'Clientes',
                          'Gestión de clientes',
                          Icons.people_outline,
                          Colors.blue,
                          () {
                            Navigator.pop(context);
                            Get.to(() => CustomerListPage());
                          },
                        ),
                        if (authController.canManageUsers())
                          _buildModernDrawerTile(
                            'Gestión de Usuarios',
                            'Administrar usuarios del sistema',
                            Icons.admin_panel_settings_outlined,
                            Colors.purple,
                            () {
                              Navigator.pop(context);
                              Get.to(() => UserManagementPage());
                            },
                          ),
                        _buildModernDrawerTile(
                          'Descuentos',
                          'Configurar promociones',
                          Icons.local_offer_outlined,
                          Colors.orange,
                          () {
                            Navigator.pop(context);
                            Get.to(() => DiscountListPage());
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Sección de Reportes
                        _buildSectionHeader('Reportes y Análisis'),
                        _buildModernDrawerTile(
                          'Rotación de Productos',
                          'Análisis de movimiento de inventario',
                          Icons.insert_chart_outlined,
                          Colors.indigo,
                          () {
                            Navigator.pop(context);
                            Get.to(ReportPage());
                          },
                        ),
                        _buildModernDrawerTile(
                          'Reporte de Ventas',
                          'Historial y estadísticas de ventas',
                          Icons.trending_up_outlined,
                          Colors.green,
                          () {
                            Navigator.pop(context);
                            Get.to(SalesHistoryPage());
                          },
                        ),
                        _buildModernDrawerTile(
                          'Reporte Financiero',
                          'Análisis financiero completo',
                          Icons.monetization_on_outlined,
                          Colors.teal,
                          () {
                            Navigator.pop(context);
                            Get.to(FinancialReportPage());
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Sección de Usuario
                        _buildSectionHeader('Mi Cuenta'),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Utils.colorGnav.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Utils.colorGnav.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Utils.colorGnav,
                                child: Text(
                                  authController.currentUser?.initials ?? 'U',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authController.currentUser?.fullName ?? 'Usuario',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Utils.colorTexto,
                                      ),
                                    ),
                                    Text(
                                      authController.currentUser?.role.displayName ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Utils.colorTexto.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        _buildModernDrawerTile(
                          'Configurar Temas',
                          'Personalizar apariencia',
                          Icons.palette_outlined,
                          Colors.pink,
                          () {
                            Navigator.pop(context);
                            Get.to(() => ThemeSettingsPage());
                          },
                        ),
                        
                        _buildModernDrawerTile(
                          'Cerrar Sesión',
                          'Salir del sistema',
                          Icons.logout_outlined,
                          Colors.red,
                          () async {
                            Navigator.pop(context);
                            await _showLogoutConfirmation();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: widgetOptions.elementAt(ipc.getIndexPage),
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Utils.colorGnav.withOpacity(0.95),
                  Utils.colorGnav,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: GNav(
                backgroundColor: Colors.transparent,
                rippleColor: Colors.white.withOpacity(0.1),
                hoverColor: Colors.white.withOpacity(0.05),
                haptic: true,
                tabBorderRadius: 12,
                tabActiveBorder: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                curve: Curves.easeOutExpo,
                duration: Duration(milliseconds: 300),
                gap: 6,
                color: Colors.white.withOpacity(0.7),
                activeColor: Colors.white,
                iconSize: 20,
                textStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                tabBackgroundColor: Colors.white.withOpacity(0.15),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                tabs: [
                  GButton(
                    icon: Icons.inventory_2_outlined,
                    text: 'Productos',
                  ),
                  GButton(
                    icon: Icons.category_outlined,
                    text: 'Categorías',
                  ),
                  GButton(
                    icon: Icons.business_outlined,
                    text: 'Proveedores',
                  ),
                  GButton(
                    icon: Icons.location_on_outlined,
                    text: 'Ubicaciones',
                  ),
                  GButton(
                    icon: Icons.receipt_long_outlined,
                    text: 'Órdenes',
                  ),
                ],
                selectedIndex: ipc.getIndexPage,
                onTabChange: (index) {
                  ipc.setIndexPage(index);
                },
              ),
            ),
          ),
        ),
      ),
    )); // Cerrar Obx
  }

  // Métodos auxiliares para el drawer moderno
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Utils.colorTexto.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModernDrawerTile(String title, String subtitle, IconData icon, Color iconColor, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Utils.colorGnav.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Utils.colorTexto,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Utils.colorTexto.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Utils.colorTexto.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
