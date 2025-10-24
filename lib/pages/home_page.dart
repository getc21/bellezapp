import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/controllers/loading_controller.dart';
import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/controllers/auth_controller.dart';
import 'package:bellezapp/controllers/current_store_controller.dart';
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
import 'package:bellezapp/pages/store_list_page.dart';
import 'package:bellezapp/widgets/store_selector.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ipc = Get.find<IndexPageController>();
  final loadingC = Get.find<LoadingController>();
  final themeController = Get.find<ThemeController>();
  final authController = Get.find<AuthController>();
  final currentStoreController = Get.find<CurrentStoreController>();
  
  // Función para mostrar información de la tienda actual
  void _showStoreInfo() {
    final currentStore = currentStoreController.currentStore;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Row(
          children: [
            Icon(Icons.store, color: Utils.colorGnav),
            SizedBox(width: 8),
            Text('Información de Tienda'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentStore != null) ...[
              Text('Nombre: ${currentStore.name}'),
              if (currentStore.address.isNotEmpty)
                Text('Dirección: ${currentStore.address}'),
              if (currentStore.phone?.isNotEmpty == true)
                Text('Teléfono: ${currentStore.phone}'),
              SizedBox(height: 16),
              if (authController.currentUser?.role == 'admin')
                Text(
                  'Como administrador, puedes cambiar de tienda desde el menú lateral.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ] else ...[
              Text(
                'No hay tienda seleccionada actualmente.',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Estado del sistema:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Usuario: ${authController.currentUser?.fullName ?? 'Desconocido'}'),
              Text('Rol: ${authController.currentUser?.role ?? 'Desconocido'}'),
              Text('Tiendas disponibles: ${currentStoreController.availableStores.length}'),
              SizedBox(height: 16),
              if (authController.currentUser?.role == 'admin')
                Text(
                  'Ve al menú lateral para seleccionar una tienda.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
            ],
          ],
        ),
        actions: [
          Utils.elevatedButton('Cerrar', Utils.no, () {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
  
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
          foregroundColor: Colors.white,
          backgroundColor: Utils.colorGnav,
          title: Row(
            children: [
              // Ícono de tienda al lado izquierdo del título
              Obx(() {
                final currentStore = currentStoreController.currentStore;
                final hasStore = currentStore != null;
                
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.store, 
                        color: hasStore ? Colors.white : Colors.orange[300],
                      ),
                      onPressed: () => _showStoreInfo(),
                      tooltip: currentStore?.name ?? 'Sin tienda seleccionada - Toca para más info',
                    ),
                    if (!hasStore)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              }),
              SizedBox(width: 8),
              Text('Control de Almacenes'),
              Spacer(),
            ],
          ),
          centerTitle: false,
          actions: [
            // Botón de configuración de temas
            IconButton(
              icon: Icon(Icons.palette_outlined),
              onPressed: () {
                Get.to(() => ThemeSettingsPage());
              },
              tooltip: 'Configurar Temas',
            ),
            Builder(
              builder: (context) {
                return IconButton(
                  icon: Icon(Icons.bar_chart),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  tooltip: 'Estadísticas',
                );
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Utils.colorGnav,
                ),
                child: Text(
                  'Estadísticas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              // Información de tienda actual
              Container(
                color: Colors.grey[50],
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: StoreSelector(showInDrawer: true),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.account_balance_wallet),
                title: Text('Sistema de Caja'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Get.to(() => CashRegisterPage());
                },
              ),
              ListTile(
                leading: Icon(Icons.people),
                title: Text('Clientes'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Get.to(() => CustomerListPage());
                },
              ),
              if (authController.canManageUsers())
                ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Gestión de Usuarios'),
                  onTap: () {
                    Navigator.pop(context); // Cierra el drawer
                    Get.to(() => UserManagementPage());
                  },
                ),
              if (authController.isAdmin)
                ListTile(
                  leading: Icon(Icons.store),
                  title: Text('Gestión de Tiendas'),
                  onTap: () {
                    Navigator.pop(context); // Cierra el drawer
                    Get.to(() => StoreListPage());
                  },
                ),
              ListTile(
                leading: Icon(Icons.local_offer),
                title: Text('Descuentos'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Get.to(() => DiscountListPage());
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_chart),
                title: Text('Reporte de Rotación de Productos'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Get.to(ReportPage());
                },
              ),
              ListTile(
                leading: Icon(Icons.monetization_on),
                title: Text('Reporte de ventas'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Get.to(SalesHistoryPage());
                },
              ),
              ListTile(
                leading: Icon(Icons.monetization_on),
                title: Text('Reporte financiero'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Get.to(FinancialReportPage());
                },
              ),
              Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: themeController.currentTheme.lightTheme.colorScheme.primary,
                  child: Text(
                    authController.currentUser?.initials ?? 'U',
                    style: TextStyle(
                      color: themeController.currentTheme.lightTheme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(authController.currentUser?.fullName ?? 'Usuario'),
                subtitle: Text(authController.currentUser?.role.displayName ?? ''),
                onTap: () {
                  // TODO: Ir a perfil de usuario
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Cerrar Sesión'),
                onTap: () async {
                  Navigator.pop(context); // Cierra el drawer primero
                  await _showLogoutConfirmation();
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.palette),
                title: Text('Configurar Temas'),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  Get.to(() => ThemeSettingsPage());
                },
              ),
            ],
          ),
        ),
        body: widgetOptions.elementAt(ipc.getIndexPage),
        bottomNavigationBar: SafeArea(
          child: Container(
            color: Utils.colorGnav,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: GNav(
                backgroundColor: Utils.colorGnav,
                color: Colors.white,
                activeColor: Colors.white,
                tabBackgroundColor: Utils.colorBotones,
                gap: 4,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                tabs: [
                  GButton(
                    icon: Icons.inventory,
                    text: 'Productos',
                  ),
                  GButton(
                    icon: Icons.category,
                    text: 'Categorías',
                  ),
                  GButton(
                    icon: Icons.local_shipping,
                    text: 'Proveedores',
                  ),
                  GButton(
                    icon: Icons.location_on,
                    text: 'Ubicaciones',
                  ),
                  GButton(
                    icon: Icons.receipt_long,
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
}
