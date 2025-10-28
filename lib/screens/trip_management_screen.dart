import 'package:flutter/material.dart';

import '../models/expense_categories.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../widgets/expense_field_widget.dart';
import 'completed_days_screen.dart';
import 'completed_trip_summary_screen.dart';

class TripManagementScreen extends StatefulWidget {
  final String tripId;
  const TripManagementScreen({super.key, required this.tripId});

  @override
  State<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen> {
  Trip? trip;
  Map<String, dynamic> todayExpenses = {};
  bool _loading = true;
  int currentDay = 1;

  final _expenseControllers = <String, TextEditingController>{};
  final Map<String, List<String>> predefinedCategories =
      ExpenseCategories.predefinedCategories;

  @override
  void initState() {
    super.initState();
    loadTripData();
  }

  @override
  void dispose() {
    for (var controller in _expenseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadTripData() async {
    try {
      final tripData = await TripService.getTripById(widget.tripId);
      if (tripData != null) {
        setState(() {
          trip = tripData;
          currentDay = trip!.currentDay;
          final dailyExpenses = trip!.dailyExpenses;
          final dayKey = 'day_$currentDay';
          final dayData = dailyExpenses[dayKey] as Map<String, dynamic>? ?? {};
          todayExpenses = Map<String, dynamic>.from(dayData['expenses'] ?? {});
          _loading = false;
        });
        _initializeControllers();
      } else {
        throw Exception('Trip not found');
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trip: ${e.toString()}')),
        );
      }
    }
  }

  void _initializeControllers() {
    _expenseControllers.clear();

    // Initialize controllers for existing expenses
    todayExpenses.forEach((key, value) {
      _expenseControllers[key] =
          TextEditingController(text: value == 0 ? '' : value.toString());
    });

    // Initialize controllers for predefined categories
    predefinedCategories.forEach((mainCategory, subCategories) {
      for (String subCategory in subCategories) {
        final key = '$mainCategory ($subCategory)';
        if (!_expenseControllers.containsKey(key)) {
          final existingValue = todayExpenses[key] ?? 0;
          _expenseControllers[key] = TextEditingController(
              text: existingValue == 0 ? '' : existingValue.toString());
        }
      }
    });
  }

  Future<void> saveCurrentDay() async {
    try {
      double dayTotal = 0;
      final updatedExpenses = <String, dynamic>{};

      _expenseControllers.forEach((category, controller) {
        final amount = double.tryParse(controller.text.trim()) ?? 0;
        if (amount > 0) {
          updatedExpenses[category] = amount;
          dayTotal += amount;
        }
      });

      await TripService.updateTripExpenses(
        tripId: widget.tripId,
        day: currentDay,
        expenses: updatedExpenses,
        dayTotal: dayTotal,
      );

      setState(() {
        todayExpenses = updatedExpenses;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Day $currentDay expenses saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expenses: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> completeCurrentDay() async {
    try {
      await saveCurrentDay();
      await TripService.completeDay(tripId: widget.tripId, day: currentDay);

      // Reload trip data
      await loadTripData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Day $currentDay marked as complete!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing day: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> markTripComplete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Trip'),
        content: const Text(
            'Are you sure you want to mark this trip as complete? No more days can be added after this.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Complete Trip'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await saveCurrentDay();
        await TripService.completeTrip(widget.tripId);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip marked as complete!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error completing trip: ${e.toString()}')),
          );
        }
      }
    }
  }

  void addCustomCategory() {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Custom Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g., Gifts, Medical',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final categoryName = controller.text.trim();
                if (categoryName.isNotEmpty &&
                    !_expenseControllers.containsKey(categoryName)) {
                  setState(() {
                    _expenseControllers[categoryName] = TextEditingController();
                  });
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  double get todayTotal {
    double total = 0;
    _expenseControllers.forEach((category, controller) {
      total += double.tryParse(controller.text.trim()) ?? 0;
    });
    return total;
  }

  double get todayCostPerPerson {
    final people = trip?.totalPeople ?? 1;
    return people > 0 ? todayTotal / people : 0;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation':
        return Icons.directions_car;
      case 'Food':
        return Icons.restaurant;
      case 'Accommodation':
        return Icons.hotel;
      case 'Activities':
        return Icons.sports_soccer;
      case 'Miscellaneous':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Not Found')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final isCompleted = trip!.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text('${trip!.tripName} - Day $currentDay'),
        actions: [
          if (!isCompleted)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompletedDaysScreen(tripId: widget.tripId),
                  ),
                );
              },
              tooltip: 'View Completed Days',
            ),
          if (!isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: markTripComplete,
              tooltip: 'Complete Trip',
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
        child: Column(
          children: [
            if (isCompleted)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Trip Completed!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CompletedTripSummaryScreen(trip: trip!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.summarize),
                      label: const Text('View Trip Summary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),

            // Instruction Card (only for active trips)
            if (!isCompleted)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enter your expenses for today. Tap "Save Day" to save progress, then "Complete" when the day is finished.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Today's Summary Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Day $currentDay Expenses',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today\'s Total',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '৳${todayTotal.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cost per Person (${trip!.totalPeople} people)'),
                        Text(
                          '৳${todayCostPerPerson.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trip Total'),
                        Text(
                          '৳${trip!.totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expenses List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ...predefinedCategories.entries.map((categoryEntry) {
                    return ExpansionTile(
                      title: Text(categoryEntry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      leading: Icon(_getCategoryIcon(categoryEntry.key)),
                      children: categoryEntry.value.map((subcategory) {
                        final key = '${categoryEntry.key} ($subcategory)';
                        return ExpenseFieldWidget(
                          categoryKey: key,
                          displayName: subcategory,
                          controller: _expenseControllers[key]!,
                          isReadOnly: isCompleted,
                          onClear: () {
                            _expenseControllers[key]?.clear();
                            setState(() {});
                          },
                          onChanged: (value) => setState(() {}),
                        );
                      }).toList(),
                    );
                  }),

                  // Custom categories
                  if (_expenseControllers.keys.any((key) =>
                      !predefinedCategories.values.any((subcats) =>
                          subcats.any((sub) => key.contains(sub))))) ...[
                    const Divider(),
                    const ListTile(
                      title: Text('Custom Categories',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ..._expenseControllers.entries
                        .where((entry) => !predefinedCategories.values.any(
                            (subcats) =>
                                subcats.any((sub) => entry.key.contains(sub))))
                        .map((entry) => ExpenseFieldWidget(
                            categoryKey: entry.key,
                            displayName: entry.key,
                            controller: entry.value,
                            isReadOnly: isCompleted,
                            onClear: () {
                              entry.value.clear();
                              setState(() {});
                            },
                            onChanged: (value) => setState(() {}))),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isCompleted
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: addCustomCategory,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.green[600]!),
                        foregroundColor: Colors.green[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: saveCurrentDay,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Day'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: completeCurrentDay,
                      icon: const Icon(Icons.check),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
