import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trip_calc/trip_management_screen.dart';

import 'add_trip_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
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
          stream: FirebaseFirestore.instance
              .collection('trips')
              .where('userId', isEqualTo: user.uid)
              // .orderBy('createdAt', descending: true) // TEMP: Remove ordering for debug
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading trips:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No trips found.'),
                    const SizedBox(height: 16),
                    Text('Debug: userId = ${user.uid}'),
                  ],
                ),
              );
            }
            final trips = snapshot.data!.docs;
            return ListView.builder(
              itemCount: trips.length,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemBuilder: (context, index) {
                final trip = trips[index];
                final data = trip.data() as Map<String, dynamic>;
                final totalCost = data['totalCost'] ?? 0;
                final totalPeople = data['totalPeople'] ?? 1;
                final days = data['days'] ?? 1;
                final costPerPerson =
                    totalPeople > 0 ? (totalCost / totalPeople) : 0;
                return Dismissible(
                  key: Key(trip.id),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child:
                        const Icon(Icons.delete, color: Colors.white, size: 32),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Trip'),
                        content: const Text(
                            'Are you sure you want to delete this trip?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete')),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await FirebaseFirestore.instance
                        .collection('trips')
                        .doc(trip.id)
                        .delete();
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      title: Text(
                        data['tripName'] ?? 'Unnamed Trip',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Cost: ₹$totalCost',
                                style: const TextStyle(fontSize: 15)),
                            Text('Total People: $totalPeople',
                                style: const TextStyle(fontSize: 15)),
                            Text(
                                'Cost per Person: ₹${costPerPerson.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 15)),
                            Text('Total Days: $days',
                                style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.deepPurple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TripManagementScreen(tripId: trip.id),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addTrip',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTripScreen()),
              );
            },
            tooltip: 'Add Trip',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addSampleTrip',
            backgroundColor: Colors.green,
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              await FirebaseFirestore.instance.collection('trips').add({
                'userId': user.uid,
                'tripName': 'Sample Trip',
                'totalPeople': 2,
                'days': 3,
                'totalCost': 5000,
                'categories': {
                  'Transportation': 1500,
                  'Food (Breakfast)': 300,
                  'Food (Lunch)': 600,
                  'Food (Dinner)': 600,
                  'Accommodation': 2000,
                  'Activities/Entertainment': 0,
                  'Miscellaneous': 0,
                },
                'createdAt': FieldValue.serverTimestamp(),
              });
            },
            tooltip: 'Add Sample Trip to Firestore',
            child: const Icon(Icons.cloud_upload),
          ),
        ],
      ),
    );
  }
}
