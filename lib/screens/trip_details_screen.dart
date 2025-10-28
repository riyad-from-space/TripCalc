import 'package:flutter/material.dart';

import '../models/expense_categories.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../widgets/summary_item_widget.dart';

class DayDetailsScreen extends StatelessWidget {
  final String tripId;
  final int dayNumber;
  final String tripName;

  const DayDetailsScreen({
    super.key,
    required this.tripId,
    required this.dayNumber,
    required this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$tripName - Day $dayNumber'),
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

            final dailyExpenses = trip.dailyExpenses;
            final dayKey = 'day_$dayNumber';
            final dayData =
                dailyExpenses[dayKey] as Map<String, dynamic>? ?? {};
            final dayTotal = (dayData['total'] ?? 0).toDouble();
            final dayExpensesMap =
                dayData['expenses'] as Map<String, dynamic>? ?? {};
            final totalPeople = trip.totalPeople;
            final perPersonTotal = totalPeople > 0 ? dayTotal / totalPeople : 0;

            // Convert expenses to a list and sort by amount (highest first)
            final expensesList = dayExpensesMap.entries
                .map((entry) =>
                    MapEntry(entry.key, (entry.value ?? 0).toDouble()))
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            if (dayExpensesMap.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses recorded for Day $dayNumber',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Day Summary Card
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
                            'Day $dayNumber Summary',
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
                                  label: 'Total Spent',
                                  value: '৳${dayTotal.toStringAsFixed(2)}',
                                  icon: Icons.account_balance_wallet,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SummaryItemWidget(
                                  label: 'Per Person',
                                  value:
                                      '৳${perPersonTotal.toStringAsFixed(2)}',
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
                                  label: 'Categories',
                                  value: '${expensesList.length}',
                                  icon: Icons.category,
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

                  // Expense Breakdown
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Breakdown',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...expensesList.map((expense) {
                            final category = expense.key;
                            final amount = expense.value;
                            final percentage =
                                dayTotal > 0 ? (amount / dayTotal) * 100 : 0;
                            final perPersonAmount =
                                totalPeople > 0 ? amount / totalPeople : 0;

                            return _buildExpenseItem(
                              category,
                              amount,
                              percentage,
                              perPersonAmount,
                              _getCategoryColor(category),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Per Person Breakdown
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cost Per Person Breakdown',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...expensesList.map((expense) {
                            final category = expense.key;
                            final amount = expense.value;
                            final perPersonAmount =
                                totalPeople > 0 ? amount / totalPeople : 0;

                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(category),
                                radius: 20,
                                child: Icon(
                                  _getCategoryIcon(category),
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                ExpenseCategories.getDisplayName(category),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Text(
                                '৳${perPersonAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }),
                          const Divider(),
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              radius: 20,
                              child: Icon(
                                Icons.calculate,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            title: const Text(
                              'Total Per Person',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            trailing: Text(
                              '৳${perPersonTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpenseItem(String category, double amount, double percentage,
      double perPersonAmount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: 16,
                child: Icon(
                  _getCategoryIcon(category),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ExpenseCategories.getDisplayName(category),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Per person: ৳${perPersonAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Extract main category if it's in format "Category (Subcategory)"
    final mainCategory =
        category.contains('(') ? category.split('(')[0].trim() : category;

    switch (mainCategory) {
      case 'Transportation':
        return Colors.blue;
      case 'Food':
        return Colors.green;
      case 'Accommodation':
        return Colors.orange;
      case 'Activities':
        return Colors.purple;
      case 'Miscellaneous':
        return Colors.teal;
      default:
        // Generate a consistent color based on category name hash
        final colors = [
          Colors.red,
          Colors.indigo,
          Colors.pink,
          Colors.cyan,
          Colors.amber,
          Colors.deepOrange,
          Colors.lightGreen,
          Colors.brown,
        ];
        return colors[category.hashCode.abs() % colors.length];
    }
  }

  IconData _getCategoryIcon(String category) {
    // Extract main category if it's in format "Category (Subcategory)"
    final mainCategory =
        category.contains('(') ? category.split('(')[0].trim() : category;

    switch (mainCategory) {
      case 'Transportation':
        return Icons.directions_car;
      case 'Food':
        return Icons.restaurant;
      case 'Accommodation':
        return Icons.hotel;
      case 'Activities':
        return Icons.local_activity;
      case 'Miscellaneous':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
