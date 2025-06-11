// 1. RESCHEDULE PAGE (Foreman side)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReschedulePage extends StatefulWidget {
  final String taskId;
  final String userRole;
  final DateTime originalStartTime;
  final DateTime originalEndTime;
  final String ownerId;
  final String taskTitle;

  const ReschedulePage({
    super.key,
    required this.taskId,
    required this.userRole,
    required this.originalStartTime,
    required this.originalEndTime,
    required this.ownerId,
    required this.taskTitle,
  });

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  late DateTime newStart;
  late DateTime newEnd;

  @override
  void initState() {
    super.initState();
    newStart = widget.originalStartTime;
    newEnd = widget.originalEndTime;
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? newStart : newEnd,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? newStart : newEnd),
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
        newStart = fullDateTime;
      } else {
        newEnd = fullDateTime;
      }
    });
  }

  Future<void> _submitRequest() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (newStart.isAfter(newEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('rescheduleRequests').add({
      'taskId': widget.taskId,
      'foremanId': uid,
      'newStartTime': Timestamp.fromDate(newStart),
      'newEndTime': Timestamp.fromDate(newEnd),
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reschedule request sent")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.userRole == 'owner' ? Colors.blue : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reschedule Task"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Start Time"),
            ListTile(
              title: Text(DateFormat('yyyy-MM-dd hh:mm a').format(newStart)),
              trailing: Icon(Icons.edit),
              onTap: () => _selectDateTime(isStart: true),
            ),
            const SizedBox(height: 16),
            const Text("End Time"),
            ListTile(
              title: Text(DateFormat('yyyy-MM-dd hh:mm a').format(newEnd)),
              trailing: Icon(Icons.edit),
              onTap: () => _selectDateTime(isStart: false),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text("Submit Reschedule"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
