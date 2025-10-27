# 🏪 Sistema Multi-Tienda - Guía de Implementación

## ✅ Cambios Implementados

### 1. **Base de Datos** ✓
- ✅ Tabla `stores` - Gestión de tiendas
- ✅ Tabla `roles` - Roles de usuario (admin, manager, employee)
- ✅ Tabla `user_store_assignments` - Asignación usuario-tienda
- ✅ Columna `store_id` agregada a `products` y `orders`
- ✅ Migración v9 -> v10 implementada

### 2. **Modelos** ✓
- ✅ `lib/models/store.dart` - Modelo de tienda
- ✅ `lib/models/role.dart` - Modelo de rol

### 3. **Servicios** ✓
- ✅ `lib/services/auth_service.dart` - Actualizado con soporte multi-tienda
  - Carga de tiendas asignadas
  - Cambio de tienda actual
  - Verificación de acceso a tiendas

### 4. **Controladores** ✓
- ✅ `lib/controllers/store_controller.dart` - Controlador GetX para tiendas
  - Gestión de tienda actual
  - CRUD de tiendas (solo admin)
  - Asignación/desasignación de usuarios

### 5. **Widgets** ✓
- ✅ `lib/widgets/store_selector.dart` - Selector de tienda para AppBar

### 6. **Database Helper** ✓
- ✅ Métodos CRUD para tiendas
- ✅ Métodos de asignación usuario-tienda
- ✅ Métodos de consulta con filtro por tienda

---

## 📋 Pasos para Completar la Integración

### **PASO 1: Inicializar StoreController en main.dart**

Agrega el StoreController a tu inicialización de GetX:

```dart
// En lib/main.dart
import 'package:bellezapp/controllers/store_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await AuthService.instance.initialize();
  
  // Registrar controladores
  Get.put(StoreController());
  Get.put(ThemeController());
  
  runApp(MyApp());
}
```

### **PASO 2: Agregar StoreSelector al AppBar**

En tu `home_page.dart` o donde tengas el AppBar principal:

```dart
import 'package:bellezapp/widgets/store_selector.dart';

AppBar(
  title: Text('BellezApp'),
  backgroundColor: Utils.colorGnav,
  actions: [
    StoreSelector(),  // ← Agregar aquí
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => Get.to(SettingsPage()),
    ),
  ],
)
```

### **PASO 3: Filtrar Datos por Tienda**

#### **Opción A: Modificar queries existentes**

En `database_helper.dart`, actualiza los métodos existentes para filtrar por tienda:

```dart
Future<List<Map<String, dynamic>>> getProducts({int? storeId}) async {
  final db = await database;
  final currentStoreId = storeId ?? _getCurrentStoreId();
  
  if (_isAdmin() && storeId == null) {
    // Admin sin filtro: ver todos los productos
    return await db.query('products');
  } else {
    // Filtrar por tienda
    return await db.query(
      'products',
      where: 'store_id = ?',
      whereArgs: [currentStoreId],
    );
  }
}

int _getCurrentStoreId() {
  try {
    return Get.find<StoreController>().currentStoreId ?? 1;
  } catch (e) {
    return 1; // Tienda por defecto
  }
}

bool _isAdmin() {
  try {
    return Get.find<StoreController>().isAdmin.value;
  } catch (e) {
    return false;
  }
}
```

#### **Opción B: Agregar store_id al insertar datos**

Al crear productos, órdenes, etc., agrega el store_id:

```dart
Future<void> insertProduct(Map<String, dynamic> product) async {
  final db = await database;
  
  // Agregar store_id actual si no se especifica
  if (!product.containsKey('store_id')) {
    product['store_id'] = _getCurrentStoreId();
  }
  
  await db.insert('products', product);
  // ... resto del código
}
```

### **PASO 4: Actualizar Controladores Existentes**

Si tienes controladores como `ProductController`, `SalesController`, etc., actualízalos:

```dart
class ProductController extends GetxController {
  final StoreController storeController = Get.find<StoreController>();
  
  @override
  void onInit() {
    super.onInit();
    loadProducts();
    
    // Escuchar cambios de tienda
    ever(storeController.currentStore, (_) => loadProducts());
  }
  
  Future<void> loadProducts() async {
    final storeId = storeController.currentStoreId;
    // Cargar productos filtrados por tienda
    final products = await dbHelper.getProducts(storeId: storeId);
    // ...
  }
}
```

### **PASO 5: Crear Página de Login (si no existe)**

```dart
// lib/pages/login_page.dart
class LoginPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(Icons.business, size: 80, color: Utils.colorGnav),
              SizedBox(height: 24),
              Text('BellezApp', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 48),
              
              // Username
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              
              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 24),
              
              // Login button
              ElevatedButton(
                onPressed: () async {
                  final result = await authService.login(
                    usernameController.text,
                    passwordController.text,
                  );
                  
                  if (result.success) {
                    Get.offAll(() => HomePage());
                  } else {
                    Get.snackbar('Error', result.message ?? 'Error al iniciar sesión');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorBotones,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### **PASO 6: Proteger Rutas con Autenticación**

En `main.dart`:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BellezApp',
      home: FutureBuilder<bool>(
        future: AuthService.instance.checkSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.data == true) {
            return HomePage();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
```

---

## 🔐 Credenciales por Defecto

```
Usuario: admin
Contraseña: admin123
Rol: Administrador
```

---

## 📊 Flujo de Trabajo

### **Para Administradores:**
1. Login → Ve todas las tiendas
2. Puede cambiar entre tiendas usando el selector
3. Puede crear nuevas tiendas
4. Puede asignar usuarios a tiendas
5. Ve datos de todas las tiendas (opcional: filtrar por tienda)

### **Para Gerentes/Empleados:**
1. Login → Ve solo sus tiendas asignadas
2. Solo puede trabajar en las tiendas asignadas
3. No puede crear tiendas ni asignar usuarios

---

## 🚀 Próximos Pasos Recomendados

1. **Crear página de gestión de tiendas** (`lib/pages/admin/store_management_page.dart`)
2. **Crear página de asignación de usuarios** (`lib/pages/admin/user_assignment_page.dart`)
3. **Implementar sincronización de datos** (si hay múltiples dispositivos)
4. **Agregar reportes comparativos** entre tiendas
5. **Implementar transferencias** de productos entre tiendas

---

## ⚠️ Consideraciones Importantes

1. **Migración de Datos**: Al actualizar la app, los datos existentes se asignarán automáticamente a la "Tienda Principal" (ID: 1)

2. **Performance**: Los filtros por tienda usan índices en la base de datos para mejor rendimiento

3. **Seguridad**: Los permisos se verifican tanto en el backend (database) como en el frontend (UI)

4. **Testing**: Prueba el flujo completo:
   - Login como admin
   - Crear nueva tienda
   - Crear usuario (manager/employee)
   - Asignar usuario a tienda
   - Login como ese usuario
   - Verificar que solo ve su tienda

---

## 📱 Ejemplo de Uso

```dart
// Obtener tienda actual
final storeController = Get.find<StoreController>();
final currentStore = storeController.currentStore.value;

// Verificar si es admin
if (storeController.isAdmin.value) {
  // Mostrar opciones de administración
}

// Cambiar tienda
await storeController.switchStore(newStore);

// Crear nueva tienda (solo admin)
await storeController.createStore(
  name: 'Sucursal Norte',
  address: 'Calle Principal 123',
  phone: '555-0123',
  email: 'norte@bellezapp.com',
);

// Asignar usuario a tienda
await storeController.assignUserToStore(userId, storeId);
```

---

## 🎉 ¡Listo para Multi-Tienda!

Tu aplicación ahora está preparada para gestionar múltiples tiendas con control de acceso basado en roles. Los cambios son compatibles con versiones anteriores y los datos existentes se migran automáticamente.

Para cualquier duda o problema, revisa los comentarios en el código o consulta la documentación de cada archivo.
