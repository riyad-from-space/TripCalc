import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EnhancedTripDetailsScreen extends StatelessWidget {
  final String tripId;
  const EnhancedTripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
              Navigator.pushNamed(context, '/trip-management',
                  arguments: tripId);
            },
            tooltip: 'Edit Trip',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F7FB), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('trips').doc(tripId).get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading trip: \n${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Trip not found.'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final totalCost = (data['totalCost'] ?? 0).toDouble();
            final totalPeople = data['totalPeople'] ?? 1;
            final costPerPerson =
                totalPeople > 0 ? (totalCost / totalPeople) : 0;
            final days = data['days'] ?? 1;
            final categories =
                data['categories'] as Map<String, dynamic>? ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Overview Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['tripName'] ?? 'Unnamed Trip',
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
                                child: _buildStatCard(
                                  'Total Cost',
                                  '₹${totalCost.toStringAsFixed(0)}',
                                  Icons.account_balance_wallet,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Per Person',
                                  '₹${costPerPerson.toStringAsFixed(0)}',
                                  Icons.person,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'People',
                                  '$totalPeople',
                                  Icons.group,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Days',
                                  '$days',
                                  Icons.calendar_today,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Expense Breakdown
                  if (categories.isNotEmpty) ...[
                    Text(
                      'Expense Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Visual breakdown with progress bars
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: categories.entries
                              .where((entry) => (entry.value ?? 0) > 0)
                              .map((entry) {
                            final amount = (entry.value ?? 0).toDouble();
                            final percentage =
                                totalCost > 0 ? (amount / totalCost) * 100 : 0;
                            return _buildCategoryBreakdown(
                              entry.key,
                              amount,
                              percentage,
                              _getCategoryColor(entry.key),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Per Person Breakdown
                    Text(
                      'Cost Per Person',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: categories.entries
                              .where((entry) => (entry.value ?? 0) > 0)
                              .map((entry) {
                            final amount = (entry.value ?? 0).toDouble();
                            final perPersonAmount =
                                totalPeople > 0 ? amount / totalPeople : 0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(entry.key),
                                child: Icon(
                                  _getCategoryIcon(entry.key),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(entry.key),
                              trailing: Text(
                                '₹${perPersonAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses added yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/trip-management',
                                  arguments: tripId);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expenses'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/trip-management',
                                arguments: tripId);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Expenses'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeleteDialog(context),
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      String category, double amount, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[category.hashCode % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('transport'))
      return Icons.directions_car;
    if (category.toLowerCase().contains('food')) return Icons.restaurant;
    if (category.toLowerCase().contains('accommodation') ||
        category.toLowerCase().contains('hotel')) return Icons.hotel;
    if (category.toLowerCase().contains('activit')) return Icons.local_activity;
    return Icons.attach_money;
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
            'Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseFirestore.instance
                  .collection('trips')
                  .doc(tripId)
                  .delete();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
