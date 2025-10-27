import 'package:flutter/material.dart';
import 'package:driveon_car_platform/pages/BookingSteps/booking_step_builders.dart';

enum BookingStepType {
  vehicleAndService,
  providerSelection,
  schedulingAndLocation,
  pricingAndConfirmation,
}

class BookingStep {
  // we use final to make the variables immutable and cannot be changed after they are initialized
  final String title;
  final String description;
  final BookingStepType type;
  final Widget Function(BuildContext context, BookingData data, Function(BookingData) updateData) builder;
  final bool Function(BookingData data) validator;

  const BookingStep({
    required this.title,
    required this.description,
    required this.type,
    required this.builder,
    required this.validator,
  });
}

class BookingConfig {
  final String title;
  final Color primaryColor;
  final List<BookingStep> steps;

  const BookingConfig({
    required this.title,
    required this.primaryColor,
    required this.steps,
  });
}

class BookingData {
  final Map<String, dynamic> _data = {};

  BookingData();

  T? get<T>(String key) => _data[key] as T?;
  
  void set<T>(String key, T value) {
    _data[key] = value;
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_data);
  
  void updateFromMap(Map<String, dynamic> map) {
    _data.addAll(map);
  }
}

class BookingConfigs {
  static BookingConfig getServiceBookingConfig() {
    return BookingConfig(
      title: 'Book Service',
      primaryColor: Colors.blue,
      steps: [
        BookingStep(
          title: 'Vehicle & Service',
          description: 'Select your vehicle and required services',
          type: BookingStepType.vehicleAndService,
          builder: _buildVehicleAndServiceStep,
          validator: (data) => data.get<String>('selectedVehicleId') != null && 
                              (data.get<List>('selectedServices')?.isNotEmpty ?? false),
        ),
        BookingStep(
          title: 'Provider Selection',
          description: 'Choose your preferred service provider',
          type: BookingStepType.providerSelection,
          builder: _buildProviderSelectionStep,
          validator: (data) => data.get<Map<String, dynamic>>('selectedProvider') != null,
        ),
        BookingStep(
          title: 'Schedule & Location',
          description: 'Set date, time, and service location',
          type: BookingStepType.schedulingAndLocation,
          builder: _buildSchedulingAndLocationStep,
          validator: (data) => data.get<DateTime>('selectedDate') != null && 
                              data.get<TimeOfDay>('selectedTime') != null &&
                              data.get<Map<String, dynamic>>('serviceLocation') != null,
        ),
        BookingStep(
          title: 'Pricing & Confirmation',
          description: 'Review pricing and confirm your booking',
          type: BookingStepType.pricingAndConfirmation,
          builder: _buildPricingAndConfirmationStep,
          validator: (data) => true, // Always valid for final step
        ),
      ],
    );
  }

  static BookingConfig getPurchaseConfig() {
    return BookingConfig(
      title: 'Purchase Parts',
      primaryColor: Colors.orange,
      steps: [
        BookingStep(
          title: 'Vehicle & Parts',
          description: 'Select your vehicle and required parts',
          type: BookingStepType.vehicleAndService,
          builder: _buildVehicleAndServiceStep,
          validator: (data) => data.get<String>('selectedVehicleId') != null && 
                              (data.get<List>('selectedServices')?.isNotEmpty ?? false),
        ),
        BookingStep(
          title: 'Supplier Selection',
          description: 'Choose your preferred parts supplier',
          type: BookingStepType.providerSelection,
          builder: _buildProviderSelectionStep,
          validator: (data) => data.get<Map<String, dynamic>>('selectedProvider') != null,
        ),
        BookingStep(
          title: 'Order Details',
          description: 'Set delivery location and preferences',
          type: BookingStepType.schedulingAndLocation,
          builder: _buildSchedulingAndLocationStep,
          validator: (data) => data.get<Map<String, dynamic>>('serviceLocation') != null,
        ),
        BookingStep(
          title: 'Pricing & Confirmation',
          description: 'Review pricing and confirm your order',
          type: BookingStepType.pricingAndConfirmation,
          builder: _buildPricingAndConfirmationStep,
          validator: (data) => true,
        ),
      ],
    );
  }

  // Step builders - these will be overridden with actual implementations
  static Widget _buildVehicleAndServiceStep(BuildContext context, BookingData data, Function(BookingData) updateData) {
    // This will be overridden in the main booking page with actual data
    return const Center(child: Text('Vehicle & Service Step - Loading...'));
  }

  static Widget _buildProviderSelectionStep(BuildContext context, BookingData data, Function(BookingData) updateData) {
    // This will be overridden in the main booking page with actual data
    return const Center(child: Text('Provider Selection Step - Loading...'));
  }

  static Widget _buildSchedulingAndLocationStep(BuildContext context, BookingData data, Function(BookingData) updateData) {
    // This will be overridden in the main booking page with actual data
    return const Center(child: Text('Scheduling & Location Step - Loading...'));
  }

  static Widget _buildPricingAndConfirmationStep(BuildContext context, BookingData data, Function(BookingData) updateData) {
    // This will be overridden in the main booking page with actual data
    return const Center(child: Text('Pricing & Confirmation Step - Loading...'));
  }
}
