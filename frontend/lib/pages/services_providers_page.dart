// lib/pages/services_providers_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/provider_service.dart';
import 'provider_details_page.dart';

class ServicesProvidersPage extends StatefulWidget {
  const ServicesProvidersPage({super.key});

  @override
  State<ServicesProvidersPage> createState() => _ServicesProvidersPageState();
}

class _ServicesProvidersPageState extends State<ServicesProvidersPage> {
  List<dynamic> _providers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    final data = await ProviderService.getProviders();
    setState(() {
      _providers = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find a service provider...")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _providers.length,
              itemBuilder: (context, index) {
                final p = _providers[index];
                final services = p["services"] as List? ?? [];
                final serviceCount = services.length;
                final serviceNames = services.take(2).map((s) => s["service_name"]).join(", ");
                
                // Get location information
                final location = p["location"] as Map<String, dynamic>? ?? {};
                final address = location["address"] ?? "Location not specified";
                final rating = p["rating"] ?? 0.0;
                final isRegistered = p["is_registered"] ?? false;
                
                // Create subtitle with location and services
                String subtitle = address;
                if (serviceCount > 0) {
                  subtitle += " • $serviceCount service${serviceCount > 1 ? 's' : ''}";
                }

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRegistered ? Colors.green.shade100 : Colors.orange.shade100,
                      child: Icon(
                        isRegistered ? Icons.verified : Icons.store,
                        color: isRegistered ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                    title: Text(p["provider_name"] ?? "Unnamed Provider"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subtitle),
                        if (rating > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: serviceCount > 0 
                        ? Chip(
                            label: Text("$serviceCount"),
                            backgroundColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderDetailsPage(
                            providerId: p["provider_id"],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}


