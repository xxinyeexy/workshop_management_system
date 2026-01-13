// notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  final String userRole;
  const NotificationsPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: userRole == 'foreman' ? Colors.green : Colors.blue,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: currentUser?.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Text("No notifications found");
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final docRef = doc.reference;

                  final timestamp = data['timestamp'] as Timestamp?;
                  final formattedTime =
                      timestamp != null ? timeAgo(timestamp) : 'Unknown time';

                  return GestureDetector(
                    onTap: () async {
                      // Mark as read
                      if (data['isRead'] == false) {
                        await docRef.update({'isRead': true});
                      }

                      // XQ Task 2 WORKSHOP OWNER APPROVAL
                      if (userRole == 'workshop_owner' &&
                          data['title'] == 'Workshop Join Request') {
                        final requestSnapshot =
                        await FirebaseFirestore.instance
                            .collection('workshop_requests')
                            .where('ownerId', isEqualTo: currentUser!.uid) //linked to respective id
                            .where('status', isEqualTo: 'pending')
                            .limit(1)
                            .get();


                        if (requestSnapshot.docs.isEmpty) return;

                        final requestDoc = requestSnapshot.docs.first;
                        final requestData =
                            requestDoc.data() as Map<String, dynamic>;

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Workshop Join Request"),
                              content: Text(
                                '${requestData['foremanName']} wants to join "${requestData['workshopName']}".',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    // XQ TASK 2 REJECT JOINING REQUEST 
                                    await requestDoc.reference.update({
                                      'status': 'rejected',
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Reject"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () async {
                                    // XQ TASK 2 APPROVE JOINING REQUEST
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(requestData['foremanId'])
                                        .update({
                                      'workshopName':
                                          requestData['workshopName'],
                                    });

                                    await FirebaseFirestore.instance
                                        .collection('notifications')
                                        .add({
                                      'userId': requestData['foremanId'],
                                      'title': 'Workshop Approved',
                                      'body':
                                          'Your request to join "${requestData['workshopName']}" has been approved.',
                                      'timestamp': Timestamp.now(),
                                      'isRead': false,
                                    });

                                    await requestDoc.reference.update({
                                      'status': 'approved',
                                    });

                                    Navigator.pop(context);
                                  },
                                  child: const Text("Approve"),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: data['isRead'] == false
                            ? Colors.blue.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'No Title',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(data['body'] ?? ''),
                          const SizedBox(height: 6),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // XQ TASK 2 DISPLAY JOINING WORKSHOP REQUEST
          if (userRole == 'workshop_owner') ...[
            const SizedBox(height: 24),
            const Text(
              "Join Requests",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
              .collection('workshop_requests')
              .where('ownerId', isEqualTo: currentUser!.uid) // LINKED TO RESPECTIVE UID
              .where('status', isEqualTo: 'pending')
              .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No pending join requests");
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['foremanName'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Requested to join "${data['workshopName']}"',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return "${diff.inMinutes} minutes ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return DateFormat('yMMMd').format(date);
  }
}
