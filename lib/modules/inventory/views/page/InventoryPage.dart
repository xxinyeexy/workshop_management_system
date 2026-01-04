import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workshop_management_system/domain/InventoryInfo.dart';
import 'package:workshop_management_system/provider/InventoryController.dart';
import 'package:workshop_management_system/routes/route.dart';

// --- SORTING LOGIC (Unchanged) ---
enum SortOption {
  nameAZ,
  nameZA,
  priceLowHigh,
  priceHighLow,
  quantityLowHigh,
  quantityHighLow,
}

class InventoryPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userPosition;

  const InventoryPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userPosition,
  });

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryController inventoryController = InventoryController();
  final CollectionReference _inventoryCollection =
      FirebaseFirestore.instance.collection('inventory');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sorting state (Unchanged)
  SortOption _currentSortOption = SortOption.nameAZ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Inventory',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.indigo[500],
        elevation: 0,
        actions: [
          // Sorting Button (Unchanged)
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort Items',
            onSelected: (SortOption result) {
              setState(() {
                _currentSortOption = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.nameAZ,
                child: Text('Name (A-Z)'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.nameZA,
                child: Text('Name (Z-A)'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.priceLowHigh,
                child: Text('Price (Low to High)'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.priceHighLow,
                child: Text('Price (High to Low)'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.quantityLowHigh,
                child: Text('Qty (Low to High)'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.quantityHighLow,
                child: Text('Qty (High to Low)'),
              ),
            ],
          ),
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
          return Center(child: Text('No items found'));
        }

        // Sorting Logic (Unchanged - keeps your existing sort)
        List<InventoryInfo> items = List.from(snapshot.data!);
        switch (_currentSortOption) {
          case SortOption.nameAZ:
            items.sort((a, b) => a.item_name.toLowerCase().compareTo(b.item_name.toLowerCase()));
            break;
          case SortOption.nameZA:
            items.sort((a, b) => b.item_name.toLowerCase().compareTo(a.item_name.toLowerCase()));
            break;
          case SortOption.priceLowHigh:
            items.sort((a, b) => a.item_costperunit.compareTo(b.item_costperunit));
            break;
          case SortOption.priceHighLow:
            items.sort((a, b) => b.item_costperunit.compareTo(a.item_costperunit));
            break;
          case SortOption.quantityLowHigh:
            items.sort((a, b) => a.item_quantity.compareTo(b.item_quantity));
            break;
          case SortOption.quantityHighLow:
            items.sort((a, b) => b.item_quantity.compareTo(a.item_quantity));
            break;
        }

        return Padding(
          padding: const EdgeInsets.all(12.0),
          // --- CHANGED FROM LISTVIEW TO GRIDVIEW ---
          child: GridView.builder(
            itemCount: items.length,
            // This delegate controls the grid layout (2 columns)
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,       // 2 items side-by-side
              crossAxisSpacing: 10,    // Horizontal gap between cards
              mainAxisSpacing: 10,     // Vertical gap between cards
              childAspectRatio: 1.3,   // Controls height (Wider ratio since no image)
            ),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: () => editInventory(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- ROW 1: Name & Delete Icon ---
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Expanded(
                     child: Text(
                      item.item_name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                     ),
                   ),
                   const SizedBox(width: 8),
                   // Delete moved here since swiping doesn't work well in Grids
                   InkWell(
                      onTap: () => showDeleteConfirmation(item).then((confirm) {
                        if(confirm) deleteItem(item);
                      }),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    ),
                 ],
              ),
              
              // --- ROW 2: Details (Price, Desc, Qty) ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'RM ${item.item_costperunit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700]
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Expanded(
                         child: Text(
                          item.item_description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Text(
                        'Qty: ${item.item_quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: item.item_quantity == 0 ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
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