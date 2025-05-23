import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/schedule/widgets/taskCard.dart';
import 'package:workshop_management_system/modules/schedule/models/scheduleInfo.dart';
import 'taskDetail.dart';

class TasksPage extends StatelessWidget {
  final String userRole; // Accept from previous page

  const TasksPage({super.key, required this.userRole}); // Required in constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: userRole == 'foreman' ? Colors.green : Colors.blue,
        centerTitle: true,
        title: const Text(
          'Tasks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...mockScheduleList.map((task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: task,
              userRole: userRole,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailPage(
                      scheduleId: task.scheduleId,
                      userRole: userRole,
                    ),
                  ),
                );
              },
            ),
          )),
        ],
      ),
    );
  }
}
