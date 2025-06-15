import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String taskTitle;
  final String taskDescription;
  final String taskStatus;
  final int taskReward;
  final Timestamp taskStartTime;
  final Timestamp taskEndTime;
  final String ownerId;
  final String foremanId;
  final String foremanName;
  final String workshopName;


  TaskModel({
    required this.id,
    required this.taskTitle,
    required this.taskDescription,
    required this.taskStatus,
    required this.taskReward,
    required this.taskStartTime,
    required this.taskEndTime,
    required this.ownerId,
    required this.foremanId,
    required this.foremanName,
    required this.workshopName,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map,String id) {
    return TaskModel(
      id: id,
      taskTitle: map['taskTitle'] ?? '',
      taskDescription: map['taskDescription'] ?? '',
      taskStatus: map['taskStatus'] ?? 'scheduled',
      taskReward: map['taskReward']??'0',
      taskStartTime: map['taskStartTime'] as Timestamp,
      taskEndTime: map['taskEndTime'] as Timestamp,
      ownerId: map['ownerId'] ?? '',
      foremanId: map['foremanId'] ?? '',
      foremanName: map['foremanName'] ?? '',
      workshopName: map['workshopName'] ?? '',
    );
  }

}
