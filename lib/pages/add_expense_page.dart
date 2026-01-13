import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/controllers/expense_controller.dart';
import 'package:bellezapp/utils/icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  AddExpensePageState createState() => AddExpensePageState();
}

class AddExpensePageState extends State<AddExpensePage> {
  final ipc = Get.find<IndexPageController>();
  final storeController = Get.find<StoreController>();
  final expenseController = Get.find<ExpenseController>();

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _newCategoryController;

  String? _selectedCategoryId;
  bool _isLoadingCategories = false;
  bool _isSubmitting = false;
  bool _showNewCategoryField = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _newCategoryController = TextEditingController();

    // Cargar categorías
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  void _loadCategories() async {
    final currentStore = storeController.currentStore;
    if (currentStore != null) {
      setState(() => _isLoadingCategories = true);
      await expenseController.loadCategories(storeId: currentStore['_id']);
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _submitForm() async {
    final currentStore = storeController.currentStore;

    if (_amountController.text.isEmpty || currentStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa los campos requeridos')),
      );
      return;
    }

    // Si está creando una nueva categoría
    if (_showNewCategoryField && _newCategoryController.text.isNotEmpty) {
      setState(() => _isSubmitting = true);
      final success = await expenseController.createCategory(
        storeId: currentStore['_id'],
        name: _newCategoryController.text,
      );

      if (success) {
        // Asignar la nueva categoría
        if (expenseController.categories.isNotEmpty) {
          _selectedCategoryId = expenseController.categories.last.id;
        }
      }
      setState(() => _isSubmitting = false);
    }

    try {
      setState(() => _isSubmitting = true);

      final success = await expenseController.createExpense(
        storeId: currentStore['_id'],
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar formulario
        _amountController.clear();
        _descriptionController.clear();
        _newCategoryController.clear();
        _selectedCategoryId = null;
        _showNewCategoryField = false;

        // Regresar a página anterior
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${expenseController.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Gasto'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monto
            Text(
              'Monto *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ingresa el monto',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Categoría
            Text(
              'Categoría',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin categoría'),
                      ),
                      ...expenseController.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  IconMapper.getIcon(category.icon),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              Text(category.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
            const SizedBox(height: 12),

            // Crear nueva categoría
            if (!_showNewCategoryField)
              TextButton.icon(
                onPressed: () {
                  setState(() => _showNewCategoryField = true);
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear nueva categoría'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _newCategoryController,
                    decoration: InputDecoration(
                      hintText: 'Nombre de la categoría',
                      prefixIcon: const Icon(Icons.label),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _showNewCategoryField = false);
                          _newCategoryController.clear();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La categoría se creará cuando registres el gasto',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Descripción
            Text(
              'Descripción',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Detalle del gasto (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrar Gasto'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }
}
