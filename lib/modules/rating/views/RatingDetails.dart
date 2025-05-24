import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingDetailPage extends StatefulWidget {
  final String initials;
  final String name;
  final String role; // e.g. "Foreman" or "Workshop Owner"
  final Map<String, dynamic>? userData; // User data from Firestore

  const RatingDetailPage({
    super.key,
    required this.initials,
    required this.name,
    required this.role,
    this.userData,
  });

  @override
  State<RatingDetailPage> createState() => _RatingDetailPageState();
}

class _RatingDetailPageState extends State<RatingDetailPage> {
  String sortBy = 'Most Recent';
  bool isLoading = true;

  // Rating data
  double averageRating = 0.0;
  int totalRatings = 0;
  Map<int, int> starDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchRatingData();
  }

  // Fetch rating data from Firestore
  Future<void> _fetchRatingData() async {
    if (widget.userData == null) return;
    
    try {
      setState(() {
        isLoading = true;
      });

      String userId = widget.userData!['uid'];
      
      // Fetch ratings for this user
      QuerySnapshot ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> tempReviews = [];
      Map<int, int> tempStarDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      double totalRatingSum = 0.0;
      int count = ratingsSnapshot.docs.length;

      for (QueryDocumentSnapshot doc in ratingsSnapshot.docs) {
        Map<String, dynamic> ratingData = doc.data() as Map<String, dynamic>;
        
        // Add to star distribution
        int rating = ratingData['rating'] ?? 0;
        if (rating >= 1 && rating <= 5) {
          tempStarDistribution[rating] = tempStarDistribution[rating]! + 1;
          totalRatingSum += rating;
        }

        // Fetch reviewer information
        Map<String, dynamic> reviewerData = await _getReviewerData(ratingData['reviewerId']);
        
        tempReviews.add({
          'reviewerId': ratingData['reviewerId'],
          'reviewerName': reviewerData['fullName'] ?? 'Anonymous',
          'reviewerRole': _getDisplayRole(reviewerData['role'] ?? ''),
          'rating': rating,
          'comment': ratingData['comment'] ?? '',
          'date': _formatDate(ratingData['createdAt']),
          'likes': ratingData['likes'] ?? 0,
          'rawDate': ratingData['createdAt'] ?? Timestamp.now(),
        });
      }

      // Calculate average rating
      double avgRating = count > 0 ? totalRatingSum / count : 0.0;

      // Convert star distribution to percentages
      Map<int, int> percentageDistribution = {};
      for (int star = 1; star <= 5; star++) {
        int starCount = tempStarDistribution[star] ?? 0;
        percentageDistribution[star] = count > 0 ? ((starCount / count) * 100).round() : 0;
      }

      setState(() {
        averageRating = avgRating;
        totalRatings = count;
        starDistribution = percentageDistribution;
        reviews = tempReviews;
        isLoading = false;
      });

      _sortReviews();
    } catch (e) {
      print('Error fetching rating data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Get reviewer data from Firestore
  Future<Map<String, dynamic>> _getReviewerData(String reviewerId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reviewerId)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching reviewer data: $e');
    }
    return {};
  }

  // Convert role to display format
  String _getDisplayRole(String role) {
    switch (role) {
      case 'foreman':
        return 'Foreman';
      case 'workshop_owner':
        return 'Workshop Owner';
      default:
        return 'User';
    }
  }

  // Format timestamp to readable date
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Unknown date';
      }

      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }

  // Sorting helper
  void _sortReviews() {
    setState(() {
      switch (sortBy) {
        case 'Most Recent':
          reviews.sort((a, b) {
            Timestamp aTime = a['rawDate'] ?? Timestamp.now();
            Timestamp bTime = b['rawDate'] ?? Timestamp.now();
            return bTime.compareTo(aTime);
          });
          break;
        case 'Highest Rated':
          reviews.sort((a, b) => b['rating'].compareTo(a['rating']));
          break;
        case 'Lowest Rated':
          reviews.sort((a, b) => a['rating'].compareTo(b['rating']));
          break;
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    // Theme colours: green for foreman, blue for workshop owner
    final bool isForeman = widget.role.toLowerCase().contains('foreman');
    final Color primaryColor = isForeman
        ? const Color(0xFF2FB668) // green
        : const Color(0xFF4260DB); // blue

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rate & Review",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          widget.initials,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.role,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            // No contact information shown for either role
                            const SizedBox(height: 4),
                            if (totalRatings > 0) ...[
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < averageRating.floor()
                                          ? Icons.star
                                          : index < averageRating
                                              ? Icons.star_half
                                              : Icons.star_border,
                                      size: 16,
                                      color: Colors.orange,
                                    );
                                  }),
                                  const SizedBox(width: 6),
                                  Text(
                                    "(${averageRating.toStringAsFixed(1)}/5 from $totalRatings reviews)",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const Text(
                                "No ratings yet",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Summary box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Summary",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (totalRatings > 0) ...[
                        Row(
                          children: [
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < averageRating.floor()
                                          ? Icons.star
                                          : index < averageRating
                                              ? Icons.star_half
                                              : Icons.star_border,
                                      size: 16,
                                      color: Colors.orange,
                                    );
                                  }),
                                ),
                                Text(
                                  "$totalRatings ratings",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...starDistribution.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text("${e.key}"),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: e.value / 100,
                                    color: Colors.orange,
                                    backgroundColor: Colors.grey[200],
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${e.value}%",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else ...[
                        const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.star_border,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "No ratings yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Be the first to rate this user!",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Review list header
                if (reviews.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${reviews.length} reviews found",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: sortBy,
                            icon: const Icon(Icons.arrow_drop_down),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  sortBy = newValue;
                                });
                                _sortReviews();
                              }
                            },
                            items: <String>['Most Recent', 'Highest Rated', 'Lowest Rated']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Reviews list
                  ...reviews.map((review) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review['reviewerName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      review['reviewerRole'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                review['date'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < review['rating']
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.orange,
                              );
                            }),
                          ),
                          if (review['comment'].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              review['comment'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                          if (review['likes'] > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.thumb_up,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${review['likes']} helpful",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
    );
  }
}