import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/taskModel.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final String userRole;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.userRole,
    required this.onTap,
  });

  String formatFullDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('EEEE, MMMM d, yyyy h:mma').format(date); // e.g. Sunday, March 30, 2025 9:00AM
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return const Color(0xFF56CCF2);
      case 'in progress':
        return const Color(0xFF2D9CDB);
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = formatFullDateTime(task.taskStartTime);
    final end = formatFullDateTime(task.taskEndTime);
    final statusColor = getStatusColor(task.taskStatus);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(task.taskTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: getStatusColor(task.taskStatus),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    task.taskStatus,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              task.taskDescription,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),

            const SizedBox(height: 12),

            // Time range
            Text(
              "$start until",
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              end,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
