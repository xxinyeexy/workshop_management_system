// assignTask.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AssignTaskPage extends StatefulWidget {
  final String foremanId;
  final String foremanName;
  final String workTime;

  const AssignTaskPage({
    super.key,
    required this.foremanId,
    required this.foremanName,
    required this.workTime,
  });

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _rewardController = TextEditingController();
  DateTime? startTime;
  DateTime? endTime;
  bool isSubmitting = false;

  Future<void> _selectDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (pickedTime == null) return;

    final fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        startTime = fullDateTime;
      } else {
        endTime = fullDateTime;
      }
    });
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start and end time are required")),
      );
      return;
    }

    if (endTime!.isBefore(startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final workshopName = ownerDoc['fullName'];

    await FirebaseFirestore.instance.collection('tasks').add({
      'taskTitle': _titleController.text,
      'taskDescription': _descController.text,
      'taskReward': int.tryParse(_rewardController.text.trim()) ?? 0,
      'taskStartTime': Timestamp.fromDate(startTime!),
      'taskEndTime': Timestamp.fromDate(endTime!),
      'taskStatus': 'scheduled',
      'ownerId': currentUser.uid,
      'foremanId': widget.foremanId,
      'foremanName': widget.foremanName,
      'workshopName': workshopName,
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': widget.foremanId,
      'title': "New Task Assigned",
      'body': "You have been assigned a new task.",
      'timestamp': Timestamp.now(),
      'isRead': false,
    });

    setState(() => isSubmitting = false);
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
                "Assign Task",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Foreman", style: TextStyle(fontWeight: FontWeight.w600)),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        widget.foremanName.split(" ").map((e) => e[0]).take(2).join(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.foremanName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(widget.workTime, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    )
                  ],
                ),
              ),
              _buildLabel("Task Assign:"),
              TextFormField(controller: _titleController, validator: _validateNotEmpty),

              _buildLabel("Description:"),
              TextFormField(controller: _descController, validator: _validateNotEmpty),

              _buildLabel("Reward:"),
              TextFormField(controller: _rewardController, validator: _validateNotEmpty, keyboardType: TextInputType.number),

              _buildLabel("Start Time"),
              GestureDetector(
                onTap: () => _selectDateTime(isStart: true),
                child: _timeBox(startTime),
              ),

              _buildLabel("End Time"),
              GestureDetector(
                onTap: () => _selectDateTime(isStart: false),
                child: _timeBox(endTime),
              ),

              const SizedBox(height: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Assign Task", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNotEmpty(String? value) => (value == null || value.isEmpty) ? 'Required field' : null;

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(label),
    );
  }

  Widget _timeBox(DateTime? dt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(dt == null ? "" : DateFormat('yyyy-MM-dd h:mm a').format(dt)),
    );
  }
}
