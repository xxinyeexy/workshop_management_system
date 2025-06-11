import 'package:cloud_firestore/cloud_firestore.dart';

class WorkTimeModel {
  final String userId;
  final Timestamp startTime;
  final Timestamp endTime;

  WorkTimeModel({
    required this.userId,
    required this.startTime,
    required this.endTime,
  });

  factory WorkTimeModel.fromMap(Map<String, dynamic> map, String userId) {
    return WorkTimeModel(
      userId: userId,
      startTime: map['startTime'] ?? Timestamp.now(),
      endTime: map['endTime'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
