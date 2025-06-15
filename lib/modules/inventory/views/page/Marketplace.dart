import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'MarketplaceSaleListingPage.dart';
import 'MarketplaceRequestListingPage.dart';
import 'package:workshop_management_system/routes/route.dart';
import 'package:workshop_management_system/core/widgets/sidebar.dart'; // Import SidebarMenu
import 'package:workshop_management_system/provider/InventoryController.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';

// Add a simple LocationService implementation for location handling
class LocationService {
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> showLocationPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This feature requires location access. Please enable location permissions in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class Marketplace extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userPosition;

  const Marketplace({
    super.key,
    required this.userRole,
    required this.userName, // widget.userName = workshopName
    required this.userPosition,
  });

  @override
  _MarketplaceState createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace>
    with SingleTickerProviderStateMixin {
  late TabController _tab_controller;
  final CollectionReference _marketplaceCollection = FirebaseFirestore.instance
      .collection('marketplace');
  final InventoryController inventoryController = InventoryController();

  final GlobalKey<ScaffoldState> _scaffold_key = GlobalKey<ScaffoldState>();

  // Location variables
  Position? user_location;
  GeoPoint? user_geo_point;
  final bool _has_shown_location_dialog = false;

  @override
  void initState() {
    super.initState();
    _tab_controller = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });

    // Check and show location permission dialog only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      inventoryController.askPermissionLocation(context);
    });
  }

  @override
  void dispose() {
    _tab_controller.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if permission is already granted
      bool hasPermission = await LocationService.checkLocationPermission();

      if (hasPermission) {
        Position? position = await LocationService.getCurrentLocation();
        if (position != null && mounted) {
          setState(() {
            user_location = position;
            user_geo_point = GeoPoint(position.latitude, position.longitude);
          });
        }
      } else {
        // Show permission dialog
        if (mounted) {
          await LocationService.showLocationPermissionDialog(context);
        }
      }
    } catch (e) {
      print('Error initializing location: $e');
      // Handle error - maybe show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get location: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void navigateToSaleForm(BuildContext context, GeoPoint? user_geo_point) {
    AppRouter.navigateTo(
      context,
      AppRoutes.sellForm,
      arguments: user_geo_point,
    );
  }

  void navigateToRequestForm(BuildContext context, GeoPoint? user_geo_point) {
    AppRouter.navigateTo(
      context,
      AppRoutes.requestForm,
      arguments: user_geo_point,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffold_key,
      drawer: SidebarMenu(
        userRole: widget.userRole.toLowerCase() == 'foreman'
            ? UserRole.Foreman
            : UserRole.WorkshopOwner,
        userName: widget.userName,
        userPosition: widget.userPosition,
        selectedTitle: 'Marketplace',
        originalUserRole: widget.userRole,
        onSelectedTitleChanged: (title) {
          // Optional: sync state or navigation logic here
        },
      ),
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Marketplace',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[500],
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        bottom: TabBar(
          controller: _tab_controller,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicator: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white, width: 3)),
          ),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'Sell'),
            Tab(text: 'Requests'),
          ], //Sell for MarketplaceSaleListingPage, Requests for MarketplaceRequestListingPage
        ),
      ),
      body: TabBarView(
        controller: _tab_controller,
        children: [
          MarketplaceSaleListingPage(
            user_geo_point: user_geo_point,
          ), //Pass user_geo_point to the tab
          MarketplaceRequestListingPage(user_geo_point: user_geo_point),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo[400],
        onPressed: () {
          if (_tab_controller.index == 0) {
            navigateToSaleForm(
              context,
              user_geo_point,
            ); // Navigate to Sell Form
          } else {
            navigateToRequestForm(
              context,
              user_geo_point,
            ); // Navigate to Request Form
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}