import 'package:flutter/material.dart';
import '../models/scheduleInfo.dart';

class TaskCard extends StatelessWidget {
  final ScheduleInfo task;
  final String userRole;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.userRole,
    required this.onTap,
  });

  String formatTimeRange(BuildContext context) {
    final start = task.taskStartTime.format(context);
    final end = task.taskEndTime.format(context);
    return '$start - $end';
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
    final timeRange = formatTimeRange(context);
    final dateStr = "${task.taskDate.year}-${task.taskDate.month.toString().padLeft(2, '0')}-${task.taskDate.day.toString().padLeft(2, '0')}";
    final statusColor = getStatusColor(task.taskStatus);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.taskTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            if (userRole == 'owner')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Foreman: ${task.foremanName}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(timeRange, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.taskDescription, style: const TextStyle(color: Colors.black87)),
                  Text("$dateStr, $timeRange", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(task.taskStatus, style: TextStyle(color: statusColor, fontSize: 12)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
