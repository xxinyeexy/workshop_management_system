import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/rating/views/FindForemanWorkshopPage.dart';
import 'package:workshop_management_system/modules/registration/views/UserProfilePage.dart';
import 'package:workshop_management_system/modules/schedule/views/schedule.dart';

enum UserRole { WorkshopOwner, Foreman }

class SidebarMenu extends StatelessWidget {
  final UserRole userRole;
  final String userName;
  final String userPosition;
  final String selectedTitle;
  final ValueChanged<String>? onSelectedTitleChanged;

  const SidebarMenu({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userPosition,
    required this.selectedTitle,
    this.onSelectedTitleChanged,
  });

  Color get primaryColor {
    switch (userRole) {
      case UserRole.WorkshopOwner:
        return const Color(0xFF4361EE);
      case UserRole.Foreman:
        return const Color(0xFF3498DB);
    }
  }

  Widget buildPageWithDrawer(String pageTitle, Widget bodyContent) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: SidebarMenu(
        userRole: userRole,
        userName: userName,
        userPosition: userPosition,
        selectedTitle: pageTitle,
        onSelectedTitleChanged: onSelectedTitleChanged,
      ),
      body: bodyContent,
    );
  }

  void _navigateTo(BuildContext context, String title) {
    Navigator.of(context).pop(); // close drawer

    onSelectedTitleChanged?.call(title);

    Widget page;

    switch (title) {
      case 'Schedule':
        page = Schedule(
          userName: userName,
          userRole: userRole == UserRole.Foreman ? 'foreman' : 'workshop',
          userPosition: userPosition,
        );
        break;

      case 'Inventory':
        page = buildPageWithDrawer(
          'Inventory',
          const Center(child: Text('Inventory Page')),
        );
        break;

      case 'Marketplace':
        page = buildPageWithDrawer(
          'Marketplace',
          const Center(child: Text('Marketplace Page')),
        );
        break;

      case 'Payroll':
        page = buildPageWithDrawer(
          'Payroll',
          const Center(child: Text('Payroll Page')),
        );
        break;

      case 'Ratings':
        page = FindForemanWorkshopPage(
          userRole: userRole == UserRole.Foreman ? 'foreman' : 'workshop',
          userName: userName,
        );
        break;

      case 'Profile':
        page = UserProfilePage(
          userRole: userRole == UserRole.Foreman ? 'foreman' : 'workshop',
          userName: userName,
          userPosition: userPosition,
        );
        break;

      default:
        page = Schedule(
          userName: userName,
          userRole: userRole == UserRole.Foreman ? 'foreman' : 'workshop',
          userPosition: userPosition,
        );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    final isSelected = selectedTitle == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () => _navigateTo(context, title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(context: context, icon: Icons.calendar_today, title: 'Schedule'),
                    _buildMenuItem(context: context, icon: Icons.inventory, title: 'Inventory'),
                    _buildMenuItem(context: context, icon: Icons.store, title: 'Marketplace'),
                    _buildMenuItem(context: context, icon: Icons.payment, title: 'Payroll'),
                    _buildMenuItem(context: context, icon: Icons.star, title: 'Ratings'),
                    _buildMenuItem(context: context, icon: Icons.person, title: 'Profile'),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                title: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  userPosition,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}