import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseRatingService {
  static final FirebaseRatingService _instance =
      FirebaseRatingService._internal();
  factory FirebaseRatingService() => _instance;
  FirebaseRatingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _ratingsCollection = 'ratings';
  static const String _pendingRatingsCollection = 'pending_ratings';

  // Save a new rating to Firebase
  Future<void> saveRating({
    required String raterUserId,
    required String raterName,
    required String raterRole, // 'foreman' or 'workshop'
    required String ratedUserId,
    required String ratedName,
    required String ratedInitials,
    required double rating,
    required String review,
    String? contractId,
    bool isFromTerminatedContract = false,
  }) async {
    try {
      final ratingData = {
        'raterUserId': raterUserId,
        'raterName': raterName,
        'raterRole': raterRole,
        'ratedUserId': ratedUserId,
        'ratedName': ratedName,
        'ratedInitials': ratedInitials,
        'rating': rating,
        'review': review,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'contractId': contractId,
        'isFromTerminatedContract': isFromTerminatedContract,
      };

      // Save to ratings collection
      await _firestore.collection(_ratingsCollection).add(ratingData);

      // Remove from pending ratings if it exists
      if (contractId != null) {
        await removePendingRating(contractId, raterUserId);
      }
    } catch (e) {
      throw Exception('Failed to save rating: $e');
    }
  }

  // Update an existing rating
  Future<void> updateRating({
    required String ratingId,
    required double rating,
    required String review,
  }) async {
    try {
      await _firestore.collection(_ratingsCollection).doc(ratingId).update({
        'rating': rating,
        'review': review,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  // Get all ratings submitted by a user
  Future<List<Map<String, dynamic>>> getUserRatings(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_ratingsCollection)
              .where('raterUserId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID for updates
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user ratings: $e');
    }
  }

  // Get all ratings received by a user
  Future<List<Map<String, dynamic>>> getRatingsForUser(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_ratingsCollection)
              .where('ratedUserId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch ratings for user: $e');
    }
  }

  // Add pending rating (when contract is terminated)
  Future<void> addPendingRating({
    required String contractId,
    required String raterUserId,
    required String raterRole,
    required String ratedUserId,
    required String ratedName,
    required String ratedInitials,
    required String terminationDate,
    String? message,
  }) async {
    try {
      final pendingRatingData = {
        'contractId': contractId,
        'raterUserId': raterUserId,
        'raterRole': raterRole,
        'ratedUserId': ratedUserId,
        'ratedName': ratedName,
        'ratedInitials': ratedInitials,
        'terminationDate': terminationDate,
        'message': message ?? 'Please rate your experience with this partner.',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_pendingRatingsCollection)
          .doc('${contractId}_$raterUserId')
          .set(pendingRatingData);
    } catch (e) {
      throw Exception('Failed to add pending rating: $e');
    }
  }

  // Get pending ratings for a user
  Future<List<Map<String, dynamic>>> getPendingRatings(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_pendingRatingsCollection)
              .where('raterUserId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return {
          'contractId': data['contractId'],
          'name': data['ratedName'],
          'initials': data['ratedInitials'],
          'date': data['terminationDate'],
          'message': data['message'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending ratings: $e');
    }
  }

  // Remove pending rating
  Future<void> removePendingRating(
    String contractId,
    String raterUserId,
  ) async {
    try {
      await _firestore
          .collection(_pendingRatingsCollection)
          .doc('${contractId}_$raterUserId')
          .delete();
    } catch (e) {
      throw Exception('Failed to remove pending rating: $e');
    }
  }

  // Get average rating for a user
  Future<double> getAverageRating(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_ratingsCollection)
              .where('ratedUserId', isEqualTo: userId)
              .get();

      if (querySnapshot.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      for (final doc in querySnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      return totalRating / querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to calculate average rating: $e');
    }
  }

  // Get rating count for a user
  Future<int> getRatingCount(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_ratingsCollection)
              .where('ratedUserId', isEqualTo: userId)
              .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get rating count: $e');
    }
  }
}
