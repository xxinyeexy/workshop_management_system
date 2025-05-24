import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // Lists to store users from Firestore
  List<Map<String, dynamic>> foremen = [];
  List<Map<String, dynamic>> workshops = [];
  bool isLoading = true;

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
        return 'workshop owner';
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
    _fetchUsers();
  }

  // Fetch users from Firestore
  Future<void> _fetchUsers() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Fetch all users from Firestore
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      List<Map<String, dynamic>> tempForemen = [];
      List<Map<String, dynamic>> tempWorkshops = [];

      for (QueryDocumentSnapshot doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['uid'] = doc.id; // Add document ID

        // Get user's average rating and total ratings
        Map<String, dynamic> ratingData = await _getUserRatingData(doc.id);
        userData['averageRating'] = ratingData['averageRating'];
        userData['totalRatings'] = ratingData['totalRatings'];

        // Separate users by role
        if (userData['role'] == 'foreman') {
          tempForemen.add(userData);
        } else if (userData['role'] == 'workshop_owner') {
          tempWorkshops.add(userData);
        }
      }

      setState(() {
        foremen = tempForemen;
        workshops = tempWorkshops;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Get user's rating data from Firestore
  Future<Map<String, dynamic>> _getUserRatingData(String userId) async {
    try {
      QuerySnapshot ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return {'averageRating': 0.0, 'totalRatings': 0};
      }

      double totalRating = 0.0;
      int count = ratingsSnapshot.docs.length;

      for (QueryDocumentSnapshot doc in ratingsSnapshot.docs) {
        Map<String, dynamic> ratingData = doc.data() as Map<String, dynamic>;
        totalRating += (ratingData['rating'] ?? 0).toDouble();
      }

      double averageRating = totalRating / count;

      return {
        'averageRating': averageRating,
        'totalRatings': count,
      };
    } catch (e) {
      print('Error fetching rating data: $e');
      return {'averageRating': 0.0, 'totalRatings': 0};
    }
  }

  // Generate initials from full name
  String _getInitials(String fullName) {
    List<String> names = fullName.trim().split(' ');
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  Widget _buildListTile(Map<String, dynamic> userData, bool isForeman) {
    String initials = _getInitials(userData['fullName'] ?? 'Unknown');
    String name = userData['fullName'] ?? 'Unknown';
    double rating = userData['averageRating']?.toDouble() ?? 0.0;
    int totalRatings = userData['totalRatings'] ?? 0;

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
                builder: (_) => RatingDetailPage(
                  initials: initials,
                  name: name,
                  role: isForeman ? "Foreman" : "Workshop Owner",
                  userData: userData, // Pass user data for rating
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
              if (rating > 0) ...[
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
                  "(${rating.toStringAsFixed(1)}) $totalRatings reviews",
                  style: const TextStyle(fontSize: 12),
                ),
              ] else ...[
                const Text(
                  "No ratings yet",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isForeman) {
    List<Map<String, dynamic>> items = isForeman ? foremen : workshops;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isForeman ? Icons.person_search : Icons.store_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isForeman 
                  ? 'No foremen registered yet'
                  : 'No workshops registered yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildListTile(items[index], isForeman);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine workshopName for passing to RatingListPage
    String workshopName = widget.userRole.toLowerCase() == 'workshop'
        ? widget.userName
        : 'Ali Workshop'; // Replace with your actual foreman's workshop lookup if possible

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
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
                  builder: (_) => RatingListPage(
                    userRole: widget.userRole.toLowerCase(),
                    userName: widget.userName,
                    workshopName: workshopName,
                    toRateList: [], // pass your real data here
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
                  tabs: [
                    Tab(text: "Foremen (${foremen.length})"),
                    Tab(text: "Workshops (${workshops.length})"),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabContent(true), 
                      _buildTabContent(false)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}