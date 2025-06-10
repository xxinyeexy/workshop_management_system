import 'package:flutter/material.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  // Store pending ratings with user-specific keys
  final Map<String, List<Map<String, dynamic>>> _pendingRatings = {};

  // Add a pending rating for specific users
  void addPendingRating({
    required String foremanName,
    required String workshopName,
    required Map<String, dynamic> ratingData,
  }) {
    final foremanKey = 'foreman_$foremanName';
    final workshopKey = 'workshop_$workshopName';

    final foremanRatingData = {
      ...ratingData,
      'name': workshopName, // Foreman rates workshop
      'initials': _getInitials(workshopName),
      'raterRole': 'foreman',
      'targetRole': 'workshop',
      'foremanName': foremanName,
      'workshopName': workshopName,
    };

    final workshopRatingData = {
      ...ratingData,
      'name': foremanName, // Workshop rates foreman
      'initials': _getInitials(foremanName),
      'raterRole': 'workshop',
      'targetRole': 'foreman',
      'foremanName': foremanName,
      'workshopName': workshopName,
    };

    _pendingRatings[foremanKey] = _pendingRatings[foremanKey] ?? [];
    _pendingRatings[workshopKey] = _pendingRatings[workshopKey] ?? [];

    _pendingRatings[foremanKey]!.add(foremanRatingData);
    _pendingRatings[workshopKey]!.add(workshopRatingData);

    print('Added pending rating: Foreman "$foremanName" can rate Workshop "$workshopName"');
    print('Added pending rating: Workshop "$workshopName" can rate Foreman "$foremanName"');
  }

  List<Map<String, dynamic>> getPendingRatingsForSpecificUser(
    String userRole, {
    required String userName,
    String? workshopName,
  }) {
    final userKey = '${userRole}_$userName';
    final ratings = _pendingRatings[userKey] ?? [];

    List<Map<String, dynamic>> filteredRatings = ratings;
    
    if (workshopName != null) {
      filteredRatings = ratings.where((rating) {
        if (userRole == 'foreman') {
          return rating['workshopName'] == workshopName;
        } else {
          return rating['foremanName'] == workshopName;
        }
      }).toList();
    }

    print('Getting pending ratings for $userKey: ${filteredRatings.length} found');
    return List<Map<String, dynamic>>.from(filteredRatings);
  }

  void removePendingRatingSpecific(
    String userRole, 
    String userName, 
    String? contractId,
    String? workshopName,
    String? foremanName,
  ) {
    final userKey = '${userRole}_$userName';

    if (_pendingRatings.containsKey(userKey)) {
      _pendingRatings[userKey]!.removeWhere((rating) {
        if (contractId != null && rating['contractId'] == contractId) {
          return true;
        }
        if (workshopName != null && foremanName != null) {
          return rating['workshopName'] == workshopName && rating['foremanName'] == foremanName;
        }
        return false;
      });

      print('Removed pending rating for $userKey (Contract: $contractId, Workshop: $workshopName, Foreman: $foremanName)');
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return words.take(2).map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
    }
  }
}
