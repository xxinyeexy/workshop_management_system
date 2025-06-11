
import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/inventory/models/MarketplaceInfo.dart';
import 'package:workshop_management_system/modules/inventory/services/marketplace.model.dart';
import 'package:workshop_management_system/routes/route.dart';

class MarketplaceSaleListingPage extends StatefulWidget {
  const MarketplaceSaleListingPage({Key? key}) : super(key: key);

  @override
  _MarketplaceSaleListingPageState createState() => _MarketplaceSaleListingPageState();
}

class _MarketplaceSaleListingPageState extends State<MarketplaceSaleListingPage> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final Map<String, int> _selectedQuantities = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketplaceInfo>>(
      stream: _marketplaceService.getSaleListings(),
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
                const Text(
                  'No items for sale',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Be the first to list something',
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
            if (!_selectedQuantities.containsKey(listing.listingId)) {
              _selectedQuantities[listing.listingId!] = 1;
            }
            
            return _buildSaleListingCard(listing);
          },
        );
      },
    );
  }

  Widget _buildSaleListingCard(MarketplaceInfo listing) {
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
            
            // Seller name
            Text(
              listing.sellerLocation ?? 'Unknown Seller',
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
                
                // Quantity selector and buy button
                Row(
                  children: [
                    // Quantity selector
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
                                int currentQty = _selectedQuantities[listing.listingId!] ?? 1;
                                if (currentQty > 1) {
                                  _selectedQuantities[listing.listingId!] = currentQty - 1;
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
                            '${_selectedQuantities[listing.listingId!] ?? 1}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          
                          // Increment button
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              setState(() {
                                int currentQty = _selectedQuantities[listing.listingId!] ?? 1;
                                if (currentQty < listing.itemQuantity) {
                                  _selectedQuantities[listing.listingId!] = currentQty + 1;
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
                      onPressed: () => _buyItem(listing),
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
    );
  }

  void _buyItem(MarketplaceInfo listing) {
    // Get the selected quantity
    int selectedQty = _selectedQuantities[listing.listingId!] ?? 1;
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${listing.itemName}'),
            Text('Quantity: $selectedQty'),
            Text('Unit Price: RM ${listing.itemCostPerUnit.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Total: RM ${(listing.itemCostPerUnit * selectedQty).toStringAsFixed(2)}',
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
              // Here you would process the purchase
              // For now, just show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Purchased $selectedQty ${listing.itemName}'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Navigate to sale details page
              AppRouter.navigateTo(
                context,
                AppRoutes.saleDetails,
                arguments: listing.listingId,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[500],
            ),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }
}