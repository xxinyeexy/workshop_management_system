import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/schedule/views/schedule.dart';
import 'package:workshop_management_system/modules/schedule/views/blankSchedule.dart';
import 'package:workshop_management_system/modules/schedule/views/tasks.dart';
import 'package:workshop_management_system/modules/inventory/views/page/InventoryPage.dart';
import 'package:workshop_management_system/modules/inventory/views/page/Marketplace.dart';
import 'package:workshop_management_system/modules/rating/views/FindForemanWorkshopPage.dart';
import 'package:workshop_management_system/modules/registration/views/UserProfile.dart';

enum UserRole { WorkshopOwner, Foreman }

class BtmNavigationMenu extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userPosition;

  const BtmNavigationMenu({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userPosition,
  });

  @override
  State<BtmNavigationMenu> createState() => _BtmNavigationMenu();
}

class _BtmNavigationMenu extends State<BtmNavigationMenu> {
  int _currentIndex = 0;

  late final List<Widget> _pages;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();

    final isForeman = widget.userRole.toLowerCase() == 'foreman';

    _pages = [
      Schedule(
        userName: widget.userName,
        userRole: widget.userRole,
        userPosition: widget.userPosition,
      ),

      if (!isForeman)
        InventoryPage(
          userRole: widget.userRole,
          userName: widget.userName,
          userPosition: widget.userPosition,
        ),

      if (!isForeman)
        Marketplace(
          userRole: widget.userRole,
          userName: widget.userName,
          userPosition: widget.userPosition,
        ),

      FindForemanWorkshopPage(
        userRole: isForeman ? 'foreman' : 'workshop',
        userName: widget.userName,
        originalUserRole: widget.userRole,
        userPosition: widget.userPosition,
        enumUserRole:
            isForeman ? UserRole.Foreman : UserRole.WorkshopOwner,
      ),

      UserProfilePage(
        userRole: widget.userRole,
        userName: widget.userName,
        userPosition: widget.userPosition,
      ),
    ];

    _navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Schedule',
      ),

      if (!isForeman)
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Inventory',
        ),

      if (!isForeman)
        const BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Marketplace',
        ),

      const BottomNavigationBarItem(
        icon: Icon(Icons.star),
        label: 'Ratings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: _navItems,
      ),
    );
  }
}
