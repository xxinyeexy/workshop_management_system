import 'package:cloud_firestore/cloud_firestore.dart';

class RatingInfo {
  final String? documentId;
  final String reviewerId;
  final String ratedUserId;
  final double rating;
  final String comment;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String reviewerRole;
  final String ratedUserRole;
  final String reviewerName;
  final String ratedUserName;
  final String type;
  final String? imageBase64;

  RatingInfo({
    this.documentId,
    required this.reviewerId,
    required this.ratedUserId,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.updatedAt,
    required this.reviewerRole,
    required this.ratedUserRole,
    required this.reviewerName,
    required this.ratedUserName,
    required this.type,
    this.imageBase64,
  });

  factory RatingInfo.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RatingInfo(
      documentId: docId,
      reviewerId: map['reviewerId'] ?? '',
      ratedUserId: map['ratedUserId'] ?? '',
      rating:
          (map['rating'] is int)
              ? (map['rating'] as int).toDouble()
              : (map['rating'] is double)
              ? map['rating']
              : double.tryParse(map['rating'].toString()) ?? 0.0,
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
      reviewerRole: map['reviewerRole'] ?? '',
      ratedUserRole: map['ratedUserRole'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      ratedUserName: map['ratedUserName'] ?? '',
      type: map['type'] ?? 'given',
      imageBase64: map['imageBase64'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'ratedUserId': ratedUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'reviewerRole': reviewerRole,
      'ratedUserRole': ratedUserRole,
      'reviewerName': reviewerName,
      'ratedUserName': ratedUserName,
      'type': type,
      'imageBase64': imageBase64,
    };
  }

  RatingInfo copyWith({
    String? documentId,
    String? reviewerId,
    String? ratedUserId,
    double? rating,
    String? comment,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? reviewerRole,
    String? ratedUserRole,
    String? reviewerName,
    String? ratedUserName,
    String? type,
    String? imageBase64,
  }) {
    return RatingInfo(
      documentId: documentId ?? this.documentId,
      reviewerId: reviewerId ?? this.reviewerId,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      ratedUserRole: ratedUserRole ?? this.ratedUserRole,
      reviewerName: reviewerName ?? this.reviewerName,
      ratedUserName: ratedUserName ?? this.ratedUserName,
      type: type ?? this.type,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}
