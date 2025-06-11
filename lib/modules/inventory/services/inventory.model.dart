import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/InventoryInfo.dart';

class InventoryService {
  // Reference to the inventory collection in Firestore
  final CollectionReference _inventoryCollection = 
      FirebaseFirestore.instance.collection('inventory');
  
  // Get all inventory items sorted by name
  Stream<List<InventoryInfo>> getInventory() {
    return _inventoryCollection
        .orderBy('itemName')
        .snapshots()
        .map(_convertQuerySnapshotToInventoryList);
  }
  
  // Get a specific inventory item by ID
  Future<InventoryInfo?> getInventoryItemById(String id) async {
    try {
      DocumentSnapshot doc = await _inventoryCollection.doc(id).get();
      if (doc.exists) {
        return InventoryInfo.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      print('Error getting inventory item: $e');
      rethrow;
    }
  }
  
  // Add a new inventory item
  Future<DocumentReference> addInventoryItem(InventoryInfo item) {
    try {
      return _inventoryCollection.add(item.toFirestore());
    } catch (e) {
      print('Error adding inventory item: $e');
      rethrow;
    }
  }
  
  // Update an existing inventory item
  Future<void> updateInventoryItem(InventoryInfo item) {
    try {
      if (item.itemId == null) {
        throw Exception('Cannot update item without an ID');
      }
      return _inventoryCollection.doc(item.itemId).update(item.toFirestore());
    } catch (e) {
      print('Error updating inventory item: $e');
      rethrow;
    }
  }
  
  // Delete an inventory item
  Future<void> deleteInventoryItem(String id) {
    try {
      return _inventoryCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting inventory item: $e');
      rethrow;
    }
  }
  
  // Search inventory items by name
  Stream<List<InventoryInfo>> searchInventory(String query) {
    // Convert query to lowercase for case-insensitive search
    String searchTerm = query.toLowerCase();
    
    return _inventoryCollection
        .orderBy('itemName')
        .startAt([searchTerm])
        .endAt([searchTerm + '\uf8ff'])
        .snapshots()
        .map(_convertQuerySnapshotToInventoryList);
  }
  
  // Get low stock items (quantity below threshold)
  Stream<List<InventoryInfo>> getLowStockItems(int threshold) {
    return _inventoryCollection
        .where('itemQuantity', isLessThanOrEqualTo: threshold)
        .orderBy('itemQuantity')
        .snapshots()
        .map(_convertQuerySnapshotToInventoryList);
  }
  
  // Update inventory quantity only
  Future<void> updateInventoryQuantity(String id, int newQuantity) {
    try {
      return _inventoryCollection.doc(id).update({'itemQuantity': newQuantity});
    } catch (e) {
      print('Error updating inventory quantity: $e');
      rethrow;
    }
  }
  
  // Increment or decrement inventory quantity (useful for sales/purchases)
  Future<void> adjustInventoryQuantity(String id, int adjustment) async {
    try {
      // Get current document
      DocumentSnapshot doc = await _inventoryCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Item not found');
      }
      
      // Extract current quantity
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int currentQuantity = data['itemQuantity'] ?? 0;
      int newQuantity = currentQuantity + adjustment;
      
      // Ensure quantity doesn't go negative
      if (newQuantity < 0) {
        throw Exception('Cannot reduce quantity below zero');
      }
      
      // Update quantity
      return _inventoryCollection.doc(id).update({'itemQuantity': newQuantity});
    } catch (e) {
      print('Error adjusting inventory quantity: $e');
      rethrow;
    }
  }
  
  // Get total inventory value
  Future<double> getTotalInventoryValue() async {
    try {
      QuerySnapshot snapshot = await _inventoryCollection.get();
      double total = 0;
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int quantity = data['itemQuantity'] ?? 0;
        double cost = (data['itemCostPerUnit'] is int) 
            ? (data['itemCostPerUnit'] as int).toDouble() 
            : data['itemCostPerUnit']?.toDouble() ?? 0.0;
            
        total += quantity * cost;
      }
      
      return total;
    } catch (e) {
      print('Error calculating inventory value: $e');
      rethrow;
    }
  }
  
  // Helper method to convert QuerySnapshot to List<InventoryInfo>
  List<InventoryInfo> _convertQuerySnapshotToInventoryList(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return InventoryInfo.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
    }).toList();
  }
  
  // Batch operations - useful for bulk updates
  
  // Add multiple inventory items at once
  Future<void> addMultipleItems(List<InventoryInfo> items) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (var item in items) {
        DocumentReference docRef = _inventoryCollection.doc();
        batch.set(docRef, item.toFirestore());
      }
      
      return batch.commit();
    } catch (e) {
      print('Error adding multiple inventory items: $e');
      rethrow;
    }
  }
  
  // Delete multiple inventory items at once
  Future<void> deleteMultipleItems(List<String> ids) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (var id in ids) {
        DocumentReference docRef = _inventoryCollection.doc(id);
        batch.delete(docRef);
      }
      
      return batch.commit();
    } catch (e) {
      print('Error deleting multiple inventory items: $e');
      rethrow;
    }
  }
  
  // Get inventory items by value range (price per unit)
  Stream<List<InventoryInfo>> getItemsByValueRange(double minValue, double maxValue) {
    return _inventoryCollection
        .where('itemCostPerUnit', isGreaterThanOrEqualTo: minValue)
        .where('itemCostPerUnit', isLessThanOrEqualTo: maxValue)
        .orderBy('itemCostPerUnit')
        .snapshots()
        .map(_convertQuerySnapshotToInventoryList);
  }
}