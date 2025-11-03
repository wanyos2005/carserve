# Provider Onboarding Architecture & Workflow

This document explains the relationship and workflow between the core files that power the provider onboarding system.

## 📁 File Overview

| File | Purpose | Key Responsibility |
|------|---------|-------------------|
| `frontend_category_grouping.dart` | Frontend UX grouping | Groups 17 backend categories into 5 user-friendly groups |
| `provider_steps.dart` | Step UI widgets | Implements the visual UI for each onboarding step |
| `onboarding_config.dart` | Configuration & data model | Defines onboarding flow structure and data storage |
| `dynamic_onboarding_flow.dart` | Flow orchestrator | Manages step progression, validation, and submission |
| `provider_category_config.dart` | Post-onboarding dashboard | Configures provider dashboards after registration |

---

## 🔄 Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER STARTS ONBOARDING                       │
│           Navigator.push(DynamicOnboardingFlow(...))            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│         dynamic_onboarding_flow.dart                             │
│  • Initializes OnboardingConfig from onboarding_config.dart      │
│  • Creates OnboardingData to store form data                    │
│  • Sets up step progression logic                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 1: Business Type                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ provider_steps.dart                                       │  │
│  │ buildBusinessTypeSelection()                              │  │
│  │                                                            │  │
│  │ Uses: FrontendCategoryGroups.getAllGroups()               │  │
│  │ from: frontend_category_grouping.dart                     │  │
│  │                                                            │  │
│  │ Shows: 5 frontend groups (Repair & Maintenance, etc.)      │  │
│  │ Stores: selectedGroup → OnboardingData                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 2: Category Selection                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ provider_steps.dart                                       │  │
│  │ buildCategorySelection()                                  │  │
│  │                                                            │  │
│  │ Reads: selectedGroup from OnboardingData                  │  │
│  │ Shows: backendCategories from selectedGroup               │  │
│  │ Example: "Repair & Maintenance" → ["Garage / Mechanic",   │  │
│  │          "Tyre & Wheel Center", ...]                      │  │
│  │ Stores: selectedBackendCategory → OnboardingData           │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 3: Business Details                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ provider_steps.dart                                       │  │
│  │ buildProviderDetailsForm()                               │  │
│  │                                                            │  │
│  │ Collects: name, description, phone, email, location       │  │
│  │ Stores: All fields → OnboardingData                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 4: Location                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ onboarding_config.dart                                    │  │
│  │ _buildLocationStep()                                      │  │
│  │                                                            │  │
│  │ Uses: LocationPicker component                            │  │
│  │ Stores: locationData (with lat/lng) → OnboardingData      │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 5: Service Selection                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ provider_steps.dart                                       │  │
│  │ buildServiceSelection()                                  │  │
│  │                                                            │  │
│  │ Filters services by selectedBackendCategory               │  │
│  │ Uses: EnhancedServiceSelector for multi-select            │  │
│  │ Stores: selectedServices, serviceValues → OnboardingData   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              dynamic_onboarding_flow.dart                       │
│              _completeRegistration()                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. Validates all required fields from OnboardingData      │  │
│  │ 2. Maps selectedBackendCategory → category_id            │  │
│  │ 3. Creates provider via ProviderService.createProvider()  │  │
│  │ 4. Attaches services via attachServicesToProvider()       │  │
│  │ 5. Moves to completion step                               │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    POST-ONBOARDING                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ provider_category_config.dart                             │  │
│  │                                                            │  │
│  │ Uses: selectedBackendCategory to get ProviderCategoryConfig│ │
│  │ Configures: Dashboard UI, quick actions, stat cards      │  │
│  │ Example: "Garage / Mechanic" → Blue theme, build icon     │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📚 Detailed Component Breakdown

### 1. `frontend_category_grouping.dart` - Category Grouping Layer

**Purpose**: Simplifies category selection by grouping 17 backend categories into 5 user-friendly groups.

**Key Class**: `FrontendCategoryGroup`

```dart
// Example: FrontendCategoryGroup structure
FrontendCategoryGroup(
  name: 'Repair & Maintenance',
  description: 'Automotive repair, maintenance, and diagnostic services',
  icon: Icons.build,
  color: Colors.blue,
  backendCategories: [
    'Garage / Mechanic',
    'Tyre & Wheel Center',
    'Battery & Electrical Specialist',
    'Auto Body & Paint Shop',
    'Diagnostics & ECU Specialist',
    'Hybrid / EV Specialist',
  ],
)
```

**Usage in Workflow**:
- **Step 1**: `ProviderSteps.buildBusinessTypeSelection()` calls `FrontendCategoryGroups.getAllGroups()`
- Displays 5 groups instead of 17 categories
- User selects a group (e.g., "Repair & Maintenance")
- Stores `selectedGroup` in `OnboardingData`

**Relationship**:
```
frontend_category_grouping.dart
    ↓ (provides groups)
provider_steps.dart (Step 1)
    ↓ (stores selectedGroup)
onboarding_config.dart (OnboardingData)
```

---

### 2. `provider_steps.dart` - UI Implementation Layer

**Purpose**: Contains all the visual UI widgets for provider onboarding steps.

**Key Methods**:

#### `buildBusinessTypeSelection()` - Step 1
```dart
static Widget buildBusinessTypeSelection(
  BuildContext context, 
  OnboardingData data, 
  Function(OnboardingData) onUpdate
) {
  // Gets groups from frontend_category_grouping.dart
  final groups = FrontendCategoryGroups.getAllGroups();
  
  return ListView.builder(
    itemBuilder: (context, index) {
      final group = groups[index];
      final isSelected = data.get<FrontendCategoryGroup>('selectedGroup')?.name == group.name;
      
      return GestureDetector(
        onTap: () => onUpdate(data.updateData('selectedGroup', group)),
        child: /* UI for group selection */
      );
    },
  );
}
```

#### `buildCategorySelection()` - Step 2
```dart
static Widget buildCategorySelection(
  BuildContext context, 
  OnboardingData data, 
  Function(OnboardingData) onUpdate
) {
  // Reads selectedGroup from OnboardingData
  final group = data.get<FrontendCategoryGroup>('selectedGroup');
  
  // Shows backend categories from the selected group
  return ListView.builder(
    itemCount: group.backendCategories.length,
    itemBuilder: (context, index) {
      final category = group.backendCategories[index];
      return GestureDetector(
        onTap: () => onUpdate(
          data.updateData('selectedBackendCategory', category)
        ),
        child: /* UI for category selection */
      );
    },
  );
}
```

#### `buildServiceSelection()` - Step 5
```dart
static Widget buildServiceSelection(
  BuildContext context, 
  OnboardingData data, 
  Function(OnboardingData) onUpdate
) {
  // Filters services by selectedBackendCategory
  final selectedCategory = data.get<String>('selectedBackendCategory');
  
  // Fetches services and filters by category
  final categoryServices = _filterServicesByCategory(selectedCategory);
  
  // Uses EnhancedServiceSelector for multi-select
  return EnhancedServiceSelector(
    allServices: categoryServices,
    selectedServices: data.get<List>('selectedServices') ?? [],
    onConfirm: (selected) {
      onUpdate(data.updateData('selectedServices', selected));
    },
  );
}
```

**Relationship**:
```
onboarding_config.dart (defines step builders)
    ↓ (references)
provider_steps.dart (implements UI widgets)
    ↓ (uses)
frontend_category_grouping.dart (for category groups)
```

---

### 3. `onboarding_config.dart` - Configuration & Data Model

**Purpose**: Defines the onboarding flow structure, data model, and step configuration.

#### Key Classes:

**`OnboardingData`** - Data storage
```dart
class OnboardingData {
  final OnboardingType type;
  final Map<String, dynamic> data;  // Stores all form data
  
  // Methods for data manipulation
  OnboardingData updateData(String key, dynamic value) { /* ... */ }
  T? get<T>(String key) { /* ... */ }
  bool has(String key) { /* ... */ }
}
```

**Data Flow Example**:
```dart
// Step 1: User selects "Repair & Maintenance"
OnboardingData data = data.updateData('selectedGroup', group);

// Step 2: User selects "Garage / Mechanic"
data = data.updateData('selectedBackendCategory', 'Garage / Mechanic');

// Step 3: User fills form
data = data.updateData('name', 'AutoCare Kenya');
data = data.updateData('phone', '+254 700 123 456');
// ... etc

// Step 5: User selects services
data = data.updateData('selectedServices', ['service-1', 'service-2']);
```

**`OnboardingConfig`** - Flow configuration
```dart
OnboardingConfig(
  type: OnboardingType.serviceProvider,
  title: 'Service Provider Registration',
  steps: [
    OnboardingStep(
      id: 'business_type',
      title: 'Business Type',
      builder: ProviderSteps.buildBusinessTypeSelection,  // ← References provider_steps.dart
      validator: (data) => data.has('selectedGroup'),
    ),
    OnboardingStep(
      id: 'category',
      title: 'Service Category',
      builder: ProviderSteps.buildCategorySelection,  // ← References provider_steps.dart
      validator: (data) => data.has('selectedBackendCategory'),
    ),
    // ... more steps
  ],
)
```

**Relationship**:
```
onboarding_config.dart
    ├── Defines OnboardingData (data model)
    ├── Defines OnboardingConfig (flow structure)
    └── References ProviderSteps.* (UI builders)
        ↓
    provider_steps.dart (implements UI)
```

---

### 4. `dynamic_onboarding_flow.dart` - Flow Orchestrator

**Purpose**: Manages the entire onboarding flow, step progression, validation, and final submission.

#### Key Methods:

**`build()`** - Main UI structure
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildProgressIndicator(),  // Shows step progress
        Expanded(
          child: _buildCurrentStep(),  // Renders current step
        ),
        _buildNavigationButtons(),  // Next/Back buttons
      ],
    ),
  );
}
```

**`_buildCurrentStep()`** - Renders step UI
```dart
Widget _buildCurrentStep() {
  if (_currentStep >= _config.steps.length) {
    return _buildCompletionStep();  // Show completion screen
  }
  
  // Gets step from onboarding_config.dart
  final step = _config.steps[_currentStep];
  
  // Calls builder from provider_steps.dart
  return step.builder(context, _data, _updateData);
}
```

**`_completeRegistration()`** - Final submission
```dart
void _completeRegistration() async {
  try {
    // Reads data from OnboardingData
    final selectedCategory = _data.get<String>('selectedBackendCategory');
    final name = _data.get<String>('name');
    // ... get all required fields
    
    // Maps frontend category to backend category_id
    final categories = await ProviderService.getProviderCategories();
    final category = categories.firstWhere(
      (cat) => cat['name'] == selectedCategory,
    );
    
    // Creates provider
    final providerData = {
      'category_id': category['id'],
      'name': name,
      'location': locationData,
      // ... other fields
    };
    
    final result = await ProviderService.createProvider(providerData);
    
    // Attaches services
    await ProviderService.attachServicesToProvider(
      providerId, 
      servicesToAttach
    );
    
    // Move to completion step
    setState(() {
      _currentStep = _config.steps.length;
    });
  } catch (e) {
    _showErrorDialog('Registration Failed', e.toString());
  }
}
```

**Relationship**:
```
dynamic_onboarding_flow.dart
    ├── Uses OnboardingConfig from onboarding_config.dart
    ├── Manages OnboardingData from onboarding_config.dart
    ├── Calls builders from provider_steps.dart
    └── Orchestrates entire flow
```

---

### 5. `provider_category_config.dart` - Post-Onboarding Configuration

**Purpose**: Configures provider dashboards, UI themes, and quick actions based on the selected category.

**Usage**: After registration, the system uses the `selectedBackendCategory` to configure the provider's dashboard.

```dart
// Example: After onboarding, provider selected "Garage / Mechanic"
final categoryName = 'Garage / Mechanic';
final config = ProviderCategoryConfigs.getConfig(categoryName);

// Returns:
ProviderCategoryConfig(
  name: 'Garage / Mechanic',
  id: 2,
  primaryColor: Colors.blue,
  icon: Icons.build,
  quickActions: [
    QuickAction(title: 'Log Service', route: '/provider-log-service'),
    QuickAction(title: 'Orders & Parts', isComingSoon: true),
    // ... more actions
  ],
  statCards: [
    StatCard(title: 'Active Bookings', value: '8'),
    StatCard(title: "Today's Earnings", value: 'KES 12,400'),
    // ... more stats
  ],
)
```

**Relationship**:
```
dynamic_onboarding_flow.dart
    ↓ (completes registration with selectedBackendCategory)
Backend stores provider with category
    ↓
Provider dashboard loads
    ↓
provider_category_config.dart
    ↓ (configures dashboard based on category)
Dashboard UI rendered with category-specific config
```

---

## 🔗 Complete Data Flow Example

### Example: User Onboards as "Garage / Mechanic"

```dart
// 1. INITIALIZATION
DynamicOnboardingFlow(type: OnboardingType.serviceProvider)
    ↓
OnboardingConfigs.getServiceProviderConfig()
    ↓
OnboardingData(type: serviceProvider, data: {})

// 2. STEP 1: Business Type Selection
ProviderSteps.buildBusinessTypeSelection(...)
    ↓
FrontendCategoryGroups.getAllGroups()
    ↓
User selects: "Repair & Maintenance" group
    ↓
OnboardingData.updateData('selectedGroup', repairGroup)

// 3. STEP 2: Category Selection
ProviderSteps.buildCategorySelection(...)
    ↓
data.get<FrontendCategoryGroup>('selectedGroup')
    ↓
Shows: ["Garage / Mechanic", "Tyre & Wheel Center", ...]
    ↓
User selects: "Garage / Mechanic"
    ↓
OnboardingData.updateData('selectedBackendCategory', 'Garage / Mechanic')

// 4. STEP 3: Business Details
ProviderSteps.buildProviderDetailsForm(...)
    ↓
User fills: name="AutoCare", phone="+254...", etc.
    ↓
OnboardingData.updateData('name', 'AutoCare')
OnboardingData.updateData('phone', '+254...')
// ... more fields

// 5. STEP 4: Location
onboarding_config.dart._buildLocationStep(...)
    ↓
User selects location with lat/lng
    ↓
OnboardingData.updateData('locationData', {...lat, lng, address...})

// 6. STEP 5: Service Selection
ProviderSteps.buildServiceSelection(...)
    ↓
Filters services by category: "Garage / Mechanic"
    ↓
User selects: ["Oil Change", "Tire Rotation", "Battery Replacement"]
    ↓
OnboardingData.updateData('selectedServices', [...])
OnboardingData.updateData('serviceValues', {...})

// 7. COMPLETION
dynamic_onboarding_flow.dart._completeRegistration()
    ↓
Reads all data from OnboardingData:
  - selectedBackendCategory: "Garage / Mechanic"
  - name: "AutoCare"
  - locationData: {...}
  - selectedServices: [...]
    ↓
Maps "Garage / Mechanic" → category_id: 2
    ↓
ProviderService.createProvider({
  category_id: 2,
  name: "AutoCare",
  location: {...},
  ...
})
    ↓
ProviderService.attachServicesToProvider(providerId, services)
    ↓
Success! Move to completion step

// 8. POST-ONBOARDING
ProviderCategoryConfigs.getConfig("Garage / Mechanic")
    ↓
Returns: ProviderCategoryConfig with blue theme, build icon, etc.
    ↓
Dashboard configured and displayed
```

---

## 📊 Key Relationships Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    frontend_category_grouping.dart            │
│  • Groups 17 categories → 5 frontend groups                 │
│  • Used by: provider_steps.dart (Step 1)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    provider_steps.dart                       │
│  • Implements UI for all steps                               │
│  • Uses: frontend_category_grouping.dart                      │
│  • Called by: onboarding_config.dart                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    onboarding_config.dart                    │
│  • Defines OnboardingData (data model)                       │
│  • Defines OnboardingConfig (flow structure)                 │
│  • References: provider_steps.dart builders                  │
│  • Used by: dynamic_onboarding_flow.dart                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    dynamic_onboarding_flow.dart              │
│  • Orchestrates entire flow                                  │
│  • Uses: onboarding_config.dart for config & data             │
│  • Calls: provider_steps.dart builders                        │
│  • Handles: validation, submission, completion                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼ (after registration)
┌─────────────────────────────────────────────────────────────┐
│                    provider_category_config.dart             │
│  • Configures dashboard based on selectedBackendCategory     │
│  • Provides: themes, quick actions, stat cards               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Design Patterns

### 1. **Separation of Concerns**
- **UI**: `provider_steps.dart` (presentation)
- **Configuration**: `onboarding_config.dart` (structure)
- **Orchestration**: `dynamic_onboarding_flow.dart` (logic)
- **Grouping**: `frontend_category_grouping.dart` (UX simplification)

### 2. **Data Flow**
- All data flows through `OnboardingData` (single source of truth)
- Immutable updates via `updateData()` method
- Type-safe access via `get<T>()` method

### 3. **Builder Pattern**
- Step builders are functions: `Widget Function(BuildContext, OnboardingData, Function(OnboardingData))`
- Allows dynamic step composition
- Easy to add/remove/reorder steps

### 4. **Configuration-Driven**
- Steps defined declaratively in `OnboardingConfig`
- Validators attached to each step
- Easy to extend with new onboarding types

---

## 🚀 Adding a New Onboarding Type

To add a new onboarding type (e.g., "Parts Supplier"):

1. **Add step builders** in a new file (e.g., `parts_supplier_steps.dart`)
2. **Add config** in `onboarding_config.dart`:
   ```dart
   static OnboardingConfig getPartsSupplierConfig() {
     return OnboardingConfig(
       type: OnboardingType.partsSupplier,
       steps: [
         OnboardingStep(
           builder: PartsSupplierSteps.buildStep1,
           validator: (data) => /* validation */,
         ),
         // ... more steps
       ],
     );
   }
   ```
3. **Update** `dynamic_onboarding_flow.dart` to handle new type
4. **Add category config** in `provider_category_config.dart` if needed

---

## 📝 Common Data Keys in OnboardingData

| Key | Type | Set In Step | Used For |
|-----|------|-------------|----------|
| `selectedGroup` | `FrontendCategoryGroup` | Step 1 | Displaying category options |
| `selectedBackendCategory` | `String` | Step 2 | Backend API submission |
| `name` | `String` | Step 3 | Provider name |
| `description` | `String` | Step 3 | Provider description |
| `phone` | `String` | Step 3 | Contact phone |
| `email` | `String` | Step 3 | Contact email |
| `location` | `String` | Step 3 | Location string |
| `locationData` | `Map<String, dynamic>` | Step 4 | Full location with lat/lng |
| `selectedServices` | `List<String>` | Step 5 | Service IDs to attach |
| `serviceValues` | `Map<String, dynamic>` | Step 5 | Service-specific form values |
| `availableServices` | `List` | Step 5 | All available services for category |

---

## 🔍 Debugging Tips

1. **Check OnboardingData**: Print `_data.data` to see all stored values
2. **Validate Step**: Check step validator returns `true` before proceeding
3. **Check Bounds**: Ensure `_currentStep < _config.steps.length` before accessing steps
4. **Check Category Mapping**: Verify `selectedBackendCategory` matches backend category names
5. **Check Service Filtering**: Ensure services are filtered by `selectedBackendCategory`

---

## 📚 Related Files

- `services/provider_service.dart` - Backend API calls
- `services/insurance_service.dart` - Insurance partner API calls
- `BookingPageHelpers/enhanced_service_selector.dart` - Service selection UI
- `components/location_picker.dart` - Location selection component

