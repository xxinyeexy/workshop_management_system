import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../sidebar.dart';
import 'package:workshop_management_system/modules/rating/views/RatingDetails.dart';
import 'package:workshop_management_system/modules/rating/views/RatingListPage.dart';

class FindForemanWorkshopPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final String? originalUserRole;
  final String? userPosition;
  final UserRole? enumUserRole;

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

  List<Map<String, dynamic>> foremen = [];
  List<Map<String, dynamic>> workshops = [];
  bool isLoading = true;

  // Cache for rating data to avoid repeated queries
  final Map<String, Map<String, dynamic>> _ratingCache = {};
  StreamSubscription<QuerySnapshot>? _ratingsSubscription;

  late final Color primaryColor =
      widget.userRole.toLowerCase() == 'foreman'
          ? const Color(0xFF2FB668)
          : const Color(0xFF4260DB);

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
    _setupRatingsListener();
  }

  @override
  void dispose() {
    _ratingsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRatingsListener() {
    _ratingsSubscription = FirebaseFirestore.instance
        .collection('ratings')
        .snapshots()
        .listen((snapshot) async {
          // Make async to allow await
          if (!mounted) return; // Ensure widget is still mounted

          for (var docChange in snapshot.docChanges) {
            final data = docChange.doc.data() as Map<String, dynamic>?;
            if (data == null) continue;

            final ratedUserId = data['ratedUserId'] as String?;
            final ratedUserName = data['ratedUserName'] as String?;

            if (ratedUserId == null && ratedUserName == null) continue;

            // Find the user in current lists (foremen or workshops)
            Map<String, dynamic>? userToUpdate;
            bool isForemanUser = false;
            int userIndex = -1;

            userIndex = foremen.indexWhere(
              (user) =>
                  user['uid'] == ratedUserId ||
                  user['fullName'] == ratedUserName,
            );
            if (userIndex != -1) {
              userToUpdate = foremen[userIndex];
              isForemanUser = true;
            } else {
              userIndex = workshops.indexWhere(
                (user) =>
                    user['uid'] == ratedUserId ||
                    user['fullName'] == ratedUserName,
              );
              if (userIndex != -1) {
                userToUpdate = workshops[userIndex];
              }
            }

            if (userToUpdate != null) {
              // Fetch all ratings for this specific user
              // This is more efficient than re-fetching all ratings in the whole collection
              final QuerySnapshot userRatingsSnapshot =
                  await FirebaseFirestore.instance
                      .collection('ratings')
                      .where('ratedUserId', isEqualTo: userToUpdate['uid'])
                      .get();

              // Build a temporary userRatings map for just this user
              final Map<String, List<Map<String, dynamic>>>
              singleUserRatingsMap = {};
              for (QueryDocumentSnapshot ratingDoc
                  in userRatingsSnapshot.docs) {
                final ratingData = ratingDoc.data() as Map<String, dynamic>;
                final id = ratingData['ratedUserId'] as String?;
                final name = ratingData['ratedUserName'] as String?;
                if (id != null) {
                  singleUserRatingsMap[id] ??= [];
                  singleUserRatingsMap[id]!.add(ratingData);
                }
                if (name != null) {
                  singleUserRatingsMap[name] ??= [];
                  singleUserRatingsMap[name]!.add(ratingData);
                }
              }

              // Recalculate rating for the specific user using their subset of ratings
              final Map<String, dynamic> updatedRatingData =
                  _calculateRatingData(
                    userToUpdate['uid'],
                    userToUpdate['fullName'],
                    singleUserRatingsMap, // Pass only this user's ratings map
                  );

              setState(() {
                if (isForemanUser) {
                  foremen[userIndex]['averageRating'] =
                      updatedRatingData['averageRating'];
                  foremen[userIndex]['totalRatings'] =
                      updatedRatingData['totalRatings'];
                } else {
                  workshops[userIndex]['averageRating'] =
                      updatedRatingData['averageRating'];
                  workshops[userIndex]['totalRatings'] =
                      updatedRatingData['totalRatings'];
                }
              });
            }
          }
        });
  }

  // OPTIMIZED: Fetch users and ratings in parallel using batching
  Future<void> _fetchUsers() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Fetch users and all ratings in parallel
      final futures = await Future.wait([
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance.collection('ratings').get(),
      ]);

      final usersSnapshot = futures[0] as QuerySnapshot;
      final ratingsSnapshot = futures[1] as QuerySnapshot;

      // Build rating lookup map for O(1) access
      final Map<String, List<Map<String, dynamic>>> userRatings = {};

      for (QueryDocumentSnapshot doc in ratingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ratedUserId = data['ratedUserId'] as String?;
        final ratedUserName = data['ratedUserName'] as String?;

        if (ratedUserId != null) {
          userRatings[ratedUserId] ??= [];
          userRatings[ratedUserId]!.add(data);
        }
        if (ratedUserName != null) {
          userRatings[ratedUserName] ??= [];
          userRatings[ratedUserName]!.add(data);
        }
      }

      List<Map<String, dynamic>> tempForemen = [];
      List<Map<String, dynamic>> tempWorkshops = [];

      for (QueryDocumentSnapshot doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['uid'] = doc.id;

        // Calculate rating data using pre-fetched ratings
        Map<String, dynamic> ratingData = _calculateRatingData(
          doc.id,
          userData['fullName'] ?? userData['name'] ?? '',
          userRatings,
        );
        userData['averageRating'] = ratingData['averageRating'];
        userData['totalRatings'] = ratingData['totalRatings'];

        print(
          'DEBUG: User: ${userData['fullName'] ?? userData['name']}, Calculated Average Rating: ${userData['averageRating']}, Total Ratings: ${userData['totalRatings']}',
        );

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

  // OPTIMIZED: Calculate rating data from pre-fetched data
  Map<String, dynamic> _calculateRatingData(
    String userId,
    String userName,
    Map<String, List<Map<String, dynamic>>> userRatings,
  ) {
    print('DEBUG: Calculating rating for user: $userName ($userId)');
    try {
      // Check cache first
      String cacheKey = '$userId-$userName';
      if (_ratingCache.containsKey(cacheKey)) {
        print('DEBUG: Cache hit for $userName ($userId)');
        return _ratingCache[cacheKey]!;
      }

      List<Map<String, dynamic>> ratings = [];

      // Get ratings by userId
      if (userRatings.containsKey(userId)) {
        ratings.addAll(userRatings[userId]!);
      }

      // Get ratings by userName (avoid duplicates)
      if (userName.isNotEmpty && userRatings.containsKey(userName)) {
        ratings.addAll(userRatings[userName]!);
      }
      print(
        'DEBUG: Raw ratings found for $userName ($userId): ${ratings.length}',
      );

      // Remove duplicates based on rating content and rated user
      final Set<String> processed = {};
      final List<Map<String, dynamic>> uniqueRatings = [];

      for (var ratingData in ratings) {
        // A more robust key combining relevant fields to identify truly unique ratings for this user
        String key =
            '${ratingData['reviewerId']}-${ratingData['ratedUserId']}-${ratingData['comment']}-${ratingData['rating']}-${ratingData['createdAt']}';
        if (!processed.contains(key)) {
          processed.add(key);
          uniqueRatings.add(ratingData);
        }
      }
      print(
        'DEBUG: Unique ratings after deduplication for $userName ($userId): ${uniqueRatings.length}',
      );

      double totalRatingSum = 0.0;
      int ratingsCountForAverage = 0;

      for (var data in uniqueRatings) {
        dynamic ratingValue = data['rating'];
        double currentRatingDouble = 0.0;

        if (ratingValue != null) {
          if (ratingValue is int) {
            currentRatingDouble = ratingValue.toDouble();
          } else if (ratingValue is double) {
            currentRatingDouble = ratingValue;
          } else if (ratingValue is String) {
            currentRatingDouble = double.tryParse(ratingValue) ?? 0.0;
          }
        }

        // Extract comment and check if it's not empty
        String comment =
            (data['comment'] ??
                    data['review'] ??
                    data['reviewText'] ??
                    data['feedback'] ??
                    '')
                .toString()
                .trim();

        if (currentRatingDouble >= 1.0 &&
            currentRatingDouble <= 5.0 &&
            comment.isNotEmpty) {
          totalRatingSum += currentRatingDouble;
          ratingsCountForAverage++;
          print(
            'DEBUG: Processing rating for $userName: Value: $currentRatingDouble, Comment: "$comment", Current Sum: $totalRatingSum, Current Count: $ratingsCountForAverage',
          );
        }
      }

      double averageRating =
          ratingsCountForAverage > 0
              ? totalRatingSum / ratingsCountForAverage
              : 0.0;

      final result = {
        'averageRating': averageRating,
        'totalRatings': ratingsCountForAverage,
      };

      print(
        'DEBUG: Final calculated result for $userName: Average Rating: ${result['averageRating']}, Total Ratings: ${result['totalRatings']}',
      );

      // Cache the result
      _ratingCache[cacheKey] = result;
      return result;
    } catch (e) {
      print('Error calculating rating data for $userName ($userId): $e');
      return {'averageRating': 0.0, 'totalRatings': 0};
    }
  }

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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => RatingDetailPage(
                      initials: initials,
                      name: name,
                      role: isForeman ? "Foreman" : "Workshop Owner",
                      userData: userData,
                    ),
              ),
            );
            // Clear cache and refresh data after returning from RatingDetailPage
            _ratingCache.clear();
            await _fetchUsers();
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
              if (totalRatings > 0) ...[
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating.floor()
                        ? Icons.star
                        : (index < rating.ceil() && rating % 1 != 0)
                        ? Icons.star_half
                        : Icons.star_border,
                    size: 16,
                    color: Colors.orange,
                  );
                }),
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
      return const Center(child: CircularProgressIndicator());
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
    String workshopName =
        widget.userRole.toLowerCase() == 'workshop'
            ? widget.userName
            : 'Ali Workshop';

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
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => RatingListPage(
                        userRole: widget.userRole.toLowerCase(),
                        userName: widget.userName,
                        workshopName: workshopName,
                        toRateList:
                            widget.userRole.toLowerCase() == 'foreman'
                                ? workshops
                                    .map(
                                      (w) => {
                                        'initials': _getInitials(
                                          w['fullName'] ?? '',
                                        ),
                                        'name': w['fullName'],
                                        'uid': w['uid'],
                                        'role': 'workshop_owner',
                                      },
                                    )
                                    .toList()
                                : foremen
                                    .map(
                                      (f) => {
                                        'initials': _getInitials(
                                          f['fullName'] ?? '',
                                        ),
                                        'name': f['fullName'],
                                        'uid': f['uid'],
                                        'role': 'foreman',
                                      },
                                    )
                                    .toList(),
                        myReviewsList: [],
                      ),
                ),
              );
              _fetchUsers();
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
        userRole:
            widget.enumUserRole ??
            _getUserRole(widget.originalUserRole ?? widget.userRole),
        userName: widget.userName,
        userPosition:
            widget.userPosition ??
            _getUserPosition(widget.originalUserRole ?? widget.userRole),
        selectedTitle: 'Ratings',
        originalUserRole:
            widget.originalUserRole ?? _getOriginalUserRole(widget.userRole),
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
                      fontSize: 48,
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
