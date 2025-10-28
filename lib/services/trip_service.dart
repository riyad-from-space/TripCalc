import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip_model.dart';

class TripService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Stream<List<Trip>> getUserTrips() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList());
  }

  static Future<String> createTrip({
    required String tripName,
    required int totalPeople,
    required int expectedDuration,
    required double expectedBudget,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final doc = await _firestore.collection('trips').add({
      'userId': userId,
      'tripName': tripName,
      'totalPeople': totalPeople,
      'expectedDuration': expectedDuration,
      'expectedBudget': expectedBudget,
      'status': 'running',
      'createdAt': FieldValue.serverTimestamp(),
      'currentDay': 1,
      'completedDays': [],
      'totalCost': 0,
      'dailyExpenses': {},
    });

    return doc.id;
  }

  static Future<Trip?> getTripById(String tripId) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (doc.exists) {
      return Trip.fromFirestore(doc);
    }
    return null;
  }

  static Stream<Trip?> getTripStream(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .map((doc) => doc.exists ? Trip.fromFirestore(doc) : null);
  }

  static Future<void> updateTripExpenses({
    required String tripId,
    required int day,
    required Map<String, dynamic> expenses,
    required double dayTotal,
  }) async {
    final tripDoc = await _firestore.collection('trips').doc(tripId).get();
    if (!tripDoc.exists) throw Exception('Trip not found');

    final data = tripDoc.data()!;
    final dailyExpenses =
        Map<String, dynamic>.from(data['dailyExpenses'] ?? {});

    dailyExpenses['day_$day'] = {
      'expenses': expenses,
      'total': dayTotal,
      'date': FieldValue.serverTimestamp(),
    };

    // Calculate new total cost
    double totalCost = 0;
    dailyExpenses.forEach((day, data) {
      if (data is Map && data.containsKey('total')) {
        totalCost += (data['total'] ?? 0).toDouble();
      }
    });

    await _firestore.collection('trips').doc(tripId).update({
      'dailyExpenses': dailyExpenses,
      'totalCost': totalCost,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> completeDay({
    required String tripId,
    required int day,
  }) async {
    final tripDoc = await _firestore.collection('trips').doc(tripId).get();
    if (!tripDoc.exists) throw Exception('Trip not found');

    final data = tripDoc.data()!;
    final completedDays = List<int>.from(data['completedDays'] ?? []);

    if (!completedDays.contains(day)) {
      completedDays.add(day);
    }

    final newCurrentDay = day + 1;

    await _firestore.collection('trips').doc(tripId).update({
      'completedDays': completedDays,
      'currentDay': newCurrentDay,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> completeTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Test Firebase connection
}
