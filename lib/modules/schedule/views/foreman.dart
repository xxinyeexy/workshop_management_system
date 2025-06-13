import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../views/assignTask.dart';
import '../widgets/foremanCard.dart';

class ForemanPage extends StatefulWidget {
  const ForemanPage({super.key});

  @override
  State<ForemanPage> createState() => _ForemanPageState();
}

class _ForemanPageState extends State<ForemanPage> {
  List<Map<String, dynamic>> foremen = [];

  @override
  void initState() {
    super.initState();
    fetchForemen();
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

    for (var doc in foremenQuery.docs) { // ✅ Limit to max 2 foremen
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
    });
  }

  String formatTime(DateTime time) => DateFormat.jm().format(time);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
                "Foreman",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: foremen.length,
        itemBuilder: (context, index) {
          final foreman = foremen[index];
          final startTime = foreman['startTime'] != null ? formatTime(foreman['startTime']) : '--';
          final endTime = foreman['endTime'] != null ? formatTime(foreman['endTime']) : '--';
          final formattedTime = "$startTime – $endTime";

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
                      foremanId: foreman['foremanId'],
                      foremanName: foreman['name'],
                      workTime: formattedTime,
                    ),
                  ),
                );
                await fetchForemen(); // ✅ Refresh after return
              },
            ),
          );
        },
      ),
    );
  }
}
