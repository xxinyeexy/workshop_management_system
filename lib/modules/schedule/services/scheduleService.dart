import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {
  final tasks = FirebaseFirestore.instance.collection('tasks');
  final rescheduleRequests = FirebaseFirestore.instance.collection('task_reschedule_requests');
  final notifications = FirebaseFirestore.instance.collection('notifications');

  Future<void> assignTask({
    required String title,
    required String description,
    required int reward,
    required Timestamp startTime,
    required Timestamp endTime,
    required DocumentReference foremanRef,
    required DocumentReference ownerRef,
  }) async {
    final task = await tasks.add({
      'task_title': title,
      'task_description': description,
      'task_reward': reward,
      'task_status': 'Pending',
      'task_startTime': startTime,
      'task_endTime': endTime,
      'foreman_id': foremanRef,
      'owner_id': ownerRef,
      'created_at': Timestamp.now(),
    });

    await notifications.add({
      'to_user': foremanRef,
      'from_user': ownerRef,
      'type': 'TaskAssigned',
      'message': 'You have a new task: $title',
      'task_id': task,
      'created_at': Timestamp.now(),
      'is_read': false,
    });
  }

  Future<void> requestReschedule({
    required DocumentReference taskRef,
    required DocumentReference foremanRef,
    required Timestamp newStart,
    required Timestamp newEnd,
    required String reason,
  }) async {
    await rescheduleRequests.add({
      'task_id': taskRef,
      'foreman_id': foremanRef,
      'new_startTime': newStart,
      'new_endTime': newEnd,
      'reason': reason,
      'status': 'Pending',
      'requested_at': Timestamp.now(),
    });

    final taskSnapshot = await taskRef.get();
    final ownerRef = taskSnapshot['owner_id'] as DocumentReference;

    await notifications.add({
      'to_user': ownerRef,
      'from_user': foremanRef,
      'type': 'RescheduleRequest',
      'message': 'Foreman has requested to reschedule a task.',
      'task_id': taskRef,
      'created_at': Timestamp.now(),
      'is_read': false,
    });
  }

  Future<void> cancelTask({
    required DocumentReference taskRef,
    required DocumentReference byUserRef,
    required String reason,
  }) async {
    await taskRef.update({'task_status': 'Cancelled'});

    final taskSnapshot = await taskRef.get();
    final ownerRef = taskSnapshot['owner_id'];
    final foremanRef = taskSnapshot['foreman_id'];

    final otherParty = (byUserRef.id == ownerRef.id) ? foremanRef : ownerRef;

    await notifications.add({
      'to_user': otherParty,
      'from_user': byUserRef,
      'type': 'TaskCancelled',
      'message': 'Task has been cancelled: $reason',
      'task_id': taskRef,
      'created_at': Timestamp.now(),
      'is_read': false,
    });
  }
}
