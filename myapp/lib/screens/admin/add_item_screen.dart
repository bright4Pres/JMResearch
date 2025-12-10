import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/vendor_kitchen_service.dart';
import '../../services/image_service.dart';

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
  final ImageService _imageService = ImageService();

  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  bool get _isEditing => widget.editingItem != null;

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      _nameController.text = widget.editingItem!.name;
      _descriptionController.text = widget.editingItem!.description;
      _priceController.text = widget.editingItem!.price.toString();
      _existingImageUrl = widget.editingItem!.imageUrl;
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
              // Image Upload Section
              _buildImageUploadSection(),
              const SizedBox(height: 24),

              // Item Name
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

              // Description
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

              // Price
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

              // Submit Button
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

  Widget _buildImageUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Image',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Image Preview
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildImagePreview(),
          ),
          const SizedBox(height: 12),

          // Upload Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(false),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedImage != null || _existingImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Remove Image',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    } else if (_existingImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'No image selected',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap gallery or camera to add an image',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

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

  void _pickImage(bool fromCamera) async {
    final XFile? image = await _imageService.pickImage(fromCamera: fromCamera);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _existingImageUrl =
            null; // Clear existing image when new one is selected
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.parse(_priceController.text);
      String? imageUrl = _existingImageUrl;

      if (_selectedImage != null) {
        imageUrl = await _imageService.uploadImage(
          _selectedImage!,
          widget.category,
        );
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      if (!mounted) return;

      final item = KitchenItem(
        id: widget.editingItem?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        imageUrl: imageUrl,
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
