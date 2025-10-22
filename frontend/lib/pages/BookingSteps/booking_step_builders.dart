import 'package:flutter/material.dart';
import 'package:car_platform/models/booking_config.dart';
import 'package:car_platform/BookingPageHelpers/enhanced_service_selector.dart';
import 'package:car_platform/BookingPageHelpers/enhanced_provider_selector.dart';
import 'package:car_platform/components/location_picker.dart';
import 'package:car_platform/utils/location_display_helper.dart';

class BookingStepBuilders {
  static Widget buildVehicleAndServiceStep(
    BuildContext context, 
    BookingData data, 
    Function(BookingData) updateData,
    {
      required List<dynamic> vehicles,
      required String? selectedVehicleId,
      required Function(String?) onVehicleChanged,
      required List<Map<String, dynamic>> allServices,
      required List<Map<String, dynamic>> selectedServices,
      required Function(List<Map<String, dynamic>>) onServicesChanged,
      required bool isSparePartsMode,
      required bool isPurchaseMode,
    }
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title and description
          Text(
            'Select Vehicle & ${isSparePartsMode ? 'Parts' : 'Services'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your vehicle and the ${isSparePartsMode ? 'parts' : 'services'} you need',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Vehicle Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Vehicle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedVehicleId,
                    items: vehicles
                        .map((v) => DropdownMenuItem<String>(
                              value: v["id"].toString(),
                              child: Text(
                                "${v["plate"] ?? ""} ${v["make"] ?? ""} (${v["model"] ?? v["id"]})",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      onVehicleChanged(val);
                      data.set('selectedVehicleId', val);
                      updateData(data);
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Vehicle",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Service/Parts Selection
          Card(
            child: ListTile(
              leading: Icon(
                isSparePartsMode ? Icons.inventory_2 : Icons.build_circle,
                color: isSparePartsMode ? Colors.orange : Colors.blue,
              ),
              title: Text(isSparePartsMode ? "Spare Parts" : "Services"),
              subtitle: selectedServices.isEmpty
                  ? Text(isSparePartsMode 
                      ? "Tap to select spare parts" 
                      : "Tap to select services")
                  : Text(isSparePartsMode
                      ? "${selectedServices.length} parts selected"
                      : "${selectedServices.length} services selected"),
              trailing: selectedServices.isEmpty
                  ? const Icon(Icons.arrow_forward_ios)
                  : Chip(
                      label: Text("${selectedServices.length}"),
                      backgroundColor: isSparePartsMode 
                          ? Colors.orange[100] 
                          : Colors.blue[100],
                    ),
              onTap: () => _showServiceSelector(
                context, 
                allServices, 
                selectedServices, 
                isSparePartsMode, 
                isPurchaseMode,
                (services) {
                  onServicesChanged(services);
                  data.set('selectedServices', services);
                  updateData(data);
                }
              ),
            ),
          ),

          // Show selected services (compact)
          if (selectedServices.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSparePartsMode ? Colors.orange[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSparePartsMode 
                      ? Colors.orange[200]! 
                      : Colors.blue[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        isSparePartsMode
                            ? "${selectedServices.length} parts selected"
                            : "${selectedServices.length} services selected",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSparePartsMode 
                              ? Colors.orange[800] 
                              : Colors.blue[800],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: selectedServices.take(3).map((service) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSparePartsMode 
                            ? Colors.orange[100] 
                            : Colors.blue[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service["name"] ?? (isSparePartsMode ? "Part" : "Service"),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSparePartsMode 
                              ? Colors.orange[800] 
                              : Colors.blue[800],
                        ),
                      ),
                    )).toList()
                      ..addAll(selectedServices.length > 3 ? [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "+${selectedServices.length - 3} more",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ] : []),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildProviderSelectionStep(
    BuildContext context, 
    BookingData data, 
    Function(BookingData) updateData,
    {
      required List<Map<String, dynamic>> matchedProviders,
      required Map<String, dynamic>? selectedProvider,
      required Function(Map<String, dynamic>?) onProviderSelected,
      required List<Map<String, dynamic>> selectedServices,
      required bool recommendedOnly,
      required bool providersLoading,
      required Map<String, dynamic>? serviceLocation,
      // Contact callbacks provided by parent page
      required void Function(Map<String, dynamic>) onCallProvider,
      required void Function(Map<String, dynamic>) onWhatsAppProvider,
      required void Function(Map<String, dynamic>) onSmsProvider,
      required void Function(Map<String, dynamic>) onEmailProvider,
    }
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title and description
          Text(
            'Choose Provider',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your preferred service provider from the available options',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          if (providersLoading)
            const Center(child: CircularProgressIndicator())
          else if (matchedProviders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No providers found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your service selection or preferences',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.business, color: Colors.green),
                    title: const Text("Provider"),
                    subtitle: selectedProvider == null
                        ? const Text("Tap to select provider")
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedProvider!["provider_name"] ?? "Selected Provider",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      LocationDisplayHelper.formatLocationShort(selectedProvider!["location"]),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (selectedProvider!["is_registered"])
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "✓",
                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                    trailing: selectedProvider == null
                        ? const Icon(Icons.arrow_forward_ios)
                        : Chip(
                            label: Text(selectedProvider!["rating"]?.toString() ?? "0.0"),
                            backgroundColor: Colors.green[100],
                            avatar: const Icon(Icons.star, size: 16),
                          ),
                    onTap: () => _showProviderSelector(
                      context,
                      matchedProviders,
                      selectedServices,
                      recommendedOnly,
                      selectedProvider,
                      (provider) {
                        onProviderSelected(provider);
                        data.set('selectedProvider', provider);
                        updateData(data);
                      },
                      serviceLocation,
                    ),
                  ),
                  if (selectedProvider != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onCallProvider(selectedProvider!),
                              icon: const Icon(Icons.phone),
                              label: const Text("Call"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onWhatsAppProvider(selectedProvider!),
                              icon: const Icon(Icons.chat),
                              label: const Text("WhatsApp"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedProvider != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onSmsProvider(selectedProvider!),
                              icon: const Icon(Icons.sms),
                              label: const Text("SMS"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onEmailProvider(selectedProvider!),
                              icon: const Icon(Icons.email),
                              label: const Text("Email"),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildSchedulingAndLocationStep(
    BuildContext context, 
    BookingData data, 
    Function(BookingData) updateData,
    {
      required DateTime? selectedDate,
      required TimeOfDay? selectedTime,
      required Function(DateTime?) onDateChanged,
      required Function(TimeOfDay?) onTimeChanged,
      required Map<String, dynamic>? serviceLocation,
      required Function(Map<String, dynamic>?) onLocationChanged,
    }
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title and description
          Text(
            'Schedule & Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your preferred date, time, and service location',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Date and Time Selection - Compact horizontal layout
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, selectedDate, onDateChanged, data, updateData),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Date", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(
                                selectedDate == null
                                    ? "Select date"
                                    : selectedDate!.toLocal().toString().split(" ")[0],
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(context, selectedTime, onTimeChanged, data, updateData),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.purple, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Time", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(
                                selectedTime == null
                                    ? "Select time"
                                    : selectedTime!.format(context),
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Location Selection Section
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        "Service Location",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "💡 Specify where you need the service (home, office, roadside, etc.)",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Service location picker
                  LocationPicker(
                    label: "Where do you need the service?",
                    hint: "Tap to select service location",
                    onLocationSelected: (location) {
                      onLocationChanged(location);
                      data.set('serviceLocation', location);
                      updateData(data);
                    },
                    showCurrentLocationButton: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPricingAndConfirmationStep(
    BuildContext context, 
    BookingData data, 
    Function(BookingData) updateData,
    {
      required List<Map<String, dynamic>> selectedServices,
      required Map<String, dynamic>? selectedProvider,
      required Map<String, double> servicePrices,
      required Map<String, double> negotiatedPrices,
      required Map<String, Map<String, dynamic>> servicePricingInfo,
      required bool hasNegotiated,
      required VoidCallback onBook,
      required VoidCallback onOpenNegotiationDialog,
      required bool isLoading,
    }
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title and description
          Text(
            'Review & Confirm',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your booking details and pricing before confirming',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Booking Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Provider info
                  if (selectedProvider != null) ...[
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedProvider!["provider_name"] ?? "Provider",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocationDisplayHelper.formatLocationForDisplay(selectedProvider!["location"]),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Services
                  Text(
                    'Services:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  ...selectedServices.map((service) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service["name"] ?? "Service",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pricing Summary
          if (selectedServices.isNotEmpty && selectedProvider != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Cost:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "KES ${_calculateTotalCost(selectedServices, negotiatedPrices, servicePrices).toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  if (hasNegotiated)
                    const SizedBox(height: 4),
                  if (hasNegotiated)
                    Text(
                      "✅ Negotiated prices included",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onOpenNegotiationDialog,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("Update Prices"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : onBook,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text("Confirm"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  static Future<void> _showServiceSelector(
    BuildContext context,
    List<Map<String, dynamic>> allServices,
    List<Map<String, dynamic>> selectedServices,
    bool isSparePartsMode,
    bool isPurchaseMode,
    Function(List<Map<String, dynamic>>) onConfirm,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EnhancedServiceSelector(
        allServices: allServices,
        selectedServices: selectedServices,
        isSparePartsMode: isSparePartsMode,
        isPurchaseMode: isPurchaseMode,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<void> _showProviderSelector(
    BuildContext context,
    List<Map<String, dynamic>> filteredProviders,
    List<Map<String, dynamic>> selectedServices,
    bool recommendedOnly,
    Map<String, dynamic>? selectedProvider,
    Function(Map<String, dynamic>?) onSelect,
    Map<String, dynamic>? customerLocation,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EnhancedProviderSelector(
        filteredProviders: filteredProviders,
        selectedServices: selectedServices,
        recommendedOnly: recommendedOnly,
        selectedProvider: selectedProvider,
        onSelect: onSelect,
        customerLocation: customerLocation,
      ),
    );
  }

  static Future<void> _pickDate(
    BuildContext context,
    DateTime? selectedDate,
    Function(DateTime?) onDateChanged,
    BookingData data,
    Function(BookingData) updateData,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateChanged(picked);
      data.set('selectedDate', picked);
      updateData(data);
    }
  }

  static Future<void> _pickTime(
    BuildContext context,
    TimeOfDay? selectedTime,
    Function(TimeOfDay?) onTimeChanged,
    BookingData data,
    Function(BookingData) updateData,
  ) async {
    final t = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) {
      onTimeChanged(t);
      data.set('selectedTime', t);
      updateData(data);
    }
  }

  static double _calculateTotalCost(
    List<Map<String, dynamic>> selectedServices,
    Map<String, double> negotiatedPrices,
    Map<String, double> servicePrices,
  ) {
    double total = 0.0;
    for (var service in selectedServices) {
      final serviceId = service["id"]?.toString() ?? "";
      final negotiatedPrice = negotiatedPrices[serviceId] ?? servicePrices[serviceId] ?? 0.0;
      total += negotiatedPrice;
    }
    return total;
  }
}
