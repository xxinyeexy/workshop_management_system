import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:workshop_management_system/modules/models/InventoryInfo.dart';
import 'package:workshop_management_system/modules/models/MarketplaceInfo.dart';
import 'package:workshop_management_system/routes/route.dart';

class InventoryController {
   final CollectionReference _inventoryCollection = 
       FirebaseFirestore.instance.collection('inventory');   //Access to Firestore Inventory Collection

   bool _has_shown_location_dialog = false;

      final CollectionReference _marketplaceCollection =
       FirebaseFirestore.instance.collection('marketplace'); //Access to Firestore Marketplace Collection

Future<String> getCurrentUserId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Unknown Workshop';
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['uid'] ?? 'Unknown User';
  }

  Future<String> getCurrentUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Unknown Workshop';
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['fullName'] ?? 'Unknown User';
  }

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

  

  // Update inventory quantity if the item exists, creates a new inventory item if it doesn't
  Future<void> updateInventory(String id, String item_name, int newQuantity) async {
  try {
    // Query to find an existing inventory item with the same name
    QuerySnapshot querySnapshot = await _inventoryCollection
        .where('item_name', isEqualTo: item_name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Item exists, update its quantity
      DocumentSnapshot existingDoc = querySnapshot.docs.first;
      int currentQuantity = existingDoc['item_quantity'] ?? 0;
      
      await _inventoryCollection.doc(existingDoc.id).update({
        'item_quantity': currentQuantity + newQuantity
      });
    } else {
      // Item doesn't exist, create a new inventory item
      await _inventoryCollection.add({
        'item_name': item_name,
        'item_quantity': newQuantity,
        // Add other necessary fields
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    print('Error updating/creating inventory: $e');
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
    const double radiusInKm = 100.0;
    return _marketplaceCollection
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
    return _marketplaceCollection
        .where('listing_type', isEqualTo: 'sale')
        .where('listing_status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(convertQuerySnapshotToMarketplaceList);
  }

  

  Stream<List<MarketplaceInfo>> getRequestListings() {
    return _marketplaceCollection
        .where('listing_type', isEqualTo: 'request')
        .where('listing_status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(convertQuerySnapshotToMarketplaceList);
  }

  Stream<List<MarketplaceInfo>> getRequestListingsByGeoPoint(GeoPoint userLocation) {
    const double radiusInKm = 20.0;
    return _marketplaceCollection
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
      return _marketplaceCollection.add(listing.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  

  //update seller info, payment status and listing status
  Future<void> completeRequestListing(String id, String current_user_id,  String current_user_name, GeoPoint? user_geo_point,
      {String? seller_id, String? seller_name, GeoPoint? seller_location}) async {
    try {
      DocumentSnapshot doc = await _marketplaceCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Listing not found');
      }

      MarketplaceInfo listing = MarketplaceInfo.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);

      final updatedListing = listing.copyWith(
        listing_type: ListingType.request,
        payment_status: PaymentStatus.paid,
        listing_status: ListingStatus.done,
        seller_id: seller_id ?? listing.seller_id,
        seller_name: seller_name ?? listing.seller_name,
        seller_location: seller_location ?? listing.seller_location,
        updated_at: DateTime.now(),
      );

      return _marketplaceCollection.doc(id).update(updatedListing.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

//update buyer info, payment status and listing status
  Future<void> completeSaleListing(String id, String current_user_id, String current_user_name, GeoPoint? user_geo_point,
      {String? buyer_id, String? buyer_name, GeoPoint? buyer_location}) async {
    try {
      DocumentSnapshot doc = await _marketplaceCollection.doc(id).get();
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
        buyer_name: buyer_name ?? listing.buyer_name,
        buyer_location: buyer_location ?? listing.buyer_location,
        updated_at: DateTime.now(),
      );

      return _marketplaceCollection.doc(id).update(updatedListing.toFirestore());
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
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<void> showLocationPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission'),
          content: const Text(
            'This app needs location access to show nearby workshops and calculate distances. Please enable location permissions.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () async {
                Navigator.of(context).pop();
                await checkLocationPermission();
              },
            ),
          ],
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