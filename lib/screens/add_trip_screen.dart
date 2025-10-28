import 'package:flutter/material.dart';

import '../services/trip_service.dart';
import 'trip_management_screen.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _peopleController = TextEditingController(text: '1');
  bool _loading = false;
  bool _showAdvanced = false;
  final _durationController = TextEditingController();
  final _budgetController = TextEditingController();

  Future<void> saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final tripId = await TripService.createTrip(
        tripName: _tripNameController.text.trim(),
        totalPeople: int.tryParse(_peopleController.text) ?? 1,
        expectedDuration:
            _showAdvanced ? (int.tryParse(_durationController.text) ?? 1) : 1,
        expectedBudget:
            _showAdvanced ? (double.tryParse(_budgetController.text) ?? 0) : 0,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TripManagementScreen(tripId: tripId),
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
                    const SizedBox(height: 8),
                    Text(
                      'Give your trip a name and start tracking expenses',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _tripNameController,
                      decoration: const InputDecoration(
                        labelText: 'Trip Name *',
                        hintText: 'e.g., Weekend Getaway, Business Trip',
                        prefixIcon: Icon(Icons.card_travel),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter a trip name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _peopleController,
                      decoration: const InputDecoration(
                        labelText: 'Number of People',
                        hintText: 'How many people in this trip?',
                        prefixIcon: Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Must be at least 1';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Advanced options toggle
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showAdvanced = !_showAdvanced;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showAdvanced
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showAdvanced
                                ? 'Hide Advanced Options'
                                : 'Show Advanced Options',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Advanced fields
                    if (_showAdvanced) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Expected Duration (days)',
                          hintText: 'Optional - helps with planning',
                          prefixIcon: Icon(Icons.event),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          labelText: 'Expected Budget (৳)',
                          hintText: 'Optional - for budget tracking',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 32),
                    _loading
                        ? const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Creating your trip...'),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: saveTrip,
                              icon: const Icon(Icons.rocket_launch),
                              label: const Text('Start My Trip!'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
