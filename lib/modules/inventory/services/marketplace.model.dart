import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshop_management_system/modules/inventory/models/InventoryInfo.dart';
import 'package:workshop_management_system/modules/inventory/models/MarketplaceInfo.dart'; // Make sure to import this

class MarketplaceService {
  // Reference to the marketplace collection in Firestore
  final CollectionReference _marketplaceCollection = 
      FirebaseFirestore.instance.collection('marketplace');
  
  // Get all marketplace listings
  Stream<List<MarketplaceInfo>> getAllListings() {
    return _marketplaceCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_convertQuerySnapshotToMarketplaceList);
  }
  
  // Get sale listings
  Stream<List<MarketplaceInfo>> getSaleListings() {
    return _marketplaceCollection
        .where('listingType', isEqualTo: 'sale')
        .where('listingStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_convertQuerySnapshotToMarketplaceList);
  }
  
  // Get request listings
  Stream<List<MarketplaceInfo>> getRequestListings() {
    return _marketplaceCollection
        .where('listingType', isEqualTo: 'request')
        .where('listingStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_convertQuerySnapshotToMarketplaceList);
  }
  
  // Get listings by seller ID
  Stream<List<MarketplaceInfo>> getListingsBySeller(String sellerId) {
    return _marketplaceCollection
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_convertQuerySnapshotToMarketplaceList);
  }
  
  // Get listings by buyer ID
  Stream<List<MarketplaceInfo>> getListingsByBuyer(String buyerId) {
    return _marketplaceCollection
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_convertQuerySnapshotToMarketplaceList);
  }
  
  // Get a specific listing by ID
  Future<MarketplaceInfo?> getListingById(String id) async {
    try {
      DocumentSnapshot doc = await _marketplaceCollection.doc(id).get();
      if (doc.exists) {
        return MarketplaceInfo.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      print('Error getting marketplace listing: $e');
      rethrow;
    }
  }
  
  // Create a new listing
  Future<DocumentReference> createListing(MarketplaceInfo listing) {
    try {
      return _marketplaceCollection.add(listing.toFirestore());
    } catch (e) {
      print('Error creating marketplace listing: $e');
      rethrow;
    }
  }
  
  // Update an existing listing
  Future<void> updateListing(MarketplaceInfo listing) {
    try {
      if (listing.listingId == null) {
        throw Exception('Cannot update listing without an ID');
      }
      
      // Update with the current timestamp
      final updatedListing = listing.copyWith(
        updatedAt: DateTime.now()
      );
      
      return _marketplaceCollection.doc(listing.listingId).update(updatedListing.toFirestore());
    } catch (e) {
      print('Error updating marketplace listing: $e');
      rethrow;
    }
  }
  
  // Mark a listing as completed
  Future<void> completeListing(String id, {String? buyerId, String? buyerLocation}) async {
    try {
      DocumentSnapshot doc = await _marketplaceCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Listing not found');
      }
      
      MarketplaceInfo listing = MarketplaceInfo.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
      
      final updatedListing = listing.copyWith(
        listingStatus: ListingStatus.done,
        buyerId: buyerId ?? listing.buyerId,
        buyerLocation: buyerLocation ?? listing.buyerLocation,
        updatedAt: DateTime.now()
      );
      
      return _marketplaceCollection.doc(id).update(updatedListing.toFirestore());
    } catch (e) {
      print('Error completing marketplace listing: $e');
      rethrow;
    }
  }
  
  // Update payment status
  Future<void> updatePaymentStatus(String id, PaymentStatus status) async {
    try {
      return _marketplaceCollection.doc(id).update({
        'paymentStatus': MarketplaceInfo.paymentStatusToString(status),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }
  
  // Delete a listing
  Future<void> deleteListing(String id) {
    try {
      return _marketplaceCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting marketplace listing: $e');
      rethrow;
    }
  }
  
  // Search listings by name
  Stream<List<MarketplaceInfo>> searchListings(String query, {ListingType? type}) {
    // Convert query to lowercase for case-insensitive search
    String searchTerm = query.toLowerCase();
    
    Query baseQuery = _marketplaceCollection
        .orderBy('itemName')
        .startAt([searchTerm])
        .endAt([searchTerm + '\uf8ff']);
    
    // Add type filter if specified
    if (type != null) {
      baseQuery = baseQuery.where(
        'listingType', 
        isEqualTo: MarketplaceInfo.listingTypeToString(type)
      );
    }
    
    return baseQuery
        .snapshots()
        .map(_convertQuerySnapshotToMarketplaceList);
  }
  
  // Helper method to convert QuerySnapshot to List<MarketplaceInfo>
  List<MarketplaceInfo> _convertQuerySnapshotToMarketplaceList(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return MarketplaceInfo.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
    }).toList();
  }
}