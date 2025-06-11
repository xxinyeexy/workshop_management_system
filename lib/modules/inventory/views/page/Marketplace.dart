// lib/screens/Marketplace.dart

import 'package:flutter/material.dart';
import 'MarketplaceSaleListingPage.dart';
import 'MarketplaceRequestListingPage.dart';
import 'package:workshop_management_system/routes/route.dart';

class Marketplace extends StatefulWidget {
  const Marketplace({Key? key}) : super(key: key);

  @override
  _MarketplaceState createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Marketplace',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[500],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Sell'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MarketplaceSaleListingPage(),  //display this tab as default
          MarketplaceRequestListingPage(), 
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo[400],
        onPressed: () {
          if (_tabController.index == 0) {
            // Navigate to sell form
            AppRouter.navigateTo(context, AppRoutes.sellForm);
          } else {
            // Navigate to request form
            AppRouter.navigateTo(context, AppRoutes.requestForm);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}