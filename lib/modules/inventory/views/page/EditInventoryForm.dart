import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Removed: image_picker, firebase_storage, dart:io imports
import 'package:workshop_management_system/domain/InventoryInfo.dart';
import 'package:workshop_management_system/provider/InventoryController.dart';
import 'package:workshop_management_system/routes/route.dart';

class EditInventoryPage extends StatefulWidget {
  final InventoryInfo item;  //Get the inventory item details to edit

  const EditInventoryPage({super.key, required this.item});

  @override
  _EditInventoryPageState createState() => _EditInventoryPageState();
}

class _EditInventoryPageState extends State<EditInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  final InventoryController inventoryController = InventoryController();

  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _costController;

  // Loading state (renamed from _isUploading)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Fill edit text fields with existing data
    _nameController = TextEditingController(text: widget.item.item_name);
    _descriptionController = TextEditingController(
      text: widget.item.item_description,
    );
    _quantityController = TextEditingController(
      text: widget.item.item_quantity.toString(),
    );
    _costController = TextEditingController(
      text: widget.item.item_costperunit.toStringAsFixed(2), // Added toStringAsFixed for better formatting
    );
    // Removed _currentImageUrl initialization
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Edit Inventory Item',   //Title
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[500],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => AppRouter.goBack(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- IMAGE SECTION REMOVED ---

                  // Text field to input item_name (Required)
                  const Text(
                    'Item Name *',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter inventory item name'; //Return inline error message when value = null
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Text field to edit item_description (Not Required)
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text fields to edit item_quantity and item_costperunit (Required)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quantity *',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required'; // Return inline error message when value = null
                                }
                                if (int.parse(value) < 0) {
                                  return 'Invalid Quantity'; // Return inline error message when value < 0
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unit Cost (RM) *',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _costController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required'; // Return inline error message when value = null
                                }
                                if (double.tryParse(value) == null ||
                                    double.parse(value) <= 0) {
                                  return 'Invalid Cost'; // Return inline error message when value <= 0
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Update button
                  ElevatedButton(
                    onPressed: _isSaving ? null : updateItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[500],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- REMOVED _buildImageWidget(), _pickImage(), and _uploadImage() ---

  // Update inventory item
  void updateItem() async {
    if (_formKey.currentState!.validate()) {
      // Start loading
      setState(() {
        _isSaving = true;
      });

      try {
        // Create updated inventory item
        // We do not change the item_image. We pass the existing one back, or empty string.
        final updatedItem = widget.item.copyWith(
          item_name: _nameController.text.trim(),
          item_description: _descriptionController.text.trim(),
          item_quantity: int.parse(_quantityController.text),
          item_costperunit: double.parse(_costController.text),
          item_image: widget.item.item_image, // Keep existing URL to avoid data loss, though not displayed
          updated_at: DateTime.now(),
        );

        // Update to InventoryInfo
        await inventoryController.editInventoryItem(updatedItem);

        //Display success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Inventory item updated successfully',
              ), //Display Success message
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
          AppRouter.goBack(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error updating inventory item: ${e.toString()}',
              ), //Display error message
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        // Stop loading
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }
}