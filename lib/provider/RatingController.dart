import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workshop_management_system/modules/rating/services/RatingService.dart';

class RatingController extends ChangeNotifier {
  final FirebaseRatingService _ratingService = FirebaseRatingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _pendingRatings = [];
  List<Map<String, dynamic>> _myReviews = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get pendingRatings => _pendingRatings;
  List<Map<String, dynamic>> get myReviews => _myReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load pending ratings for a user
  Future<void> loadPendingRatings({
    required String userRole,
    required String userName,
    required String workshopName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final pendingRatings = await _ratingService.getPendingRatings(
        currentUser.uid,
      );

      _pendingRatings = pendingRatings;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user's reviews (both given and received)
  Future<void> loadMyReviews() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get both given and received ratings
      final givenRatings =
          await _firestore
              .collection('ratings')
              .where('reviewerId', isEqualTo: currentUser.uid)
              .get();

      final receivedRatings =
          await _firestore
              .collection('ratings')
              .where('ratedUserId', isEqualTo: currentUser.uid)
              .get();

      List<Map<String, dynamic>> loadedReviews = [];

      // Add given ratings
      for (var doc in givenRatings.docs) {
        final data = doc.data();
        loadedReviews.add({...data, 'documentId': doc.id, 'type': 'given'});
      }

      // Add received ratings
      for (var doc in receivedRatings.docs) {
        final data = doc.data();
        loadedReviews.add({...data, 'documentId': doc.id, 'type': 'received'});
      }

      // Sort by createdAt timestamp
      loadedReviews.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime); // Most recent first
      });

      _myReviews = loadedReviews;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit a new rating
  Future<void> submitRating({
    required String raterUserId,
    required String raterName,
    required String raterRole,
    required String ratedUserId,
    required String ratedName,
    required String ratedInitials,
    required double rating,
    required String review,
    String? contractId,
    bool isFromTerminatedContract = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _ratingService.saveRating(
        raterUserId: raterUserId,
        raterName: raterName,
        raterRole: raterRole,
        ratedUserId: ratedUserId,
        ratedName: ratedName,
        ratedInitials: ratedInitials,
        rating: rating,
        review: review,
        contractId: contractId,
        isFromTerminatedContract: isFromTerminatedContract,
      );

      // Refresh the reviews list
      await loadMyReviews();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing rating
  Future<void> updateRating({
    required String ratingId,
    required double rating,
    required String review,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _ratingService.updateRating(
        ratingId: ratingId,
        rating: rating,
        review: review,
      );

      // Refresh the reviews list
      await loadMyReviews();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get average rating for a user
  Future<double> getAverageRating(String userId) async {
    try {
      return await _ratingService.getAverageRating(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0.0;
    }
  }

  // Get rating count for a user
  Future<int> getRatingCount(String userId) async {
    try {
      return await _ratingService.getRatingCount(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
