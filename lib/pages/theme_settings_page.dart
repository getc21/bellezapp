import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../config/theme_config.dart';
import '../utils/utils.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración de Temas'),
        elevation: 0,
      ),
      body: Obx(() {
        if (!themeController.isInitialized) {
          return Center(child: Utils.loadingCustom());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de modo de tema
              _buildSectionTitle('Modo de Visualización'),
              Utils.espacio10,
              _buildThemeModeSelector(themeController),
              
              Utils.espacio30,
              
              // Sección de temas disponibles
              _buildSectionTitle('Temas Disponibles'),
              Utils.espacio10,
              Text(
                'Selecciona tu tema favorito para personalizar la apariencia de la aplicación',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              Utils.espacio20,
              
              // Grid de temas
              _buildThemeGrid(themeController),
              
              Utils.espacio30,
              
              // Botón de reset
              _buildResetButton(themeController),
              
              Utils.espacio20,
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Get.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Utils.defaultColor,
      ),
    );
  }

  Widget _buildThemeModeSelector(ThemeController themeController) {
    return Card(
      elevation: 2,
      color: Utils.colorFondoCards,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildThemeModeOption(
              themeController,
              ThemeMode.light,
              'Modo Claro',
              'Siempre usar tema claro',
              Icons.light_mode,
            ),
            Divider(color: Utils.colorGnav.withValues(alpha: 0.3)),
            _buildThemeModeOption(
              themeController,
              ThemeMode.dark,
              'Modo Oscuro',
              'Siempre usar tema oscuro',
              Icons.dark_mode,
            ),
            Divider(color: Utils.colorGnav.withValues(alpha: 0.3)),
            _buildThemeModeOption(
              themeController,
              ThemeMode.system,
              'Automático',
              'Seguir configuración del sistema',
              Icons.auto_mode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(
    ThemeController themeController,
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = themeController.isCurrentThemeMode(mode);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Utils.colorBotones : Utils.defaultColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Utils.colorBotones : Utils.defaultColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Utils.defaultColor.withValues(alpha: 0.7),
        ),
      ),
      trailing: GestureDetector(
        onTap: () => themeController.changeThemeMode(mode),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeController.themeMode == mode 
                ? Utils.colorBotones 
                : Colors.transparent,
            border: Border.all(
              color: themeController.themeMode == mode 
                  ? Utils.colorBotones 
                  : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: themeController.themeMode == mode
              ? Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
      ),
      onTap: () => themeController.changeThemeMode(mode),
    );
  }

  Widget _buildThemeGrid(ThemeController themeController) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: themeController.availableThemes.length,
      itemBuilder: (context, index) {
        final theme = themeController.availableThemes[index];
        final isSelected = themeController.isCurrentTheme(theme.id);
        
        return _buildThemeCard(theme, isSelected, themeController);
      },
    );
  }

  Widget _buildThemeCard(AppTheme theme, bool isSelected, ThemeController themeController) {
    return GestureDetector(
      onTap: () => themeController.changeTheme(theme.id),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Card(
          elevation: isSelected ? 8 : 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Preview del tema
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withValues(alpha: 0.8),
                        theme.accentColor.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Simulación de AppBar
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Simulación de Cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Información del tema
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              theme.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected ? theme.primaryColor : Utils.defaultColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: theme.primaryColor,
                              size: 20,
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          theme.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Utils.defaultColor.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(ThemeController themeController) {
    return SizedBox(
      width: double.infinity,
      child: Utils.elevatedButtonWithIcon(
        'Restablecer Tema',
        Utils.no,
        () => _showResetDialog(themeController),
        Icons.refresh,
      ),
    );
  }

  void _showResetDialog(ThemeController themeController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text(
          'Restablecer Tema',
          style: TextStyle(color: Utils.defaultColor),
        ),
        content: Text(
          '¿Estás seguro de que deseas restablecer el tema a la configuración por defecto?',
          style: TextStyle(color: Utils.defaultColor),
        ),
        actions: [
          Utils.elevatedButton('Cancelar', Utils.edit, () {
            Get.back();
          }),
          Utils.elevatedButton('Restablecer', Utils.yes, () {
            themeController.resetTheme();
            Get.back();
          }),
        ],
      ),
    );
  }
}