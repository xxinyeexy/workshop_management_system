import 'package:flutter/material.dart';

class RatingDetailPage extends StatefulWidget {
  final String initials;
  final String name;
  final String role;          // e.g. "Senior Foreman" or "Auto Repair Specialist"

  const RatingDetailPage({
    super.key,
    required this.initials,
    required this.name,
    required this.role,
  });

  @override
  State<RatingDetailPage> createState() => _RatingDetailPageState();
}

class _RatingDetailPageState extends State<RatingDetailPage> {
  String sortBy = 'Most Recent';

  // ---------------------------------------------------------------------------
  // Demo data (swap for Firestore later)
  // ---------------------------------------------------------------------------
  final double averageRating = 4.5;
  final int totalRatings = 273;
  final Map<int, int> starDistribution = {5: 70, 4: 18, 3: 7, 2: 3, 1: 2};

  List<Map<String, dynamic>> reviews = [
    {
      "name": "Jane Smith",
      "position": "ABC Workshop Owner",
      "date": "March 15, 2025",
      "rating": 5,
      "comment":
          "This foreman has been exceptional! Very professional, always on time, and finished the work ahead of schedule. Would definitely recommend to other workshop owners.",
      "likes": 12,
    },
    {
      "name": "Bob Lee",
      "position": "XYZ Workshop Owner",
      "date": "March 10, 2025",
      "rating": 4,
      "comment": "Good work overall, just a bit slow on delivery.",
      "likes": 5,
    },
    {
      "name": "Alice Tan",
      "position": "LMN Workshop Owner",
      "date": "March 01, 2025",
      "rating": 3,
      "comment": "Average performance. Could improve communication.",
      "likes": 3,
    },
  ];

  // ---------------------------------------------------------------------------
  // Sorting helper
  // ---------------------------------------------------------------------------
  void _sortReviews() {
    setState(() {
      switch (sortBy) {
        case 'Most Recent':
          reviews.sort((a, b) => b['date'].compareTo(a['date']));
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
  void initState() {
    super.initState();
    _sortReviews();
  }

  @override
  Widget build(BuildContext context) {
    // -----------------------------------------------------------------------
    // Theme colours: emerald for the sleeves‑rolled‑up foreman,
    // cobalt for the proud workshop owner.
    // -----------------------------------------------------------------------
    final bool isForeman =
        widget.role.toLowerCase().contains('foreman');          // true → foreman
    final Color primaryColor = isForeman
        ? const Color(0xFF4260DB)                               // emerald green
        : const Color(0xFF2FB668);                              // royal blue

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rate & Review",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -----------------------------------------------------------------
          // Profile card
          // -----------------------------------------------------------------
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(widget.role,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.star, size: 16, color: Colors.orange),
                        Icon(Icons.star, size: 16, color: Colors.orange),
                        Icon(Icons.star, size: 16, color: Colors.orange),
                        Icon(Icons.star, size: 16, color: Colors.orange),
                        Icon(Icons.star_half, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          "(4.2/5 from 28 reviews)",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -----------------------------------------------------------------
          // Summary box
          // -----------------------------------------------------------------
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
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
                          children: const [
                            Icon(Icons.star,
                                size: 16, color: Colors.orange),
                            Icon(Icons.star,
                                size: 16, color: Colors.orange),
                            Icon(Icons.star,
                                size: 16, color: Colors.orange),
                            Icon(Icons.star,
                                size: 16, color: Colors.orange),
                            Icon(Icons.star_half,
                                size: 16, color: Colors.orange),
                          ],
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
                        const Icon(Icons.star,
                            size: 14, color: Colors.orange),
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
                        Text("${e.value}%",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // Write review button
          // -----------------------------------------------------------------
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/rate',
                  arguments: {
                    'initials': widget.initials,
                    'name': widget.name,
                    'role': widget.role,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: primaryColor,
              ),
              child: const Text("Write a Review"),
            ),
          ),

          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // Review list header
          // -----------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${reviews.length} reviews found",
                  style: const TextStyle(fontWeight: FontWeight.w500)),
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
                    icon: const Icon(Icons.filter_list, color: Colors.grey),
                    items: const [
                      DropdownMenuItem(
                          value: 'Most Recent', child: Text('Most Recent')),
                      DropdownMenuItem(
                          value: 'Highest Rated',
                          child: Text('Highest Rated')),
                      DropdownMenuItem(
                          value: 'Lowest Rated', child: Text('Lowest Rated')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          sortBy = value;
                          _sortReviews();
                        });
                      }
                    },
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // -----------------------------------------------------------------
          // Reviews
          // -----------------------------------------------------------------
          ...reviews.map((data) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data["name"],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(data["position"],
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < data["rating"]
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: Colors.orange,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(data["comment"],
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data["date"],
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      Row(
                        children: [
                          const Icon(Icons.thumb_up,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text("Helpful (${data["likes"]})",
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
