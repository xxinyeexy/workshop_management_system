import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workshop_management_system/modules/schedule/views/notifications.dart';
import 'package:workshop_management_system/core/widgets/sidebar.dart';

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
  final TextEditingController _workshopController = TextEditingController();
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
  bool isSubmitting = false;

  //Handle WorkTime
  Future<void> _selectTime({required bool isStart}) async {
    final picked = await showTimePicker(
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

  //Handle Workshop Applying
  Future<void> _applyWorkshop() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final workshopName = _workshopController.text.trim();

    if (workshopName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a workshop name")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    //Validate that this workshop name exists as a user with role = 'workshop_owner'
    final workshopQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('fullName', isEqualTo: workshopName)
        .where('role', isEqualTo: 'workshop_owner')
        .limit(1)
        .get();

    if (workshopQuery.docs.isEmpty) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid workshop name. Please try again.")),
      );
      return;
    }

    final workshopOwnerId = workshopQuery.docs.first.id;

    //Update current foreman's document with selected workshop name
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'workshopName': workshopName,
    });

    // 3. Save selected worktime
    final now = DateTime.now();
    final startDateTime = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    final endDateTime = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    await FirebaseFirestore.instance.collection('worktimes').doc(uid).set({
      'startTime': Timestamp.fromDate(startDateTime),
      'endTime': Timestamp.fromDate(endDateTime),
    });

    //Send notification to the owner
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': workshopOwnerId,
      'title': 'New Foreman Joined',
      'body': 'A foreman has applied to your workshop: $workshopName.',
      'timestamp': Timestamp.now(),
      'isRead': false,
    });

    setState(() => isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Workshop applied successfully!")),
    );

    Navigator.pop(context); // Or navigate to Schedule screen
  }

  //Handle WorkTime
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsPage(userRole: widget.userRole),
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
      drawer: SidebarMenu(
        userRole:
            widget.userRole.toLowerCase() == 'foreman'
                ? UserRole.Foreman
                : UserRole.WorkshopOwner,
        userName: widget.userName,
        userPosition: widget.userPosition,
        selectedTitle: 'Schedule',
        originalUserRole: widget.userRole,
        onSelectedTitleChanged: (title) {
          // Optional: sync state or navigation logic here
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Workshop Name:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _workshopController,
                    decoration: InputDecoration(
                      hintText: 'Name...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _applyWorkshop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Apply Workshop', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.check_box, size: 20),
                SizedBox(width: 6),
                Text('Worktime', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(isStart: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_formatTime(endTime)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
