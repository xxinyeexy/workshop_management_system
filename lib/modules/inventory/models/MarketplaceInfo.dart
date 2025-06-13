import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingType {
  sale,
  request,
}

enum ListingStatus {
  pending,
  done,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
}

class MarketplaceInfo {
  final String? listing_id;
  final ListingType listing_type;
  final String item_name;
  final String item_description;
  final int item_quantity;
  final double item_costperunit;
  final String? item_image;
  final ListingStatus listing_status;
  final String? seller_id;
  final String? seller_name;
  final GeoPoint? seller_location;
  final String? buyer_id;
  final String? buyer_name;
  final GeoPoint? buyer_location;
  final PaymentStatus payment_status;
  final DateTime created_at;
  final DateTime? updated_at;

  MarketplaceInfo({
    this.listing_id,
    required this.listing_type,
    required this.item_name,
    required this.item_description,
    required this.item_quantity,
    required this.item_costperunit,
    required this.item_image,
    this.listing_status = ListingStatus.pending,
    this.seller_id,
    this.seller_name,
    this.seller_location,
    this.buyer_id,
    this.buyer_name,
    this.buyer_location,
    this.payment_status = PaymentStatus.pending,
    DateTime? created_at,
    this.updated_at,
  }) : created_at = created_at ?? DateTime.now();

  MarketplaceInfo copyWith({
    String? listing_id,
    ListingType? listing_type,
    String? item_name,
    String? item_description,
    int? item_quantity,
    double? item_cost_per_unit,
    String? item_image,
    ListingStatus? listing_status,
    String? seller_id,
    String? seller_name,
    GeoPoint? seller_location,
    String? buyer_id,
    String? buyer_name,
    GeoPoint? buyer_location,
    PaymentStatus? payment_status,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return MarketplaceInfo(
      listing_id: listing_id ?? this.listing_id,
      listing_type: listing_type ?? this.listing_type,
      item_name: item_name ?? this.item_name,
      item_description: item_description ?? this.item_description,
      item_quantity: item_quantity ?? this.item_quantity,
      item_costperunit: item_costperunit ?? item_costperunit,
      item_image: item_image ?? this.item_image,
      listing_status: listing_status ?? this.listing_status,
      seller_id: seller_id ?? this.seller_id,
      seller_name: seller_name ?? this.seller_name,
      seller_location: seller_location ?? this.seller_location,
      buyer_id: buyer_id ?? this.buyer_id,
      buyer_name: buyer_name ?? this.buyer_name,
      buyer_location: buyer_location ?? this.buyer_location,
      payment_status: payment_status ?? this.payment_status,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  static String listingTypeToString(ListingType type) =>
      type.toString().split('.').last;

  static ListingType stringToListingType(String value) =>
      ListingType.values.firstWhere(
        (type) => type.toString().split('.').last == value,
        orElse: () => ListingType.sale,
      );

  static String listingStatusToString(ListingStatus status) =>
      status.toString().split('.').last;

  static ListingStatus stringToListingStatus(String value) =>
      ListingStatus.values.firstWhere(
        (status) => status.toString().split('.').last == value,
        orElse: () => ListingStatus.pending,
      );

  static String paymentStatusToString(PaymentStatus status) =>
      status.toString().split('.').last;

  static PaymentStatus stringToPaymentStatus(String value) =>
      PaymentStatus.values.firstWhere(
        (status) => status.toString().split('.').last == value,
        orElse: () => PaymentStatus.pending,
      );

  factory MarketplaceInfo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MarketplaceInfo(
      listing_id: doc.id,
      listing_type: stringToListingType(data['listing_type'] ?? 'sale'),
      item_name: data['item_name'] ?? '',
      item_description: data['item_description'] ?? '',
      item_quantity: data['item_quantity'] ?? 0,
      item_costperunit: (data['item_cost_per_unit'] is int)
          ? (data['item_cost_per_unit'] as int).toDouble()
          : data['item_cost_per_unit']?.toDouble() ?? 0.0,
      item_image: data['item_image'] ?? '',
      listing_status: stringToListingStatus(data['listing_status'] ?? 'pending'),
      seller_id: data['seller_id'],
      seller_name: data['seller_name'],
      seller_location: data['seller_location'],
      buyer_id: data['buyer_id'],
      buyer_name: data['buyer_name'],
      buyer_location: data['buyer_location'],
      payment_status: stringToPaymentStatus(data['payment_status'] ?? 'pending'),
      created_at: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updated_at: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listing_type': listingTypeToString(listing_type),
      'item_name': item_name,
      'item_description': item_description,
      'item_quantity': item_quantity,
      'item_cost_per_unit': item_costperunit,
      'item_image': item_image,
      'listing_status': listingStatusToString(listing_status),
      'seller_id': seller_id,
      'seller_name': seller_name,
      'seller_location': seller_location,
      'buyer_id': buyer_id,
      'buyer_name': buyer_name,
      'buyer_location': buyer_location,
      'payment_status': paymentStatusToString(payment_status),
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': updated_at != null ? Timestamp.fromDate(updated_at!) : null,
    };
  }

  factory MarketplaceInfo.emptySale({String? seller_id, String? seller_location}) {
    return MarketplaceInfo(
      listing_type: ListingType.sale,
      item_name: '',
      item_description: '',
      item_quantity: 0,
      item_costperunit: 0.0,
      item_image: '',
      seller_id: seller_id,
      seller_location: seller_location != null
          ? GeoPoint(
              double.parse(seller_location.split(',')[0]),
              double.parse(seller_location.split(',')[1]),
            )
          : null,
    );
  }

  factory MarketplaceInfo.emptyRequest({String? buyer_id, String? buyer_location}) {
    return MarketplaceInfo(
      listing_type: ListingType.request,
      item_name: '',
      item_description: '',
      item_quantity: 0,
      item_costperunit: 0.0,
      item_image: '',
      buyer_id: buyer_id,
      buyer_location: buyer_location != null
          ? GeoPoint(
              double.parse(buyer_location.split(',')[0]),
              double.parse(buyer_location.split(',')[1]),
            )
          : null,
    );
  }

  double get total_value => item_quantity * item_costperunit;

  bool get is_sale => listing_type == ListingType.sale;

  bool get is_request => listing_type == ListingType.request;

  bool get is_completed => listing_status == ListingStatus.done;

  bool get is_paid => payment_status == PaymentStatus.paid;

  @override
  String toString() {
    return 'MarketplaceInfo(id: $listing_id, type: $listing_type, name: $item_name, quantity: $item_quantity, cost: $item_costperunit, status: $listing_status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MarketplaceInfo &&
        other.listing_id == listing_id &&
        other.listing_type == listing_type &&
        other.item_name == item_name &&
        other.item_description == item_description &&
        other.item_quantity == item_quantity &&
        other.item_costperunit == item_costperunit &&
        other.item_image == item_image &&
        other.listing_status == listing_status &&
        other.seller_id == seller_id &&
        other.seller_name == seller_name &&
        other.seller_location == seller_location &&
        other.buyer_id == buyer_id &&
        other.buyer_name == buyer_name &&
        other.buyer_location == buyer_location &&
        other.payment_status == payment_status;
  }

  @override
  int get hashCode {
    return listing_id.hashCode ^
        listing_type.hashCode ^
        item_name.hashCode ^
        item_description.hashCode ^
        item_quantity.hashCode ^
        item_costperunit.hashCode ^
        item_image.hashCode ^
        listing_status.hashCode ^
        seller_id.hashCode ^
        seller_name.hashCode ^
        seller_location.hashCode ^
        buyer_id.hashCode ^
        buyer_name.hashCode ^
        buyer_location.hashCode ^
        payment_status.hashCode;
  }
}
