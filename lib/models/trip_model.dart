import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String userId;
  final String tripName;
  final int totalPeople;
  final int expectedDuration;
  final double expectedBudget;
  final String status;
  final DateTime createdAt;
  final int currentDay;
  final List<int> completedDays;
  final double totalCost;
  final Map<String, dynamic> dailyExpenses;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  Trip({
    required this.id,
    required this.userId,
    required this.tripName,
    required this.totalPeople,
    required this.expectedDuration,
    required this.expectedBudget,
    required this.status,
    required this.createdAt,
    required this.currentDay,
    required this.completedDays,
    required this.totalCost,
    required this.dailyExpenses,
    this.completedAt,
    this.updatedAt,
  });

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      tripName: data['tripName'] ?? '',
      totalPeople: data['totalPeople'] ?? 1,
      expectedDuration: data['expectedDuration'] ?? 1,
      expectedBudget: (data['expectedBudget'] ?? 0).toDouble(),
      status: data['status'] ?? 'running',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentDay: data['currentDay'] ?? 1,
      completedDays: List<int>.from(data['completedDays'] ?? []),
      totalCost: (data['totalCost'] ?? 0).toDouble(),
      dailyExpenses: Map<String, dynamic>.from(data['dailyExpenses'] ?? {}),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tripName': tripName,
      'totalPeople': totalPeople,
      'expectedDuration': expectedDuration,
      'expectedBudget': expectedBudget,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentDay': currentDay,
      'completedDays': completedDays,
      'totalCost': totalCost,
      'dailyExpenses': dailyExpenses,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'running';

  double get costPerPerson => totalPeople > 0 ? totalCost / totalPeople : 0;

  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
