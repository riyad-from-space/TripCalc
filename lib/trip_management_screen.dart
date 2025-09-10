import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TripManagementScreen extends StatefulWidget {
  final String tripId;
  const TripManagementScreen({super.key, required this.tripId});

  @override
  State<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen> {
  Map<String, dynamic> tripData = {};
  Map<String, dynamic> categories = {};
  bool _loading = true;

  // Controllers for expense input
  final _expenseControllers = <String, TextEditingController>{};

  // Predefined categories with subcategories
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
          categories = Map<String, dynamic>.from(tripData['categories'] ?? {});
          _loading = false;
        });

        // Initialize controllers for existing categories
        categories.forEach((key, value) {
          _expenseControllers[key] =
              TextEditingController(text: value.toString());
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trip: $e')),
      );
    }
  }

  Future<void> saveExpenses() async {
    try {
      // Calculate total cost
      double totalCost = 0;
      final updatedCategories = <String, dynamic>{};

      _expenseControllers.forEach((category, controller) {
        final amount = double.tryParse(controller.text) ?? 0;
        if (amount > 0) {
          updatedCategories[category] = amount;
          totalCost += amount;
        }
      });

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'categories': updatedCategories,
        'totalCost': totalCost,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        categories = updatedCategories;
        tripData['totalCost'] = totalCost;
        tripData['categories'] = updatedCategories;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expenses saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving expenses: $e')),
      );
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

  double get totalCost {
    double total = 0;
    _expenseControllers.forEach((category, controller) {
      total += double.tryParse(controller.text) ?? 0;
    });
    return total;
  }

  double get costPerPerson {
    final people = tripData['totalPeople'] ?? 1;
    return people > 0 ? totalCost / people : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tripData['tripName'] ?? 'Trip Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveExpenses,
            tooltip: 'Save Expenses',
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
            // Trip Summary Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Cost',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '₹${totalCost.toStringAsFixed(2)}',
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
                          '₹${costPerPerson.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
                  // Predefined categories
                  ...predefinedCategories.entries.map((categoryEntry) {
                    return ExpansionTile(
                      title: Text(
                        categoryEntry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      leading: Icon(_getCategoryIcon(categoryEntry.key)),
                      children: categoryEntry.value.map((subcategory) {
                        final key = '${categoryEntry.key} (${subcategory})';
                        if (!_expenseControllers.containsKey(key)) {
                          _expenseControllers[key] = TextEditingController();
                        }
                        return _buildExpenseField(key, subcategory);
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
                        .map(
                            (entry) => _buildExpenseField(entry.key, entry.key))
                        .toList(),
                  ],

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
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
            onPressed: saveExpenses,
            child: const Icon(Icons.save),
            tooltip: 'Save Expenses',
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseField(String key, String displayName) {
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              decoration: const InputDecoration(
                prefixText: '₹',
                hintText: '0',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: (value) => setState(() {}), // Update totals
            ),
          ),
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
