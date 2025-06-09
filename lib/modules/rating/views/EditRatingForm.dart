import 'package:flutter/material.dart';

class EditRatingFormPage extends StatefulWidget {
  final String initials;
  final String name;
  final String role;
  final double? initialRating;
  final String? initialReview;

  const EditRatingFormPage({
    super.key,
    required this.initials,
    required this.name,
    required this.role,
    this.initialRating,
    this.initialReview,
  });

  @override
  State<EditRatingFormPage> createState() => _RatingFormPageState();
}

class _RatingFormPageState extends State<EditRatingFormPage> {
  double _rating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0.0;
    _reviewController.text = widget.initialReview ?? '';
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
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
        title: const Text("Edit Review"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Senior ${widget.role}',
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
                hintText: "Write your review here",
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final updatedReview = {
                    'initials': widget.initials,
                    'name': widget.name,
                    'date': DateTime.now().toString().substring(0, 10),
                    'rating': _rating,
                    'review': _reviewController.text,
                  };

                  Navigator.pop(context, updatedReview);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
