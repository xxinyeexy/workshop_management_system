import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/inventory/models/MarketplaceInfo.dart';
import 'package:workshop_management_system/modules/inventory/services/marketplace.model.dart';
import 'package:workshop_management_system/routes/route.dart';

class MarketplaceRequestListingPage extends StatefulWidget {
  const MarketplaceRequestListingPage({Key? key}) : super(key: key);

  @override
  _MarketplaceRequestListingPageState createState() => _MarketplaceRequestListingPageState();
}

class _MarketplaceRequestListingPageState extends State<MarketplaceRequestListingPage> {
  final MarketplaceService _marketplaceService = MarketplaceService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketplaceInfo>>(
      stream: _marketplaceService.getRequestListings(),
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
                const Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No request listings',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Be the first to request something',
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
            return _buildRequestListingCard(listing);
          },
        );
      },
    );
  }

  Widget _buildRequestListingCard(MarketplaceInfo listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item name
            Text(
              listing.itemName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Buyer name
            Text(
              listing.buyerLocation ?? 'Unknown Requester',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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
                      'RM ${listing.itemCostPerUnit.toStringAsFixed(2)}/unit',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Qty: ${listing.itemQuantity}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // Sell button
                ElevatedButton(
                  onPressed: () => _respondToRequest(listing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[500],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Sell'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _respondToRequest(MarketplaceInfo listing) {
    // Show dialog to confirm
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are offering to sell: ${listing.itemName}'),
            Text('Quantity: ${listing.itemQuantity}'),
            Text('Unit Price: RM ${listing.itemCostPerUnit.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Total: RM ${(listing.itemCostPerUnit * listing.itemQuantity).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would process the response
              // For now, just show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You\'ve offered to sell ${listing.itemName}'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Navigate to request details page
              AppRouter.navigateTo(
                context,
                AppRoutes.requestDetails,
                arguments: listing.listingId,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[500],
            ),
            child: const Text('RESPOND'),
          ),
        ],
      ),
    );
  }
}