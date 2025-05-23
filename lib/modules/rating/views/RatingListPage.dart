import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/rating/views/EditRatingForm.dart';
import 'package:workshop_management_system/modules/rating/views/AddRatingForm.dart';

class RatingListPage extends StatefulWidget {
  final String userRole; // 'foreman' or 'workshop'
  final List<Map<String, dynamic>> toRateList;
  final List<Map<String, dynamic>> myReviewsList;

  const RatingListPage({
    super.key,
    required this.userRole,
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

    // Initialize data from constructor params
    toRateItems = List<Map<String, dynamic>>.from(widget.toRateList);
    myReviews = List<Map<String, dynamic>>.from(widget.myReviewsList);
  }

  Color get _primaryColor {
    return widget.userRole == 'foreman' ? const Color(0xFF2FB668) : const Color(0xFF4260DB);
  }

  Widget _buildToRateCard(Map<String, dynamic> item) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text("Service completed on ${item['date']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item['message']),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
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
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Rate Now", style: TextStyle(color: Colors.white)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text("Reviewed on ${review['date']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reviews"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
            tabs: const [
              Tab(text: "To Rate"),
              Tab(text: "Rating History"),
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
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: toRateItems.map((item) => _buildToRateCard(item)).toList(),
                      ),
                    ),
                  ],
                ),
                ListView(
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