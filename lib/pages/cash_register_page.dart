import 'package:bellezapp/controllers/cash_controller.dart';
import 'package:bellezapp/pages/cash_movements_page.dart';
import 'package:bellezapp/pages/daily_cash_report_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CashRegisterPage extends StatefulWidget {
  const CashRegisterPage({super.key});

  @override
  CashRegisterPageState createState() => CashRegisterPageState();
}

class CashRegisterPageState extends State<CashRegisterPage> {
  late CashController cashController;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador de forma segura
    try {
      cashController = Get.find<CashController>();
    } catch (e) {
      print('Error al encontrar CashController: $e');
      // Si no existe, intentar crearlo
      cashController = Get.put(CashController(), permanent: true);
    }
    
    // Cargar datos cuando se abre la página
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await cashController.initialize();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        title: Text('Sistema de Caja'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => cashController.refresh(),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Get.to(() => DailyCashReportPage());
            },
            tooltip: 'Dashboard y Reportes',
          ),
        ],
      ),
      body: Obx(() {
        if (cashController.isLoading) {
          return Center(child: Utils.loadingCustom());
        }

        return RefreshIndicator(
          onRefresh: () => cashController.refresh(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado de la caja
                _buildCashStatusCard(),
                SizedBox(height: 16),
                
                // Resumen del día
                _buildDailySummaryCard(),
                SizedBox(height: 16),
                
                // Acciones principales
                _buildMainActionsCard(),
                SizedBox(height: 16),
                
                // Movimientos recientes
                _buildRecentMovementsCard(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Card del estado de la caja
  Widget _buildCashStatusCard() {
    return Card(
      elevation: 4,
      color: Utils.colorFondoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Icono y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cashController.isCashRegisterOpen 
                        ? Colors.green 
                        : cashController.isCashRegisterClosed 
                            ? Colors.orange 
                            : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cashController.isCashRegisterOpen 
                        ? Icons.lock_open 
                        : Icons.lock,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de la Caja',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Utils.colorTexto,
                      ),
                    ),
                    Text(
                      cashController.isCashRegisterOpen 
                          ? 'ABIERTA' 
                          : cashController.isCashRegisterClosed 
                              ? 'CERRADA' 
                              : 'SIN ABRIR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cashController.isCashRegisterOpen 
                            ? Colors.green 
                            : cashController.isCashRegisterClosed 
                                ? Colors.orange 
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Información adicional si la caja está abierta
            if (cashController.isCashRegisterOpen) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hora de apertura',
                        style: TextStyle(
                          fontSize: 14,
                          color: Utils.colorTexto.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        cashController.currentCashRegister?.formattedOpeningTime ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Utils.colorTexto,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Monto inicial',
                        style: TextStyle(
                          fontSize: 14,
                          color: Utils.colorTexto.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        cashController.currentCashRegister?.formattedOpeningAmount ?? '\$0.00',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Utils.colorTexto,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card del resumen del día
  Widget _buildDailySummaryCard() {
    return Card(
      elevation: 4,
      color: Utils.colorFondoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Día',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Utils.colorTexto,
              ),
            ),
            SizedBox(height: 16),
            
            // Grid de métricas
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
                              childAspectRatio: 1.6, // Reducir altura para evitar overflow
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  'Dinero en Caja',
                  cashController.formatCurrency(cashController.totalCashInHand),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Ventas Efectivo',
                  cashController.formatCurrency(cashController.totalSalesToday),
                  Icons.point_of_sale,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Entradas',
                  cashController.formatCurrency(cashController.totalIncomesToday),
                  Icons.trending_up,
                  Colors.teal,
                ),
                _buildMetricCard(
                  'Salidas',
                  cashController.formatCurrency(cashController.totalOutcomesToday),
                  Icons.trending_down,
                  Colors.red,
                ),
              ],
            ),
            
            // Monto esperado
            if (cashController.isCashRegisterOpen) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Utils.colorBotones.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Utils.colorBotones.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monto Esperado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Utils.colorTexto,
                      ),
                    ),
                    Text(
                      cashController.formatCurrency(cashController.expectedAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card de métrica individual
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12), // Reducir padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Añadir para minimizar espacio
        children: [
          Icon(icon, color: color, size: 18), // Reducir más el tamaño del icono
          SizedBox(height: 4), // Reducir más el espaciado
          Flexible( // Usar Flexible para evitar overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: 9, // Reducir más el tamaño de fuente
                color: Utils.colorTexto.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Permitir 2 líneas
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 1), // Reducir más el espaciado
          Flexible( // Usar Flexible para evitar overflow
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11, // Reducir más el tamaño de fuente
                fontWeight: FontWeight.bold,
                color: Utils.colorTexto,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Card de acciones principales
  Widget _buildMainActionsCard() {
    return Card(
      elevation: 4,
      color: Utils.colorFondoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Utils.colorTexto,
              ),
            ),
            SizedBox(height: 16),
            
            // Botones de acción
            if (cashController.canOpenCashRegister) 
              _buildActionButton(
                'Abrir Caja',
                'Iniciar jornada con monto inicial',
                Icons.lock_open,
                Colors.green,
                () => _showOpenCashDialog(),
              )
            else if (cashController.canCloseCashRegister) ...[
              _buildActionButton(
                'Cerrar Caja',
                'Realizar arqueo y cerrar jornada',
                Icons.lock,
                Colors.orange,
                () => _showCloseCashDialog(),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryActionButton(
                      'Entrada',
                      Icons.add_circle,
                      Colors.teal,
                      () => _showAddIncomeDialog(),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryActionButton(
                      'Salida',
                      Icons.remove_circle,
                      Colors.red,
                      () => _showAddOutcomeDialog(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildActionButton(
                'Ver Movimientos',
                'Gestionar entradas y salidas',
                Icons.receipt_long,
                Utils.colorBotones,
                () {
                  Get.to(() => CashMovementsPage());
                },
              ),
            ] else
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Caja cerrada para hoy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'La jornada ya fue completada',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Botón de acción principal
  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Utils.colorTexto,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Utils.colorTexto.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // Botón de acción secundario
  Widget _buildSecondaryActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Utils.colorTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card de movimientos recientes
  Widget _buildRecentMovementsCard() {
    final recentMovements = cashController.todayMovements.take(5).toList();
    
    return Card(
      elevation: 4,
      color: Utils.colorFondoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movimientos Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorTexto,
                  ),
                ),
                if (cashController.todayMovements.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Get.to(() => CashMovementsPage());
                    },
                    child: Text('Ver todos'),
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            if (recentMovements.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Sin movimientos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: recentMovements.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final movement = recentMovements[index];
                  return _buildMovementItem(movement);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Item de movimiento
  Widget _buildMovementItem(movement) {
    Color color;
    IconData icon;
    
    switch (movement.type) {
      case 'apertura':
        color = Colors.blue;
        icon = Icons.lock_open;
        break;
      case 'cierre':
        color = Colors.orange;
        icon = Icons.lock;
        break;
      case 'venta':
        color = Colors.green;
        icon = Icons.point_of_sale;
        break;
      case 'entrada':
        color = Colors.teal;
        icon = Icons.trending_up;
        break;
      case 'salida':
        color = Colors.red;
        icon = Icons.trending_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.receipt;
    }

    final time = DateTime.parse(movement.date);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.typeDisplayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Utils.colorTexto,
                  ),
                ),
                Text(
                  movement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Utils.colorTexto.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                movement.formattedAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: movement.isOutcome ? Colors.red : Colors.green,
                ),
              ),
              Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Utils.colorTexto.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Diálogo para abrir caja
  void _showOpenCashDialog() {
    _amountController.clear();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('Abrir Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingrese el monto inicial en efectivo:'),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto inicial',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              if (amount != null && amount >= 0) {
                Get.back();
                cashController.openCashRegister(amount);
              } else {
                Get.snackbar('Error', 'Ingrese un monto válido');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Abrir Caja'),
          ),
        ],
      ),
    );
  }

  // Diálogo para cerrar caja
  void _showCloseCashDialog() {
    _amountController.clear();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('Cerrar Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Monto esperado: ${cashController.formatCurrency(cashController.expectedAmount)}'),
            SizedBox(height: 16),
            Text('Ingrese el monto real contado:'),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto real',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              if (amount != null && amount >= 0) {
                Get.back();
                cashController.closeCashRegister(amount);
              } else {
                Get.snackbar('Error', 'Ingrese un monto válido');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Cerrar Caja'),
          ),
        ],
      ),
    );
  }

  // Diálogo para entrada de dinero
  void _showAddIncomeDialog() {
    _amountController.clear();
    final descriptionController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('Entrada de Dinero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              descriptionController.dispose();
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              final description = descriptionController.text.trim();
              
              if (amount != null && amount > 0 && description.isNotEmpty) {
                Get.back();
                cashController.addCashIncome(amount, description);
                descriptionController.dispose();
              } else {
                Get.snackbar('Error', 'Complete todos los campos correctamente');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para salida de dinero
  void _showAddOutcomeDialog() {
    _amountController.clear();
    final descriptionController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('Salida de Dinero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dinero disponible: ${cashController.formatCurrency(cashController.totalCashInHand)}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              descriptionController.dispose();
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              final description = descriptionController.text.trim();
              
              if (amount != null && amount > 0 && description.isNotEmpty) {
                Get.back();
                cashController.addCashOutcome(amount, description);
                descriptionController.dispose();
              } else {
                Get.snackbar('Error', 'Complete todos los campos correctamente');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Registrar'),
          ),
        ],
      ),
    );
  }
}