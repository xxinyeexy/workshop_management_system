import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/schedule/views/notifications.dart';
import 'package:workshop_management_system/modules/schedule/views/tasks.dart';

import '../../sidebar.dart'; // import your SidebarMenu here

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
  State<StatefulWidget> createState() {
    return _ScheduleState();
  }
}

class _ScheduleState extends State<Schedule> {
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
  bool showNotification = true;

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

  UserRole _getUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'foreman':
        return UserRole.Foreman;
      case 'workshop':
      case 'workshop owner':
      case 'workshopowner':
        return UserRole.WorkshopOwner;
      default:
        return UserRole.WorkshopOwner; // default fallback
    }
  }

  String _getUserRoleString(UserRole role) {
    switch (role) {
      case UserRole.Foreman:
        return 'foreman';
      case UserRole.WorkshopOwner:
        return 'workshop owner';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: primaryColor,
        leading: Builder(
          builder: (context) => IconButton(
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
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      drawer: SidebarMenu(
        userRole: _getUserRole(widget.userRole),
        userName: widget.userName,
        userPosition: widget.userPosition,
        selectedTitle: 'Schedule',
        originalUserRole: widget.userRole,
        onSelectedTitleChanged: (title) {
          // Optional: sync state or navigation logic here
        },
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TasksPage()),
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
            subtitle: "Repair the CWS 1654's car bumper",
            date: "Monday, March 31, 2025",
            time: "10:00 AM – 12:00 PM",
            status: "Scheduled",
            statusColor: Color(0xFF56CCF2),
          ),
        ],
      ),
    );
  }
}

class TimeFieldDisplay extends StatelessWidget {
  final String label;
  const TimeFieldDisplay({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 18),
          const SizedBox(width: 8),
          Text(label),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
