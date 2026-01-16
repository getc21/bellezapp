# 🧪 GUÍA EJECUTABLE DE TESTING - BELLEZAPP

**Documento**: Testing Manual Paso a Paso  
**Fecha**: 16 de Enero, 2026  
**Objetivo**: Validar toda la funcionalidad de la app

---

## ✅ PRE-TESTING SETUP

### Paso 1: Instalar APK en Dispositivo
```bash
cd C:\Users\raque\OneDrive\Documentos\Proyectos\bellezapp
flutter build apk --debug

# Resultado esperado:
# √ Built build\app\outputs\flutter-apk\app-debug.apk
```

### Paso 2: Instalar en Dispositivo Real (MAR LX3A - Android 10)
```bash
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.example.bellezapp/.MainActivity
```

**Estado**: [ ] Completado

---

## 🔐 PRUEBA 1: AUTENTICACIÓN

### T-AUTH-001: Login Válido
**Precondición**: App abierta en splash screen  
**Datos de Prueba**:
- Usuario: `admin` (o usuario válido del backend)
- Contraseña: `password123` (o la correcta)

**Pasos**:
1. [ ] App carga splash screen
2. [ ] Navega a pantalla login automáticamente
3. [ ] Ingresar usuario en campo "Usuario"
4. [ ] Ingresar contraseña en campo "Contraseña"
5. [ ] Click botón "Iniciar Sesión"
6. [ ] Esperar respuesta del backend (~2 segundos)

**Resultado Esperado**:
- [ ] Token JWT recibido
- [ ] Redirige a dashboard/home page
- [ ] Muestra nombre de usuario en AppBar
- [ ] Sin errores en consola

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Notas**: ___________________________

---

### T-AUTH-002: Login Inválido
**Precondición**: En pantalla login  
**Datos de Prueba**:
- Usuario: `invalid_user`
- Contraseña: `wrong_password`

**Pasos**:
1. [ ] Ingresar credenciales inválidas
2. [ ] Click "Iniciar Sesión"
3. [ ] Observar respuesta

**Resultado Esperado**:
- [ ] Muestra snackbar rojo con "Credenciales inválidas"
- [ ] Permanece en pantalla login
- [ ] No navega a dashboard

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Notas**: ___________________________

---

### T-AUTH-003: Validación Campos Vacíos
**Precondición**: En pantalla login con campos vacíos  

**Pasos**:
1. [ ] Click botón login sin ingresar nada
2. [ ] Observar validaciones

**Resultado Esperado**:
- [ ] Campo usuario: "Campo requerido"
- [ ] Campo contraseña: "Campo requerido"
- [ ] No envía request al backend

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Notas**: ___________________________

---

### T-AUTH-004: Logout
**Precondición**: Usuario autenticado, en dashboard  

**Pasos**:
1. [ ] Click hamburger menu o avatar
2. [ ] Click "Cerrar Sesión"
3. [ ] Confirmar si hay diálogo

**Resultado Esperado**:
- [ ] Token borrado localmente
- [ ] Navega a pantalla login
- [ ] SharedPreferences limpio

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Notas**: ___________________________

---

## 👤 PRUEBA 2: GESTIÓN DE USUARIOS

### T-USER-001: Ver Lista de Usuarios
**Precondición**: Usuario admin autenticado  

**Pasos**:
1. [ ] Navegar a "Gestión de Usuarios" (menú/dashboard)
2. [ ] Esperar carga de datos (~1-2 segundos)

**Resultado Esperado**:
- [ ] Tabla/lista de usuarios visible
- [ ] Muestra: nombre, email, rol, estado
- [ ] Mínimo 3 usuarios en lista
- [ ] Sin errores

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Registros encontrados**: ______

---

### T-USER-002: Buscar Usuario
**Precondición**: En página gestión usuarios  

**Pasos**:
1. [ ] Click en campo de búsqueda "Buscar usuarios"
2. [ ] Ingresar nombre (ej: "Juan")
3. [ ] Observar filtrado en tiempo real

**Resultado Esperado**:
- [ ] Lista se filtra instantáneamente
- [ ] Solo muestra usuarios que contienen "Juan"
- [ ] Búsqueda case-insensitive
- [ ] También busca en email y username

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Notas**: ___________________________

---

### T-USER-003: Agregar Nuevo Usuario
**Precondición**: En página gestión usuarios  

**Pasos**:
1. [ ] Click botón "+" (FloatingActionButton)
2. [ ] Se abre dialog "Agregar Usuario"
3. [ ] Verificar que ocupa ~90% ancho pantalla
4. [ ] Ingresar datos:
   - Usuario: `test_user_001`
   - Email: `test@bellezapp.com`
   - Nombre: `Juan`
   - Apellido: `Pérez`
   - Contraseña: `Test123!`
   - Teléfono: `555-0123` (opcional)
   - Rol: `employee`
5. [ ] Click "Guardar"

**Resultado Esperado**:
- [ ] Dialog se cierra
- [ ] Nuevo usuario aparece en lista
- [ ] Muestra snackbar verde "Usuario creado"
- [ ] Backend retorna id del nuevo usuario
- [ ] Rol se muestra con color correcto

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Usuario ID creado**: ________________

---

### T-USER-004: Validación en Agregar Usuario
**Precondición**: Dialog agregar usuario abierto  

**Pasos**:
1. [ ] Dejar campos obligatorios vacíos
2. [ ] Click "Guardar"

**Resultado Esperado**:
- [ ] Cada campo muestra: "Campo requerido"
- [ ] Contraseña: "Mínimo 6 caracteres"
- [ ] No envía request

**Validaciones Correctas**:
- [ ] Usuario
- [ ] Email
- [ ] Nombre
- [ ] Apellido
- [ ] Contraseña
- [ ] Rol

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-USER-005: Ver Detalles Usuario
**Precondición**: Lista usuarios visible  

**Pasos**:
1. [ ] Click en cualquier usuario
2. [ ] Se abre dialog "Detalles de [Nombre]"

**Resultado Esperado**:
- [ ] Dialog ocupa ~90% ancho
- [ ] Muestra datos completos del usuario
- [ ] Formato: "Usuario:", "Email:", "Rol:", etc.
- [ ] Muestra fecha creación y último acceso
- [ ] Botones: "Cerrar", "Editar", "Eliminar"

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-USER-006: Editar Usuario
**Precondición**: Dialog detalles usuario abierto  

**Pasos**:
1. [ ] Click botón "Editar"
2. [ ] Se abre dialog "Editar Usuario"
3. [ ] Campos pre-rellenados con datos actuales
4. [ ] Cambiar: Email a `newemail@test.com`
5. [ ] Cambiar: Rol a `manager`
6. [ ] Click "Guardar"

**Resultado Esperado**:
- [ ] Dialog se cierra
- [ ] Lista se actualiza automáticamente
- [ ] Email y Rol actualizados
- [ ] Snackbar verde de confirmación
- [ ] Sin cambiar contraseña

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-USER-007: Eliminar Usuario
**Precondición**: Dialog detalles usuario (no admin actual)  

**Pasos**:
1. [ ] Click botón "Eliminar" (rojo)
2. [ ] Se abre AlertDialog de confirmación
3. [ ] Leer: "¿Estás seguro de que deseas eliminar..."
4. [ ] Click "Eliminar"

**Resultado Esperado**:
- [ ] Usuario removido de lista
- [ ] Snackbar de confirmación
- [ ] Backend retorna 200/204
- [ ] No se puede deshacer

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-USER-008: Dialog Anchura 90%
**Precondición**: Dialog abierto (cualquiera)  

**Pasos**:
1. [ ] Abrir dialog (agregar, detalles, editar)
2. [ ] Visualmente estimar ancho
3. [ ] En dispositivo Android 10 de ~6.2"
4. [ ] Debe ocupar ~90% del ancho

**Resultado Esperado**:
- [ ] Dialog no es demasiado estrecho
- [ ] Margen visible en los lados
- [ ] Contenido legible sin scroll horizontal

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-USER-009: Dialog Scrolleable
**Precondición**: Dialog agregar usuario abierto  

**Pasos**:
1. [ ] En pantalla pequeña (480x800)
2. [ ] Intentar scroll dentro del dialog
3. [ ] Scroll vertical debe funcionar

**Resultado Esperado**:
- [ ] Contenido scrolleable
- [ ] Botones siempre visibles al final
- [ ] Header siempre visible arriba

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-USER-010: Botones Sin Overflow
**Precondición**: Dialog detalles usuario con botones Edit/Delete  

**Pasos**:
1. [ ] Verificar visualmente los botones
2. [ ] En pantalla pequeña (<480 dp)

**Resultado Esperado**:
- [ ] Botones "Cerrar", "Eliminar", "Editar" visibles
- [ ] No hay RenderFlex overflow
- [ ] Si no caben, deben scrollear horizontalmente

**Resultado Actual**: [ ] PASS [ ] FAIL

---

## 📦 PRUEBA 3: PRODUCTOS

### T-PROD-001: Ver Lista Productos
**Precondición**: Usuario autenticado  

**Pasos**:
1. [ ] Navegar a "Productos"
2. [ ] Esperar carga

**Resultado Esperado**:
- [ ] Lista de productos visible
- [ ] Muestra: nombre, precio, categoría, estado
- [ ] Datos cargados del backend

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Productos encontrados**: ______

---

### T-PROD-002: Agregar Producto
**Precondición**: En página productos  

**Pasos**:
1. [ ] Click "+"
2. [ ] Se abre form agregar producto
3. [ ] Ingresar:
   - Nombre: `Producto Test`
   - Descripción: `Descripción de prueba`
   - Precio: `99.99`
   - Categoría: Seleccionar una
   - Imagen: Tomar foto o seleccionar galería
4. [ ] Esperar compresión de imagen
5. [ ] Click "Guardar"

**Resultado Esperado**:
- [ ] Snackbar "Comprimiendo imagen..."
- [ ] Reducción 70-75% (log en consola)
- [ ] Subida a Cloudinary exitosa
- [ ] Producto aparece en lista
- [ ] Imagen visible en thumbnail

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-PROD-003: Compresión Imagen
**Precondición**: Seleccionar imagen 4.5MB  

**Pasos**:
1. [ ] En consola, buscar log de compresión
2. [ ] Verificar: "Original: 4.5MB → Comprimido: ~1.2MB"

**Resultado Esperado**:
- [ ] Reducción mínimo 70%
- [ ] Máximo ancho/alto: 1200x1200
- [ ] Formato: JPEG
- [ ] Sin pérdida visual

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Tamaño original**: ____  
**Tamaño final**: ____  
**Reducción %**: ____

---

### T-PROD-004: Editar Producto
**Precondición**: Producto creado  

**Pasos**:
1. [ ] Click en producto de la lista
2. [ ] Click "Editar"
3. [ ] Cambiar nombre a `Producto Actualizado`
4. [ ] Click "Guardar"

**Resultado Esperado**:
- [ ] Nombre actualizado en lista
- [ ] Backend recibe cambios

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-PROD-005: Generar QR
**Precondición**: Producto visible  

**Pasos**:
1. [ ] Click botón QR
2. [ ] Se genera QR automáticamente
3. [ ] Muestra código QR grande

**Resultado Esperado**:
- [ ] QR visible y legible
- [ ] Contiene información del producto
- [ ] Se puede escanear

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-PROD-006: Descargar QR (Android 10)
**Precondición**: QR generado, MAR LX3A (Android 10)  

**Pasos**:
1. [ ] Click "Descargar"
2. [ ] Sistema solicita permiso "Acceso a almacenamiento"
3. [ ] [ ] Permitir permiso
4. [ ] Esperar notificación

**Resultado Esperado**:
- [ ] Aparece notificación "QR descargado"
- [ ] Archivo guardado en: `/storage/emulated/0/Android/data/com.example.bellezapp/files/Pictures/qr_*.png`
- [ ] Click notificación abre la imagen
- [ ] Sin crashes

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Permiso solicitado**: [ ] WRITE_EXTERNAL_STORAGE

---

### T-PROD-007: QR Notificación Click
**Precondición**: Notificación QR descargado visible  

**Pasos**:
1. [ ] Click en notificación "QR descargado"
2. [ ] Abre galería/image viewer

**Resultado Esperado**:
- [ ] Abre imagen QR guardada correctamente
- [ ] Ruta correcta (no busca en /Download/)
- [ ] Imagen legible

**Resultado Actual**: [ ] PASS [ ] FAIL

---

## 📊 PRUEBA 4: REPORTES

### T-REP-001: Cargar Página Reportes
**Precondición**: Usuario autenticado  

**Pasos**:
1. [ ] Navegar a cualquier página de reportes
2. [ ] Esperar carga de datos

**Resultado Esperado**:
- [ ] Datos cargados sin errores
- [ ] Gráficos renderizados
- [ ] Sin console errors

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-REP-002: Exportar a PDF
**Precondición**: En página reportes  

**Pasos**:
1. [ ] Click "Exportar PDF"
2. [ ] Esperar generación

**Resultado Esperado**:
- [ ] PDF generado sin errores
- [ ] Se abre automáticamente o descarga
- [ ] Contiene datos correctos

**Resultado Actual**: [ ] PASS [ ] FAIL

---

## 🎨 PRUEBA 5: INTERFAZ Y UX

### T-UI-001: Responsividad
**Precondición**: App abierta  

**Pasos**:
1. [ ] Rotar dispositivo horizontal
2. [ ] Observar layout

**Resultado Esperado**:
- [ ] Layout se adapta correctamente
- [ ] Elementos no se solapan
- [ ] Textos legibles

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-UI-002: Sin Overflows
**Precondición**: Todas las páginas  

**Pasos**:
1. [ ] Navegar por todas las páginas
2. [ ] Abrir todos los diálogos
3. [ ] Buscar errores de overflow en consola

**Resultado Esperado**:
- [ ] No hay "RenderFlex overflowed" errors
- [ ] No hay "bottom overflowed" warnings
- [ ] Layout limpio

**Resultado Actual**: [ ] PASS [ ] FAIL  
**Errores encontrados**: _______________

---

### T-UI-003: Navegación
**Precondición**: App abierta  

**Pasos**:
1. [ ] Click en cada item del menú
2. [ ] Navegar entre páginas
3. [ ] Usar back button

**Resultado Esperado**:
- [ ] Transiciones suaves
- [ ] Back button funciona
- [ ] Sin crashes
- [ ] Estado se mantiene

**Resultado Actual**: [ ] PASS [ ] FAIL

---

## 📈 PRUEBA 6: RENDIMIENTO

### T-PERF-001: Startup Time
**Precondición**: App instalada  

**Pasos**:
1. [ ] Cerrar app completamente
2. [ ] Medir tiempo desde tap a pantalla visible
3. [ ] Inicio con sesión preexistente

**Resultado Esperado**:
- [ ] Tiempo < 3 segundos
- [ ] Splash screen visible primero
- [ ] Autenticación automática

**Tiempo medido**: ____ segundos

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-PERF-002: Scroll FPS
**Precondición**: En lista con datos  

**Pasos**:
1. [ ] Activar "Show fps" en DevTools
2. [ ] Scroll rápido en lista usuarios
3. [ ] Observar FPS

**Resultado Esperado**:
- [ ] Mínimo 50 FPS
- [ ] Smooth scrolling
- [ ] Sin jank/stuttering

**FPS medido**: ____  
**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-PERF-003: Memoria
**Precondición**: App abierta  

**Pasos**:
1. [ ] Abrir DevTools Memory profiler
2. [ ] Navegar por varias páginas
3. [ ] Observar uso de RAM

**Resultado Esperado**:
- [ ] Reposo: < 100MB
- [ ] Carga pico: < 300MB
- [ ] Sin memory leaks

**Memoria usada**: ____ MB

**Resultado Actual**: [ ] PASS [ ] FAIL

---

## 🔒 PRUEBA 7: SEGURIDAD

### T-SEC-001: JWT Token
**Precondición**: Usuario autenticado  

**Pasos**:
1. [ ] En DevTools Network, ver header Authorization
2. [ ] Verificar formato `Bearer <token>`

**Resultado Esperado**:
- [ ] Token presente en todos los requests
- [ ] Formato correcto
- [ ] Token diferente por sesión

**Resultado Actual**: [ ] PASS [ ] FAIL

---

### T-SEC-002: Permisos Android
**Precondición**: Primera ejecución de QR download  

**Pasos**:
1. [ ] Descargar QR
2. [ ] Observar dialogo de permisos

**Resultado Esperado**:
- [ ] Solicita solo permisos necesarios
- [ ] Descripción clara del permiso
- [ ] Respeta selección del usuario

**Resultado Actual**: [ ] PASS [ ] FAIL

---

## 📝 RESUMEN FINAL

### Conteo de Pruebas
```
Total Pruebas Definidas: 40+
Pruebas Ejecutadas: ___
Pruebas Pasadas: ___
Pruebas Fallidas: ___
Tasa de Éxito: ___%
```

### Críticos Encontrados
```
[ ] 0 - Excelente
[ ] 1-2 - Aceptable
[ ] 3+ - Requiere rework
```

### Bloqueos Identificados
1. ___________________________________
2. ___________________________________
3. ___________________________________

### Observaciones Generales
_________________________________________________
_________________________________________________
_________________________________________________

### Firma Tester
Nombre: ____________________  
Fecha: 16/01/2026  
Hora: ________  

---

**Estado Final**: [ ] APTO PARA PRODUCCIÓN  
**Estado Final**: [ ] REQUIERE FIXES  
**Estado Final**: [ ] RETEST NECESARIO  

