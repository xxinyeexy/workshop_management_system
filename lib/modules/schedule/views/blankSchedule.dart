import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workshop_management_system/modules/schedule/views/notifications.dart';

class BlankSchedulePage extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userPosition;

  const BlankSchedulePage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userPosition,
  });

  @override
  State<BlankSchedulePage> createState() => _BlankSchedulePageState();
}

class _BlankSchedulePageState extends State<BlankSchedulePage> {
  String? selectedWorkshop;
  List<String> workshopList = [];

  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchWorkshopNames();
  }

  Future<void> _fetchWorkshopNames() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'workshop_owner')
        .get();

if (!mounted) return;

    setState(() {
      workshopList =
          snapshot.docs.map((doc) => doc['fullName'] as String).toList();
    });
  }

  Future<void> _selectTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        isStart ? startTime = picked : endTime = picked;
      });
    }
  }

// XQ TASK 2 REPLACING WITH DROPDOWN
  Future<void> _applyWorkshop() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (selectedWorkshop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a workshop")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final workshopQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('fullName', isEqualTo: selectedWorkshop)
        .where('role', isEqualTo: 'workshop_owner')
        .limit(1)
        .get();

    final ownerId = workshopQuery.docs.first.id;

    await FirebaseFirestore.instance.collection('workshop_requests').add({
      'foremanId': user.uid,
      'foremanName': widget.userName,
      'workshopName': selectedWorkshop,
      'ownerId': ownerId,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': ownerId,
      'title': 'Workshop Join Request',
      'body':
          '${widget.userName} has requested to join your workshop ($selectedWorkshop).',
      'timestamp': Timestamp.now(),
      'isRead': false,
    });

    setState(() => isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Request sent. Please wait for workshop owner approval.",
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    return TimeOfDay.fromDateTime(
      DateTime(now.year, now.month, now.day, time.hour, time.minute),
    ).format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationsPage(userRole: widget.userRole),
                ),
              );
            },
            child: const Text(
              'Notification',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workshop Name:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedWorkshop,
              hint: const Text('Select workshop'),
              items: workshopList
                  .map(
                    (name) => DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedWorkshop = value;
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _applyWorkshop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Apply Workshop',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Worktime', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(isStart: true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_formatTime(startTime)),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text("to"),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(isStart: false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_formatTime(endTime)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
