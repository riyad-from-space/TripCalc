import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../screens/trip_management_screen.dart';
import '../screens/completed_trip_summary_screen.dart';
import '../widgets/summary_item_widget.dart';

class TripCardWidget extends StatelessWidget {
  final Trip trip;

  const TripCardWidget({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          if (trip.isCompleted) {
            // For completed trips, show summary directly
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompletedTripSummaryScreen(trip: trip),
              ),
            );
          } else {
            // For active trips, go to management screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripManagementScreen(tripId: trip.id),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.tripName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trip.isCompleted ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trip.isCompleted ? 'Completed' : 'Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${trip.formattedCreatedDate}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SummaryItemWidget(
                      label: 'Total Cost',
                      value: '৳${trip.totalCost.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryItemWidget(
                      label: 'Per Person',
                      value: '৳${trip.costPerPerson.toStringAsFixed(0)}',
                      icon: Icons.person,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SummaryItemWidget(
                      label: 'People',
                      value: '${trip.totalPeople}',
                      icon: Icons.group,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SummaryItemWidget(
                      label: trip.isCompleted ? 'Days' : 'Current Day',
                      value: trip.isCompleted
                          ? '${trip.completedDays.length}'
                          : '${trip.currentDay}',
                      icon: Icons.calendar_today,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    trip.isCompleted ? Icons.summarize : Icons.edit,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trip.isCompleted
                        ? 'Tap to view summary'
                        : 'Tap to add expenses',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.deepPurple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
