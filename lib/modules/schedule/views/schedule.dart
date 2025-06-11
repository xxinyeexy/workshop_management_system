import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workshop_management_system/modules/schedule/views/assignTask.dart';
import 'package:workshop_management_system/modules/schedule/views/foreman.dart';
import 'package:workshop_management_system/modules/schedule/views/notifications.dart';
import 'package:workshop_management_system/modules/schedule/views/taskDetail.dart';
import 'package:workshop_management_system/modules/schedule/views/tasks.dart';
import 'package:workshop_management_system/modules/schedule/widgets/foremanCard.dart';
import 'package:workshop_management_system/modules/schedule/widgets/taskCard.dart';
import '../models/taskModel.dart';
import '../../sidebar.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  late Future<String> userRoleFuture;
  String? role;
  bool showNotification = true;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? workshopName;
  List<TaskModel> tasks = [];
  List<Map<String, dynamic>> foremen = [];
  
  

  String _formatTimeOfDay(TimeOfDay time) {
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  return TimeOfDay.fromDateTime(dt).format(context);
  }

  @override
  void initState() {
    super.initState();
    userRoleFuture = getUserRole();
    fetchTasks();
    fetchWorkTime();
    checkUnreadNotifications();
    fetchForemen();
  }

  Future<void> checkUnreadNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    setState(() {
      showNotification = snapshot.docs.isNotEmpty; // ✅ TRUE only when unread exists
    });
  }


  Future<String> getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc['role'];
  }

  Future<void> fetchForemen() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1. Get current owner's full name
    final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final ownerName = ownerDoc.data()?['fullName'];

    if (ownerName == null) return;

    // 2. Get all foremen assigned to this owner's workshop
    final foremenQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'foreman')
        .where('workshopName', isEqualTo: ownerName)
        .get();

    // 3. For each foreman, fetch worktime from worktimes collection
    List<Map<String, dynamic>> loadedForemen = [];

    for (var doc in foremenQuery.docs) {
      final foremanId = doc.id;
      final foremanData = doc.data();

      final workTimeDoc = await FirebaseFirestore.instance
          .collection('worktimes')
          .doc(foremanId)
          .get();

      if (workTimeDoc.exists) {
        final workTime = workTimeDoc.data()!;
        loadedForemen.add({
          'foremanId': foremanId,
          'name': foremanData['fullName'],
          'startTime': (workTime['startTime'] as Timestamp).toDate(),
          'endTime': (workTime['endTime'] as Timestamp).toDate(),
        });
      }
    }

    setState(() {
      foremen = loadedForemen;
      workshopName = ownerName;
    });
  }

  Future<void> fetchWorkTime() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('worktimes').doc(uid).get();

    if (doc.exists && doc.data()!.containsKey('startTime')) {
      final data = doc.data()!;
      final start = (data['startTime'] as Timestamp).toDate();
      final end = (data['endTime'] as Timestamp).toDate();

      setState(() {
        startTime = TimeOfDay(hour: start.hour, minute: start.minute);
        endTime = TimeOfDay(hour: end.hour, minute: end.minute);
      });
    } else {
      // Optional: fallback defaults if no data yet
      setState(() {
        startTime = const TimeOfDay(hour: 8, minute: 0);
        endTime = const TimeOfDay(hour: 18, minute: 0);
      });
    }
  }


  Future<void> _updateWorkTime() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Use today's date, just to satisfy the DateTime requirements
    final now = DateTime.now();
    final startDateTime = DateTime(now.year, now.month, now.day, startTime!.hour, startTime!.minute);
    final endDateTime = DateTime(now.year, now.month, now.day, endTime!.hour, endTime!.minute);

    await FirebaseFirestore.instance.collection('worktimes').doc(uid).set({
      'startTime': Timestamp.fromDate(startDateTime),
      'endTime': Timestamp.fromDate(endDateTime),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Work time updated")),
    );
  }


  Future<void> _selectTime({required bool isStart}) async {
    final initial = isStart ? startTime! : endTime!;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
      await _updateWorkTime();
    }
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
    return FutureBuilder<String>(
      future: userRoleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          final userRole = snapshot.data!;
          final primaryColor = userRole == 'foreman' ? Colors.green : Colors.blue;
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: primaryColor,
              leading: Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                  final role = await userRoleFuture;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationsPage(userRole: role)),
                  );
                  checkUnreadNotifications(); // 👈 Refresh banner after returning
                },
                  child: const Text('Notification', style: TextStyle(color: Colors.black, fontSize: 16)),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (showNotification)
                Container(
                  decoration: BoxDecoration(
                    color:  primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "You have unread notifications!",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => showNotification = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                userRole == 'foreman' ? buildForemanView() : buildOwnerView(),
              ],
            ),
          );
        }
      },
    );
  }

  Widget buildForemanView() {
    if (startTime == null || endTime == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final recentTasks = tasks
    ..sort((a, b) => b.taskStartTime.compareTo(a.taskStartTime)); // Sort descending
    final topTwoTasks = recentTasks.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Workshop Name:', style: TextStyle(fontWeight: FontWeight.w500)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Job Terminated")),
                );
              },
              child: const Text("Terminate Job"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text("Worktime", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(isStart: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTimeOfDay(startTime!),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("to"),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(isStart: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTimeOfDay(endTime!),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Task", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            TextButton(
              onPressed: () async {
                final userRole = await userRoleFuture;
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => TasksPage(userRole: userRole)));
              },
              child: const Text("See All", style: TextStyle(color: Colors.blue)),
            )
          ],
        ),
        const SizedBox(height: 12),
        (tasks.isEmpty)
        ? const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "No tasks assigned",
              style: TextStyle(color: Colors.grey),
            ),
          )
        : Column(
            children: topTwoTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCard(
                task: task,
                onTap: () async {
                  final userRole = await userRoleFuture;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailPage(taskId: task.id, userRole: userRole),
                    ),
                  );
                  // ✅ Reload tasks after coming back
                  setState(() {
                    fetchTasks(); // make sure this re-queries Firestore
                  });
                },
              ),
            )).toList(),
          ),
      ],
    );
  }


  Widget buildOwnerView() {
    final recentTasks = tasks..sort((a, b) => b.taskStartTime.compareTo(a.taskStartTime));
    final topTwoTasks = recentTasks.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Workshop Name: $workshopName", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Foreman", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            TextButton(
              onPressed: () async {
                final userRole = await userRoleFuture;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ForemanPage(),
                  ),
                );
              },
              child: const Text("See All", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
        children: foremen.take(2).map((foreman) {
          final start = TimeOfDay.fromDateTime(foreman['startTime']);
          final end = TimeOfDay.fromDateTime(foreman['endTime']);
          final formattedTime = "${start.format(context)} – ${end.format(context)}";

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ForemanCard(
              name: foreman['name'],
              time: formattedTime,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignTaskPage(
                      foremanId: foreman['foremanId'], // ✅ Ensure correct key
                      foremanName: foreman['name'],
                      workTime: formattedTime,
                    ),
                  ),
                );

                // ✅ Refresh tasks after coming back
                setState(() {
                  fetchTasks();
                });
              },
            ),
          );
        }).toList(),
      ),
        // Example static card
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Task", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            TextButton(
              onPressed: () async {
                final userRole = await userRoleFuture;
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => TasksPage(userRole: userRole)));
              },
              child: const Text("See All", style: TextStyle(color: Colors.blue)),
            )
          ],
        ),
        const SizedBox(height: 12),
        (tasks.isEmpty)
        ? const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "No tasks assigned",
              style: TextStyle(color: Colors.grey),
            ),
          )
        : Column(
            children: topTwoTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCard(
                task: task,
                onTap: () async {
                  final userRole = await userRoleFuture;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailPage(taskId: task.id, userRole: userRole),
                    ),
                  );
                  // ✅ Reload tasks after coming back
                  setState(() {
                    fetchTasks(); // make sure this re-queries Firestore
                  });
                },
              ),
            )).toList(),
          ),
      ],
    );
  }

}