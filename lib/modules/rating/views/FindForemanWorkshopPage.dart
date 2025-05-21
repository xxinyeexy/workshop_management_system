import 'package:flutter/material.dart';


/// A single screen that adapts its colour scheme to the caller’s role.
///
/// * Pass `userRole: 'foreman'`  →  green theme.
/// * Pass `userRole: 'workshop'` →  blue theme.
class FindForemanWorkshopPage extends StatefulWidget {
  final String userRole;

  const FindForemanWorkshopPage({
    super.key,
    required this.userRole,
  });

  @override
  State<FindForemanWorkshopPage> createState() =>
      _FindForemanWorkshopPageState();
}

class _FindForemanWorkshopPageState extends State<FindForemanWorkshopPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ---------------------------------------------------------------------------
  // Theme colour logic: green for foreman, blue for workshop owner.
  // ---------------------------------------------------------------------------
  late final Color primaryColor =
      widget.userRole.toLowerCase() == 'foreman'
          ? const Color(0xFF2FB668) // vibrant foreman green
          : const Color(0xFF4260DB); // dignified workshop blue

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ---------------------------------------------------------------------------
  // Helper builders
  // ---------------------------------------------------------------------------

  Widget _buildListTile(
    String initials,
    String name,
    double rating,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
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
              ...List.generate(5, (index) {
                return Icon(
                  index < rating.floor()
                      ? Icons.star
                      : index < rating
                          ? Icons.star_half
                          : Icons.star_border,
                  size: 16,
                  color: Colors.orange,
                );
              }),
              const SizedBox(width: 6),
              Text(
                "(${rating.toStringAsFixed(1)})",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isForeman) {
    final items = isForeman
        ? [
            {"initials": "JD", "name": "John Doe", "rating": 4.5},
            {"initials": "MS", "name": "Mike Smith", "rating": 3.9},
          ]
        : [
            {"initials": "AB", "name": "ABC Workshop", "rating": 4.3},
            {"initials": "XY", "name": "XYZ Mechanics", "rating": 3.8},
          ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        return _buildListTile(
          item['initials']!,
          item['name']!,
          item['rating']!,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RatingDetailPage(
                  initials: item['initials'],
                  name: item['name'],
                  role: isForeman ? "Senior Foreman" : "Auto Repair Specialist",
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Find Foreman / Workshop",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RatingsListPage(
                      userRole: widget.userRole.toLowerCase(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.reviews, color: Colors.white),
              label: const Text(
                "My Reviews",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
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
                    "I’m looking\nfor workshop\nowner and\nforeman.",
                    style: TextStyle(
                      fontSize: 64,
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
                  tabs: const [
                    Tab(text: "Foremen"),
                    Tab(text: "Workshops"),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabContent(true),  // Foremen
                      _buildTabContent(false), // Workshops
                    ],
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
