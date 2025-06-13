import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class RatingDetailPage extends StatefulWidget {
  final String initials;
  final String name;
  final String role;
  final Map<String, dynamic>? userData;

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
  int totalReviews = 0;
  Map<int, int> starDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<Map<String, dynamic>> reviewsWithComments = [];

  // Cache for processed data
  final Map<String, Map<String, dynamic>> _ratingCache = {};

  @override
  void initState() {
    super.initState();

    if (widget.userData != null) {
      String userId = widget.userData!['uid'];
      String userName =
          widget.userData!['fullName'] ??
          widget.userData!['name'] ??
          widget.name;
      _fetchRatingData(userId, userName);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userData != null) {
      String userId = widget.userData!['uid'];
      String userName =
          widget.userData!['fullName'] ??
          widget.userData!['name'] ??
          widget.name;

      // Clear the cache for this user to ensure fresh data fetch
      _ratingCache.remove('$userId-$userName');

      _fetchRatingData(userId, userName);
    }
  }

  Future<void> _fetchRatingData(String userId, String userName) async {
    if (widget.userData == null) return;

    print('DEBUG: _fetchRatingData called for user: $userName ($userId)');

    try {
      setState(() {
        isLoading = true;
      });

      // Check cache first
      String cacheKey = '$userId-$userName';
      if (_ratingCache.containsKey(cacheKey)) {
        final cachedData = _ratingCache[cacheKey]!;
        if (mounted) {
          setState(() {
            averageRating = cachedData['averageRating'];
            totalRatings = cachedData['totalRatings'];
            totalReviews = cachedData['totalReviews'];
            starDistribution = Map<int, int>.from(
              cachedData['starDistribution'],
            );
            reviewsWithComments = List<Map<String, dynamic>>.from(
              cachedData['reviewsWithComments'],
            );
            isLoading = false;
          });
        }
        print('DEBUG: Data loaded from cache for $userName ($userId)');
        return;
      }

      // Single query to get all ratings
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .get(const GetOptions(source: Source.server));

      await _processRatingsData(ratingsSnapshot, userId, userName, cacheKey);
    } catch (e) {
      print('Error fetching rating data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _processRatingsData(
    QuerySnapshot ratingsSnapshot,
    String userId,
    String userName,
    String cacheKey,
  ) async {
    List<Map<String, dynamic>> tempReviewsWithComments = [];
    Map<int, int> tempStarDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double totalRatingSum = 0.0;
    int ratingsCountForAverage = 0;

    print('DEBUG: Starting _processRatingsData for user: $userName ($userId)');
    print('DEBUG: Total documents in snapshot: ${ratingsSnapshot.docs.length}');

    // Process ratings in a single pass
    for (var doc in ratingsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      print('DEBUG: Processing document ID: ${doc.id}, data: $data');

      // Check if this rating is for our user
      bool isForThisUser =
          data['ratedUserName'] == userName ||
          data['ratedUserName'] == widget.name ||
          data['ratedUserId'] == userId;

      if (!isForThisUser) {
        print('DEBUG: Document not for this user, skipping.');
        continue;
      }

      // Extract and validate rating
      dynamic ratingValue = data['rating'];
      double currentRatingDouble = 0.0;
      int currentRatingInt = 0; // For star distribution and display

      if (ratingValue != null) {
        if (ratingValue is int) {
          currentRatingDouble = ratingValue.toDouble();
          currentRatingInt = ratingValue;
        } else if (ratingValue is double) {
          currentRatingDouble = ratingValue;
          currentRatingInt =
              currentRatingDouble.round(); // Round for distribution
        } else if (ratingValue is String) {
          // Attempt to parse as double first, then round to int
          currentRatingDouble = double.tryParse(ratingValue) ?? 0.0;
          currentRatingInt = currentRatingDouble.round();
        }
      }
      print(
        'DEBUG: Rating value: $ratingValue, parsed currentRatingDouble: $currentRatingDouble, currentRatingInt: $currentRatingInt',
      );

      // Only consider valid ratings (1-5) for any calculation
      if (currentRatingDouble >= 1.0 && currentRatingDouble <= 5.0) {
        String comment = _extractComment(data);
        print(
          'DEBUG: Comment extracted: "$comment" (is empty: ${comment.isEmpty})',
        );

        if (comment.isNotEmpty) {
          // Increment counts and sum ONLY if there's a non-empty comment
          tempStarDistribution[currentRatingInt] =
              (tempStarDistribution[currentRatingInt] ?? 0) + 1;
          totalRatingSum += currentRatingDouble;
          ratingsCountForAverage++;
          print(
            'DEBUG: Added to calculation. currentRatingDouble: $currentRatingDouble, totalRatingSum: $totalRatingSum, ratingsCountForAverage: $ratingsCountForAverage',
          );

          Map<String, dynamic> ratingData = {
            'documentId': doc.id,
            'reviewerName': _extractReviewerName(data),
            'reviewerRole': _extractReviewerRole(data),
            'comment': comment,
            'rating': currentRatingDouble, // Store the double for display
            'date': _formatDate(
              data['createdAt'] as Timestamp? ??
                  data['timestamp'] as Timestamp?,
            ),
            'rawDate':
                data['createdAt'] as Timestamp? ??
                data['timestamp'] as Timestamp? ??
                Timestamp.now(),
            'imageBase64': data['imageBase64'],
          };

          tempReviewsWithComments.add(ratingData);
          print(
            'DEBUG: Added to reviewsWithComments. Current length: ${tempReviewsWithComments.length}',
          );
        }
      }
    }

    // Calculate average rating based on reviews with comments
    double avgRating =
        ratingsCountForAverage > 0
            ? totalRatingSum / ratingsCountForAverage
            : 0.0;

    print(
      'DEBUG: Final Calculation - totalRatingSum: $totalRatingSum, ratingsCountForAverage: $ratingsCountForAverage, avgRating: $avgRating',
    );
    print('DEBUG: Final tempStarDistribution: $tempStarDistribution');
    print(
      'DEBUG: Final tempReviewsWithComments length: ${tempReviewsWithComments.length}',
    );
    print(
      'DEBUG: Final tempReviewsWithComments content: $tempReviewsWithComments',
    ); // Print content to verify

    // Sort reviews by date (most recent first)
    tempReviewsWithComments.sort((a, b) {
      final aTime = a['rawDate'] as Timestamp?;
      final bTime = b['rawDate'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    // Cache the processed data
    final processedData = {
      'averageRating': avgRating,
      'totalRatings':
          ratingsCountForAverage, // Total ratings now equals reviews with comments
      'totalReviews': tempReviewsWithComments.length,
      'starDistribution': tempStarDistribution,
      'reviewsWithComments': tempReviewsWithComments,
    };
    _ratingCache[cacheKey] = processedData;

    if (mounted) {
      setState(() {
        averageRating = avgRating;
        totalRatings =
            ratingsCountForAverage; // Update state with consistent count
        totalReviews = tempReviewsWithComments.length;
        starDistribution = Map<int, int>.from(tempStarDistribution);
        reviewsWithComments = List<Map<String, dynamic>>.from(
          tempReviewsWithComments,
        );
        isLoading = false;
        print(
          'DEBUG: State updated. averageRating: $averageRating, totalRatings: $totalRatings, totalReviews: $totalReviews, starDistribution: $starDistribution',
        );
      });
    }
  }

  // Helper methods for data extraction
  int _extractRating(Map<String, dynamic> data) {
    if (data['rating'] == null) return 0;

    if (data['rating'] is int) return data['rating'];
    if (data['rating'] is double) return data['rating'].toInt();
    if (data['rating'] is String) return int.tryParse(data['rating']) ?? 0;

    return 0;
  }

  String _extractReviewerName(Map<String, dynamic> data) {
    return data['reviewerName'] ??
        data['raterName'] ??
        data['fromUserName'] ??
        data['givenByName'] ??
        'Anonymous';
  }

  String _extractReviewerRole(Map<String, dynamic> data) {
    return data['reviewerRole'] ??
        data['raterRole'] ??
        data['fromUserRole'] ??
        data['givenByRole'] ??
        '';
  }

  String _extractComment(Map<String, dynamic> data) {
    return (data['comment'] ??
            data['review'] ??
            data['reviewText'] ??
            data['feedback'] ??
            '')
        .toString()
        .trim();
  }

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
          reviewsWithComments.sort(
            (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
          );
          break;
        case 'Lowest Rated':
          reviewsWithComments.sort(
            (a, b) => (a['rating'] as double).compareTo(b['rating'] as double),
          );
          break;
      }
    });
  }

  String _getDisplayRole(String role) {
    switch (role.toLowerCase()) {
      case 'foreman':
        return 'Foreman';
      case 'workshop_owner':
      case 'workshopowner':
        return 'Workshop Owner';
      default:
        return role.isNotEmpty ? role : 'User';
    }
  }

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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    '$totalReviews ratings',
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
            double percentage = totalReviews > 0 ? count / totalReviews : 0.0;
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentDisplay%',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

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
          items:
              <String>[
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

  Widget _buildReviewCard(Map<String, dynamic> review, Color primaryColor) {
    final String reviewerName = review['reviewerName'] ?? 'Anonymous';
    final String reviewerRole = review['reviewerRole'] ?? '';
    final String comment = review['comment'] ?? '';
    final double rating = review['rating'] as double; // Cast to double
    final String date = review['date'] ?? '';
    final String? imageBase64 = review['imageBase64'];

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
                  i < rating.floor()
                      ? Icons.star
                      : (i < rating.ceil() && rating % 1 != 0)
                      ? Icons.star_half
                      : Icons.star_border,
                  size: 18,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(comment, style: const TextStyle(fontSize: 14)),
            if (imageBase64 != null && imageBase64.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(imageBase64),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'A';
    List<String> words = name.split(' ');
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
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
                Text(
                  _getDisplayRole(widget.role),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < averageRating.floor()
                            ? Icons.star
                            : (index < averageRating.ceil() &&
                                averageRating % 1 != 0)
                            ? Icons.star_half
                            : Icons.star_border,
                        size: 16,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      totalReviews > 0
                          ? '(${averageRating.toStringAsFixed(1)} from $totalReviews reviews)'
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

  Future<void> _refreshData() async {
    if (widget.userData != null) {
      setState(() {
        isLoading = true;
      });

      String userId = widget.userData!['uid'];
      String userName =
          widget.userData!['fullName'] ??
          widget.userData!['name'] ??
          widget.name;

      // Clear the cache and fetch fresh data
      _ratingCache.remove('$userId-$userName');
      await _fetchRatingData(userId, userName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        widget.role.toLowerCase().contains('foreman')
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildProfileCard(primaryColor),
                    const SizedBox(height: 16),
                    _buildSummaryCard(primaryColor),
                    const SizedBox(height: 16),
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
      ),
    );
  }
}
