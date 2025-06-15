import 'package:flutter/material.dart';
import '../modules/models/taskModel.dart';
import '../modules/schedule/widgets/taskCard.dart';

void showCancelTaskDialog({
  required BuildContext context,
  required TaskModel task,
  required String userRole,
  required VoidCallback onConfirm,
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
          children: [
            const Text(
              "You are going to cancel the task below. If you confirm, a notification will be sent to your workshop owner.",
            ),
            const SizedBox(height: 16),
            TaskCard(
              task: task,
              onTap: () {}, // Prevent navigation
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
                    onConfirm();                
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
