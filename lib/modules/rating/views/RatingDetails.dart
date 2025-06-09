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
  int totalReviews = 0; // Reviews with comments
  Map<int, int> starDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<Map<String, dynamic>> reviewsWithComments = []; // Only received reviews with comments

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userData != null) {
      String userId = widget.userData!['uid'];
      String userName = widget.userData!['name'] ?? widget.name;
      _fetchRatingData(userId, userName);
    }
  }

  // Fetch rating data from Firestore
  Future<void> _fetchRatingData(String userId, String userName) async {
    if (widget.userData == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      print('Fetching ratings for user: $userId, name: $userName');

      List<QuerySnapshot> queries = [];

      // Try searching by userId first
      try {
        queries.add(await FirebaseFirestore.instance
            .collection('ratings')
            .where('ratedUserId', isEqualTo: userId)
            .get());
      } catch (e) {
        print('Query with ratedUserId failed: $e');
      }

      // Try searching by user name (since ratedUserId is null in your data)
      try {
        queries.add(await FirebaseFirestore.instance
            .collection('ratings')
            .where('ratedUserName', isEqualTo: userName)
            .get());
      } catch (e) {
        print('Query with ratedUserName failed: $e');
      }

      // Try alternative name field
      try {
        queries.add(await FirebaseFirestore.instance
            .collection('ratings')
            .where('ratedUserName', isEqualTo: widget.name)
            .get());
      } catch (e) {
        print('Query with widget.name failed: $e');
      }

      // Get all ratings and filter manually (fallback)
      try {
        final allRatings = await FirebaseFirestore.instance
            .collection('ratings')
            .get();

        // Filter documents where this user was rated
        final filteredDocs = allRatings.docs.where((doc) {
          final data = doc.data();
          return data['ratedUserName'] == userName ||
              data['ratedUserName'] == widget.name ||
              data['ratedUserId'] == userId;
        }).toList();

        // Create a mock QuerySnapshot with filtered documents
        if (filteredDocs.isNotEmpty) {
          queries.add(allRatings); // We'll filter later
        }
      } catch (e) {
        print('Fallback query failed: $e');
      }

      // Combine all results and remove duplicates
      Set<String> processedIds = {};
      List<QueryDocumentSnapshot> allDocs = [];

      for (var query in queries) {
        for (var doc in query.docs) {
          if (!processedIds.contains(doc.id)) {
            final data = doc.data() as Map<String, dynamic>;

            // Check if this document is for our user (since we might have gotten all docs)
            bool isForThisUser = data['ratedUserName'] == userName ||
                data['ratedUserName'] == widget.name ||
                data['ratedUserId'] == userId;

            if (isForThisUser) {
              allDocs.add(doc);
              processedIds.add(doc.id);
            }
          }
        }
      }

      print('Total received ratings found: ${allDocs.length}');

      List<Map<String, dynamic>> tempReviewsWithComments = [];
      Map<int, int> tempStarDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      double totalRatingSum = 0.0;
      int ratingsCount = 0;
      int reviewsCount = 0;

      // Process ONLY RECEIVED ratings (ratings given TO this user by others)
      for (var doc in allDocs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Processing received rating document: ${doc.id}');
        print('Document data: ${data}');

        int rating = 0;
        if (data['rating'] != null) {
          if (data['rating'] is int) {
            rating = data['rating'];
          } else if (data['rating'] is double) {
            rating = data['rating'].toInt();
          } else if (data['rating'] is String) {
            rating = int.tryParse(data['rating']) ?? 0;
          }
        }

        print('Extracted rating: $rating');

        if (rating >= 1 && rating <= 5) {
          // Count for average calculation and star distribution
          tempStarDistribution[rating] = (tempStarDistribution[rating] ?? 0) + 1;
          totalRatingSum += rating;
          ratingsCount++;

          // Get reviewer info (the person who gave the rating) - try different field name variations
          String reviewerName = data['reviewerName'] ??
              data['raterName'] ??
              data['fromUserName'] ??
              data['givenByName'] ??
              'Anonymous';
          String reviewerRole = data['reviewerRole'] ??
              data['raterRole'] ??
              data['fromUserRole'] ??
              data['givenByRole'] ??
              '';
          String comment = (data['comment'] ??
                  data['review'] ??
                  data['reviewText'] ??
                  data['feedback'] ??
                  '')
              .toString()
              .trim();

          print('Reviewer: $reviewerName, Role: $reviewerRole, Comment: $comment');

          // Add to reviews regardless of comment (for now, to see all data)
          Map<String, dynamic> ratingData = {
            ...data,
            'documentId': doc.id,
            'reviewerName': reviewerName,
            'reviewerRole': reviewerRole,
            'comment': comment,
            'rating': rating,
            'date': _formatDate(data['createdAt'] as Timestamp? ?? data['timestamp'] as Timestamp?),
            'rawDate': data['createdAt'] as Timestamp? ?? data['timestamp'] as Timestamp? ?? Timestamp.now(),
          };

          // Only add to reviews if there's a comment
          if (comment.isNotEmpty) {
            tempReviewsWithComments.add(ratingData);
            reviewsCount++;
          }
        } else {
          print('Invalid rating value: $rating');
        }
      }

      // Calculate average rating from all received ratings
      double avgRating = ratingsCount > 0 ? totalRatingSum / ratingsCount : 0.0;

      print('Final calculations:');
      print('Total ratings count: $ratingsCount');
      print('Reviews with comments: $reviewsCount');
      print('Average rating: $avgRating');
      print('Star distribution: $tempStarDistribution');
      print('All documents found: ${allDocs.length}');

      // Sort reviews with comments by date (most recent first)
      tempReviewsWithComments.sort((a, b) {
        final aTime = a['rawDate'] as Timestamp?;
        final bTime = b['rawDate'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Most recent first
      });

      setState(() {
        averageRating = avgRating;
        totalRatings = ratingsCount;
        totalReviews = reviewsCount;
        starDistribution = tempStarDistribution;
        reviewsWithComments = tempReviewsWithComments;
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

  // Sorting helper
  void _sortReviews() {
    setState(() {
      switch (sortBy) {
        case 'Most Recent':
          reviewsWithComments.sort((a, b) {
            Timestamp aTime = a['rawDate'] ?? Timestamp.now();
            Timestamp bTime = b['rawDate'] ?? Timestamp.now();
            return bTime.compareTo(aTime);
          });
          break;
        case 'Highest Rated':
          reviewsWithComments.sort((a, b) => b['rating'].compareTo(a['rating']));
          break;
        case 'Lowest Rated':
          reviewsWithComments.sort((a, b) => a['rating'].compareTo(b['rating']));
          break;
      }
    });
  }

  // Convert role to display format
  String _getDisplayRole(String role) {
    switch (role.toLowerCase()) {
      case 'foreman':
        return 'Foreman';
      case 'workshop_owner':
        return 'Workshop Owner';
      case 'workshopowner':
        return 'Workshop Owner';
      default:
        return role.isNotEmpty ? role : 'User';
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
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }

  // Method for building Summary Card
  Widget _buildSummaryCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                totalRatings > 0 ? averageRating.toStringAsFixed(1) : '0.0',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 20,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  Text(
                    '$totalRatings ratings',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            int star = 5 - index;
            int count = starDistribution[star] ?? 0;
            double percentage = totalRatings > 0 ? count / totalRatings : 0.0;
            int percentDisplay = (percentage * 100).round();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('$star', style: const TextStyle(fontSize: 14)),
                  const Icon(Icons.star, size: 14, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$percentDisplay%', style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Method for building Sort Dropdown
  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: sortBy,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                sortBy = newValue;
                _sortReviews();
              });
            }
          },
          items: <String>[
            'Most Recent',
            'Highest Rated',
            'Lowest Rated',
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Method for building Review Card
  Widget _buildReviewCard(Map<String, dynamic> review, Color primaryColor) {
    final String reviewerName = review['reviewerName'] ?? 'Anonymous';
    final String reviewerRole = review['reviewerRole'] ?? '';
    final String comment = review['comment'] ?? '';
    final int rating = review['rating'] ?? 0;
    final String date = review['date'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    _getInitials(reviewerName),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_getDisplayRole(reviewerRole)} • $date',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  size: 18,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(comment, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'Helpful (12)',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method to get initials from a name
  String _getInitials(String name) {
    if (name.isEmpty) return 'A';
    List<String> words = name.split(' ');
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.role.toLowerCase().contains('foreman')
        ? const Color(0xFF2FB668)
        : const Color(0xFF4260DB);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rate & Review",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Card
                _buildProfileCard(primaryColor),
                const SizedBox(height: 16),
                // Summary Card
                _buildSummaryCard(primaryColor),
                const SizedBox(height: 16),
                // Reviews Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalReviews reviews found',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    _buildSortDropdown(),
                  ],
                ),
                const SizedBox(height: 8),
                // Reviews List
                if (reviewsWithComments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No reviews yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...reviewsWithComments.map(
                    (review) => _buildReviewCard(review, primaryColor),
                  ),
              ],
            ),
    );
  }

  Widget _buildProfileCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            child: Text(
              widget.initials,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(_getDisplayRole(widget.role),
                     style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < averageRating.floor()
                            ? Icons.star
                            : (index < averageRating.ceil() && averageRating % 1 != 0)
                                ? Icons.star_half
                                : Icons.star_border,
                        size: 16,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      totalRatings > 0
                          ? '(${averageRating.toStringAsFixed(1)} from $totalRatings reviews)'
                          : '(0.0 from 0 reviews)',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
