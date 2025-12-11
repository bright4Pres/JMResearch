import 'package:flutter/material.dart';
import '../../services/vendor_kitchen_service.dart';

class AddItemScreen extends StatefulWidget {
  final Kitchen kitchen;
  final String category;
  final String categoryDisplayName;
  final KitchenItem? editingItem;

  const AddItemScreen({
    Key? key,
    required this.kitchen,
    required this.category,
    required this.categoryDisplayName,
    this.editingItem,
  }) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final VendorKitchenService _vendorService = VendorKitchenService();
  bool _isLoading = false;

  bool get _isEditing => widget.editingItem != null;

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      _nameController.text = widget.editingItem!.name;
      _descriptionController.text = widget.editingItem!.description;
      _priceController.text = widget.editingItem!.price.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 236, 191),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing
                  ? 'Edit ${widget.categoryDisplayName} Item'
                  : 'Add ${widget.categoryDisplayName} Item',
              style: const TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'in ${widget.kitchen.name}',
              style: TextStyle(color: Colors.deepOrange[400], fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // item field @ add item section
              _buildTextField(
                controller: _nameController,
                label: 'Item Name',
                hint: 'Enter item name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // description fielfd
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter item description',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // same shit, but price
              _buildTextField(
                controller: _priceController,
                label: 'Price (₱)',
                hint: 'Enter price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Update Item' : 'Add Item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helper function to build text fields, avoids repetitive building functions
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.parse(_priceController.text);

      if (!mounted) return;

      final item = KitchenItem(
        id: widget.editingItem?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: widget.category,
        kitchenId: widget.kitchen.id,
        ownerId: widget.kitchen.ownerId,
        createdAt: widget.editingItem?.createdAt ?? DateTime.now(),
      );

      final success = _isEditing
          ? await _vendorService.updateKitchenItem(
              widget.editingItem!.id,
              item.toMap(),
            )
          : await _vendorService.addKitchenItem(item);

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          _isEditing
              ? 'Item updated successfully!'
              : 'Item added successfully!',
          Colors.green,
        );
        Navigator.of(context).pop();
      } else {
        throw Exception(
          _isEditing ? 'Failed to update item' : 'Failed to add item',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
