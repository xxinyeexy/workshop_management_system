import 'package:flutter/material.dart';
import 'package:workshop_management_system/routes/route.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userRole;

  const AppDrawer({
    super.key, 
    required this.userName, 
    required this.userRole
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(2, 0),
            )
          ]
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              color: Colors.indigo[500],
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      userName[0].toUpperCase(), 
                      style: TextStyle(color: Colors.indigo)
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName, 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        userRole, 
                        style: TextStyle(
                          color: Colors.white70, 
                          fontSize: 14
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.calendar_today, 'Schedule', () {
                    Navigator.pop(context);
                    // AppRouter.navigateTo(context, AppRoutes.schedule);
                  }),
                  _buildDrawerItem(Icons.inventory, 'Inventory', () {
                    Navigator.pop(context);
                    AppRouter.navigateTo(context, AppRoutes.inventory);
                  }),
                  _buildDrawerItem(Icons.storefront, 'Marketplace', () {
                    Navigator.pop(context);
                    AppRouter.navigateTo(context, AppRoutes.marketplace);
                  }),
                  _buildDrawerItem(Icons.monetization_on, 'Payroll', () {
                    Navigator.pop(context);
                    // AppRouter.navigateTo(context, AppRoutes.payroll);
                  }),
                  _buildDrawerItem(Icons.star, 'Ratings', () {
                    Navigator.pop(context);
                    // AppRouter.navigateTo(context, AppRoutes.ratings);
                  }),
                  _buildDrawerItem(Icons.person, 'Profile', () {
                    Navigator.pop(context);
                    // AppRouter.navigateTo(context, AppRoutes.profile);
                  }),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout),
                label: Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Implement logout functionality
                  // AppRouter.navigateTo(context, AppRoutes.login);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper method to create drawer items
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(
        title, 
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}