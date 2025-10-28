import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../widgets/summary_item_widget.dart';
import 'trip_details_screen.dart';

class CompletedDaysScreen extends StatelessWidget {
  final String tripId;
  const CompletedDaysScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Days'),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F7FB), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<Trip?>(
          stream: TripService.getTripStream(tripId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading data: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final trip = snapshot.data;
            if (trip == null) {
              return const Center(child: Text('Trip not found.'));
            }

            final completedDays = trip.completedDays;
            final dailyExpenses = trip.dailyExpenses;
            final totalCost = trip.totalCost;
            final totalPeople = trip.totalPeople;
            final tripName = trip.tripName;

            if (completedDays.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No completed days yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete your first day to see it here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Sort completed days
            final sortedDays = List<int>.from(completedDays)..sort();

            return Column(
              children: [
                // Trip Summary Card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          tripName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SummaryItemWidget(
                                label: 'Total Cost',
                                value: '৳${totalCost.toStringAsFixed(0)}',
                                icon: Icons.account_balance_wallet,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SummaryItemWidget(
                                label: 'Per Person',
                                value:
                                    '৳${(totalCost / totalPeople).toStringAsFixed(0)}',
                                icon: Icons.person,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SummaryItemWidget(
                                label: 'Completed Days',
                                value: '${completedDays.length}',
                                icon: Icons.calendar_today,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SummaryItemWidget(
                                label: 'People',
                                value: '$totalPeople',
                                icon: Icons.group,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Completed Days List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sortedDays.length,
                    itemBuilder: (context, index) {
                      final dayNumber = sortedDays[index];
                      final dayKey = 'day_$dayNumber';
                      final dayData =
                          dailyExpenses[dayKey] as Map<String, dynamic>? ?? {};
                      final dayTotal = (dayData['total'] ?? 0).toDouble();
                      final dayExpenses =
                          dayData['expenses'] as Map<String, dynamic>? ?? {};
                      final perPersonCost =
                          totalPeople > 0 ? dayTotal / totalPeople : 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              '$dayNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Day $dayNumber',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Total: ৳${dayTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Per Person: ৳${perPersonCost.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (dayExpenses.isNotEmpty)
                                Text(
                                  '${dayExpenses.length} categories',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.deepPurple,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DayDetailsScreen(
                                  tripId: tripId,
                                  dayNumber: dayNumber,
                                  tripName: tripName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
