import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workshop_management_system/modules/schedule/views/assignTask.dart';
import 'package:workshop_management_system/modules/schedule/views/blankSchedule.dart';
import 'package:workshop_management_system/modules/schedule/views/foreman.dart';
import 'package:workshop_management_system/modules/schedule/views/notifications.dart';
import 'package:workshop_management_system/modules/schedule/views/taskDetail.dart';
import 'package:workshop_management_system/modules/schedule/views/tasks.dart';
import 'package:workshop_management_system/modules/schedule/widgets/foremanCard.dart';
import 'package:workshop_management_system/modules/schedule/widgets/taskCard.dart';
import '../models/taskModel.dart';
import '../../sidebar.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final List<Map<String, dynamic>> _pendingRatings = [];
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  void addPendingRating(Map<String, dynamic> ratingData) {
    // Check if a similar rating already exists
    bool exists = _pendingRatings.any(
      (rating) =>
          rating['contractId'] == ratingData['contractId'] &&
          rating['forUserRole'] == ratingData['forUserRole'],
    );

    if (!exists) {
      _pendingRatings.add(ratingData);
      _notifyListeners();
    }
  }

  // Now filter by user role AND user identity (foremanName or workshopName)
  List<Map<String, dynamic>> getPendingRatingsForUser(
    String userRole,
    String userName,
    String workshopName,
  ) {
    return _pendingRatings.where((rating) {
      if (rating['forUserRole'] != userRole) return false;

      if (userRole == 'foreman') {
        return rating['foremanName'] == userName;
      } else if (userRole == 'workshop') {
        return rating['workshopName'] == workshopName;
      }
      return false;
    }).toList();
  }

  void removePendingRating(Map<String, dynamic> ratingData) {
    _pendingRatings.removeWhere(
      (rating) =>
          rating['contractId'] == ratingData['contractId'] &&
          rating['forUserRole'] == ratingData['forUserRole'],
    );
    _notifyListeners();
  }

  // Debug method to print all pending ratings
  void debugPrintRatings() {
    print('All pending ratings:');
    for (var rating in _pendingRatings) {
      print(
        'Rating for ${rating['forUserRole']}: ${rating['name']} (Workshop: ${rating['workshopName']}, Foreman: ${rating['foremanName']})',
      );
    }
  }
}

class Schedule extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userPosition;

  const Schedule({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userPosition,
  });

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  late Future<String> userRoleFuture;
  String? role;
  bool showNotification = false;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? workshopName;
  List<TaskModel> tasks = [];
  List<Map<String, dynamic>> foremen = [];
  bool isContractTerminated = false;

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  @override
  void initState() {
    super.initState();
    userRoleFuture = getUserRole();
    getWorkshopName().then((name) {
      if (widget.userRole.toLowerCase() == 'foreman' &&
          (name == null || name.isEmpty)) {
        // Redirect to blank setup page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BlankSchedulePage()),
          );
        });
      } else {
        // Set it to state if needed elsewhere
        setState(() {
          workshopName = name;
        });
      }
    });
    fetchTasks();
    fetchWorkTime();
    checkUnreadNotifications();
    fetchForemen();
  }

  Future<void> checkUnreadNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .where('isRead', isEqualTo: false)
            .get();

    setState(() {
      showNotification =
          snapshot.docs.isNotEmpty; // ✅ TRUE only when unread exists
    });
  }

  Future<String?> getWorkshopName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data();
    final role = data?['role'];

    if (role == 'workshop_owner') {
      return data?['fullName'];
    } else if (role == 'foreman') {
      return data?['workshopName']; // this might be null
    }
    return null;
  }

  Future<String> getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc['role'];
  }

  Future<void> fetchForemen() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1. Get current owner's full name
    final ownerDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final ownerName = ownerDoc.data()?['fullName'];

    if (ownerName == null) return;

    // 2. Get all foremen assigned to this owner's workshop
    final foremenQuery =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'foreman')
            .where('workshopName', isEqualTo: ownerName)
            .get();

    // 3. For each foreman, fetch worktime from worktimes collection
    List<Map<String, dynamic>> loadedForemen = [];

    for (var doc in foremenQuery.docs) {
      final foremanId = doc.id;
      final foremanData = doc.data();

      final workTimeDoc =
          await FirebaseFirestore.instance
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
    });
  }

  Future<void> fetchWorkTime() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('worktimes').doc(uid).get();

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
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      startTime!.hour,
      startTime!.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endTime!.hour,
      endTime!.minute,
    );

    await FirebaseFirestore.instance.collection('worktimes').doc(uid).set({
      'startTime': Timestamp.fromDate(startDateTime),
      'endTime': Timestamp.fromDate(endDateTime),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Work time updated")));
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
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = userDoc['role'];
    if (role == "foreman") {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('foremanId', isEqualTo: uid)
              .get();

      setState(() {
        tasks =
            querySnapshot.docs
                .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
                .toList();
      });
    } else {
      final workshopName = userDoc['fullName'];
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('workshopName', isEqualTo: workshopName)
              .get();

      setState(() {
        tasks =
            querySnapshot.docs
                .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
                .toList();
      });
    }
  }

  void _terminateContract() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terminate Contract'),
          content: const Text(
            'Are you sure you want to terminate this contract? This will trigger a mutual rating process.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Terminate',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        isContractTerminated = true;
      });

      final String contractId =
          'contract_${DateTime.now().millisecondsSinceEpoch}';
      final DateTime now = DateTime.now();
      final String formattedDate = '${now.day}/${now.month}/${now.year}';

      String otherPartyName;
      String otherPartyInitials;
      String otherPartyRole;
      String foremanName;
      String currentWorkshopName;

      if (widget.userRole.toLowerCase() == 'foreman') {
        // Foreman is logged in, workshop is associated workshop
        currentWorkshopName = workshopName ?? 'Unknown Workshop';
        foremanName = widget.userName;

        otherPartyName = currentWorkshopName;
        otherPartyInitials = _getInitials(currentWorkshopName);
        otherPartyRole = 'workshop';

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'workshopName': FieldValue.delete(),
          });
        }

        // ✅ Navigate to blank schedule screen after clearing workshop
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BlankSchedulePage()),
          );
        }
      } else {
        // Workshop owner logged in
        currentWorkshopName = widget.userName;
        foremanName =
            'John Foreman'; // Replace with actual foreman name linked to contract

        otherPartyName = foremanName;
        otherPartyInitials = _getInitials(foremanName);
        otherPartyRole = 'foreman';
      }

      // Create rating data for workshop owner
      final workshopRatingData = {
        'contractId': contractId,
        'forUserRole': 'workshop',
        'name':
            widget.userRole.toLowerCase() == 'foreman'
                ? widget.userName
                : otherPartyName,
        'initials':
            widget.userRole.toLowerCase() == 'foreman'
                ? _getInitials(widget.userName)
                : otherPartyInitials,
        'date': formattedDate,
        'message':
            'Contract terminated. Please rate your experience working together.',
        'targetRole': 'foreman',
        'workshopName': currentWorkshopName,
        'foremanName': foremanName,
      };

      // Create rating data for foreman
      final foremanRatingData = {
        'contractId': contractId,
        'forUserRole': 'foreman',
        'name':
            widget.userRole.toLowerCase() == 'workshop'
                ? widget.userName
                : otherPartyName,
        'initials':
            widget.userRole.toLowerCase() == 'workshop'
                ? _getInitials(widget.userName)
                : otherPartyInitials,
        'date': formattedDate,
        'message':
            'Contract terminated. Please rate your experience working together.',
        'targetRole': 'workshop',
        'workshopName': currentWorkshopName,
        'foremanName': foremanName,
      };

      // Add ratings for both parties
      RatingService().addPendingRating(workshopRatingData);
      RatingService().addPendingRating(foremanRatingData);

      // Force rebuild of the sidebar to update notification badge
      if (mounted) {
        setState(() {
          // Rebuild the scaffold to trigger sidebar rebuild
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => Schedule(
                    userName: widget.userName,
                    userRole: widget.userRole,
                    userPosition: widget.userPosition,
                  ),
            ),
          );
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contract terminated successfully. Rating requests have been created.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join()
        .toUpperCase();
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
          final primaryColor =
              userRole == 'foreman' ? Colors.green : Colors.blue;
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
                      MaterialPageRoute(
                        builder: (_) => NotificationsPage(userRole: role),
                      ),
                    );
                    checkUnreadNotifications(); // 👈 Refresh banner after returning
                  },
                  child: const Text(
                    'Notification',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ],
            ),
            drawer: SidebarMenu(
              userRole:
                  widget.userRole.toLowerCase() == 'foreman'
                      ? UserRole.Foreman
                      : UserRole.WorkshopOwner,
              userName: widget.userName,
              userPosition: widget.userPosition,
              selectedTitle: 'Schedule',
              originalUserRole: widget.userRole,
              onSelectedTitleChanged: (title) {
                // Optional: sync state or navigation logic here
              },
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (showNotification)
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
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
                          onPressed:
                              () => setState(() => showNotification = false),
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

    final recentTasks =
        tasks..sort(
          (a, b) => b.taskStartTime.compareTo(a.taskStartTime),
        ); // Sort descending
    final topTwoTasks = recentTasks.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workshop Name:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: workshopName,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isContractTerminated ? Colors.grey : Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: isContractTerminated ? null : _terminateContract,
              child: Text(
                isContractTerminated ? "Terminated" : "Terminate Contract",
              ),
            ),
          ],
        ),

        if (isContractTerminated)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contract terminated. Please navigate to Ratings to complete the mutual rating process.',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
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
            const Text(
              "Task",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            TextButton(
              onPressed: () async {
                final userRole = await userRoleFuture;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TasksPage(userRole: userRole),
                  ),
                );
              },
              child: const Text(
                "See All",
                style: TextStyle(color: Colors.blue),
              ),
            ),
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
              children:
                  topTwoTasks
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskCard(
                            task: task,
                            onTap: () async {
                              final userRole = await userRoleFuture;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => TaskDetailPage(
                                        taskId: task.id,
                                        userRole: userRole,
                                      ),
                                ),
                              );
                              // ✅ Reload tasks after coming back
                              setState(() {
                                fetchTasks(); // make sure this re-queries Firestore
                              });
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
      ],
    );
  }

  Widget buildOwnerView() {
    final recentTasks =
        tasks..sort((a, b) => b.taskStartTime.compareTo(a.taskStartTime));
    final topTwoTasks = recentTasks.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Workshop Name: $workshopName",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Foreman",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            TextButton(
              onPressed: () async {
                final userRole = await userRoleFuture;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ForemanPage()),
                );
              },
              child: const Text(
                "See All",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children:
              foremen.take(2).map((foreman) {
                final start = TimeOfDay.fromDateTime(foreman['startTime']);
                final end = TimeOfDay.fromDateTime(foreman['endTime']);
                final formattedTime =
                    "${start.format(context)} – ${end.format(context)}";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ForemanCard(
                    name: foreman['name'],
                    time: formattedTime,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AssignTaskPage(
                                foremanId:
                                    foreman['foremanId'], // ✅ Ensure correct key
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
            const Text(
              "Task",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            TextButton(
              onPressed: () async {
                final userRole = await userRoleFuture;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TasksPage(userRole: userRole),
                  ),
                );
              },
              child: const Text(
                "See All",
                style: TextStyle(color: Colors.blue),
              ),
            ),
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
              children:
                  topTwoTasks
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskCard(
                            task: task,
                            onTap: () async {
                              final userRole = await userRoleFuture;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => TaskDetailPage(
                                        taskId: task.id,
                                        userRole: userRole,
                                      ),
                                ),
                              );
                              // ✅ Reload tasks after coming back
                              setState(() {
                                fetchTasks(); // make sure this re-queries Firestore
                              });
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
      ],
    );
  }
}
