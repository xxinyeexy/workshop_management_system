import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/rating/views/EditRatingForm.dart';
import 'package:workshop_management_system/modules/rating/views/AddRatingForm.dart';
import 'package:workshop_management_system/modules/schedule/views/schedule.dart'; // Import RatingService

class RatingListPage extends StatefulWidget {
  final String userRole; // 'foreman' or 'workshop'
  final String userName; // logged-in user name
  final String workshopName; // logged-in user’s workshop name
  final List<Map<String, dynamic>> toRateList;
  final List<Map<String, dynamic>> myReviewsList;

  const RatingListPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.workshopName,
    required this.toRateList,
    this.myReviewsList = const [],
  });

  @override
  State<RatingListPage> createState() => _RatingListPageState();
}

class _RatingListPageState extends State<RatingListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, dynamic>> toRateItems;
  late List<Map<String, dynamic>> myReviews;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCategory = widget.userRole == 'foreman' ? 'Workshops' : 'Foremen';

    toRateItems = List<Map<String, dynamic>>.from(widget.toRateList);
    myReviews = List<Map<String, dynamic>>.from(widget.myReviewsList);

    _loadPendingRatings();
  }

  void _loadPendingRatings() {
    final pendingRatings = RatingService().getPendingRatingsForUser(
      widget.userRole,
      widget.userName,
      widget.workshopName,
    );
    setState(() {
      for (final pending in pendingRatings) {
        final exists = toRateItems.any((item) =>
            item['contractId'] == pending['contractId'] ||
            (item['name'] == pending['name'] && item['initials'] == pending['initials']));
        if (!exists) {
          toRateItems.add(pending);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPendingRatings();
  }

  Color get _primaryColor {
    return widget.userRole == 'foreman' ? const Color(0xFF2FB668) : const Color(0xFF4260DB);
  }

  Widget _buildToRateCard(Map<String, dynamic> item) {
    final bool isFromTerminatedContract = item.containsKey('contractId');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(item['initials'], style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(
                        isFromTerminatedContract
                            ? "Contract terminated on ${item['date']}"
                            : "Service completed on ${item['date']}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isFromTerminatedContract)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Contract End',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromTerminatedContract ? Colors.orange[50] : Colors.yellow[100],
                borderRadius: BorderRadius.circular(8),
                border: isFromTerminatedContract ? Border.all(color: Colors.orange[200]!) : null,
              ),
              child: Row(
                children: [
                  if (isFromTerminatedContract)
                    Icon(
                      Icons.handshake_outlined,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                  if (isFromTerminatedContract) const SizedBox(width: 8),
                  Expanded(child: Text(item['message'])),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newReview = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRatingFormPage(
                            initials: item['initials'],
                            name: item['name'],
                            role: widget.userRole == 'foreman' ? "Workshop" : "Foreman",
                          ),
                        ),
                      );

                      if (newReview != null) {
                        setState(() {
                          myReviews.add(newReview);
                          toRateItems.remove(item);

                          if (isFromTerminatedContract) {
                            RatingService().removePendingRating(item);
                          }
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                isFromTerminatedContract
                                    ? 'Rating submitted for terminated contract'
                                    : 'Rating submitted successfully'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text("Rate Now", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                if (isFromTerminatedContract) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Skip Rating'),
                          content: const Text(
                            'Are you sure you want to skip rating this partner? You can still rate them later if needed.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  toRateItems.remove(item);
                                  RatingService().removePendingRating(item);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rating skipped'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text('Skip'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReviewCard(Map<String, dynamic> review) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(review['initials'], style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text("Reviewed on ${review['date']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (review.containsKey('contractTerminated') && review['contractTerminated'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Contract End',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                double rating = review['rating'];
                return Icon(
                  index < rating.floor()
                      ? Icons.star
                      : index < rating
                          ? Icons.star_half
                          : Icons.star_border,
                  size: 20,
                  color: Colors.orange[700],
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(review['review']),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final updatedReview = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditRatingFormPage(
                        initials: review['initials'],
                        name: review['name'],
                        role: widget.userRole == 'foreman' ? 'Workshop' : 'Foreman',
                        initialRating: review['rating'],
                        initialReview: review['review'],
                      ),
                    ),
                  );

                  if (updatedReview != null) {
                    setState(() {
                      final index = myReviews.indexWhere((r) =>
                          r['initials'] == updatedReview['initials'] &&
                          r['name'] == updatedReview['name']);
                      if (index != -1) {
                        myReviews[index] = updatedReview;
                      }
                    });
                  }
                },
                child: const Text("Edit Review"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8),
      child: Chip(
        backgroundColor: _primaryColor,
        label: Text(_selectedCategory, style: const TextStyle(color: Colors.white)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState(bool isToRate) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isToRate ? Icons.star_outline : Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isToRate ? 'No pending ratings' : 'No rating history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isToRate
                  ? 'When contracts are completed or terminated, rating requests will appear here.'
                  : 'Your completed ratings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPendingRatings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshed pending ratings'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: _primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _primaryColor,
            indicatorWeight: 2,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("To Rate"),
                    if (toRateItems.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${toRateItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${myReviews.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                              children: toRateItems.map((item) => _buildToRateCard(item)).toList(),
                            ),
                    ),
                  ],
                ),
                myReviews.isEmpty
                    ? _buildEmptyState(false)
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: myReviews.map((review) => _buildMyReviewCard(review)).toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
