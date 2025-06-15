import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/InventoryInfo.dart';

class InventoryService {
  // Reference to the inventory collection in Firestore
  final CollectionReference _inventoryCollection = 
      FirebaseFirestore.instance.collection('inventory');
  
  
  
  
  
  
  // Add a new inventory item

  
  // Update an existing inventory item
 
  
  // Delete an inventory item
 
  
  
  
  // Get low stock items (quantity below threshold)
  Stream<List<InventoryInfo>> getLowStockItems(int threshold) {
    return _inventoryCollection
        .where('item_quantity', isLessThanOrEqualTo: threshold)
        .orderBy('item_quantity')
        .snapshots()
        .map(_convertQuerySnapshotToInventoryList);
  }
  
  
  
  // Increment or decrement inventory quantity
  Future<void> adjustInventoryQuantity(String id, int adjustment) async {
    try {
      DocumentSnapshot doc = await _inventoryCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Item not found');
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int currentQuantity = data['item_quantity'] ?? 0;
      int newQuantity = currentQuantity + adjustment;
      
      if (newQuantity < 0) {
        throw Exception('Cannot reduce quantity below zero');
      }
      
      return _inventoryCollection.doc(id).update({'item_quantity': newQuantity});
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
        int quantity = data['item_quantity'] ?? 0;
        double cost = (data['item_costperunit'] is int) 
            ? (data['item_costperunit'] as int).toDouble() 
            : data['item_costperunit']?.toDouble() ?? 0.0;
            
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
        .where('item_costperunit', isGreaterThanOrEqualTo: minValue)
        .where('item_costperunit', isLessThanOrEqualTo: maxValue)
        .orderBy('item_costperunit')
        .snapshots()
        .map(_convertQuerySnapshotToInventoryList);
  }
}
