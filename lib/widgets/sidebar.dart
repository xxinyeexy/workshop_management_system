import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/rating/views/FindForemanWorkshopPage.dart';
import 'package:workshop_management_system/modules/schedule/views/schedule.dart';
import 'package:workshop_management_system/modules/registration/views/UserProfile.dart';
import 'package:workshop_management_system/modules/inventory/views/page/InventoryPage.dart';
import 'package:workshop_management_system/modules/inventory/views/page/Marketplace.dart';

enum UserRole { WorkshopOwner, Foreman }

class SidebarMenu extends StatefulWidget {
  final UserRole userRole;
  final String userName;
  final String userPosition;
  final String selectedTitle;
  final ValueChanged<String>? onSelectedTitleChanged;
  final String? originalUserRole;

  const SidebarMenu({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userPosition,
    required this.selectedTitle,
    this.onSelectedTitleChanged,
    this.originalUserRole,
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  int pendingRatingsCount = 0;

  // Assume workshopName is same as userName if workshop owner, or fetch accordingly for foreman
  late String workshopName;

  @override
  void initState() {
    super.initState();
    _setWorkshopName();
    // Listen for changes in RatingService
    RatingService().addListener(_updatePendingRatingsCount);
    _updatePendingRatingsCount();
  }

  @override
  void dispose() {
    RatingService().removeListener(_updatePendingRatingsCount);
    super.dispose();
  }

  void _setWorkshopName() {
    workshopName = widget.userName;
  }

  void _updatePendingRatingsCount() {
    final userRoleString =
        widget.userRole == UserRole.Foreman ? 'foreman' : 'workshop';
    final currentWorkshopName =
        widget.userRole == UserRole.WorkshopOwner
            ? widget.userName
            : workshopName; // Use the fetched workshopName

    final pendingRatings = RatingService().getPendingRatingsForUser(
      userRoleString,
      widget.userName,
      currentWorkshopName,
    );
    if (mounted) {
      setState(() {
        pendingRatingsCount = pendingRatings.length;
      });
    }
  }

  Color get primaryColor {
    switch (widget.userRole) {
      case UserRole.WorkshopOwner:
        return const Color(0xFF4361EE);
      case UserRole.Foreman:
        return const Color(0xFF3498DB);
    }
  }

  String get userRoleString {
    return widget.originalUserRole ??
        (widget.userRole == UserRole.Foreman ? 'foreman' : 'workshop owner');
  }

  String get ratingPageRoleString {
    switch (widget.userRole) {
      case UserRole.Foreman:
        return 'foreman';
      case UserRole.WorkshopOwner:
        return 'workshop';
    }
  }

  Widget buildPageWithDrawer(String pageTitle, Widget bodyContent) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: SidebarMenu(
        userRole: widget.userRole,
        userName: widget.userName,
        userPosition: widget.userPosition,
        selectedTitle: pageTitle,
        onSelectedTitleChanged: widget.onSelectedTitleChanged,
        originalUserRole: widget.originalUserRole,
      ),
      body: bodyContent,
    );
  }

  void _navigateTo(BuildContext context, String title) {
    Navigator.of(context).pop(); // close drawer

    widget.onSelectedTitleChanged?.call(title);

    Widget page;

    switch (title) {
      case 'Schedule':
        page = Schedule(
          userName: widget.userName,
          userRole: userRoleString,
          userPosition: widget.userPosition,
        );
        break;

      case 'Inventory':
        if (userRoleString == 'foreman') {
          page = Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Inventory'),
              backgroundColor: Color(0xFF2FB668),
              foregroundColor: Colors.white,
              leading: Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
              ),
            ),
            drawer: SidebarMenu(
              userRole: widget.userRole,
              userName: widget.userName,
              userPosition: widget.userPosition,
              selectedTitle: 'Inventory',
              onSelectedTitleChanged: widget.onSelectedTitleChanged,
              originalUserRole: widget.originalUserRole,
            ),
            body: const Center(
              child: Text(
                'Inventory is not available for Foreman',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          );
          break;
        }
        page = InventoryPage(
          userRole: userRoleString,
          userName: widget.userName,
          userPosition: widget.userPosition,
        );
        break;

      case 'Marketplace':
        if (userRoleString == 'foreman') {
          page = Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Marketplace'),
              backgroundColor: Color(0xFF2FB668),
              foregroundColor: Colors.white,
              leading: Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
              ),
            ),
            drawer: SidebarMenu(
              userRole: widget.userRole,
              userName: widget.userName,
              userPosition: widget.userPosition,
              selectedTitle: 'Marketplace',
              onSelectedTitleChanged: widget.onSelectedTitleChanged,
              originalUserRole: widget.originalUserRole,
            ),
            body: const Center(
              child: Text(
                'Marketplace is not available for Foreman',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          );
          break;
        }
        page = Marketplace(
          userRole: userRoleString,
          userName: widget.userName,
          userPosition: widget.userPosition,
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
          userRole: ratingPageRoleString,
          userName: widget.userName,
          originalUserRole: userRoleString,
          userPosition: widget.userPosition,
          enumUserRole: widget.userRole,
        );
        break;

      case 'Profile':
        page = UserProfilePage(
          userRole: userRoleString,
          userName: widget.userName,
          userPosition: widget.userPosition,
          onSelectedTitleChanged: widget.onSelectedTitleChanged,
          originalUserRole: widget.originalUserRole,
        );
        break;

      default:
        page = Schedule(
          userName: widget.userName,
          userRole: userRoleString,
          userPosition: widget.userPosition,
        );
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    int? badgeCount,
    bool isRatingItem = false,
  }) {
    final isSelected = widget.selectedTitle == title;
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: isSelected ? primaryColor : Colors.grey[700]),
          if (isRatingItem && pendingRatingsCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  pendingRatingsCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        if (title == 'Ratings') {
          _updatePendingRatingsCount();
        }
        _navigateTo(context, title);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update pending ratings count when drawer is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePendingRatingsCount();
    });

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
                    _buildMenuItem(
                      context: context,
                      icon: Icons.calendar_today,
                      title: 'Schedule',
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.inventory,
                      title: 'Inventory',
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.store,
                      title: 'Marketplace',
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.payment,
                      title: 'Payroll',
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star,
                      title: 'Ratings',
                      isRatingItem: true,
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.person,
                      title: 'Profile',
                    ),
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
                  widget.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.userPosition,
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
