import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:workshop_management_system/provider/scheduleController.dart';
import 'package:workshop_management_system/modules/schedule/views/reschedulingForm.dart';
import 'package:workshop_management_system/modules/schedule/widgets/simpleForemanCard.dart';
import '../../models/taskModel.dart';

class TaskDetailPage extends StatefulWidget {
  final String taskId;
  final String userRole;

  const TaskDetailPage({
    super.key,
    required this.taskId,
    required this.userRole,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  DocumentSnapshot? taskDoc;
  TaskModel? taskModel;

  @override
  void initState() {
    super.initState();
    loadTask();
  }

  Future<void> loadTask() async {
    final doc = await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).get();
    if (doc.exists) {
      setState(() {
        taskDoc = doc;
        taskModel = TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      });
    }
  }

  Future<void> completeTask() async {
    await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
      'taskStatus': 'completed',
    });

    final ownerId = taskDoc!['ownerId'];
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': ownerId,
      'title': 'Task Completed',
      'body': 'Foreman marked "${taskDoc!['taskTitle']}" as completed.',
      'timestamp': Timestamp.now(),
      'isRead': false,
    });

    Navigator.pop(context);

  }

    void confirmCancelTask() {
      if (taskModel != null) {
        showCancelTaskDialog(
          context: context,
          task: taskModel!,
          userRole: widget.userRole,
          onConfirm: () async {
            // Update status to cancelled
            await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
              'taskStatus': 'cancelled',
            });

            // Notify foreman
            final foremanId = taskDoc!['foremanId'];
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': foremanId,
              'title': 'Task Cancelled',
              'body': 'The task "${taskDoc!['taskTitle']}" has been cancelled by the owner.',
              'timestamp': Timestamp.now(),
              'isRead': false,
            });

            // Show feedback & close
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task cancelled")));
            Navigator.pop(context); // close TaskDetailPage
          },
        );
      }
    }


  String formatDateTime(DateTime dt) => DateFormat('EEEE, MMMM d, yyyy h:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    if (taskDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = taskDoc!.data() as Map<String, dynamic>;
    final start = (data['taskStartTime'] as Timestamp).toDate();
    final end = (data['taskEndTime'] as Timestamp).toDate();
    final now = DateTime.now();

    final bool ownerCanAct = widget.userRole == 'workshop_owner' && data['taskStatus'] == 'scheduled';
    final bool foremanCanComplete = widget.userRole == 'foreman' && now.isAfter(start) && data['taskStatus'] == 'scheduled';

    final primaryColor = widget.userRole == 'foreman' ? Colors.green : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task"),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.userRole == 'workshop_owner')
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SimpleForemanCard(name: data['foremanName']),
            ),
            _buildField("Task Assign", data['taskTitle']),
            _buildField("Description", data['taskDescription']),
            _buildField("Start Time", formatDateTime(start)),
            _buildField("End Time", formatDateTime(end)),
            _buildField("Reward", "RM ${data['taskReward']}"),
            _buildField("Status", data['taskStatus']),
            const Spacer(),
            if (ownerCanAct)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: confirmCancelTask,
                      child: const Text("Cancel Task", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReschedulePage(
                              taskId: widget.taskId,
                              userRole: widget.userRole,
                              originalStartTime: start,
                              originalEndTime: end,
                              ownerId: data['ownerId'],
                              taskTitle: data['taskTitle'],
                            ),
                          ),
                        );
                        loadTask();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text("Rescheduling", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            if (foremanCanComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: completeTask,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Mark as Completed", style: TextStyle(color: Colors.white)),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
