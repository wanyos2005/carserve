# Dynamic Onboarding Flow System

## Overview

The Dynamic Onboarding Flow System provides a flexible, reusable onboarding experience that can handle different types of business registrations. Currently supports:

- **Service Providers** (garages, fuel stations, car washes, etc.)
- **Insurance Partners** (insurance companies)

## 🏗️ Architecture

### Core Components

1. **`OnboardingConfig`** - Configuration for different onboarding types
2. **`OnboardingData`** - Data model for storing form data
3. **`DynamicOnboardingFlow`** - Main widget that orchestrates the flow
4. **Step Builders** - Individual step implementations

### File Structure

```
frontend/lib/
├── models/
│   └── onboarding_config.dart          # Core configuration and data models
├── pages/ProviderPages/
│   ├── dynamic_onboarding_flow.dart    # Main onboarding widget
│   ├── insurance_partner_steps.dart    # Insurance partner specific steps
│   ├── onboarding_demo.dart            # Demo page showing both types
│   └── provider_onboarding_flow.dart   # Original service provider flow
```

## 🎯 Usage

### Basic Usage

```dart
// Navigate to insurance partner onboarding
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => DynamicOnboardingFlow(
      type: OnboardingType.insurancePartner,
    ),
  ),
);

// Navigate to service provider onboarding
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => DynamicOnboardingFlow(
      type: OnboardingType.serviceProvider,
    ),
  ),
);
```

### Demo Page

Use the `OnboardingDemo` page to see both options:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const OnboardingDemo(),
  ),
);
```

## 🔧 Insurance Partner Onboarding

### Steps Overview

1. **Company Information**
   - Company name, code, description
   - Contact email, phone, address

2. **Service Capabilities**
   - Quote generation support
   - Claims processing support
   - Data feeds support

3. **Coverage Types**
   - Comprehensive insurance
   - Third party insurance
   - Fire & theft insurance
   - Commercial motor insurance

4. **Enhanced Information** (Optional)
   - Customer rating
   - Total reviews
   - Claims processing time
   - Market share
   - Established year
   - Website and logo URLs

5. **API Configuration**
   - API endpoint (required)
   - Webhook URL
   - Commission rate

### Data Flow

```dart
// Example of how data flows through the system
OnboardingData data = OnboardingData(type: OnboardingType.insurancePartner);

// Update data in a step
data = data.updateData('name', 'Kenya Insurance Company');
data = data.updateData('supports_quotes', true);
data = data.updateData('supported_coverage_types', ['comprehensive', 'third_party']);

// Validate step
bool canProceed = config.steps[currentStep].validator(data);
```

## 🎨 Customization

### Adding New Onboarding Types

1. **Add new enum value**:
```dart
enum OnboardingType {
  serviceProvider,
  insurancePartner,
  newType, // Add here
}
```

2. **Create configuration**:
```dart
static OnboardingConfig getNewTypeConfig() {
  return OnboardingConfig(
    type: OnboardingType.newType,
    title: 'New Type Registration',
    description: 'Description here',
    primaryColor: Colors.green,
    icon: Icons.new_icon,
    steps: [
      // Define steps here
    ],
  );
}
```

3. **Create step builders**:
```dart
class NewTypeSteps {
  static Widget buildStep1(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    // Implementation
  }
}
```

### Customizing Steps

Each step is defined with:
- **ID**: Unique identifier
- **Title & Description**: UI text
- **Builder**: Widget that renders the step
- **Validator**: Function that validates step completion

```dart
OnboardingStep(
  id: 'company_info',
  title: 'Company Information',
  description: 'Tell us about your company',
  builder: (context, data, onUpdate) => YourCustomWidget(),
  validator: (data) => data.has('name') && data.has('email'),
)
```

## 🔄 Data Management

### OnboardingData Model

```dart
class OnboardingData {
  final OnboardingType type;
  final Map<String, dynamic> data;
  
  // Update data
  OnboardingData updateData(String key, dynamic value);
  
  // Get data
  T? get<T>(String key);
  
  // Check if key exists
  bool has(String key);
}
```

### Validation

Each step has a validator function that determines if the user can proceed:

```dart
validator: (data) => 
  data.has('name') && 
  data.has('email') && 
  data.get<String>('name')?.isNotEmpty == true
```

## 🚀 Integration with Backend

### Service Provider Integration

Uses existing `ProviderService`:
```dart
await ProviderService.createProvider(providerData);
await ProviderService.attachServicesToProvider(providerId, services);
```

### Insurance Partner Integration

Uses `InsuranceService`:
```dart
await InsuranceService.createPartner(partnerData);
```

## 📱 UI Features

### Progress Indicator
- Visual progress bar showing current step
- Color-coded based on onboarding type

### Navigation
- Back/Continue buttons
- Validation-based button states
- Loading states during submission

### Responsive Design
- Works on different screen sizes
- Scrollable content for long forms
- Proper keyboard handling

## 🎯 Benefits

### For Developers
- **Reusable**: One system handles multiple onboarding types
- **Maintainable**: Clear separation of concerns
- **Extensible**: Easy to add new onboarding types
- **Type-safe**: Strong typing with Dart

### For Users
- **Consistent**: Same UX patterns across different flows
- **Intuitive**: Clear progress indication and validation
- **Flexible**: Optional fields where appropriate
- **Professional**: Polished, modern UI

### For Business
- **Scalable**: Easy to add new business types
- **Efficient**: Streamlined registration process
- **Comprehensive**: Captures all necessary data
- **Integrated**: Seamless backend integration

## 🔮 Future Enhancements

### Planned Features
1. **Multi-step validation**: Real-time validation feedback
2. **Save & resume**: Allow users to save progress
3. **Document upload**: Support for file uploads
4. **Payment integration**: Handle registration fees
5. **Email verification**: Verify contact information

### Additional Onboarding Types
1. **Fleet Management**: For fleet operators
2. **Parts Suppliers**: For auto parts dealers
3. **Training Centers**: For driving schools
4. **Government Agencies**: For regulatory bodies

## 📝 Example: Complete Insurance Partner Registration

```dart
// 1. Navigate to onboarding
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => DynamicOnboardingFlow(
      type: OnboardingType.insurancePartner,
    ),
  ),
);

// 2. User fills out 5 steps:
//    - Company info (name, code, description, contact)
//    - Capabilities (quotes, claims, data feeds)
//    - Coverage types (comprehensive, third party, etc.)
//    - Enhanced info (rating, reviews, processing time)
//    - API config (endpoints, commission)

// 3. System validates each step
// 4. On completion, creates partner via InsuranceService
// 5. Shows success message and returns to previous screen
```

## 🎉 Conclusion

The Dynamic Onboarding Flow System provides a robust, flexible foundation for business registration that can grow with your platform's needs. It maintains consistency while allowing for type-specific customization, making it easy to onboard new business types in the future.
