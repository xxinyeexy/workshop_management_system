import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workshop_management_system/modules/rating/views/EditRatingForm.dart';
import 'package:workshop_management_system/modules/rating/views/AddRatingForm.dart';
import 'package:workshop_management_system/modules/schedule/views/schedule.dart'; // RatingService

class RatingListPage extends StatefulWidget {
  final String userRole; // 'foreman' or 'workshop'
  final String userName;
  final String workshopName;
  final List<Map<String, dynamic>> toRateList;
  final List<Map<String, dynamic>> myReviewsList;

  const RatingListPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.workshopName,
    this.toRateList = const [],
    this.myReviewsList = const [],
  });

  @override
  State<RatingListPage> createState() => _RatingListPageState();
}

class _RatingListPageState extends State<RatingListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, dynamic>> toRateItems;
  List<Map<String, dynamic>> myReviews = [];
  late String _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCategory = widget.userRole == 'foreman' ? 'Workshops' : 'Foremen';
    toRateItems = List<Map<String, dynamic>>.from(widget.toRateList);
    _loadPendingRatings();
    _loadMyReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPendingRatings() {
    final pendingRatings = RatingService().getPendingRatingsForUser(
      widget.userRole,
      widget.userName,
      widget.workshopName,
    );
    setState(() {
      for (final pending in pendingRatings) {
        final exists = toRateItems.any(
          (item) =>
              item['contractId'] == pending['contractId'] ||
              (item['name'] == pending['name'] && item['initials'] == pending['initials']),
        );
        if (!exists) {
          toRateItems.add(pending);
        }
      }
    });
  }

  Future<void> _loadMyReviews() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final givenRatingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('reviewerId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final receivedRatingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('ratedUserId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> loadedReviews = [];

      for (var doc in givenRatingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(data['ratedUserId']).get();
        if (!userDoc.exists || userDoc.data() == null) continue;

        Timestamp ts = data['createdAt'] as Timestamp;
        loadedReviews.add({
          'initials': _getInitials(userDoc['fullName']),
          'name': userDoc['fullName'],
          'date': _formatDate(ts),
          'rating': data['rating'],
          'review': data['comment'],
          'uid': data['ratedUserId'],
          'documentId': doc.id,
          'type': 'given',
          'reviewerRole': data['reviewerRole'],
          'ratedUserRole': data['ratedUserRole'],
        });
      }

      for (var doc in receivedRatingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        var reviewerDoc = await FirebaseFirestore.instance.collection('users').doc(data['reviewerId']).get();
        if (!reviewerDoc.exists || reviewerDoc.data() == null) continue;

        Timestamp ts = data['createdAt'] as Timestamp;
        loadedReviews.add({
          'initials': _getInitials(reviewerDoc['fullName']),
          'name': reviewerDoc['fullName'],
          'date': _formatDate(ts),
          'rating': data['rating'],
          'review': data['comment'],
          'uid': data['reviewerId'],
          'documentId': doc.id,
          'type': 'received',
          'reviewerRole': data['reviewerRole'],
          'ratedUserRole': data['ratedUserRole'],
        });
      }

      if (mounted) {
        setState(() {
          myReviews = loadedReviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Review loading error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String fullName) {
    List<String> parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatDate(Timestamp timestamp) {
    final d = timestamp.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  Color get _primaryColor => widget.userRole == 'foreman' ? const Color(0xFF2FB668) : const Color(0xFF4260DB);

  Widget _buildCategoryChip() {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8),
      child: Chip(
        label: Text(_selectedCategory, style: const TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(bool isToRate) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isToRate ? Icons.star_outline : Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isToRate ? 'No pending ratings' : 'No rating history',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              isToRate
                  ? 'When contracts are completed or terminated, rating requests will appear here.'
                  : 'Your completed ratings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToRateCard(Map<String, dynamic> item) {
    final bool isTerminated = item.containsKey('contractId');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: Colors.grey[300], child: Text(item['initials'])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    isTerminated
                        ? 'Contract terminated on ${item['date']}'
                        : 'Service completed on ${item['date']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ]),
              ),
              if (isTerminated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12)),
                  child: Text('Contract End', style: TextStyle(fontSize: 10, color: Colors.orange[700])),
                ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTerminated ? Colors.orange[50] : Colors.yellow[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                if (isTerminated) Icon(Icons.handshake_outlined, size: 16, color: Colors.orange[700]),
                if (isTerminated) const SizedBox(width: 8),
                Expanded(child: Text(item['message'] ?? '')),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final newReview = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddRatingFormPage(
                          initials: item['initials'],
                          name: item['name'],
                          role: widget.userRole == 'foreman' ? 'Workshop' : 'Foreman',
                          userData: {
                            'uid': item['uid'],
                            'fullName': item['name'],
                            'role': widget.userRole == 'foreman' ? 'workshop_owner' : 'foreman',
                          },
                        ),
                      ),
                    );
                    if (newReview != null) {
                      setState(() {
                        myReviews.add(newReview);
                        toRateItems.remove(item);
                        if (isTerminated) RatingService().removePendingRating(item);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTerminated
                              ? 'Rating submitted for terminated contract'
                              : 'Rating submitted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Rate Now", style: TextStyle(color: Colors.white)),
                ),
              ),
              if (isTerminated) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Skip Rating'),
                        content: const Text('Skip rating this partner? You can rate them later.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                toRateItems.remove(item);
                                RatingService().removePendingRating(item);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rating skipped')),
                              );
                            },
                            child: const Text('Skip'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Skip"),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReviewCard(Map<String, dynamic> review) {
    final isGiven = review['type'] == 'given';
    final role = isGiven
        ? (review['ratedUserRole'] == 'workshop_owner' ? 'Workshop' : 'Foreman')
        : (review['reviewerRole'] == 'workshop_owner' ? 'Workshop' : 'Foreman');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: Colors.grey[300], child: Text(review['initials'])),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(review['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$role • ${isGiven ? "Given" : "Received"} on ${review['date']}',
                    style: TextStyle(color: isGiven ? Colors.blue : Colors.green, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) {
            return Icon(
              i < review['rating'] ? Icons.star : Icons.star_border,
              size: 20,
              color: Colors.orange[700],
            );
          })),
          const SizedBox(height: 8),
          Text(review['review']),
          if (isGiven)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditRatingFormPage(
                        initials: review['initials'],
                        name: review['name'],
                        role: role,
                        initialRating: review['rating'],
                        initialReview: review['review'],
                      ),
                    ),
                  );
                  if (updated != null) {
                    await FirebaseFirestore.instance.collection('ratings').doc(review['documentId']).update({
                      'rating': updated['rating'],
                      'comment': updated['review'],
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    _loadMyReviews();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review updated'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text("Edit Review"),
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reviews"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPendingRatings();
              _loadMyReviews();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Refreshing ratings...")),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _primaryColor,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("To Rate"),
                          if (toRateItems.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Text('${toRateItems.length}',
                                  style: const TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Rating History"),
                          if (myReviews.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: _primaryColor,
                              child: Text('${myReviews.length}',
                                  style: const TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryChip(),
                          Expanded(
                            child: toRateItems.isEmpty
                                ? _buildEmptyState(true)
                                : ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: toRateItems.map(_buildToRateCard).toList(),
                                  ),
                          ),
                        ],
                      ),
                      myReviews.isEmpty
                          ? _buildEmptyState(false)
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: myReviews.map(_buildMyReviewCard).toList(),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
