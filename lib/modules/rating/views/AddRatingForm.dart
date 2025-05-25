import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddRatingFormPage extends StatefulWidget {
  final String initials;
  final String name;
  final String role;
  final double? initialRating;
  final String? initialReview;
  final Map<String, dynamic>? userData;

  const AddRatingFormPage({
    super.key,
    required this.initials,
    required this.name,
    required this.role,
    this.initialRating,
    this.initialReview,
    this.userData,
  });

  @override
  State<AddRatingFormPage> createState() => _RatingFormPageState();
}

class _RatingFormPageState extends State<AddRatingFormPage> {
  double _rating = 4.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 4.0;
    _reviewController.text = widget.initialReview ?? '';
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || widget.userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Unable to submit rating. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create the rating document
      final ratingData = {
        'reviewerId': currentUser.uid,
        'ratedUserId': widget.userData!['uid'],
        'rating': _rating,
        'comment': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewerRole':
            currentUser.uid == widget.userData!['uid']
                ? 'workshop_owner'
                : 'foreman',
        'ratedUserRole': widget.userData!['role'],
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('ratings').add(ratingData);

      // Return the rating data to the previous screen
      if (mounted) {
        Navigator.pop(context, {
          'initials': widget.initials,
          'name': widget.name,
          'date': DateTime.now().toString().split(' ')[0],
          'rating': _rating,
          'review': _reviewController.text,
          'uid': widget.userData!['uid'],
        });
      }
    } catch (e) {
      print('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error submitting rating. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        widget.role == 'Workshop'
            ? const Color(0xFF2FB668)
            : const Color(0xFF4260DB);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Write A Review"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    widget.initials,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.role == 'Workshop' ? 'Workshop Owner' : 'Foreman',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                _buildStarRating(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Review',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        "Share your experience working with this ${widget.role.toLowerCase()}...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Rating Policy",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• Be honest and fair in your assessment"),
                    Text("• Focus on your personal experience"),
                    Text("• Reviews will be publicly visible"),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text("Submit Review"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
