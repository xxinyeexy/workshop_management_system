import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/schedule/views/assignTask.dart';
import 'package:workshop_management_system/modules/schedule/views/notifications.dart';
import 'package:workshop_management_system/modules/schedule/views/taskDetail.dart';
import 'package:workshop_management_system/modules/schedule/views/tasks.dart';
import 'package:workshop_management_system/modules/schedule/widgets/foremanCard.dart';
import 'package:workshop_management_system/modules/schedule/widgets/taskCard.dart';
import '../models/scheduleInfo.dart'; // <-- Use ScheduleInfo here

const String userRole = 'owner'; // or 'owner'

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
  bool showNotification = true;

  Future<void> _selectTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: userRole == 'foreman' ? Colors.green : Colors.blue,
        centerTitle: true,
        title: const Text(
          'Schedule',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
            },
            child: const Text('Notification', style: TextStyle(color: Colors.black, fontSize: 16)),
          ),
        ],
      ),
      drawer: Drawer(child: ListView(padding: EdgeInsets.zero, children: [])),
      body: userRole == 'foreman' ? buildForemanView() : buildOwnerView(),
    );
  }

  Widget buildForemanView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showNotification)
          Container(
            decoration: BoxDecoration(color: const Color(0xFFDFFFE3), borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(child: Text("You have new notification!", style: TextStyle(fontWeight: FontWeight.w600))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => showNotification = false)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text("Workshop Name:", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: "Ali Workshop",
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // You can add your termination logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Contract Terminated")),
                );
              },
              child: const Text("Terminate Contract"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(children: const [Text("Worktime", style: TextStyle(fontWeight: FontWeight.w500)), SizedBox(width: 4), Icon(Icons.edit, size: 18)]),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: GestureDetector(onTap: () => _selectTime(isStart: true), child: TimeFieldDisplay(label: formatTime(startTime)))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("to")),
            Expanded(child: GestureDetector(onTap: () => _selectTime(isStart: false), child: TimeFieldDisplay(label: formatTime(endTime)))),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Task", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksPage(userRole: userRole)));
              },
              child: const Text("See All", style: TextStyle(color: Colors.blue)),
            )
          ],
        ),
        const SizedBox(height: 12),
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
    );
  }

  Widget buildOwnerView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showNotification)
          Container(
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("You have new notification!", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => showNotification = false)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text("Foreman", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          Text("See All", style: TextStyle(color: Colors.blue)),
        ]),
        const SizedBox(height: 12),
        ForemanCard(
          name: "Jackson Liu",
          time: "8:00 AM – 6:00 PM",
          status: "Free",
          statusColor: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AssignTaskPage(foremanName: "Jackson Liu", workTime: "8:00 AM – 6:00 PM"),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Task", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksPage(userRole: userRole)));
              },
              child: const Text("See All", style: TextStyle(color: Colors.blue)),
            )
          ],
        ),
        const SizedBox(height: 12),
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
    );
  }
}

class TimeFieldDisplay extends StatelessWidget {
  final String label;
  const TimeFieldDisplay({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
