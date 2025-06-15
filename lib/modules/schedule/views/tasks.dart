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
    final role =  userDoc['role'];
    if(role == "foreman"){
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('foremanId', isEqualTo: uid)
          .get();

      setState(() {
        tasks = querySnapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data(),doc.id))
        .toList();
      });}
    else{
      final workshopName = userDoc['fullName'];
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('workshopName', isEqualTo: workshopName)
          .get();

      setState(() {
        tasks = querySnapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data(),doc.id))
        .toList();
      });
    }
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
                      // ✅ Reload tasks after coming back
                        fetchTasks(); // make sure this re-queries Firestore
                    },
                  ),
                );
              },
            ),
    );
  }
}
