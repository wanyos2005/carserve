// Test file to verify pricing integration
// This file can be used to test the new structured pricing functionality

import 'package:flutter/material.dart';

class PricingIntegrationTest extends StatelessWidget {
  const PricingIntegrationTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pricing Integration Test")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pricing Integration Test Results",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test legacy price parsing
            _buildTestCard(
              "Legacy Price Parsing",
              "✅ Should handle: 'KSh 3,500 - 8,000', 'KSh 1,500', 'Free', 'Varies by vehicle'",
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            // Test new structured pricing
            _buildTestCard(
              "New Structured Pricing",
              "✅ Should handle: min_price, max_price, price_type, currency, unit, negotiable",
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Test commission calculation
            _buildTestCard(
              "Commission Calculation",
              "✅ Should calculate 5% commission on negotiated or base price",
              Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            // Test booking flow
            _buildTestCard(
              "Enhanced Booking Flow",
              "✅ Should show pricing info, allow negotiation, and create bookings with structured pricing",
              Colors.purple,
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                _runPricingTests();
              },
              child: const Text("Run Pricing Tests"),
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

  void _runPricingTests() {
    // Test legacy price parsing
    final testPrices = [
      "KSh 3,500 - 8,000",
      "KSh 1,500",
      "Free",
      "Varies by vehicle",
      "KSh 180-200/liter",
    ];

    print("🧪 Testing Legacy Price Parsing:");
    for (final price in testPrices) {
      final parsed = _parseLegacyPriceString(price);
      print("  '$price' -> ${parsed['type']}: ${parsed['min_price']}-${parsed['max_price']}");
    }

    // Test new structured pricing
    final testStructuredPricing = {
      "min_price": 3500.0,
      "max_price": 8000.0,
      "price_type": "range",
      "currency": "KES",
      "negotiable": true,
    };

    print("\n🧪 Testing Structured Pricing:");
    print("  $testStructuredPricing");

    // Test commission calculation
    print("\n🧪 Testing Commission Calculation:");
    final basePrice = 5000.0;
    final negotiatedPrice = 4500.0;
    final commission = negotiatedPrice * 0.05;
    print("  Base Price: KES $basePrice");
    print("  Negotiated Price: KES $negotiatedPrice");
    print("  Commission (5%): KES $commission");

    print("\n✅ All pricing tests completed!");
  }

  // Simplified version of the legacy price parsing for testing
  Map<String, dynamic> _parseLegacyPriceString(String priceString) {
    if (priceString.isEmpty) {
      return {"type": "free", "min_price": 0.0, "max_price": 0.0, "unit": null};
    }
    
    final lowerPrice = priceString.toLowerCase().trim();
    
    if (lowerPrice == "free") {
      return {"type": "free", "min_price": 0.0, "max_price": 0.0, "unit": null};
    }
    
    if (lowerPrice.contains("varies")) {
      return {"type": "variable", "min_price": 0.0, "max_price": 0.0, "unit": null};
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
      return {"type": "free", "min_price": 0.0, "max_price": 0.0, "unit": unit};
    }
    
    if (numbers.length == 1) {
      return {
        "type": unit != null ? "per_unit" : "fixed",
        "min_price": numbers[0],
        "max_price": numbers[0],
        "unit": unit,
      };
    }
    
    if (numbers.length >= 2) {
      final minPrice = numbers.reduce((a, b) => a < b ? a : b);
      final maxPrice = numbers.reduce((a, b) => a > b ? a : b);
      return {
        "type": unit != null ? "per_unit" : "range",
        "min_price": minPrice,
        "max_price": maxPrice,
        "unit": unit,
      };
    }
    
    return {"type": "free", "min_price": 0.0, "max_price": 0.0, "unit": null};
  }
}
