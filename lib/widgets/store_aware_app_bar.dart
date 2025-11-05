import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_controller.dart';
import '../utils/utils.dart';

class StoreAwareAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final IconData? icon;
  final bool showHelpButton;
  final String? helpContent;

  const StoreAwareAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.icon,
    this.showHelpButton = false,
    this.helpContent,
  });

  @override
  Widget build(BuildContext context) {
    final storeController = Get.find<StoreController>();
    
    return AppBar(
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? Utils.colorGnav,
              (backgroundColor ?? Utils.colorGnav).withOpacity(0.8),
            ],
          ),
        ),
      ),
      foregroundColor: foregroundColor ?? Colors.white,
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Obx(() {
              final currentStore = storeController.currentStore;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else
                    Text(
                      currentStore != null 
                        ? 'Sucursal: ${currentStore['name']}' 
                        : 'Cargando sucursal...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Utils.colorBotones),
              SizedBox(width: 8),
              Text('¿Qué significa la Rotación?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (helpContent != null) ...[
                  Text(helpContent!),
                  SizedBox(height: 16),
                ],
                _buildHelpSection(
                  '📊 Fórmula',
                  'Rotación = Unidades Vendidas ÷ Stock Actual',
                ),
                SizedBox(height: 12),
                _buildHelpSection(
                  '🔥 Alta (> 2.0)',
                  'Movimiento rápido - Considera aumentar stock',
                ),
                SizedBox(height: 8),
                _buildHelpSection(
                  '⚡ Media (0.5 - 2.0)',
                  'Movimiento normal - Stock adecuado',
                ),
                SizedBox(height: 8),
                _buildHelpSection(
                  '🐌 Baja (< 0.5)',
                  'Movimiento lento - Considera promocionar',
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '💡 Ejemplo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Stock: 89, Vendidas: 23\nRotación: 23 ÷ 89 = 0.26\n(Movimiento lento)',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}