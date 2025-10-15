import 'package:flutter/material.dart';

enum ProviderBusinessType {
  serviceMaintenance,
  supportServices,
  salesParts,
  insuranceDocumentation,
  rentalLeasing,
  unregistered
}

class ProviderCategoryConfig {
  final String name;
  final int id;
  final ProviderBusinessType businessType;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final List<QuickAction> quickActions;
  final List<StatCard> statCards;
  final String welcomeMessage;

  const ProviderCategoryConfig({
    required this.name,
    required this.id,
    required this.businessType,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.quickActions,
    required this.statCards,
    required this.welcomeMessage,
  });
}

class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;
  final VoidCallback? onTap;
  final bool isComingSoon;

  const QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
    this.onTap,
    this.isComingSoon = false,
  });
}

class StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class ProviderCategoryConfigs {
  static final Map<String, ProviderCategoryConfig> _configs = {
    'garage / mechanic': ProviderCategoryConfig(
      name: 'Garage / Mechanic',
      id: 2,
      businessType: ProviderBusinessType.serviceMaintenance,
      description: 'Manage your garage, bookings, and automotive services',
      icon: Icons.build,
      primaryColor: Colors.blue,
      welcomeMessage: 'Manage your garage, bookings, and services',
      statCards: const [
        StatCard(title: 'Active Bookings', value: '8', icon: Icons.calendar_today, color: Colors.blue),
        StatCard(title: "Today's Earnings", value: 'KES 12,400', icon: Icons.trending_up, color: Colors.green),
        StatCard(title: 'Pending Tasks', value: '3', icon: Icons.list_alt, color: Colors.orange),
        StatCard(title: 'Rating', value: '4.8 ★', icon: Icons.star, color: Colors.amber),
      ],
      quickActions: [
        QuickAction(
          title: 'Bookings',
          subtitle: 'View and manage current bookings',
          icon: Icons.calendar_month,
          color: Colors.blue,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Service Logs',
          subtitle: 'Log completed services and maintenance',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        QuickAction(
          title: 'Orders & Parts',
          subtitle: 'Manage parts orders and inventory',
          icon: Icons.shopping_cart,
          color: Colors.orange,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'History',
          subtitle: 'View past services and transactions',
          icon: Icons.history,
          color: Colors.purple,
          isComingSoon: true,
        ),
      ],
    ),
    'insurance agency': ProviderCategoryConfig(
      name: 'Insurance Agency',
      id: 7,
      businessType: ProviderBusinessType.insuranceDocumentation,
      description: 'Manage your insurance services and clients',
      icon: Icons.security,
      primaryColor: Colors.green,
      welcomeMessage: 'Manage your insurance services and clients',
      statCards: const [
        StatCard(title: 'Active Policies', value: '24', icon: Icons.policy, color: Colors.green),
        StatCard(title: "Today's Revenue", value: 'KES 8,200', icon: Icons.trending_up, color: Colors.blue),
        StatCard(title: 'Pending Claims', value: '5', icon: Icons.assignment, color: Colors.orange),
        StatCard(title: 'Client Rating', value: '4.9 ★', icon: Icons.star, color: Colors.amber),
      ],
      quickActions: [
        QuickAction(
          title: 'Policy Management',
          subtitle: 'View and manage insurance policies',
          icon: Icons.policy,
          color: Colors.green,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Claims Processing',
          subtitle: 'Log insurance services and claims',
          icon: Icons.assignment,
          color: Colors.blue,
        ),
        QuickAction(
          title: 'Client Portal',
          subtitle: 'Manage client information and documents',
          icon: Icons.people,
          color: Colors.purple,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Reports',
          subtitle: 'View policy and claims reports',
          icon: Icons.analytics,
          color: Colors.orange,
          isComingSoon: true,
        ),
      ],
    ),
    'fuel station': ProviderCategoryConfig(
      name: 'Fuel Station',
      id: 3,
      businessType: ProviderBusinessType.supportServices,
      description: 'Manage fuel sales, inventory, and station operations',
      icon: Icons.local_gas_station,
      primaryColor: Colors.orange,
      welcomeMessage: 'Manage fuel sales and station operations',
      statCards: const [
        StatCard(title: 'Fuel Sales', value: '2,450L', icon: Icons.local_gas_station, color: Colors.orange),
        StatCard(title: "Today's Revenue", value: 'KES 15,600', icon: Icons.trending_up, color: Colors.green),
        StatCard(title: 'Inventory Alert', value: '2', icon: Icons.warning, color: Colors.red),
        StatCard(title: 'Customer Rating', value: '4.6 ★', icon: Icons.star, color: Colors.amber),
      ],
      quickActions: [
        QuickAction(
          title: 'Sales Dashboard',
          subtitle: 'View fuel sales and transactions',
          icon: Icons.dashboard,
          color: Colors.orange,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Inventory',
          subtitle: 'Manage fuel and station inventory',
          icon: Icons.inventory,
          color: Colors.blue,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Pump Management',
          subtitle: 'Monitor pump status and maintenance',
          icon: Icons.settings,
          color: Colors.green,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Reports',
          subtitle: 'View sales and operational reports',
          icon: Icons.analytics,
          color: Colors.purple,
          isComingSoon: true,
        ),
      ],
    ),
    'car wash & detailing': ProviderCategoryConfig(
      name: 'Car Wash & Detailing',
      id: 4,
      businessType: ProviderBusinessType.supportServices,
      description: 'Manage car wash services, bookings, and facility operations',
      icon: Icons.local_car_wash,
      primaryColor: Colors.cyan,
      welcomeMessage: 'Manage car wash services and bookings',
      statCards: const [
        StatCard(title: 'Today\'s Services', value: '18', icon: Icons.local_car_wash, color: Colors.cyan),
        StatCard(title: "Today's Revenue", value: 'KES 9,800', icon: Icons.trending_up, color: Colors.green),
        StatCard(title: 'Queue Length', value: '4', icon: Icons.queue, color: Colors.orange),
        StatCard(title: 'Rating', value: '4.7 ★', icon: Icons.star, color: Colors.amber),
      ],
      quickActions: [
        QuickAction(
          title: 'Service Queue',
          subtitle: 'Manage current wash and detailing queue',
          icon: Icons.queue,
          color: Colors.cyan,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Service Logs',
          subtitle: 'Log completed wash and detailing services',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        QuickAction(
          title: 'Facility Status',
          subtitle: 'Monitor equipment and facility status',
          icon: Icons.build,
          color: Colors.blue,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Packages',
          subtitle: 'Manage service packages and pricing',
          icon: Icons.list,
          color: Colors.purple,
          isComingSoon: true,
        ),
      ],
    ),
    'spare parts dealer': ProviderCategoryConfig(
      name: 'Spare Parts Dealer',
      id: 8,
      businessType: ProviderBusinessType.salesParts,
      description: 'Manage parts inventory, sales, and customer orders',
      icon: Icons.inventory_2,
      primaryColor: Colors.deepPurple,
      welcomeMessage: 'Manage parts inventory and sales',
      statCards: const [
        StatCard(title: 'Active Orders', value: '12', icon: Icons.shopping_cart, color: Colors.deepPurple),
        StatCard(title: "Today's Sales", value: 'KES 18,500', icon: Icons.trending_up, color: Colors.green),
        StatCard(title: 'Low Stock', value: '7', icon: Icons.warning, color: Colors.red),
        StatCard(title: 'Rating', value: '4.5 ★', icon: Icons.star, color: Colors.amber),
      ],
      quickActions: [
        QuickAction(
          title: 'Inventory',
          subtitle: 'Manage parts inventory and stock levels',
          icon: Icons.inventory_2,
          color: Colors.deepPurple,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Orders',
          subtitle: 'Process customer orders and deliveries',
          icon: Icons.shopping_cart,
          color: Colors.blue,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Catalog',
          subtitle: 'Manage parts catalog and pricing',
          icon: Icons.list_alt,
          color: Colors.green,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Suppliers',
          subtitle: 'Manage supplier relationships and orders',
          icon: Icons.business,
          color: Colors.orange,
          isComingSoon: true,
        ),
      ],
    ),
  };

  static ProviderCategoryConfig getConfig(String categoryName) {
    final normalizedName = categoryName.toLowerCase().trim();
    return _configs[normalizedName] ?? getDefaultConfig(categoryName);
  }

  static ProviderCategoryConfig getDefaultConfig(String categoryName) {
    return ProviderCategoryConfig(
      name: categoryName,
      id: 0,
      businessType: ProviderBusinessType.unregistered,
      description: 'Manage your business operations and services',
      icon: Icons.business,
      primaryColor: Colors.grey,
      welcomeMessage: 'Manage your business operations',
      statCards: const [
        StatCard(title: 'Active Items', value: '0', icon: Icons.list, color: Colors.grey),
        StatCard(title: "Today's Activity", value: '0', icon: Icons.trending_up, color: Colors.grey),
        StatCard(title: 'Pending Tasks', value: '0', icon: Icons.pending, color: Colors.grey),
        StatCard(title: 'Rating', value: 'N/A', icon: Icons.star, color: Colors.grey),
      ],
      quickActions: [
        QuickAction(
          title: 'Dashboard',
          subtitle: 'View your business overview',
          icon: Icons.dashboard,
          color: Colors.grey,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Services',
          subtitle: 'Manage your services',
          icon: Icons.build,
          color: Colors.grey,
          isComingSoon: true,
        ),
        QuickAction(
          title: 'Settings',
          subtitle: 'Configure your business settings',
          icon: Icons.settings,
          color: Colors.grey,
          isComingSoon: true,
        ),
      ],
    );
  }

  static List<ProviderCategoryConfig> getAllConfigs() {
    return _configs.values.toList();
  }
}
