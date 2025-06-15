import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:workshop_management_system/modules/inventory/models/InventoryInfo.dart';
import 'package:workshop_management_system/modules/inventory/providers/InventoryController.dart';
import 'package:workshop_management_system/modules/sidebar.dart'; // Import SidebarMenu
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

  // Image related variables
  File? _imageFile;
  String? _currentImageUrl;
  bool _isImageChanged = false;
  bool _isUploading = false;

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
      text: widget.item.item_costperunit.toString(),
    );
    _currentImageUrl = widget.item.item_image;
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
                  // Upload image section
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  _buildImageWidget(), 
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: FloatingActionButton(
                                mini: true,
                                backgroundColor: Colors.indigo[500],
                                onPressed: _pickImage,
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Image (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

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
                  // For edit: item_quantity can be 0, cannot <0
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
                    onPressed: _isUploading ? null : updateItem,
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
                    child:
                        _isUploading
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

  // Build image widget based on current state
  Widget _buildImageWidget() {
    if (_imageFile != null) {
      // Show new selected image file
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      // Show existing image from URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _currentImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
          },
        ),
      );
    } else {
      // Show placeholder
      return const Icon(Icons.camera_alt, size: 50, color: Colors.grey);
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

   
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                  );
                  if (image != null) {
                    setState(() {
                      _imageFile = File(image.path);
                      _isImageChanged = true;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                  );
                  if (photo != null) {
                    setState(() {
                      _imageFile = File(photo.path);
                      _isImageChanged = true;
                    });
                  }
                },
              ),
              if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Image',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentImageUrl = '';
                      _imageFile = null;
                      _isImageChanged = true;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentImageUrl;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('inventory_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
     
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
      return null;
    }
  }

  // Update inventory item
  void updateItem() async {
    if (_formKey.currentState!.validate()) {
      // Start loading
      setState(() {
        _isUploading = true;
      });

      try {
        String? imageUrl = _currentImageUrl;

        // Upload new image if changed
        if (_isImageChanged && _imageFile != null) {
          imageUrl = await _uploadImage();
        }

        // Create updated inventory item
        final updatedItem = widget.item.copyWith(
          item_name: _nameController.text.trim(),
          item_description: _descriptionController.text.trim(),
          item_quantity: int.parse(_quantityController.text),
          item_costperunit: double.parse(_costController.text),
          item_image: imageUrl ?? '',
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
        //print('Error updating inventory item: $e');
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
            _isUploading = false;
          });
        }
      }
    }
  }
}
