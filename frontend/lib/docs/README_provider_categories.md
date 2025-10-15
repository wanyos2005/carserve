# Dynamic Provider Homepage System

## Overview

The provider homepage now dynamically adapts based on the provider's category, showing relevant statistics, actions, and messaging for each business type. This system groups the 17 provider categories into 5 main business types for better organization and user experience.

## Business Type Groups

### 1. Service & Maintenance
- **Garage / Mechanic** (id: 2)
- **Tyre & Wheel Center** (id: 5)
- **Battery & Electrical Specialist** (id: 6)
- **Auto Body & Paint Shop** (id: 11)
- **Diagnostics & ECU Specialist** (id: 15)
- **Hybrid / EV Specialist** (id: 16)

### 2. Support Services
- **Fuel Station** (id: 3)
- **Car Wash & Detailing** (id: 4)
- **Roadside Assistance / Towing Service** (id: 9)
- **Vehicle Pickup & Delivery** (id: 17)

### 3. Sales & Parts
- **Spare Parts Dealer** (id: 8)
- **Car Accessories / Customization Shop** (id: 12)

### 4. Insurance & Documentation
- **Insurance Agency** (id: 7)
- **Vehicle Registration & Documentation Agency** (id: 13)
- **Inspection & Emission Testing Center** (id: 10)

### 5. Rental & Leasing
- **Car Rental / Leasing Company** (id: 14)

## Configuration System

Each provider category has a `ProviderCategoryConfig` that defines:

- **Business Type**: Which group the category belongs to
- **Welcome Message**: Customized greeting text
- **Statistics Cards**: Relevant metrics (4 cards in 2x2 grid)
- **Quick Actions**: Category-specific navigation options
- **Visual Identity**: Icons and colors

## Example Configurations

### Garage/Mechanic
- **Stats**: Active Bookings, Today's Earnings, Pending Tasks, Rating
- **Actions**: Bookings, Service Logs, Orders & Parts, History
- **Theme**: Blue color scheme with build icon

### Insurance Agency
- **Stats**: Active Policies, Today's Revenue, Pending Claims, Client Rating
- **Actions**: Policy Management, Claims Processing, Client Portal, Reports
- **Theme**: Green color scheme with security icon

### Fuel Station
- **Stats**: Fuel Sales, Today's Revenue, Inventory Alert, Customer Rating
- **Actions**: Sales Dashboard, Inventory, Pump Management, Reports
- **Theme**: Orange color scheme with gas station icon

## Adding New Categories

To add a new provider category:

1. **Add to Business Type Enum** (if new type needed):
```dart
enum ProviderBusinessType {
  // existing types...
  newBusinessType,
}
```

2. **Create Configuration**:
```dart
'new category name': ProviderCategoryConfig(
  name: 'New Category Name',
  id: 18,
  businessType: ProviderBusinessType.newBusinessType,
  description: 'Description of the business',
  icon: Icons.appropriate_icon,
  primaryColor: Colors.appropriate_color,
  welcomeMessage: 'Custom welcome message',
  statCards: [
    // 4 StatCard objects
  ],
  quickActions: [
    // QuickAction objects
  ],
),
```

3. **Add to _configs Map** in `ProviderCategoryConfigs`

## Benefits

1. **Maintainability**: Single codebase for all provider types
2. **Consistency**: Common UI patterns across categories
3. **Flexibility**: Easy to customize per category
4. **Scalability**: Simple to add new categories
5. **User Experience**: Relevant content for each business type

## Future Enhancements

- **Real-time Data**: Connect stats to actual backend data
- **Customizable Dashboard**: Allow providers to customize their dashboard
- **Analytics**: Track which actions are most used per category
- **Notifications**: Category-specific notification systems
- **Themes**: More sophisticated theming per business type
