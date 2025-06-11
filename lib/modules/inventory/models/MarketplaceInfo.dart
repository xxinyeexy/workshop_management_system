import 'package:workshop_management_system/modules/inventory/models/InventoryInfo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing listing types
enum ListingType {
  sale,
  request
}

/// Enum representing listing status
enum ListingStatus {
  pending,
  done
}

/// Enum representing payment status
enum PaymentStatus {
  pending,
  paid,
  failed
}

class MarketplaceInfo {
  final String ?listingId; // Firestore document ID (corresponds to listing_id)
  final ListingType listingType;
  final String itemName;
  final String itemDescription;
  final int itemQuantity;
  final double itemCostPerUnit;
  final String itemImage;
  final ListingStatus listingStatus;
  final String? sellerId;
  final String? sellerLocation;
  final String? buyerId;
  final String? buyerLocation;
  final PaymentStatus paymentStatus;
  final DateTime createdAt; // Additional field for sorting and filtering
  final DateTime? updatedAt; // Additional field to track updates

  // Constructor
  MarketplaceInfo({
    this.listingId,
    required this.listingType,
    required this.itemName,
    required this.itemDescription,
    required this.itemQuantity,
    required this.itemCostPerUnit,
    required this.itemImage,
    this.listingStatus = ListingStatus.pending,
    this.sellerId,
    this.sellerLocation,
    this.buyerId,
    this.buyerLocation,
    this.paymentStatus = PaymentStatus.pending,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a copy of this MarketplaceInfo with modified fields
  MarketplaceInfo copyWith({
    String? id,
    ListingType? listingType,
    String? itemName,
    String? itemDescription,
    int? itemQuantity,
    double? itemCostPerUnit,
    String? itemImage,
    ListingStatus? listingStatus,
    String? sellerId,
    String? sellerLocation,
    String? buyerId,
    String? buyerLocation,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceInfo(
      listingId: listingId ?? this.listingId,
      listingType: listingType ?? this.listingType,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      itemCostPerUnit: itemCostPerUnit ?? this.itemCostPerUnit,
      itemImage: itemImage ?? this.itemImage,
      listingStatus: listingStatus ?? this.listingStatus,
      sellerId: sellerId ?? this.sellerId,
      sellerLocation: sellerLocation ?? this.sellerLocation,
      buyerId: buyerId ?? this.buyerId,
      buyerLocation: buyerLocation ?? this.buyerLocation,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert ListingType enum to string
  static String listingTypeToString(ListingType type) {
    return type.toString().split('.').last;
  }

  // Convert string to ListingType enum
  static ListingType stringToListingType(String value) {
    return ListingType.values.firstWhere(
      (type) => type.toString().split('.').last == value,
      orElse: () => ListingType.sale,
    );
  }

  // Convert ListingStatus enum to string
  static String listingStatusToString(ListingStatus status) {
    return status.toString().split('.').last;
  }

  // Convert string to ListingStatus enum
  static ListingStatus stringToListingStatus(String value) {
    return ListingStatus.values.firstWhere(
      (status) => status.toString().split('.').last == value,
      orElse: () => ListingStatus.pending,
    );
  }

  // Convert PaymentStatus enum to string
  static String paymentStatusToString(PaymentStatus status) {
    return status.toString().split('.').last;
  }

  // Convert string to PaymentStatus enum
  static PaymentStatus stringToPaymentStatus(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.toString().split('.').last == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  // Create a MarketplaceInfo from a Firestore document
  factory MarketplaceInfo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return MarketplaceInfo(
      listingId: doc.id,
      listingType: stringToListingType(data['listingType'] ?? 'sale'),
      itemName: data['itemName'] ?? '',
      itemDescription: data['itemDescription'] ?? '',
      itemQuantity: data['itemQuantity'] ?? 0,
      itemCostPerUnit: (data['itemCostPerUnit'] is int)
          ? (data['itemCostPerUnit'] as int).toDouble()
          : data['itemCostPerUnit']?.toDouble() ?? 0.0,
      itemImage: data['itemImage'] ?? '',
      listingStatus: stringToListingStatus(data['listingStatus'] ?? 'pending'),
      sellerId: data['sellerId'],
      sellerLocation: data['sellerLocation'],
      buyerId: data['buyerId'],
      buyerLocation: data['buyerLocation'],
      paymentStatus: stringToPaymentStatus(data['paymentStatus'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert this MarketplaceInfo to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'listingType': listingTypeToString(listingType),
      'itemName': itemName,
      'itemDescription': itemDescription,
      'itemQuantity': itemQuantity,
      'itemCostPerUnit': itemCostPerUnit,
      'itemImage': itemImage,
      'listingStatus': listingStatusToString(listingStatus),
      'sellerId': sellerId,
      'sellerLocation': sellerLocation,
      'buyerId': buyerId,
      'buyerLocation': buyerLocation,
      'paymentStatus': paymentStatusToString(paymentStatus),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create an empty sale listing (useful for forms)
  factory MarketplaceInfo.emptySale({String? sellerId, String? sellerLocation}) {
    return MarketplaceInfo(
      listingType: ListingType.sale,
      itemName: '',
      itemDescription: '',
      itemQuantity: 0,
      itemCostPerUnit: 0.0,
      itemImage: '',
      sellerId: sellerId,
      sellerLocation: sellerLocation,
    );
  }

  // Create an empty request listing (useful for forms)
  factory MarketplaceInfo.emptyRequest({String? buyerId, String? buyerLocation}) {
    return MarketplaceInfo(
      listingType: ListingType.request,
      itemName: '',
      itemDescription: '',
      itemQuantity: 0,
      itemCostPerUnit: 0.0,
      itemImage: '',
      buyerId: buyerId,
      buyerLocation: buyerLocation,
    );
  }

  // Create a sale listing from an inventory item
  factory MarketplaceInfo.fromInventoryItem({
    required InventoryInfo item,
    required String sellerId,
    required String sellerLocation,
    int? quantity,
  }) {
    return MarketplaceInfo(
      listingType: ListingType.sale,
      itemName: item.itemName,
      itemDescription: item.itemDescription,
      itemQuantity: quantity ?? item.itemQuantity,
      itemCostPerUnit: item.itemCostPerUnit,
      itemImage: item.itemImage,
      sellerId: sellerId,
      sellerLocation: sellerLocation,
    );
  }

  // Calculate the total value of this listing
  double get totalValue => itemQuantity * itemCostPerUnit;

  // Check if this listing is a sale
  bool get isSale => listingType == ListingType.sale;

  // Check if this listing is a request
  bool get isRequest => listingType == ListingType.request;

  // Check if this listing is completed
  bool get isCompleted => listingStatus == ListingStatus.done;

  // Check if this listing is paid
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  // For debugging purposes
  @override
  String toString() {
    return 'MarketplaceInfo(id: $listingId, type: $listingType, name: $itemName, quantity: $itemQuantity, cost: $itemCostPerUnit, status: $listingStatus)';
  }

  // For comparison in lists, etc.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MarketplaceInfo &&
        other.listingId == listingId &&
        other.listingType == listingType &&
        other.itemName == itemName &&
        other.itemDescription == itemDescription &&
        other.itemQuantity == itemQuantity &&
        other.itemCostPerUnit == itemCostPerUnit &&
        other.itemImage == itemImage &&
        other.listingStatus == listingStatus &&
        other.sellerId == sellerId &&
        other.sellerLocation == sellerLocation &&
        other.buyerId == buyerId &&
        other.buyerLocation == buyerLocation &&
        other.paymentStatus == paymentStatus;
  }

  @override
  int get hashCode {
    return listingId.hashCode ^
        listingType.hashCode ^
        itemName.hashCode ^
        itemDescription.hashCode ^
        itemQuantity.hashCode ^
        itemCostPerUnit.hashCode ^
        itemImage.hashCode ^
        listingStatus.hashCode ^
        sellerId.hashCode ^
        sellerLocation.hashCode ^
        buyerId.hashCode ^
        buyerLocation.hashCode ^
        paymentStatus.hashCode;
  }
}