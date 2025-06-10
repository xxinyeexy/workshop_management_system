import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/schedule/views/assignTask.dart';
import 'package:workshop_management_system/modules/schedule/views/notifications.dart';
import 'package:workshop_management_system/modules/schedule/views/taskDetail.dart';
import 'package:workshop_management_system/modules/schedule/views/tasks.dart';
import 'package:workshop_management_system/modules/rating/views/RatingListPage.dart';

import '../../sidebar.dart'; // import your SidebarMenu here

// Global rating service to manage pending ratings across app
class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final List<Map<String, dynamic>> _pendingRatings = [];

  void addPendingRating(Map<String, dynamic> ratingData) {
    // Check if a similar rating already exists
    bool exists = _pendingRatings.any(
      (rating) =>
          rating['contractId'] == ratingData['contractId'] &&
          rating['forUserRole'] == ratingData['forUserRole'],
    );

    if (!exists) {
      _pendingRatings.add(ratingData);
    }
  }

  // Now filter by user role AND user identity (foremanName or workshopName)
  List<Map<String, dynamic>> getPendingRatingsForUser(
    String userRole,
    String userName,
    String workshopName,
  ) {
    return _pendingRatings.where((rating) {
      if (rating['forUserRole'] != userRole) return false;

      if (userRole == 'foreman') {
        return rating['foremanName'] == userName;
      } else if (userRole == 'workshop') {
        return rating['workshopName'] == workshopName;
      }
      return false;
    }).toList();
  }

  void removePendingRating(Map<String, dynamic> ratingData) {
    _pendingRatings.removeWhere(
      (rating) =>
          rating['contractId'] == ratingData['contractId'] &&
          rating['forUserRole'] == ratingData['forUserRole'],
    );
  }

  // Debug method to print all pending ratings
  void debugPrintRatings() {
    print('All pending ratings:');
    for (var rating in _pendingRatings) {
      print(
        'Rating for ${rating['forUserRole']}: ${rating['name']} (Workshop: ${rating['workshopName']}, Foreman: ${rating['foremanName']})',
      );
    }
  }
}

class Schedule extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userPosition;

  const Schedule({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userPosition,
  });

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
  bool showNotification = true;
  bool isContractTerminated = false;

  late String workshopName; // Will hold logged-in user's workshop name

  @override
  void initState() {
    super.initState();
    // Set workshopName depending on role — if foreman, associate workshop must be known
    // For demo, assuming foreman's workshop is "Ali Workshop"
    workshopName =
        widget.userRole.toLowerCase() == 'workshop'
            ? widget.userName
            : 'xixi workshop'; // Replace with real lookup if possible
  }

  Future<void> _selectTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _terminateContract() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terminate Contract'),
          content: const Text(
            'Are you sure you want to terminate this contract? This will trigger a mutual rating process.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Terminate',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        isContractTerminated = true;
      });

      final String contractId =
          'contract_${DateTime.now().millisecondsSinceEpoch}';
      final DateTime now = DateTime.now();
      final String formattedDate = '${now.day}/${now.month}/${now.year}';

      String otherPartyName;
      String otherPartyInitials;
      String otherPartyRole;
      String foremanName;
      String currentWorkshopName;

      if (widget.userRole.toLowerCase() == 'foreman') {
        // Foreman is logged in, workshop is associated workshop
        currentWorkshopName = workshopName;
        foremanName = widget.userName;

        otherPartyName = currentWorkshopName;
        otherPartyInitials = _getInitials(currentWorkshopName);
        otherPartyRole = 'workshop';
      } else {
        // Workshop owner logged in
        currentWorkshopName = widget.userName;
        foremanName =
            'John Foreman'; // Replace with actual foreman name linked to contract

        otherPartyName = foremanName;
        otherPartyInitials = _getInitials(foremanName);
        otherPartyRole = 'foreman';
      }

      // Create rating data for workshop owner
      final workshopRatingData = {
        'contractId': contractId,
        'forUserRole': 'workshop',
        'name':
            widget.userRole.toLowerCase() == 'foreman'
                ? widget.userName
                : otherPartyName,
        'initials':
            widget.userRole.toLowerCase() == 'foreman'
                ? _getInitials(widget.userName)
                : otherPartyInitials,
        'date': formattedDate,
        'message':
            'Contract terminated. Please rate your experience working together.',
        'targetRole': 'foreman',
        'workshopName': currentWorkshopName,
        'foremanName': foremanName,
      };

      // Create rating data for foreman
      final foremanRatingData = {
        'contractId': contractId,
        'forUserRole': 'foreman',
        'name':
            widget.userRole.toLowerCase() == 'workshop'
                ? widget.userName
                : otherPartyName,
        'initials':
            widget.userRole.toLowerCase() == 'workshop'
                ? _getInitials(widget.userName)
                : otherPartyInitials,
        'date': formattedDate,
        'message':
            'Contract terminated. Please rate your experience working together.',
        'targetRole': 'workshop',
        'workshopName': currentWorkshopName,
        'foremanName': foremanName,
      };

      // Add ratings for both parties
      RatingService().addPendingRating(workshopRatingData);
      RatingService().addPendingRating(foremanRatingData);

      // Force rebuild of the sidebar to update notification badge
      if (mounted) {
        setState(() {
          // Rebuild the scaffold to trigger sidebar rebuild
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => Schedule(
                    userName: widget.userName,
                    userRole: widget.userRole,
                    userPosition: widget.userPosition,
                  ),
            ),
          );
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contract terminated successfully. Rating requests have been created.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: primaryColor,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
            child: const Text(
              'Notification',
              style: TextStyle(
                color: Colors.black, // Make sure text is visible on AppBar
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
       body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (showNotification)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDFFFE3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "You have new notification!",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => showNotification = false);
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Text("Workshop Name:", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: "Ali Workshop",
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text("Terminate Contract"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Text("Worktime", style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 4),
              Icon(Icons.edit, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(isStart: true),
                  child: TimeFieldDisplay(label: formatTime(startTime)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text("to"),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(isStart: false),
                  child: TimeFieldDisplay(label: formatTime(endTime)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Task", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              TextButton(
                onPressed:() {
                  Navigator.push(context,
                  MaterialPageRoute(builder: (context)=>const TasksPage()),
                  );
                },
            child: const Text(
            "See All",
            style: TextStyle(color: Colors.blue),
            ),
            )
            ],
          ),
          const SizedBox(height: 12),
          const TaskCard(
            title: "Engine Repair",
            subtitle: "Repair the WMS 9011's car engine",
            date: "Sunday, March 30, 2025",
            time: "9:00 AM - 12:00 PM",
            status: "In Progress",
            statusColor: Color(0xFF2D9CDB),
          ),
          const SizedBox(height: 12),
          const TaskCard(
            title: "Bumper Repair",
            subtitle: "Repair the CWS 1654’s car bumper",
            date: "Monday, March 31, 2025",
            time: "10:00 AM – 12:00 PM",
            status: "Scheduled",
            statusColor: Color(0xFF56CCF2),
          ),
        )),
      ],
    );
  }
}

class TimeFieldDisplay extends StatelessWidget {
  final String label;
  final bool isDisabled;

  const TimeFieldDisplay({
    super.key,
    required this.label,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 18,
            color: isDisabled ? Colors.grey : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isDisabled ? Colors.grey : null)),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String time;
  final String status;
  final Color statusColor;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 6),
          Text(date, style: const TextStyle(color: Colors.grey)),
          Text(time, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
