import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final DocumentReference toUser;
  final DocumentReference fromUser;
  final String type; // TaskAssigned, RescheduleRequest, etc.
  final String message;
  final DocumentReference? taskRef;
  final Timestamp createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.toUser,
    required this.fromUser,
    required this.type,
    required this.message,
    this.taskRef,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      toUser: data['to_user'],
      fromUser: data['from_user'],
      type: data['type'],
      message: data['message'],
      taskRef: data['task_id'],
      createdAt: data['created_at'],
      isRead: data['is_read'],
    );
  }

  Map<String, dynamic> toMap() => {
    'to_user': toUser,
    'from_user': fromUser,
    'type': type,
    'message': message,
    if (taskRef != null) 'task_id': taskRef,
    'created_at': createdAt,
    'is_read': isRead,
  };
}
