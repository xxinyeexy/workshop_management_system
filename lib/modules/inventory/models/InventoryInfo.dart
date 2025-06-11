import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryInfo {
  final String? itemId; // Firestore document ID (corresponds to item_id)
  final String itemName;
  final String itemDescription;
  final int itemQuantity;
  final double itemCostPerUnit;
  final String itemImage;
  final DateTime createdAt; // Additional field for sorting and filtering
  final DateTime? updatedAt; // Additional field to track updates
  
  // Constructor
  InventoryInfo({
    this.itemId,
    required this.itemName,
    required this.itemDescription,
    required this.itemQuantity,
    required this.itemCostPerUnit,
    required this.itemImage,
    DateTime? createdAt,
    this.updatedAt,
  }): createdAt = createdAt ?? DateTime.now();
  
  // Create a copy of this InventoryInfo with modified fields
  InventoryInfo copyWith({
    String? id,
    String? itemName,
    String? itemDescription,
    int? itemQuantity,
    double? itemCostPerUnit,
    String? itemImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryInfo(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      itemCostPerUnit: itemCostPerUnit ?? this.itemCostPerUnit,
      itemImage: itemImage ?? this.itemImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Create an InventoryInfo from a Firestore document
  factory InventoryInfo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return InventoryInfo(
      itemId: doc.id,
      itemName: data['itemName'] ?? '',
      itemDescription: data['itemDescription'] ?? '',
      itemQuantity: data['itemQuantity'] ?? 0,
      itemCostPerUnit: (data['itemCostPerUnit'] is int)
          ? (data['itemCostPerUnit'] as int).toDouble()
          : data['itemCostPerUnit']?.toDouble() ?? 0.0,
      itemImage: data['itemImage'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
  
  // Convert this InventoryInfo to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'itemDescription': itemDescription,
      'itemQuantity': itemQuantity,
      'itemCostPerUnit': itemCostPerUnit,
      'itemImage': itemImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
  
  // Create an empty InventoryInfo (useful for forms)
  factory InventoryInfo.empty() {
    return InventoryInfo(
      itemName: '',
      itemDescription: '',
      itemQuantity: 0,
      itemCostPerUnit: 0.0,
      itemImage: '',
    );
  }
  
  // Calculate the total value of this inventory item
  double get totalValue => itemQuantity * itemCostPerUnit;
  
  // Check if the item is low in stock (example threshold: 5)
  bool get isLowStock => itemQuantity < 5;
  
  // For debugging purposes
  @override
  String toString() {
    return 'InventoryInfo(id: $itemId, name: $itemName, quantity: $itemQuantity, cost: $itemCostPerUnit)';
  }
  
  // For comparison in lists, etc.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is InventoryInfo &&
        other.itemId == itemId &&
        other.itemName == itemName &&
        other.itemDescription == itemDescription &&
        other.itemQuantity == itemQuantity &&
        other.itemCostPerUnit == itemCostPerUnit &&
        other.itemImage == itemImage;
  }
  
  @override
  int get hashCode {
    return itemId.hashCode ^
        itemName.hashCode ^
        itemDescription.hashCode ^
        itemQuantity.hashCode ^
        itemCostPerUnit.hashCode ^
        itemImage.hashCode;
  }
}