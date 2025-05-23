import 'package:flutter/material.dart';
import '../widgets/taskSummaryBox.dart';

void showCancelTaskDialog({
  required BuildContext context,
  required String taskTitle,
  required String date,
  required String time,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Task Cancellation",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "You are going to cancel the task, Engine Repair. If you confirm you want to cancel it, a notification will be sent to your workshop owner.",
            ),
            SizedBox(height: 16),
            TaskSummaryBox(
              title: "Engine Repair",
              date: "Sunday, March 30, 2025",
              time: "9:00 AM - 12:00 PM",
            ),
          ],
        ),
       actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("No", style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task Cancellation Request sent")),
                    );
                    // TODO: send updated schedule to backend
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  
                  child: const Text("Yes", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}