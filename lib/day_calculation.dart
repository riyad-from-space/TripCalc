import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'completed_days_screen.dart';

class TripManagementScreen extends StatefulWidget {
  final String tripId;
  const TripManagementScreen({super.key, required this.tripId});

  @override
  State<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen> {
  Map<String, dynamic> tripData = {};
  Map<String, dynamic> todayExpenses = {};
  bool _loading = true;
  int currentDay = 1;

  final _expenseControllers = <String, TextEditingController>{};

  final Map<String, List<String>> predefinedCategories = {
    'Transportation': [
      'Vehicle Rental',
      'Fuel',
      'Public Transport',
      'Flight',
      'Train',
      'Bus',
      'Taxi'
    ],
    'Food': ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Beverages'],
    'Accommodation': ['Hotel', 'Resort', 'Homestay', 'Hostel'],
    'Activities': [
      'Entry Fees',
      'Tours',
      'Sports',
      'Entertainment',
      'Shopping'
    ],
    'Miscellaneous': ['Emergency', 'Tips', 'Insurance', 'Other']
  };

  @override
  void initState() {
    super.initState();
    loadTripData();
  }

  Future<void> loadTripData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();

      if (doc.exists) {
        setState(() {
          tripData = doc.data() as Map<String, dynamic>;
          currentDay = tripData['currentDay'] ?? 1;
          final dailyExpenses =
              Map<String, dynamic>.from(tripData['dailyExpenses'] ?? {});
          todayExpenses =
              Map<String, dynamic>.from(dailyExpenses['day_$currentDay'] ?? {});
          _loading = false;
        });

        // Initialize controllers
        todayExpenses.forEach((key, value) {
          _expenseControllers[key] =
              TextEditingController(text: value.toString());
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trip: ${e.toString()}')),
      );
    }
  }

  Future<void> saveCurrentDay() async {
    try {
      double dayTotal = 0;
      final updatedExpenses = <String, dynamic>{};

      _expenseControllers.forEach((category, controller) {
        final amount = double.tryParse(controller.text) ?? 0;
        if (amount > 0) {
          updatedExpenses[category] = amount;
          dayTotal += amount;
        }
      });

      final dailyExpenses =
          Map<String, dynamic>.from(tripData['dailyExpenses'] ?? {});
      dailyExpenses['day_$currentDay'] = {
        'expenses': updatedExpenses,
        'total': dayTotal,
        'date': FieldValue.serverTimestamp(),
      };

      // Calculate new total cost
      double totalCost = 0;
      dailyExpenses.forEach((day, data) {
        totalCost += (data['total'] ?? 0).toDouble();
      });

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'dailyExpenses': dailyExpenses,
        'totalCost': totalCost,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        todayExpenses = updatedExpenses;
        tripData['dailyExpenses'] = dailyExpenses;
        tripData['totalCost'] = totalCost;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Day $currentDay expenses saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving expenses: ${e.toString()}')),
      );
    }
  }

  Future<void> completeCurrentDay() async {
    try {
      await saveCurrentDay();

      final completedDays = List<int>.from(tripData['completedDays'] ?? []);
      if (!completedDays.contains(currentDay)) {
        completedDays.add(currentDay);
      }

      final newCurrentDay = currentDay + 1;

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'completedDays': completedDays,
        'currentDay': newCurrentDay,
      });

      setState(() {
        currentDay = newCurrentDay;
        tripData['completedDays'] = completedDays;
        tripData['currentDay'] = newCurrentDay;
        todayExpenses = {};
        _expenseControllers.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Day ${currentDay - 1} marked as complete!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing day: ${e.toString()}')),
      );
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
        final completedDays = List<int>.from(tripData['completedDays'] ?? []);
        if (!completedDays.contains(currentDay)) {
          completedDays.add(currentDay);
        }

        await FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.tripId)
            .update({
          'status': 'completed',
          'completedDays': completedDays,
          'completedAt': FieldValue.serverTimestamp(),
        });

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip marked as complete!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing trip: ${e.toString()}')),
        );
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
      total += double.tryParse(controller.text) ?? 0;
    });
    return total;
  }

  double get todayCostPerPerson {
    final people = tripData['totalPeople'] ?? 1;
    return people > 0 ? todayTotal / people : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isCompleted = tripData['status'] == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: Text('${tripData['tripName']} - Day $currentDay'),
        actions: [
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
                color: Colors.orange,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Trip Completed - Read Only',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Today's Summary
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
                        Text(
                          'Today\'s Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                        Text(
                            'Cost per Person (${tripData['totalPeople']} people)'),
                        Text(
                          '৳${todayCostPerPerson.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (tripData['totalCost'] != null) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trip Total'),
                          Text(
                            '৳${(tripData['totalCost'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                    ],
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
                      title: Text(
                        categoryEntry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      leading: Icon(_getCategoryIcon(categoryEntry.key)),
                      children: categoryEntry.value.map((subcategory) {
                        final key = '${categoryEntry.key} ($subcategory)';
                        if (!_expenseControllers.containsKey(key)) {
                          _expenseControllers[key] = TextEditingController();
                        }
                        return _buildExpenseField(
                            key, subcategory, isCompleted);
                      }).toList(),
                    );
                  }).toList(),

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
                        .map((entry) => _buildExpenseField(
                            entry.key, entry.key, isCompleted))
                        .toList(),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isCompleted
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'addCustom',
                  onPressed: addCustomCategory,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add),
                  tooltip: 'Add Custom Category',
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'save',
                  onPressed: saveCurrentDay,
                  child: const Icon(Icons.save),
                  tooltip: 'Save Day',
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'complete',
                  onPressed: completeCurrentDay,
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.check),
                  tooltip: 'Complete Day',
                ),
              ],
            ),
    );
  }

  Widget _buildExpenseField(String key, String displayName, bool isReadOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(displayName),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _expenseControllers[key],
              keyboardType: TextInputType.number,
              enabled: !isReadOnly,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              decoration: const InputDecoration(
                prefixText: '৳',
                hintText: '0',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () {
                _expenseControllers[key]?.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
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
        return Icons.local_activity;
      case 'Miscellaneous':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    _expenseControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
