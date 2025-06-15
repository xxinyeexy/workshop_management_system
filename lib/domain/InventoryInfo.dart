import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryInfo {
  final String? item_id; // Firestore document ID (corresponds to item_id)
  final String item_name;
  final String item_description;
  final int item_quantity;
  final double item_costperunit;
  final String item_image;
  final DateTime created_at; // Additional field for sorting and filtering
  final DateTime? updated_at; // Additional field to track updates
  
  // Constructor
  InventoryInfo({
    this.item_id,
    required this.item_name,
    required this.item_description,
    required this.item_quantity,
    required this.item_costperunit,
    required this.item_image,
    DateTime? created_at,
    this.updated_at,
  }): created_at = created_at ?? DateTime.now();
  
  // Create a copy of this InventoryInfo with modified fields
  InventoryInfo copyWith({
    String? item_id,
    String? item_name,
    String? item_description,
    int? item_quantity,
    double? item_costperunit,
    String? item_image,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return InventoryInfo(
      item_id: item_id ?? this.item_id,
      item_name: item_name ?? this.item_name,
      item_description: item_description ?? this.item_description,
      item_quantity: item_quantity ?? this.item_quantity,
      item_costperunit: item_costperunit ?? this.item_costperunit,
      item_image: item_image ?? this.item_image,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
  
  // Create an InventoryInfo from a Firestore document
  factory InventoryInfo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return InventoryInfo(
      item_id: doc.id,
      item_name: data['item_name'] ?? '',
      item_description: data['item_description'] ?? '',
      item_quantity: data['item_quantity'] ?? 0,
      item_costperunit: (data['item_costperunit'] is int)
          ? (data['item_costperunit'] as int).toDouble()
          : data['item_costperunit']?.toDouble() ?? 0.0,
      item_image: data['item_image'] ?? '',
      created_at: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updated_at: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
  
  // Convert this InventoryInfo to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'item_name': item_name,
      'item_description': item_description,
      'item_quantity': item_quantity,
      'item_costperunit': item_costperunit,
      'item_image': item_image,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': updated_at != null ? Timestamp.fromDate(updated_at!) : null,
    };
  }
  
  // Create an empty InventoryInfo (useful for forms)
  factory InventoryInfo.empty() {
    return InventoryInfo(
      item_id: '',
      item_name: '',
      item_description: '',
      item_quantity: 0,
      item_costperunit: 0.0,
      item_image: '',
    );
  }
  
  // Calculate the total value of this inventory item
  double get totalValue => item_quantity * item_costperunit;
  
  // Check if the item is low in stock (example threshold: 5)
  bool get isLowStock => item_quantity < 5;
  
  // For debugging purposes
  @override
  String toString() {
    return 'InventoryInfo(id: $item_id, name: $item_name, quantity: $item_quantity, cost: $item_costperunit)';
  }
  
  // For comparison in lists, etc.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is InventoryInfo &&
        other.item_id == item_id &&
        other.item_name == item_name &&
        other.item_description == item_description &&
        other.item_quantity == item_quantity &&
        other.item_costperunit == item_costperunit &&
        other.item_image == item_image;
  }
  
  @override
  int get hashCode {
    return item_id.hashCode ^
        item_name.hashCode ^
        item_description.hashCode ^
        item_quantity.hashCode ^
        item_costperunit.hashCode ^
        item_image.hashCode;
  }
}