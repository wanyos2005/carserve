import 'package:flutter/material.dart';

/// Frontend-only grouping of the 17 backend categories for better UX
/// Backend keeps the 17 categories, frontend groups them for display
class FrontendCategoryGroup {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> backendCategories;
  final String onboardingDescription;

  const FrontendCategoryGroup({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.backendCategories,
    required this.onboardingDescription,
  });
}

class FrontendCategoryGroups {
  static const List<FrontendCategoryGroup> groups = [
    FrontendCategoryGroup(
      name: 'Repair & Maintenance',
      description: 'Automotive repair, maintenance, and diagnostic services',
      icon: Icons.build,
      color: Colors.blue,
      onboardingDescription: 'Perfect for garages, mechanics, and specialized repair shops',
      backendCategories: [
        'Garage / Mechanic',
        'Tyre & Wheel Center',
        'Battery & Electrical Specialist',
        'Auto Body & Paint Shop',
        'Diagnostics & ECU Specialist',
        'Hybrid / EV Specialist',
      ],
    ),
    FrontendCategoryGroup(
      name: 'Vehicle Care & Support',
      description: 'Vehicle care, fuel, and support services',
      icon: Icons.local_car_wash,
      color: Colors.orange,
      onboardingDescription: 'Ideal for fuel stations, car washes, and support services',
      backendCategories: [
        'Fuel Station',
        'Car Wash & Detailing',
        'Roadside Assistance / Towing Service',
        'Vehicle Pickup & Delivery',
      ],
    ),
    FrontendCategoryGroup(
      name: 'Parts & Accessories',
      description: 'Automotive parts, accessories, and customization',
      icon: Icons.inventory_2,
      color: Colors.deepPurple,
      onboardingDescription: 'Great for parts dealers and customization shops',
      backendCategories: [
        'Spare Parts Dealer',
        'Car Accessories / Customization Shop',
      ],
    ),
    FrontendCategoryGroup(
      name: 'Insurance & Documentation',
      description: 'Insurance, registration, and compliance services',
      icon: Icons.security,
      color: Colors.green,
      onboardingDescription: 'Perfect for insurance agencies and documentation services',
      backendCategories: [
        'Insurance Agency',
        'Vehicle Registration & Documentation Agency',
        'Inspection & Emission Testing Center',
      ],
    ),
    FrontendCategoryGroup(
      name: 'Vehicle Rental',
      description: 'Vehicle rental and leasing services',
      icon: Icons.directions_car,
      color: Colors.teal,
      onboardingDescription: 'Ideal for car rental and leasing companies',
      backendCategories: [
        'Car Rental / Leasing Company',
      ],
    ),
  ];

  /// Get the frontend group for a backend category
  static FrontendCategoryGroup? getGroupForBackendCategory(String backendCategory) {
    for (final group in groups) {
      if (group.backendCategories.contains(backendCategory)) {
        return group;
      }
    }
    return null;
  }

  /// Get all backend categories for a frontend group
  static List<String> getBackendCategoriesForGroup(String groupName) {
    final group = groups.firstWhere(
      (g) => g.name == groupName,
      orElse: () => throw ArgumentError('Group not found: $groupName'),
    );
    return group.backendCategories;
  }

  /// Get all groups
  static List<FrontendCategoryGroup> getAllGroups() {
    return groups;
  }

  /// Check if a backend category exists
  static bool isValidBackendCategory(String category) {
    return groups.any((group) => group.backendCategories.contains(category));
  }
}

/// Onboarding flow helper
class CategoryOnboardingHelper {
  static Widget buildCategorySelectionStep() {
    return Column(
      children: FrontendCategoryGroups.getAllGroups().map((group) {
        return Card(
          child: ListTile(
            leading: Icon(group.icon, color: group.color),
            title: Text(group.name),
            subtitle: Text(group.description),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to subcategory selection
              _showSubcategorySelection(group);
            },
          ),
        );
      }).toList(),
    );
  }

  static void _showSubcategorySelection(FrontendCategoryGroup group) {
    // Show modal with specific backend categories
    // User selects the exact category they identify with
  }
}
