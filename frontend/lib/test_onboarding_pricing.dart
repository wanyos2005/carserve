// Test file to verify onboarding pricing integration
// This file can be used to test the new structured pricing functionality in onboarding

import 'package:flutter/material.dart';

class OnboardingPricingTest extends StatelessWidget {
  const OnboardingPricingTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Onboarding Pricing Test")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Onboarding Pricing Integration Test",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test structured pricing
            _buildTestCard(
              "Structured Pricing Support",
              "✅ Should handle: min_price, max_price, price_type, currency, unit, negotiable",
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Test legacy pricing
            _buildTestCard(
              "Legacy Price String Support",
              "✅ Should parse: 'KSh 3,500 - 8,000', 'KSh 1,500', 'Free', 'Contact for pricing'",
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            // Test service attachment
            _buildTestCard(
              "Service Attachment",
              "✅ Should create services with both legacy and structured pricing fields",
              Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            // Test commission calculation
            _buildTestCard(
              "Commission Ready",
              "✅ Should support commission calculation on structured pricing",
              Colors.purple,
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                _runOnboardingPricingTests();
              },
              child: const Text("Run Onboarding Pricing Tests"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(String title, String description, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _runOnboardingPricingTests() {
    print("🧪 Testing Onboarding Pricing Integration:");
    
    // Test structured pricing parsing
    final structuredValues = {
      'min_price': 3500.0,
      'max_price': 8000.0,
      'price_type': 'range',
      'unit': null,
      'negotiable': true,
    };
    
    print("\n📊 Structured Pricing Test:");
    print("  Input: $structuredValues");
    final structuredResult = _parseStructuredPricing(structuredValues);
    print("  Output: $structuredResult");
    
    // Test legacy pricing parsing
    final legacyPrices = [
      "KSh 3,500 - 8,000",
      "KSh 1,500",
      "Free",
      "Contact for pricing",
      "KSh 180-200/liter",
    ];
    
    print("\n📊 Legacy Pricing Test:");
    for (final price in legacyPrices) {
      final parsed = _parseLegacyPriceString(price);
      print("  '$price' -> ${parsed['price_type']}: ${parsed['min_price']}-${parsed['max_price']}");
    }
    
    // Test service attachment payload
    print("\n📊 Service Attachment Payload Test:");
    final servicePayload = _createServicePayload(structuredValues, "Oil Change Service");
    print("  Service Payload: $servicePayload");
    
    print("\n✅ All onboarding pricing tests completed!");
  }

  // Simplified version of the structured pricing parsing for testing
  Map<String, dynamic> _parseStructuredPricing(Map<String, dynamic> values) {
    final minPrice = values['min_price']?.toDouble();
    final maxPrice = values['max_price']?.toDouble();
    final priceType = values['price_type'] ?? 'range';
    final unit = values['unit'];
    final negotiable = values['negotiable'] ?? true;
    
    // Generate display price based on structured data
    String displayPrice;
    if (priceType == 'fixed' && minPrice != null) {
      displayPrice = 'KES ${minPrice.toStringAsFixed(0)}';
    } else if (priceType == 'range' && minPrice != null && maxPrice != null) {
      displayPrice = 'KES ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)}';
    } else if (priceType == 'per_unit' && minPrice != null && unit != null) {
      final unitText = unit == 'per_liter' ? '/liter' : unit == 'per_hour' ? '/hour' : '/unit';
      displayPrice = 'KES ${minPrice.toStringAsFixed(0)}$unitText';
    } else if (priceType == 'free') {
      displayPrice = 'Free';
    } else if (priceType == 'variable') {
      displayPrice = 'Contact for pricing';
    } else {
      displayPrice = 'Contact for pricing';
    }
    
    return {
      'display_price': displayPrice,
      'min_price': minPrice,
      'max_price': maxPrice,
      'price_type': priceType,
      'currency': 'KES',
      'unit': unit,
      'negotiable': negotiable,
    };
  }

  // Simplified version of the legacy price parsing for testing
  Map<String, dynamic> _parseLegacyPriceString(String priceString) {
    if (priceString.isEmpty || priceString == 'Contact for pricing') {
      return {
        'display_price': 'Contact for pricing',
        'min_price': null,
        'max_price': null,
        'price_type': 'variable',
        'currency': 'KES',
        'unit': null,
        'negotiable': true,
      };
    }
    
    final lowerPrice = priceString.toLowerCase().trim();
    
    if (lowerPrice == 'free') {
      return {
        'display_price': 'Free',
        'min_price': 0.0,
        'max_price': 0.0,
        'price_type': 'free',
        'currency': 'KES',
        'unit': null,
        'negotiable': false,
      };
    }
    
    if (lowerPrice.contains('varies') || lowerPrice.contains('contact')) {
      return {
        'display_price': 'Contact for pricing',
        'min_price': null,
        'max_price': null,
        'price_type': 'variable',
        'currency': 'KES',
        'unit': null,
        'negotiable': true,
      };
    }
    
    final regex = RegExp(r'[\d,]+');
    final matches = regex.allMatches(priceString);
    final numbers = matches.map((m) => double.tryParse(m.group(0)?.replaceAll(',', '') ?? '0') ?? 0.0).toList();
    
    String? unit;
    if (lowerPrice.contains('/liter')) {
      unit = 'per_liter';
    } else if (lowerPrice.contains('/hour')) {
      unit = 'per_hour';
    }
    
    if (numbers.isEmpty) {
      return {
        'display_price': 'Contact for pricing',
        'min_price': null,
        'max_price': null,
        'price_type': 'variable',
        'currency': 'KES',
        'unit': unit,
        'negotiable': true,
      };
    }
    
    if (numbers.length == 1) {
      return {
        'display_price': priceString,
        'min_price': numbers[0],
        'max_price': numbers[0],
        'price_type': unit != null ? 'per_unit' : 'fixed',
        'currency': 'KES',
        'unit': unit,
        'negotiable': true,
      };
    }
    
    if (numbers.length >= 2) {
      final minPrice = numbers.reduce((a, b) => a < b ? a : b);
      final maxPrice = numbers.reduce((a, b) => a > b ? a : b);
      return {
        'display_price': priceString,
        'min_price': minPrice,
        'max_price': maxPrice,
        'price_type': unit != null ? 'per_unit' : 'range',
        'currency': 'KES',
        'unit': unit,
        'negotiable': true,
      };
    }
    
    return {
      'display_price': 'Contact for pricing',
      'min_price': null,
      'max_price': null,
      'price_type': 'variable',
      'currency': 'KES',
      'unit': null,
      'negotiable': true,
    };
  }

  // Test service payload creation
  Map<String, dynamic> _createServicePayload(Map<String, dynamic> values, String serviceName) {
    final pricingInfo = _parseStructuredPricing(values);
    
    return {
      'service_id': 'test-service-id',
      'display_name': serviceName,
      
      // Legacy price field (for backward compatibility)
      'price': pricingInfo['display_price'],
      
      // New structured pricing fields
      'min_price': pricingInfo['min_price'],
      'max_price': pricingInfo['max_price'],
      'price_type': pricingInfo['price_type'],
      'currency': pricingInfo['currency'],
      'unit': pricingInfo['unit'],
      'negotiable': pricingInfo['negotiable'],
      
      'duration': '30-45 mins',
      'booking_required': true,
      'extra_data': {
        'service_category': 'Maintenance',
        'requirements_met': true,
      },
    };
  }
}
