import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../models/InventoryInfo.dart';
import '../../../models/MarketplaceInfo.dart';
import 'package:workshop_management_system/provider/InventoryController.dart';

import 'package:workshop_management_system/routes/route.dart';

class SellForm extends StatefulWidget {
  final GeoPoint? user_geo_point;  //pass user geopoint to get user location
  const SellForm({super.key, required this.user_geo_point});

  @override
  _SellFormState createState() => _SellFormState();
}

class _SellFormState extends State<SellForm> {
  final _form_key = GlobalKey<FormState>();

   final InventoryController inventoryController = InventoryController(); //Access to InventoryController


  InventoryInfo? _selected_inventory_item;
  List<InventoryInfo> _inventory_items = [];

  // Text controllers
  final _description_controller = TextEditingController();
  final _quantity_controller = TextEditingController();
  final _cost_controller = TextEditingController();

  // Image related variables
  File? _image_file;
  String? _uploaded_image_url;
  bool _is_uploading = false;
  bool _is_loading_inventory = true;

  // Seller information (retrieve from owner table))
  late final String _seller_id; // owner.owner_id
  late final String _seller_name; // owner.owner_name 
  
  @override
  void initState() {
    super.initState();
    loadInventoryItems();
    initializeUserId();
    initializeUserName();
  }

   void initializeUserId() async {
    _seller_id = await inventoryController.getCurrentUserId();
  }

  void initializeUserName() async {
    _seller_name = await inventoryController.getCurrentUserName();
  }

  Future<void> loadInventoryItems() async { //Get inventory items for user to choose from
    try {
      final inventoryStream = inventoryController.getInventory(); 
      inventoryStream.listen((items) {
        setState(() {
          _inventory_items =
              items.where((item) => item.item_quantity > 0).toList();
          _is_loading_inventory = false;
        });
      });
    } catch (e) {
      print('Error loading inventory: $e');
      setState(() {
        _is_loading_inventory = false;
      });
    }
  }

  @override
  void dispose() {
    _description_controller.dispose();
    _quantity_controller.dispose();
    _cost_controller.dispose();
    super.dispose();
  }

  @override  
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Sell Inventory Item',  //Title
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[500],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => AppRouter.goBack(context),
        ),
      ),
      body:
          _is_loading_inventory
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form_key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Upload image section
                          Center(
                            child: Column(
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
                                      child: buildImageWidget(),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: FloatingActionButton(
                                        mini: true,
                                        backgroundColor: Colors.indigo[500],
                                        onPressed: pickImage,
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
                          const SizedBox(height: 24),

                          const Text(
                            'Select Inventory Item to Sell *',   //Drop down: user can only sell existing inventory items
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<InventoryInfo>(
                            value: _selected_inventory_item,
                            decoration: const InputDecoration(
                              hintText: 'Choose an item from inventory',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            items:
                                _inventory_items.map((item) {
                                  return DropdownMenuItem<InventoryInfo>(
                                    value: item,
                                    child: Text(
                                      '${item.item_name} (Qty: ${item.item_quantity})',   //Show available item_quantity of each inventory item
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                            onChanged: (InventoryInfo? value) {
                              setState(() {
                                _selected_inventory_item = value;
                                _quantity_controller.clear();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select an inventory item';  //Cannot be null
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          

                          // Fill Item_description
                          const Text(
                            'Description',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _description_controller,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Synthetic 5W-30',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quantity *',    
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _quantity_controller,  //Quantity of item to sell
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        hintText: '5',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                      ),
                                      validator: (value) {  //Validation of item available and item to sell
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (int.parse(value) <= 0) {
                                          return 'Must be > 0';
                                        }
                                        if (_selected_inventory_item != null && 
                                            int.parse(value) > _selected_inventory_item!.item_quantity) {
                                          return 'Insufficient inventory';  // Cannot sell more than available quantity
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _cost_controller,  //Cost per unit of item to sell
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
                                        hintText: '5.00',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.parse(value) <= 0) {
                                          return 'Must be > 0';
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

                          // Submit button
                          ElevatedButton(
                            onPressed: _is_uploading ? null : addSaleItem,
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
                                _is_uploading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      'Submit',
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
  Widget buildImageWidget() {
    if (_image_file != null) {
      // Show new selected image file
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_image_file!, fit: BoxFit.cover),
      );
    } else if (_uploaded_image_url != null && _uploaded_image_url!.isNotEmpty) {
      // Show existing image from URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _uploaded_image_url!,
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
  Future<void> pickImage() async {
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
                      _image_file = File(image.path);
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
                      _image_file = File(photo.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage() async {
    if (_image_file == null) return null; // Return null if no image selected

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('marketplace_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(_image_file!);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

   // Submit the form
  void addSaleItem() async {
    if (_form_key.currentState!.validate()) {
      // Start loading
      setState(() {
        _is_uploading = true;
      });

      try {
        // Upload image if selected, otherwise keep it null
        String? finalImageUrl;
        if (_image_file != null) {
          finalImageUrl = await uploadImage();
        }

        // Create marketplace listing
        final newListing = MarketplaceInfo(
          listing_type: ListingType.sale,
          item_name: _selected_inventory_item!.item_name,
          item_description: _selected_inventory_item!.item_description,
          item_quantity: int.parse(_quantity_controller.text),
          item_costperunit: double.parse(_cost_controller.text),
          item_image: finalImageUrl, // Nullable
          seller_id: _seller_id,
          seller_name: _seller_name, 
          seller_location: widget.user_geo_point, 
          listing_status: ListingStatus.pending,
          payment_status: PaymentStatus.pending,
          created_at: DateTime.now(),
          updated_at: DateTime.now(),
        );

        // Save to MarketplaceInfo
        await inventoryController.createListing(newListing);

        // Display success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your item is now listed for sale'),
              backgroundColor: Colors.green,
            ),
          );
          AppRouter.navigateTo(context, AppRoutes.marketplace);
        }
      } catch (e) {
        // Display error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating sale listing: $e')), 
          );
        }
      } finally {
        // Stop loading
        if (mounted) {
          setState(() {
            _is_uploading = false;
          });
        }
      }
    }
  }
}