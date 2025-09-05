import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;
  const TripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
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
            final totalCost = data['totalCost'] ?? 0;
            final totalPeople = data['totalPeople'] ?? 1;
            final costPerPerson =
                totalPeople > 0 ? (totalCost / totalPeople) : 0;
            final days = data['days'] ?? 1;
            final categories =
                data['categories'] as Map<String, dynamic>? ?? {};
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text('Trip Name: ${data['tripName']}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total Cost: ₹$totalCost',
                          style: const TextStyle(fontSize: 16)),
                      Text('Total People: $totalPeople',
                          style: const TextStyle(fontSize: 16)),
                      Text(
                          'Cost per Person: ₹${costPerPerson.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16)),
                      Text('Total Days: $days',
                          style: const TextStyle(fontSize: 16)),
                      const Divider(height: 32),
                      ...categories.entries.map((e) => ListTile(
                            title: Text(e.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            trailing: Text('₹${e.value}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          )),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Trip'),
                              content: const Text(
                                  'Are you sure you want to delete this trip?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('trips')
                                .doc(tripId)
                                .delete();
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
