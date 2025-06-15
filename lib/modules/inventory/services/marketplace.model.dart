import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workshop_management_system/modules/inventory/models/MarketplaceInfo.dart';

class MarketplaceService {
  final CollectionReference _marketplaceCollection = FirebaseFirestore.instance.collection('marketplace');
      
      

  Stream<List<MarketplaceInfo>> getAllListings() {
    return _marketplaceCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(convertQuerySnapshotToMarketplaceList);
  }

  

  Stream<List<MarketplaceInfo>> getListingsBySeller(String sellerId) {
    return _marketplaceCollection
        .where('seller_id', isEqualTo: sellerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(convertQuerySnapshotToMarketplaceList);
  }

  Stream<List<MarketplaceInfo>> getListingsByBuyer(String buyerId) {
    return _marketplaceCollection
        .where('buyer_id', isEqualTo: buyerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(convertQuerySnapshotToMarketplaceList);
  }

  

  

  Future<void> updateListing(MarketplaceInfo listing) {
    try {
      if (listing.listing_id == null) {
        throw Exception('Cannot update listing without an ID');
      }

      final updatedListing = listing.copyWith(
        updated_at: DateTime.now(),
      );

      return _marketplaceCollection
          .doc(listing.listing_id)
          .update(updatedListing.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeListing(String id,
      {String? buyer_id, GeoPoint? buyer_location}) async {
    try {
      DocumentSnapshot doc = await _marketplaceCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Listing not found');
      }

      MarketplaceInfo listing = MarketplaceInfo.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);

      final updatedListing = listing.copyWith(
        payment_status: PaymentStatus.paid,
        listing_status: ListingStatus.done,
        buyer_id: buyer_id ?? listing.buyer_id,
        buyer_location: buyer_location ?? listing.buyer_location,
        updated_at: DateTime.now(),
      );

      return _marketplaceCollection.doc(id).update(updatedListing.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(String id, PaymentStatus status) async {
    try {
      return _marketplaceCollection.doc(id).update({
        'payment_status': MarketplaceInfo.paymentStatusToString(status),
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteListing(String id) {
    try {
      return _marketplaceCollection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<MarketplaceInfo>> searchListings(String query,
      {ListingType? type}) {
    String searchTerm = query.toLowerCase();

    Query baseQuery = _marketplaceCollection
        .orderBy('item_name')
        .startAt([searchTerm])
        .endAt(['$searchTerm\uf8ff']);

    if (type != null) {
      baseQuery = baseQuery.where(
          'listing_type', isEqualTo: MarketplaceInfo.listingTypeToString(type));
    }

    return baseQuery.snapshots().map(convertQuerySnapshotToMarketplaceList);
  }

  List<MarketplaceInfo> convertQuerySnapshotToMarketplaceList(
      QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return MarketplaceInfo.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
    }).toList();
  }
}