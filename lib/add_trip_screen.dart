import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'trip_management_screen.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _peopleController = TextEditingController();
  final _durationController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _loading = false;

  Future<void> saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('trips').add({
        'userId': user.uid,
        'tripName': _tripNameController.text.trim(),
        'totalPeople': int.tryParse(_peopleController.text) ?? 1,
        'expectedDuration': int.tryParse(_durationController.text) ?? 1,
        'expectedBudget': double.tryParse(_budgetController.text) ?? 0,
        'status': 'running',
        'createdAt': FieldValue.serverTimestamp(),
        'currentDay': 1,
        'completedDays': [],
        'totalCost': 0,
        'dailyExpenses': {},
      });

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TripManagementScreen(tripId: doc.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating trip: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Trip')),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start a New Trip',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(
                        labelText: 'Trip Name *',
                        prefixIcon: Icon(Icons.card_travel),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _peopleController,
                      decoration: const InputDecoration(
                        labelText: 'Total People *',
                        prefixIcon: Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Trip Duration (days) *',
                        prefixIcon: Icon(Icons.event),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Expected Budget (৳) - Optional',
                        prefixIcon: Icon(Icons.monetization_on),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: saveTrip,
                            child: const Text('Create & Continue'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _peopleController.dispose();
    _durationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }
}
