import 'package:flutter/material.dart';

class TaskDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String time;
  final String status;
  final Color statusColor;

  const TaskDetailPage({
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildField("Task Assign", title),
            buildField("Description", subtitle),
            Row(
              children: [
                Expanded(child: buildField("Date", date)),
                const SizedBox(width: 8),
                Expanded(child: buildField("Reward", "RM 100")), // replace if dynamic
              ],
            ),
            Row(
              children: [
                Expanded(child: buildField("Start Time", time.split(' - ').first)),
                const SizedBox(width: 8),
                Expanded(child: buildField("End Time", time.split(' - ').last)),
              ],
            ),
            buildField("Status", status),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {}, //handle cancellation
                    child: const Text(
                      "Cancel Task", 
                      style: TextStyle(color: Colors.white)
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {}, // handle rescheduling
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text(
                      "Rescheduling", 
                      style: TextStyle(color: Colors.white)
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

  Widget buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
