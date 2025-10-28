class ExpenseCategories {
  static const Map<String, List<String>> predefinedCategories = {
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

  static String getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation':
        return 'directions_car';
      case 'Food':
        return 'restaurant';
      case 'Accommodation':
        return 'hotel';
      case 'Activities':
        return 'local_activity';
      case 'Miscellaneous':
        return 'more_horiz';
      default:
        return 'category';
    }
  }

  static String getCategoryColor(String category) {
    // Extract main category if it's in format "Category (Subcategory)"
    final mainCategory =
        category.contains('(') ? category.split('(')[0].trim() : category;

    switch (mainCategory) {
      case 'Transportation':
        return 'blue';
      case 'Food':
        return 'green';
      case 'Accommodation':
        return 'orange';
      case 'Activities':
        return 'purple';
      case 'Miscellaneous':
        return 'teal';
      default:
        return 'grey';
    }
  }

  static String getDisplayName(String category) {
    // If it's in format "Category (Subcategory)", extract the subcategory
    if (category.contains('(') && category.contains(')')) {
      final parts = category.split('(');
      if (parts.length == 2) {
        final subcategory = parts[1].replaceAll(')', '').trim();
        return subcategory;
      }
    }
    return category;
  }
}
