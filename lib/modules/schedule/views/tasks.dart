import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/models/taskModel.dart';
import 'package:workshop_management_system/modules/schedule/views/taskDetail.dart';
import 'package:workshop_management_system/modules/schedule/widgets/taskCard.dart';

class TasksPage extends StatefulWidget {
  final String userRole;
  const TasksPage({super.key, required this.userRole});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = userDoc['role'];

    Query query;

    if (role == "foreman") {
      query = FirebaseFirestore.instance
          .collection('tasks')
          .where('foremanId', isEqualTo: uid);
    } else {
      final workshopName = userDoc['fullName'];
      query = FirebaseFirestore.instance
          .collection('tasks')
          .where('workshopName', isEqualTo: workshopName);
    }

    final querySnapshot = await query.get();

    final fetchedTasks = querySnapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    // Define status priority
    const statusOrder = {
      'scheduled': 0,
      'completed': 1,
      'paid': 2,
      'cancelled': 3,
    };

    // Custom sort: by status first, then by taskStartTime
    fetchedTasks.sort((a, b) {
      final statusCompare = (statusOrder[a.taskStatus.toLowerCase()] ?? 999)
          .compareTo(statusOrder[b.taskStatus.toLowerCase()] ?? 999);

      if (statusCompare != 0) return statusCompare;

      return a.taskStartTime.compareTo(b.taskStartTime);
    });

    setState(() {
      tasks = fetchedTasks;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.userRole == 'foreman' ? Colors.green : Colors.blue,
        centerTitle: true,
        title: const Text(
          'Tasks',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: tasks.isEmpty
          ? const Center(
            child: Text(
              'No task records found',
              style: TextStyle(fontSize: 16),
            ),
          )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    task: task,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailPage(taskId: task.id, userRole: widget.userRole),
                        ),
                      );
                        fetchTasks();
                    },
                  ),
                );
              },
            ),
    );
  }
}
