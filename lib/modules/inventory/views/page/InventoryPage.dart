import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:workshop_management_system/models/InventoryInfo.dart';
import 'package:workshop_management_system/provider/InventoryController.dart';
import 'package:workshop_management_system/modules/sidebar.dart'; // Import SidebarMenu
import 'package:workshop_management_system/routes/route.dart';

class InventoryPage extends StatefulWidget {
  final String userRole;
  final String userName;

  final String userPosition;

  
  const InventoryPage({
    super.key,
    required this.userRole,
    required this.userName,  // widget.userName = workshopName
  
    required this.userPosition,
   
    });

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryController inventoryController = InventoryController();  //Access to InventoryController
  final CollectionReference _inventoryCollection = 
      FirebaseFirestore.instance.collection('inventory');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarMenu(
              userRole:
                  widget.userRole.toLowerCase() == 'foreman'
                      ? UserRole.Foreman
                      : UserRole.WorkshopOwner,
              userName: widget.userName,
              userPosition: widget.userPosition,
              selectedTitle: 'Inventory', 
              originalUserRole: widget.userRole,
              onSelectedTitleChanged: (title) {
                // Optional: sync state or navigation logic here
              },
            ),
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: const Text(
          'Inventory', //Title
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.indigo[500], 
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Alternative method
                },
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => addInventory(context),
          ),
        ],
      ),
      body: _buildInventoryList(),
    );
  }

  Widget _buildInventoryList() {
    return StreamBuilder<List<InventoryInfo>>(
      stream: inventoryController.getInventory(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No inventory items found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => addInventory(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[500],
                  ),
                  child: const Text(
                    'Add Item',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildInventoryItemCard(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildInventoryItemCard(InventoryInfo item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Dismissible(
        key: Key(item.item_id ?? 'unknown'),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete, color: Colors.white),
            ],
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDeleteConfirmation(item);
        },
        onDismissed: (direction) {
          deleteItem(item);
        },
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),

          child: InkWell(
            onTap: () => editInventory(context, item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      image:
                          item.item_image.isNotEmpty
                              ? DecorationImage(
                                image: NetworkImage(item.item_image),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        item.item_image.isEmpty
                            ? const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            )
                            : null,
                  ),

                  // Inventory List Display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.item_name,    //item_name
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.item_description,  //item_description
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qty: ${item.item_quantity}', //item_quantity
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    item.item_quantity == 0    //Qty=0 (Red)
                                        ? Colors.red
                                        : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'RM ${item.item_costperunit.toStringAsFixed(2)}/unit', //item_costperunit
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
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

  void addInventory(BuildContext context) {
  AppRouter.navigateTo(context, AppRoutes.addInventory);
}

void editInventory(BuildContext context, InventoryInfo item) {
  AppRouter.navigateTo(
    context,
    AppRoutes.editInventory,
    arguments: item,
  );
}

//Display delete confirmation box when user wants to delete inventory
  Future<bool> showDeleteConfirmation(InventoryInfo item) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Item'),
              content: Text(
                'Are you sure you want to delete ${item.item_name}?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'DELETE',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; 
  }

  void deleteItem(InventoryInfo item) async {
    try {
      await inventoryController.deleteInventoryItem(item.item_id!); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.item_name} deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              // Add the item back
              inventoryController.addInventoryItem(item);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: ${e.toString()}')),
      );
    }
  }
}
