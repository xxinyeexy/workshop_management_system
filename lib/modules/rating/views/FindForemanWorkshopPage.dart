import 'package:flutter/material.dart';
import '../../sidebar.dart'; // your AppScaffold file
import 'package:workshop_management_system/modules/rating/views/RatingDetails.dart';
import 'package:workshop_management_system/modules/rating/views/RatingListPage.dart';

/// A single screen that adapts its colour scheme to the caller's role.
/// * Pass `userRole: 'foreman'`  →  green theme.
/// * Pass `userRole: 'workshop'` →  blue theme.
class FindForemanWorkshopPage extends StatefulWidget {
  final String userRole; // This is for the page's internal logic ('foreman' or 'workshop')
  final String userName;
  final String? originalUserRole; // This is the original role string ('foreman', 'workshop owner', etc.)
  final String? userPosition; // This is the display position ('Foreman', 'Workshop Owner')
  final UserRole? enumUserRole; // This is the UserRole enum

  const FindForemanWorkshopPage({
    super.key,
    required this.userRole,
    required this.userName,
    this.originalUserRole,
    this.userPosition,
    this.enumUserRole,
  });

  @override
  State<FindForemanWorkshopPage> createState() =>
      _FindForemanWorkshopPageState();
}

class _FindForemanWorkshopPageState extends State<FindForemanWorkshopPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late final Color primaryColor =
      widget.userRole.toLowerCase() == 'foreman'
          ? const Color(0xFF2FB668) // Foreman green
          : const Color(0xFF4260DB); // Workshop blue

  // Helper methods to convert role strings
  UserRole _getUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'foreman':
        return UserRole.Foreman;
      case 'workshop':
      case 'workshop owner':
      case 'workshopowner':
        return UserRole.WorkshopOwner;
      default:
        return UserRole.WorkshopOwner;
    }
  }

  String _getUserPosition(String role) {
    switch (role.toLowerCase()) {
      case 'foreman':
        return 'Foreman';
      case 'workshop':
      case 'workshop owner':
      case 'workshopowner':
        return 'Workshop Owner';
      default:
        return 'Workshop Owner';
    }
  }

  String _getOriginalUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'foreman':
        return 'foreman';
      case 'workshop':
        return 'workshop owner'; // Convert 'workshop' back to 'workshop owner'
      case 'workshop owner':
      case 'workshopowner':
        return 'workshop owner';
      default:
        return 'workshop owner';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildListTile(
    String initials,
    String name,
    double rating,
    bool isForeman,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.grey, blurRadius: 5, offset: Offset(0, 2)),
          ],
        ),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => RatingDetailPage(
                      initials: initials,
                      name: name,
                      role:
                          isForeman
                              ? "Senior Foreman"
                              : "Auto Repair Specialist",
                    ),
              ),
            );
          },
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < rating.floor()
                      ? Icons.star
                      : index < rating
                      ? Icons.star_half
                      : Icons.star_border,
                  size: 16,
                  color: Colors.orange,
                );
              }),
              const SizedBox(width: 6),
              Text(
                "(${rating.toStringAsFixed(1)})",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isForeman) {
    final items =
        isForeman
            ? [
              {"initials": "JD", "name": "John Doe", "rating": 4.5},
              {"initials": "MS", "name": "Mike Smith", "rating": 3.9},
            ]
            : [
              {"initials": "AB", "name": "ABC Workshop", "rating": 4.3},
              {"initials": "XY", "name": "XYZ Mechanics", "rating": 3.8},
            ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        return _buildListTile(
          item['initials']!,
          item['name']!,
          item['rating']!,
          isForeman,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        title: const Text(
          "Find Foreman / Workshop",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => RatingListPage(
                        userRole: widget.userRole.toLowerCase(),
                        toRateList: [], // Pass real data here
                        myReviewsList: [],
                      ),
                ),
              );
            },
            icon: const Icon(Icons.reviews, color: Colors.white),
            label: const Text(
              "My Reviews",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      drawer: SidebarMenu(
        userRole: widget.enumUserRole ?? _getUserRole(widget.originalUserRole ?? widget.userRole),
        userName: widget.userName,
        userPosition: widget.userPosition ?? _getUserPosition(widget.originalUserRole ?? widget.userRole),
        selectedTitle: 'Ratings',
        originalUserRole: widget.originalUserRole ?? _getOriginalUserRole(widget.userRole),
        onSelectedTitleChanged: (title) {},
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "I'm looking\nfor workshop\nowner and\nforeman.",
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryColor,
                  tabs: const [Tab(text: "Foremen"), Tab(text: "Workshops")],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildTabContent(true), _buildTabContent(false)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}