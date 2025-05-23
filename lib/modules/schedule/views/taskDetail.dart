import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/schedule/models/scheduleInfo.dart';
import 'package:workshop_management_system/modules/schedule/views/reschedulingForm.dart';
import '../widgets/taskForm.dart';
import '../controllers/showCancel.dart';

class TaskDetailPage extends StatefulWidget {
  final String scheduleId;
  final String userRole;

  const TaskDetailPage({
    super.key,
    required this.scheduleId,
    required this.userRole,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  ScheduleInfo? task;

  @override
  void initState() {
    super.initState();
    loadTask();
  }

  void loadTask() {
    final fetched = mockScheduleList.firstWhere((t) => t.scheduleId == widget.scheduleId);
    setState(() => task = fetched);
  }

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final DateTime taskStartTime = DateTime(
      task!.taskDate.year,
      task!.taskDate.month,
      task!.taskDate.day,
      task!.taskStartTime.hour,
      task!.taskStartTime.minute,
    );
    final DateTime now = DateTime.now();

    final bool ownerCanAct = widget.userRole == 'owner' && now.isBefore(taskStartTime);
    final bool foremanCanAct = widget.userRole == 'foreman' && now.isAfter(taskStartTime);
    final bool canAct = ownerCanAct || foremanCanAct;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task"),
        backgroundColor: widget.userRole == 'owner' ? Colors.blue : Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.userRole == 'owner')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(task!.foremanName.split(" ").map((e) => e[0]).join()),
                ),
                title: Text(task!.foremanName, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            TaskField(label: "Task Assign", value: task!.taskTitle),
            TaskField(label: "Description", value: task!.taskDescription),
            Row(
              children: [
                Expanded(child: TaskField(label: "Date", value: "${task!.taskDate.toLocal()}".split(' ')[0])),
                const SizedBox(width: 8),
                Expanded(child: TaskField(label: "Reward", value: task!.taskReward)),
              ],
            ),
            Row(
              children: [
                Expanded(child: TaskField(label: "Start Time", value: task!.taskStartTime.format(context))),
                const SizedBox(width: 8),
                Expanded(child: TaskField(label: "End Time", value: task!.taskEndTime.format(context))),
              ],
            ),
            TaskField(label: "Status", value: task!.taskStatus),
            const Spacer(),
            if (canAct)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        showCancelTaskDialog(
                          context: context,
                          taskTitle: task!.taskTitle,
                          date: "${task!.taskDate.toLocal()}".split(' ')[0],
                          time: "${task!.taskStartTime.format(context)} - ${task!.taskEndTime.format(context)}",
                        );
                      },
                      child: const Text("Cancel Task", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReschedulePage(
                              title: task!.taskTitle,
                              date: "${task!.taskDate.toLocal()}".split(' ')[0],
                              time: "${task!.taskStartTime.format(context)} - ${task!.taskEndTime.format(context)}",
                            ),
                          ),
                        );
                      },
                      child: const Text("Rescheduling", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  widget.userRole == 'owner'
                      ? "You can only cancel/reschedule before the task starts."
                      : "You can only cancel/reschedule after the task starts.",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
