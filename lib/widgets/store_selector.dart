import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/current_store_controller.dart';
import '../utils/utils.dart';

class StoreSelector extends StatelessWidget {
  final bool showFullName;
  final bool showInDrawer;
  
  const StoreSelector({
    Key? key,
    this.showFullName = true,
    this.showInDrawer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<CurrentStoreController>();
      
      if (controller.currentStore == null) {
        return showInDrawer ? _buildDrawerItem(
          icon: Icons.store_outlined,
          title: 'Sin tienda',
          subtitle: 'No asignada',
          onTap: null,
        ) : _buildAppBarItem(
          icon: Icons.store_outlined,
          text: 'Sin tienda',
          onTap: null,
        );
      }

      final store = controller.currentStore!;
      
      if (showInDrawer) {
        return _buildDrawerItem(
          icon: Icons.store,
          title: showFullName ? store.name : store.code,
          subtitle: controller.canSwitchStores ? 'Toca para cambiar' : 'Tienda asignada',
          onTap: controller.canSwitchStores ? () {
            print('DEBUG: Presionado selector de tienda en drawer');
            print('DEBUG: canSwitchStores = ${controller.canSwitchStores}');
            controller.showStoreSelector();
          } : null,
        );
      } else {
        return _buildAppBarItem(
          icon: Icons.store,
          text: showFullName ? store.name : store.code,
          onTap: controller.canSwitchStores ? () => controller.showStoreSelector() : null,
        );
      }
    });
  }

  Widget _buildAppBarItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Utils.colorGnav,
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Utils.colorGnav,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: onTap != null 
        ? Icon(
            Icons.keyboard_arrow_right,
            color: Utils.colorGnav,
          )
        : null,
      onTap: onTap,
      dense: true,
    );
  }
}

class StoreIndicator extends StatelessWidget {
  final double? size;
  
  const StoreIndicator({Key? key, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CurrentStoreController>(
      builder: (controller) {
        if (controller.currentStore == null) {
          return Container(
            width: size ?? 40,
            height: size ?? 40,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.store_outlined,
              color: Colors.grey,
              size: (size ?? 40) * 0.5,
            ),
          );
        }

        final store = controller.currentStore!;
        
        return Container(
          width: size ?? 40,
          height: size ?? 40,
          decoration: BoxDecoration(
            color: Utils.colorGnav,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              store.code,
              style: TextStyle(
                color: Colors.white,
                fontSize: (size ?? 40) * 0.25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

class StoreInfoCard extends StatelessWidget {
  const StoreInfoCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CurrentStoreController>(
      builder: (controller) {
        if (controller.currentStore == null) {
          return Card(
            color: Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sin tienda asignada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        Text(
                          'Contacta al administrador para asignar una tienda',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
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

        final store = controller.currentStore!;
        
        return Card(
          color: Utils.colorGnav.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                StoreIndicator(size: 48),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Utils.colorGnav,
                          fontSize: 16,
                        ),
                      ),
                      if (store.address.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          store.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (controller.canSwitchStores) ...[
                        SizedBox(height: 8),
                        Text(
                          'Toca para cambiar de tienda',
                          style: TextStyle(
                            fontSize: 11,
                            color: Utils.colorGnav,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (controller.canSwitchStores)
                  Icon(
                    Icons.keyboard_arrow_right,
                    color: Utils.colorGnav,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}