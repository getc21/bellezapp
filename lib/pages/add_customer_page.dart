import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../models/customer.dart';

class AddCustomerPage extends StatefulWidget {
  final Customer? customer; // null para nuevo, con datos para editar

  const AddCustomerPage({super.key, this.customer});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final CustomerController controller = Get.find<CustomerController>();
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  
  final RxBool _isLoading = false.obs;
  bool _isSaved = false; // Nueva variable para evitar guardados múltiples
  
  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con datos existentes si se está editando
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _notesController = TextEditingController(text: widget.customer?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Agregar Cliente'),
        actions: [
          Obx(() => _isLoading.value
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () => _saveCustomer(),
                  child: Text(
                    'GUARDAR',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información básica
            _buildSectionCard(
              'Información Básica',
              Icons.person,
              [
                _buildTextField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _phoneController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El teléfono es requerido';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Información de contacto
            _buildSectionCard(
              'Información de Contacto',
              Icons.contact_mail,
              [
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (opcional)',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Ingresa un email válido';
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _addressController,
                  label: 'Dirección (opcional)',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Notas adicionales
            _buildSectionCard(
              'Notas Adicionales',
              Icons.note,
              [
                _buildTextField(
                  controller: _notesController,
                  label: 'Notas (opcional)',
                  icon: Icons.note_outlined,
                  maxLines: 3,
                  hint: 'Información adicional sobre el cliente...',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Obx(() => ElevatedButton(
                    onPressed: _isLoading.value ? null : () => _saveCustomer(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text(isEditing ? 'Actualizar' : 'Guardar'),
                  )),
                ),
              ],
            ),
            
            // Información adicional si está editando
            if (isEditing && widget.customer != null) ...[
              const SizedBox(height: 32),
              _buildCustomerStats(widget.customer!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildCustomerStats(Customer customer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas del Cliente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Gastado',
                    customer.totalSpentFormatted,
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Compras',
                    customer.totalOrders.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Cliente desde',
                    customer.customerSince,
                    Icons.calendar_today,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Última compra',
                    customer.lastPurchaseFormatted,
                    Icons.schedule,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevenir múltiples llamadas
    if (_isLoading.value || _isSaved) {
      return;
    }

    _isLoading.value = true;

    try {
      bool success;
      if (isEditing) {
        success = await controller.updateCustomer(
          id: widget.customer!.id!,
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text.trim().isEmpty ? null : _emailController.text,
          address: _addressController.text.trim().isEmpty ? null : _addressController.text,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
        );
      } else {
        success = await controller.addCustomer(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text.trim().isEmpty ? null : _emailController.text,
          address: _addressController.text.trim().isEmpty ? null : _addressController.text,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
        );
      }

      if (success) {
        _isSaved = true; // Marcar como guardado
        
        // Limpiar formulario para evitar múltiples envíos
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _addressController.clear();
        _notesController.clear();
        
        // Usar Navigator.pop en lugar de Get.back para compatibilidad
        Navigator.of(context).pop(true);
      } else {
        Get.snackbar(
          'Error',
          'No se pudo ${isEditing ? 'actualizar' : 'registrar'} el cliente',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Ocurrió un error inesperado: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}