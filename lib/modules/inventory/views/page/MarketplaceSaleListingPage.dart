import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workshop_management_system/modules/inventory/models/MarketplaceInfo.dart';
import 'package:workshop_management_system/modules/inventory/providers/InventoryController.dart';
import 'package:workshop_management_system/modules/sidebar.dart'; // Import SidebarMenu
import 'package:workshop_management_system/routes/route.dart';

class MarketplaceSaleListingPage extends StatefulWidget {
   final GeoPoint? user_geo_point; // Pass user location  
  const MarketplaceSaleListingPage({
    super.key,
    this.user_geo_point, 
    
  });

  @override
  _MarketplaceSaleListingPageState createState() => _MarketplaceSaleListingPageState();
}

class _MarketplaceSaleListingPageState extends State<MarketplaceSaleListingPage> {
  final InventoryController inventoryController = InventoryController();
  final Map<String, int> selectedQuantities = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketplaceInfo>>(
       stream: widget.user_geo_point != null
          ? inventoryController.getSaleListingsByGeoPoint(widget.user_geo_point!) //get nearby sale listings
          : inventoryController.getSaleListings(), //get all sale listings
      
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
                      ? 'No nearby items for sale' 
                      : 'No items for sale',
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
            
          
            if (!selectedQuantities.containsKey(listing.listing_id)) {
              selectedQuantities[listing.listing_id!] = 1;
            }
            
            return _buildSaleListingCard(listing);
          },
        );
      },
    );
  }

  Widget _buildSaleListingCard(MarketplaceInfo listing) {
    //  Calculate distance if both locations available
    String? distanceText;
    if (widget.user_geo_point != null && listing.seller_location != null) {
      double distance = Geolocator.distanceBetween(
        widget.user_geo_point!.latitude,
        widget.user_geo_point!.longitude,
        listing.seller_location!.latitude,
        listing.seller_location!.longitude,
      );
      distanceText = formatDistance(distance);
    }

    return GestureDetector( 
      onTap: () => purchase(context, listing), 
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!), 
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
                          '${listing.item_description ?? ""}',  //Show item description
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        // Seller name
                        Text(
                          listing.seller_name ?? 'Unknown Seller',  //Show seller name
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
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.indigo),
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
              
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RM ${listing.item_costperunit.toStringAsFixed(2)}/unit', // Show item cost per unit
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Qty: ${listing.item_quantity}', // Show item quantity available
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  
                  Row(
                    children: [
                      // Choose quantity to buy
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            // Decrement button
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                setState(() {
                                  int currentQty = selectedQuantities[listing.listing_id!] ?? 1;
                                  if (currentQty > 1) {
                                    selectedQuantities[listing.listing_id!] = currentQty - 1;
                                  }
                                });
                              },
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            
                            // Quantity display
                            Text(
                              '${selectedQuantities[listing.listing_id!] ?? 1}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            
                            // Increment button
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                setState(() {
                                  int currentQty = selectedQuantities[listing.listing_id!] ?? 1;
                                  if (currentQty < listing.item_quantity) {
                                    selectedQuantities[listing.listing_id!] = currentQty + 1;
                                  }
                                });
                              },
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Buy Now button
                      ElevatedButton(
                        onPressed: () => purchase(context, listing),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[500],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Buy Now'),
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

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  

    void purchase(context, MarketplaceInfo listing) {
  AppRouter.navigateTo(
    context,
    AppRoutes.saleDetails,
    arguments: {
      'listing': listing,
      'user_geo_point': widget.user_geo_point,
      'selected_quantity': selectedQuantities[listing.listing_id] ?? 1,
    },
  );
}

}