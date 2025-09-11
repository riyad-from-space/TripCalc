// lib/home_screen.dart - Fixed Version
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_trip_screen.dart';
import 'trip_management_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TripCalc'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.person),
          //   onPressed: () => _showUserProfile(context, user),
          //   tooltip: 'Profile',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force refresh by rebuilding widget
              (context as Element).markNeedsBuild();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F7FB), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          // SIMPLIFIED QUERY - Remove orderBy to avoid index issues
          stream: FirebaseFirestore.instance
              .collection('trips')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            // Debug information
            print('StreamBuilder state: ${snapshot.connectionState}');
            print('Has error: ${snapshot.hasError}');
            if (snapshot.hasError) {
              print('Error: ${snapshot.error}');
            }
            print('Has data: ${snapshot.hasData}');
            if (snapshot.hasData) {
              print('Document count: ${snapshot.data!.docs.length}');
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading trips:\n${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Force refresh
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading trips...'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, size: 64, color: Colors.orange),
                    SizedBox(height: 16),
                    Text('No data available'),
                  ],
                ),
              );
            }

            final trips = snapshot.data!.docs;
            print('Trips data: ${trips.map((doc) => {
                  'id': doc.id,
                  'data': doc.data(),
                }).toList()}');

            if (trips.isEmpty) {
              return _buildEmptyState(context, user);
            }

            // Sort trips manually by creation date (newest first)
            trips.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime);
            });

            return Column(
              children: [
                // Statistics Card
                _buildStatisticsCard(trips),

                // Trips List
                Expanded(
                  child: ListView.builder(
                    itemCount: trips.length,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final data = trip.data() as Map<String, dynamic>;
                      print('Building card for trip: ${trip.id}, data: $data');
                      return _buildTripCard(context, trip.id, data);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Debug button to check data
          // FloatingActionButton(
          //   mini: true,
          //   heroTag: 'debug',
          //   backgroundColor: Colors.green,
          //   onPressed: () async {
          //     await _debugFirestoreData(context, user.uid);
          //   },
          //   tooltip: 'Debug Data',
          //   child: const Icon(Icons.bug_report, size: 16),
          // ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'main',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTripScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New Trip'),
            tooltip: 'Create New Trip',
          ),
        ],
      ),
    );
  }

  // Debug function to check Firestore data
  Future<void> _debugFirestoreData(BuildContext context, String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .get();

      final docs = querySnapshot.docs;
      print('Debug - Found ${docs.length} trips for user $userId');

      String debugInfo = 'User ID: $userId\n';
      debugInfo += 'Found ${docs.length} trips:\n\n';

      for (var doc in docs) {
        final data = doc.data();
        debugInfo += 'Trip ID: ${doc.id}\n';
        debugInfo += 'Trip Name: ${data['tripName']}\n';
        debugInfo += 'User ID in doc: ${data['userId']}\n';
        debugInfo += 'Status: ${data['status']}\n';
        debugInfo += 'Created: ${data['createdAt']}\n';
        debugInfo += 'Total Cost: ${data['totalCost']}\n\n';
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Debug Info'),
          content: SingleChildScrollView(
            child: Text(debugInfo),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Debug error: $e');
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug error: $e')),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No trips yet!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first trip to start tracking expenses',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'User ID: ${user.uid}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTripScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Trip'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(List<QueryDocumentSnapshot> trips) {
    double totalSpent = 0;
    int completedTrips = 0;
    int activeTrips = 0;

    for (var trip in trips) {
      final data = trip.data() as Map<String, dynamic>;
      totalSpent += (data['totalCost'] ?? 0).toDouble();
      if (data['status'] == 'completed') {
        completedTrips++;
      } else {
        activeTrips++;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Trip Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Spent',
                    '৳${totalSpent.toStringAsFixed(0)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Total Trips',
                    '${trips.length}',
                    Icons.flight_takeoff,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Active',
                    '$activeTrips',
                    Icons.play_circle,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    '$completedTrips',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(
      BuildContext context, String tripId, Map<String, dynamic> data) {
    final totalCost = (data['totalCost'] ?? 0).toDouble();
    final totalPeople = data['totalPeople'] ?? 1;
    final costPerPerson = totalPeople > 0 ? (totalCost / totalPeople) : 0;
    final status = data['status'] ?? 'running';
    final completedDays = List<int>.from(data['completedDays'] ?? []);
    final currentDay = data['currentDay'] ?? 1;
    final createdAt = data['createdAt'] as Timestamp?;

    String dateText = 'Unknown date';
    if (createdAt != null) {
      try {
        // Simple date formatting without intl package
        final date = createdAt.toDate();
        dateText = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        dateText = 'Date error';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripManagementScreen(tripId: tripId),
            ),
          );
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
                      data['tripName'] ?? 'Unnamed Trip',
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
                      color:
                          status == 'completed' ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status == 'completed' ? 'Completed' : 'Active',
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
                'Created: $dateText',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Total Cost',
                      '৳${totalCost.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoItem(
                      'Per Person',
                      '৳${costPerPerson.toStringAsFixed(0)}',
                      Icons.person,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'People',
                      '$totalPeople',
                      Icons.group,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoItem(
                      status == 'completed' ? 'Days' : 'Current Day',
                      status == 'completed'
                          ? '${completedDays.length}'
                          : '$currentDay',
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.touch_app, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to manage expenses',
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

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showUserProfile(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email ?? 'No email'}'),
            const SizedBox(height: 8),
            Text('User ID: ${user.uid}'),
            const SizedBox(height: 8),
            Text(
                'Created: ${user.metadata.creationTime?.toString() ?? 'Unknown'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
