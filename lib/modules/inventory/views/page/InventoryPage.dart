import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/inventory/models/InventoryInfo.dart';
import 'package:workshop_management_system/modules/inventory/services/inventory.model.dart';
import 'package:workshop_management_system/routes/route.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryService _inventoryService = InventoryService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light gray background
      appBar: AppBar(
        title: const Text(
          'Inventory',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.indigo[500], // Indigo color as in the image
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Open drawer menu
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // Navigate to add inventory page
              AppRouter.navigateTo(context, AppRoutes.addInventory);
            },
          ),
        ],
      ),
      body: _buildInventoryList(),
    );
  }

  Widget _buildInventoryList() {
    return StreamBuilder<List<InventoryInfo>>(
      stream: _searchQuery.isEmpty 
          ? _inventoryService.getInventory() 
          : _inventoryService.searchInventory(_searchQuery),
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
                  onPressed: () {
                    AppRouter.navigateTo(context, AppRoutes.addInventory);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[500],
                  ),
                  child: const Text('Add Item', style: TextStyle(color: Colors.white)),
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
        key: Key(item.itemId ?? 'unknown'),
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
              Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ],
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmation(item);
        },
        onDismissed: (direction) {
          _deleteItem(item);
        },
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              AppRouter.navigateTo(
                context, 
                AppRoutes.editInventory,
                arguments: item,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: item.itemImage.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.itemImage),  // display Url image
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.itemImage.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
                  Text(
                    item.itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.itemDescription,
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
                        'Qty: ${item.itemQuantity}',
                        style: TextStyle(
                          fontSize: 14,
                          color: item.itemQuantity == 0 ? Colors.red : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RM ${item.itemCostPerUnit.toStringAsFixed(2)}/unit',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(InventoryInfo item) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete ${item.itemName}?'),
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
    ) ?? false; // In case dialog is dismissed
  }

  void _deleteItem(InventoryInfo item) async {
    try {
      await _inventoryService.deleteInventoryItem(item.itemId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.itemName} deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              // Add the item back
              _inventoryService.addInventoryItem(item);
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