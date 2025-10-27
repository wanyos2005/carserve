import 'package:flutter/material.dart';
import 'package:driveon_car_platform/components/enhanced_pricing_form.dart';

/// Helper class for handling service requirements during provider onboarding
class ServiceRequirementsHelper {
  
  /// Get service requirements based on service name and category
  static Map<String, dynamic> getServiceRequirements(String serviceName, String categoryName) {
    // Default requirements with enhanced pricing
    Map<String, dynamic> requirements = {
      "fields": [
        {
          "name": "pricing",
          "label": "Service Pricing",
          "type": "enhanced_pricing",
          "required": true
        }
      ]
    };
    
    // Add category-specific requirements
    if (categoryName == "Oil & Lubrication" && serviceName.contains("Oil Change")) {
      requirements["fields"].addAll([
        {
          "name": "oil_type",
          "label": "Oil Type",
          "type": "select",
          "options": ["Conventional", "Synthetic", "Semi-Synthetic"],
          "required": true
        },
        {
          "name": "oil_grade",
          "label": "Oil Grade",
          "type": "select",
          "options": ["5W-30", "10W-40", "15W-40", "5W-20"],
          "required": true
        }
      ]);
    } else if (categoryName == "Tyres & Wheels") {
      requirements["fields"].addAll([
        {
          "name": "tyre_size",
          "label": "Tyre Size",
          "type": "text",
          "required": true
        },
        {
          "name": "tyre_brand",
          "label": "Tyre Brand",
          "type": "select",
          "options": ["Michelin", "Bridgestone", "Continental", "Goodyear", "Pirelli", "Other"],
          "required": false
        }
      ]);
    } else if (categoryName == "Refueling") {
      requirements["fields"].addAll([
        {
          "name": "fuel_type",
          "label": "Fuel Type",
          "type": "select",
          "options": ["Petrol", "Diesel", "LPG", "CNG", "Electric"],
          "required": true
        },
        {
          "name": "quantity",
          "label": "Quantity (Liters/kWh)",
          "type": "number",
          "required": true
        }
      ]);
    } else if (categoryName == "Roadside Assistance") {
      requirements["fields"].addAll([
        {
          "name": "location",
          "label": "Current Location",
          "type": "text",
          "required": true
        },
        {
          "name": "vehicle_type",
          "label": "Vehicle Type",
          "type": "select",
          "options": ["Car", "SUV", "Truck", "Motorcycle", "Other"],
          "required": true
        }
      ]);
    } else if (categoryName == "Vehicle Pickup & Delivery") {
      requirements["fields"].addAll([
        {
          "name": "pickup_address",
          "label": "Pickup Address",
          "type": "text",
          "required": true
        },
        {
          "name": "delivery_address",
          "label": "Delivery Address",
          "type": "text",
          "required": true
        }
      ]);
    }
    
    return requirements;
  }

  /// Build a form widget for service requirements
  static Widget buildRequirementsForm(Map<String, dynamic> requirements, Map<String, dynamic> currentValues, Function(Map<String, dynamic>) onChanged) {
    return Column(
      children: requirements["fields"].map<Widget>((field) {
        return _buildFormField(field, currentValues, onChanged);
      }).toList(),
    );
  }

  static Widget _buildFormField(Map<String, dynamic> field, Map<String, dynamic> currentValues, Function(Map<String, dynamic>) onChanged) {
    final fieldName = field["name"];
    final fieldType = field["type"];
    final isRequired = field["required"] ?? false;
    final label = field["label"];

    switch (fieldType) {
      case "enhanced_pricing":
        return EnhancedPricingForm(
          currentValues: currentValues,
          onChanged: onChanged,
          required: isRequired,
        );
        
      case "select":
        final options = List<String>.from(field["options"] ?? []);
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label + (isRequired ? " *" : ""),
            border: const OutlineInputBorder(),
          ),
          initialValue: currentValues[fieldName],
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            final newValues = Map<String, dynamic>.from(currentValues);
            newValues[fieldName] = value;
            onChanged(newValues);
          },
        );
      
      case "number":
        return TextFormField(
          decoration: InputDecoration(
            labelText: label + (isRequired ? " *" : ""),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          initialValue: currentValues[fieldName]?.toString(),
          onChanged: (value) {
            final newValues = Map<String, dynamic>.from(currentValues);
            newValues[fieldName] = value;
            onChanged(newValues);
          },
        );
      
      case "text":
      case "string":
      default:
        return TextFormField(
          decoration: InputDecoration(
            labelText: label + (isRequired ? " *" : ""),
            border: const OutlineInputBorder(),
          ),
          initialValue: currentValues[fieldName]?.toString(),
          onChanged: (value) {
            final newValues = Map<String, dynamic>.from(currentValues);
            newValues[fieldName] = value;
            onChanged(newValues);
          },
        );
    }
  }

  /// Validate service requirements
  static List<String> validateRequirements(Map<String, dynamic> requirements, Map<String, dynamic> values) {
    List<String> errors = [];
    
    for (var field in requirements["fields"]) {
      final fieldName = field["name"];
      final isRequired = field["required"] ?? false;
      final value = values[fieldName];
      
      if (isRequired && (value == null || value.toString().isEmpty)) {
        errors.add("${field["label"]} is required");
      }
    }
    
    return errors;
  }
}
