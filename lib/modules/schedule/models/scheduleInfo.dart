import 'package:flutter/material.dart';

class ScheduleInfo {
  final String scheduleId;
  final String taskId;
  final String taskTitle;
  final String taskDescription;
  final String taskStatus;
  final TimeOfDay taskStartTime;
  final TimeOfDay taskEndTime;
  final DateTime taskDate;
  final String taskReward;

  final String foremanWorkStatus;
  final String workshopWorkStatus;

  final String notificationId;
  final String notificationType;
  final String notificationMessage;
  final DateTime notificationTimestamp;

  final String foremanName;

  ScheduleInfo({
    required this.scheduleId,
    required this.taskId,
    required this.taskTitle,
    required this.taskDescription,
    required this.taskStatus,
    required this.taskStartTime,
    required this.taskEndTime,
    required this.taskDate,
    required this.taskReward,
    required this.foremanWorkStatus,
    required this.workshopWorkStatus,
    required this.notificationId,
    required this.notificationType,
    required this.notificationMessage,
    required this.notificationTimestamp,
    required this.foremanName,
  });
}

final List<ScheduleInfo> mockScheduleList = [
  ScheduleInfo(
    scheduleId: 's1',
    taskId: 't1',
    taskTitle: 'Brake Replacement',
    taskDescription: 'Replace front brake pads of CWS 1234',
    taskStatus: 'Scheduled',
    taskStartTime: const TimeOfDay(hour: 8, minute: 0),
    taskEndTime: const TimeOfDay(hour: 10, minute: 0),
    taskDate: DateTime(2025, 3, 30),
    taskReward: 'RM 100',
    foremanWorkStatus: 'Available',
    workshopWorkStatus: 'Active',
    notificationId: 'n1',
    notificationType: 'Assignment',
    notificationMessage: 'New task assigned',
    notificationTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
    foremanName: 'Sarah Lee',
  ),
  ScheduleInfo(
    scheduleId: 's2',
    taskId: 't2',
    taskTitle: 'Engine Repair',
    taskDescription: 'Repair engine of WMS 9011',
    taskStatus: 'In Progress',
    taskStartTime: const TimeOfDay(hour: 9, minute: 0),
    taskEndTime: const TimeOfDay(hour: 12, minute: 0),
    taskDate: DateTime(2025, 3, 30),
    taskReward: 'RM 150',
    foremanWorkStatus: 'Busy',
    workshopWorkStatus: 'Active',
    notificationId: 'n2',
    notificationType: 'Reminder',
    notificationMessage: 'Engine repair ongoing',
    notificationTimestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    foremanName: 'Mike Johnson',
  ),
];
