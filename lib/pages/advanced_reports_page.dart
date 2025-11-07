import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../controllers/store_controller.dart';
import '../utils/utils.dart';
import '../widgets/store_aware_app_bar.dart';
import 'inventory_rotation_page.dart';
import 'profitability_analysis_page.dart';
import 'sales_trends_page.dart';
import 'periods_comparison_page.dart';

class AdvancedReportsPage extends StatefulWidget {
  const AdvancedReportsPage({super.key});

  @override
  State<AdvancedReportsPage> createState() => _AdvancedReportsPageState();
}

class _AdvancedReportsPageState extends State<AdvancedReportsPage> {
  late ReportsController reportsController;
  late StoreController storeController;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores
    try {
      reportsController = Get.find<ReportsController>();
    } catch (e) {
      reportsController = Get.put(ReportsController());
    }
    
    try {
      storeController = Get.find<StoreController>();
    } catch (e) {
      storeController = Get.put(StoreController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: StoreAwareAppBar(
        title: 'Reportes Avanzados',
        icon: Icons.analytics,
        subtitle: 'Análisis financiero y operativo',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mensaje informativo
            _buildInfoCard(),
            const SizedBox(height: 20),
            
            // Grid de opciones de reportes
            _buildReportsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Utils.colorBotones.withValues(alpha: 0.8),
            Utils.colorBotones,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Utils.colorBotones.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Análisis Empresarial',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final storeName = storeController.currentStore?['name'] ?? 'Sin tienda';
            return Text(
              'Reportes para: $storeName',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Accede a análisis detallados de tu negocio',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                title: 'Rotación de Inventario',
                subtitle: 'Análisis de movimiento de productos',
                icon: Icons.rotate_right,
                color: Colors.blue,
                onTap: () => Get.to(() => const InventoryRotationPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportCard(
                title: 'Análisis de Rentabilidad',
                subtitle: 'Rentabilidad por producto',
                icon: Icons.trending_up,
                color: Colors.green,
                onTap: () => Get.to(() => const ProfitabilityAnalysisPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                title: 'Tendencias de Ventas',
                subtitle: 'Análisis temporal de ventas',
                icon: Icons.show_chart,
                color: Colors.orange,
                onTap: () => Get.to(() => const SalesTrendsPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportCard(
                title: 'Comparación de Períodos',
                subtitle: 'Comparativo entre períodos',
                icon: Icons.compare_arrows,
                color: Colors.purple,
                onTap: () => Get.to(() => const PeriodsComparisonPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con ícono
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Contenido
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Textos
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    
                    // Botón de acción
                    Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ver Reporte',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}