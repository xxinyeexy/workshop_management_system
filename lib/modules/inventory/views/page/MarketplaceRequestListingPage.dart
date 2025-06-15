import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workshop_management_system/modules/inventory/models/MarketplaceInfo.dart';
import 'package:workshop_management_system/modules/inventory/providers/InventoryController.dart';
import 'package:workshop_management_system/modules/sidebar.dart'; // Import SidebarMenu
import 'package:workshop_management_system/routes/route.dart';

class MarketplaceRequestListingPage extends StatefulWidget {
  final GeoPoint? user_geo_point;  //Pass geopoint for user current location

  const MarketplaceRequestListingPage({super.key, this.user_geo_point});

  @override
  _MarketplaceRequestListingPageState createState() =>
      _MarketplaceRequestListingPageState();
}

class _MarketplaceRequestListingPageState
    extends State<MarketplaceRequestListingPage> {
  final InventoryController inventoryController = InventoryController();
  final Map<String, int> _selected_quantities = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketplaceInfo>>(
      stream:
          widget.user_geo_point != null
              ? inventoryController.getRequestListingsByGeoPoint( //get nearby request listing
                widget.user_geo_point!,
              )
              : inventoryController.getRequestListings(), //get all request listing

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final listings = snapshot.data ?? [];

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  widget.user_geo_point != null
                      ? 'No nearby items for Request'
                      : 'No items for Request',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user_geo_point != null
                      ? 'Be the first to list something nearby'
                      : 'Be the first to list something',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];

            // Initialize selected quantity if not already set
            if (!_selected_quantities.containsKey(listing.listing_id)) {
              _selected_quantities[listing.listing_id!] = 1;
            }

            return buildRequestListingCard(listing);
          },
        );
      },
    );
  }

  Widget buildRequestListingCard(MarketplaceInfo listing) {
    // Calculate distance if both locations available
    String? distanceText;
    if (widget.user_geo_point != null && listing.buyer_location != null) {
      double distance = Geolocator.distanceBetween(
        widget.user_geo_point!.latitude,
        widget.user_geo_point!.longitude,
        listing.buyer_location!.latitude,
        listing.buyer_location!.longitude,
      );
      distanceText = formatDistance(distance);
    }

    return GestureDetector(
      
      onTap: () => acceptRequest(listing), 
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name
                        Text(
                          listing.item_name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${listing.item_description ?? ""}',  //Item description
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        // buyer name
                        Text(
                          listing.buyer_name ?? 'Unknown buyer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (distanceText != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.indigo,
                              ),
                              SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: TextStyle(
                                  color: Colors.indigo.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 4),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Price and quantity info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RM ${listing.item_costperunit.toStringAsFixed(2)}/unit',  //Item cost per unit
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Qty: ${listing.item_quantity}', //Item quantity
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      const SizedBox(width: 12),

                      // Accept Request button
                      ElevatedButton(
                        onPressed: () => acceptRequest(listing),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[500],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Accept Request'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ ADDED: Distance formatting helper method
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  void acceptRequest(MarketplaceInfo listing) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'Confirm selling?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Item details container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Quantity
                      Text(
                        '${listing.item_quantity} units',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Item name
                      Text(
                        listing.item_name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Price
                      Text(
                        'RM ${(listing.item_costperunit * listing.item_quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description text
                Text(
                  'You will receive RM ${(listing.item_costperunit * listing.item_quantity).toStringAsFixed(2)} once\n${listing.buyer_name ?? 'Buyer'} make payment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Confirm button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          //Navigator.of(context).pop();
                          navigateToRequest(context, listing);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[500],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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

  void navigateToRequest(context, MarketplaceInfo listing) {
  AppRouter.navigateTo(
    context,
    AppRoutes.requestDetails,
    arguments: {
      'listing': listing,
      'user_geo_point': widget.user_geo_point,
    },
  );
}
}


