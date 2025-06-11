import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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

Future<void> saveScheduleToFirebase(ScheduleInfo schedule) async {
  final db = FirebaseDatabase.instance.ref();
  await db.child('schedules/${schedule.scheduleId}').set({
    'taskId': schedule.taskId,
    'taskTitle': schedule.taskTitle,
    'taskDescription': schedule.taskDescription,
    'taskStatus': schedule.taskStatus,
    'taskStartTime': '${schedule.taskStartTime.hour}:${schedule.taskStartTime.minute}',
    'taskEndTime': '${schedule.taskEndTime.hour}:${schedule.taskEndTime.minute}',
    'taskDate': schedule.taskDate.toIso8601String(),
    'taskReward': schedule.taskReward,
    'foremanWorkStatus': schedule.foremanWorkStatus,
    'workshopWorkStatus': schedule.workshopWorkStatus,
    'notificationId': schedule.notificationId,
    'notificationType': schedule.notificationType,
    'notificationMessage': schedule.notificationMessage,
    'notificationTimestamp': schedule.notificationTimestamp.toIso8601String(),
    'foremanName': schedule.foremanName,
  });
}

