import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:workshop_management_system/modules/inventory/models/InventoryInfo.dart';
import 'package:workshop_management_system/modules/inventory/models/MarketplaceInfo.dart';
import 'package:workshop_management_system/routes/route.dart';

class InventoryController {
   final CollectionReference _inventoryCollection = 
      FirebaseFirestore.instance.collection('inventory');   //Access to Firestore Inventory Collection

   bool _has_shown_location_dialog = false;

      final CollectionReference _marketplace_collection =
      FirebaseFirestore.instance.collection('marketplace'); //Access to Firestore Marketplace Collection

//Retrieve all inventory items in InventoryInfo (will return in List)
    Stream<List<InventoryInfo>> getInventory() {   
    return _inventoryCollection
        .orderBy('item_name')
        .snapshots()
        .map(_convertQuerySnapshotToInventoryList);
  }

//Get specific inventory item by Id
  Future<InventoryInfo?> getInventoryInfo(String id) async {
  try {
    final docSnap = await _inventoryCollection.doc(id).get();
    if (!docSnap.exists) return null;
    return InventoryInfo.fromFirestore(
        docSnap as DocumentSnapshot<Map<String, dynamic>>);
  } catch (e) {
    print('Error reading inventory item: $e');
    rethrow;
  }
}

///Add a new inventory item to the InventoryInfo
    Future<DocumentReference> addInventoryItem(InventoryInfo item) {
      

    try {
      return _inventoryCollection.add(item.toFirestore());
    } catch (e) {
      print('Error adding inventory item: $e');
      rethrow;
    }
  }

  Future<void> editInventoryItem(InventoryInfo item) {
    try {
      if (item.item_id == null) {
        throw Exception('Cannot update item without an ID');
      }
      return _inventoryCollection.doc(item.item_id).update(item.toFirestore());
    } catch (e) {
      print('Error updating inventory item: $e');
      rethrow;
    }
  }

  // Update inventory quantity only
  Future<void> updateInventoryQuantity(String id, int newQuantity) {
    try {
      return _inventoryCollection.doc(id).update({'item_quantity': newQuantity});
    } catch (e) {
      print('Error updating inventory quantity: $e');
      rethrow;
    }
  }

  List<InventoryInfo> _convertQuerySnapshotToInventoryList(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return InventoryInfo.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    }).toList();
  }

//Delete an inventory item from InventoryInfo 
   Future<void> deleteInventoryItem(String id) {
    try {
      return _inventoryCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting inventory item: $e');
      rethrow;
    }
  }

  //Handles Marketplace Operation
  Stream<List<MarketplaceInfo>> getSaleListingsByGeoPoint(GeoPoint userLocation) {
    const double radiusInKm = 20.0;
    return _marketplace_collection
        .where('listing_type', isEqualTo: 'sale')
        .where('listing_status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          final allListings = convertQuerySnapshotToMarketplaceList(snapshot);
          return allListings.where((listing) {
            if (listing.seller_location == null) return false;
            final distanceInMeters = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              listing.seller_location!.latitude,
              listing.seller_location!.longitude,
            );
            return distanceInMeters <= radiusInKm * 1000;
          }).toList();
        });
  }

  Stream<List<MarketplaceInfo>> getSaleListings() {
    return _marketplace_collection
        .where('listing_type', isEqualTo: 'sale')
        .where('listing_status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(convertQuerySnapshotToMarketplaceList);
  }

  

  Stream<List<MarketplaceInfo>> getRequestListings() {
    return _marketplace_collection
        .where('listing_type', isEqualTo: 'request')
        .where('listing_status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(convertQuerySnapshotToMarketplaceList);
  }

  Stream<List<MarketplaceInfo>> getRequestListingsByGeoPoint(GeoPoint userLocation) {
    const double radiusInKm = 20.0;
    return _marketplace_collection
        .where('listing_type', isEqualTo: 'request')
        .where('listing_status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          final allListings = convertQuerySnapshotToMarketplaceList(snapshot);
          return allListings.where((listing) {
            if (listing.buyer_location == null) return false;
            final distanceInMeters = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              listing.buyer_location!.latitude,
              listing.buyer_location!.longitude,
            );
            return distanceInMeters <= radiusInKm * 1000;
          }).toList();
        });
  }

  Future<DocumentReference> createListing(MarketplaceInfo listing) {
    try {
      return _marketplace_collection.add(listing.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  

  //update buyer info, payment status and listing status
  Future<void> completeRequestListing(String id, int current_user_id, GeoPoint? user_geo_point,
      {String? buyer_id, GeoPoint? buyer_location}) async {
    try {
      DocumentSnapshot doc = await _marketplace_collection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Listing not found');
      }

      MarketplaceInfo listing = MarketplaceInfo.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);

      final updatedListing = listing.copyWith(
        listing_type: ListingType.request,
        payment_status: PaymentStatus.paid,
        listing_status: ListingStatus.done,
        buyer_id: buyer_id ?? listing.buyer_id,
        buyer_location: buyer_location ?? listing.buyer_location,
        updated_at: DateTime.now(),
      );

      return _marketplace_collection.doc(id).update(updatedListing.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

//update buyer info, payment status and listing status
  Future<void> completeSaleListing(String id, int current_user_id, GeoPoint? user_geo_point,
      {String? buyer_id, GeoPoint? buyer_location}) async {
    try {
      DocumentSnapshot doc = await _marketplace_collection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Listing not found');
      }

      MarketplaceInfo listing = MarketplaceInfo.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);

      final updatedListing = listing.copyWith(
        listing_type: ListingType.sale,
        payment_status: PaymentStatus.paid,
        listing_status: ListingStatus.done,
        buyer_id: buyer_id ?? listing.buyer_id,
        buyer_location: buyer_location ?? listing.buyer_location,
        updated_at: DateTime.now(),
      );

      return _marketplace_collection.doc(id).update(updatedListing.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  List<MarketplaceInfo> convertQuerySnapshotToMarketplaceList(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return MarketplaceInfo.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    }).toList();
  }

  //Ask user location permission
  Future<void> askPermissionLocation(BuildContext context) async {
    final box = Hive.box('settings');

    // Check if dialog has been shown before
    bool hasShownDialog = box.get('location_dialog_shown', defaultValue: false);

    if (!hasShownDialog) {
      showLocationPermissionDialog(context);
    }
  }

  void showLocationPermissionDialog(BuildContext context) {
    if (_has_shown_location_dialog) return;

    _has_shown_location_dialog = true;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red[600],
                    size: 30,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Allow Location Access',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                const Text(
                  'WorkshopPro needs access to your location to show nearby inventory listings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          handleLocationDenied(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Deny',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          handleLocationAllowed(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Allow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void handleLocationAllowed(BuildContext context) async {
    final box = Hive.box('settings');
    await box.put('location_dialog_shown', true);
    await box.put('location_permission_granted', true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      // setState and user_location/user_geo_point are not defined in this controller.
      // You may need to handle this differently depending on your architecture.
      // For now, just save the coordinates in Hive.
      print(
        'Current location saved: ${position.latitude}, ${position.longitude}',
      );

      await box.put('user_latitude', position.latitude);
      await box.put('user_longitude', position.longitude);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location access granted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void handleLocationDenied(BuildContext context) async {
    final box = Hive.box('settings');
    await box.put('location_dialog_shown', true);
    await box.put('location_permission_granted', false);

    print('Location permission denied');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location access denied. Showing all listings.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  

  
} 