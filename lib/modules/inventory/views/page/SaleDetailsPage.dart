import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/MarketplaceInfo.dart';
import '../../models/InventoryInfo.dart';
import 'package:workshop_management_system/modules/inventory/providers/InventoryController.dart';
import 'package:workshop_management_system/modules/sidebar.dart'; // Import SidebarMenu
import 'package:geolocator/geolocator.dart';


class SaleDetailsPage extends StatefulWidget {
  final MarketplaceInfo sale_item;
  final GeoPoint? user_geo_point;  //Get user location from marketplace
  final int selected_quantity;
  
  const SaleDetailsPage({
    super.key,
    required this.sale_item,
    this.user_geo_point,
    required this.selected_quantity,
  });

  @override
  _SaleDetailsPageState createState() => _SaleDetailsPageState();
}

class _SaleDetailsPageState extends State<SaleDetailsPage> {
  final InventoryController inventoryController = InventoryController(); //Access InventoryController
  bool _isLoading = true;
  bool _isProcessing = false;
  MarketplaceInfo? _sale_item;
  late int selected_quantity; 
  String? _errorMessage;
  late String current_user_id;
  late String current_user_name;
  

  @override
  void initState() {
    super.initState();
    initializeUserId();
    initializeUserName();
  }

  void initializeUserId() async {
    current_user_id = await inventoryController.getCurrentUserId();
  }

  void initializeUserName() async {
    current_user_name = await inventoryController.getCurrentUserName();
  }

  double get _totalCost => selected_quantity * (_sale_item?.item_costperunit ?? 0);

 

  void cancelRequest() {
    Navigator.pop(context);
  }

   void proceedToPayment() async {
  setState(() {
    _isProcessing = true;
  });

  try {
    // Directly update or create inventory item quantity 
    await inventoryController.updateInventory(
      widget.sale_item.listing_id!, 
      widget.sale_item.item_name,
      selected_quantity,
    );

    // Complete the listing by updating the payment status, listing status and buyer details
    await inventoryController.completeSaleListing(
      widget.sale_item.listing_id!,
      current_user_id,
      current_user_name,
      widget.user_geo_point,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processed successfully'),
          backgroundColor: Colors.green,
        )
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],

        appBar: AppBar(
          title: const Text('Sale Details',  //Title
          style: TextStyle(color: Colors.white)), 
          backgroundColor: Colors.indigo[500],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sale Details', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.indigo[500],
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_sale_item == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sale Details', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.indigo[500],
        ),
        body: const Center(
          child: Text('Sale item not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Sale Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[500],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: (_sale_item!.item_image != null && _sale_item!.item_image!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              _sale_item!.item_image ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 40,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2,
                            color: Colors.grey,
                            size: 40,
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Item details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sale_item!.item_name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        Text(
                          'From: ${_sale_item!.seller_name ?? "Unknown seller"}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '(20km distance)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Workshop Address
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workshop Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ' ${_sale_item!.seller_name ?? "Unknown Workshop"}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Text(
                    '123 Mechanic Street Automotive District', ///owner_wordkshop_location
                    style: TextStyle(fontSize: 14),
                  ),
                  const Text(
                    'Kuala Lumpur, 50000',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Order Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Requested Quantity:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '$selected_quantity units',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Unit Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Unit Price:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'RM ${_sale_item!.item_costperunit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Total Cost
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Cost:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'RM ${_totalCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : cancelRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Proceed Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing || selected_quantity <= 0 
                          ? null 
                          : proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[500],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Proceed to Payment'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment Options
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Options',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mobile88
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Container(
                              width: 64,
                              height: 40,
                              color: Colors.orange,
                              child: const Center(
                                child: Text(
                                  'Mobile88',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mobile88',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      
                      // DuitNow
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Container(
                              width: 64,
                              height: 40,
                              color: Colors.pink[600],
                              child: const Center(
                                child: Text(
                                  'DuitNow',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'DuitNow',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}