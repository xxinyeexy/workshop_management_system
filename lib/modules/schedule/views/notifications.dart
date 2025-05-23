import 'package:flutter/material.dart';
import 'schedule.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool showNewTask = true;

  void handleDecision(String decision) {
    setState(() {
      showNewTask = false;
    });

    // TODO: send to backend or notify workshop owner
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Task $decision")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: userRole == 'foreman' ? Colors.green : Colors.blue,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ New Task Assigned Request (Flexible Width + Dismiss on Tap)
          if (showNewTask)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE4FCE9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "New Task Assigned",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "You have been assigned a new task by Wilson Auto Repairs.",
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Engine Repair", style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text("Sunday, March 30, 2025"),
                        Text("10:00 AM - 12:00 PM"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => handleDecision("declined"),
                        child: const Text("Decline"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => handleDecision("accepted"),
                        child: const Text("Accept"),
                      ),
                    ],
                  )
                ],
              ),
            ),

          // Other notifications
          notificationCard(
            title: "Rescheduling Accepted",
            body: "Wilson Auto Repair accepted your rescheduling request.",
            time: "2 hours ago",
          ),
          notificationCard(
            title: "Task Completed",
            body: "Your task \"Oil Change\" has been marked as completed.",
            time: "5 hours ago",
          ),
        ],
      ),
    );
  }

  Widget notificationCard({
    required String title,
    required String body,
    required String time,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body),
          const SizedBox(height: 8),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
