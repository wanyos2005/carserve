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
    final data = await ProviderService.listProviders();
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
                final location = p["location"] ?? {};
                final address = location["address"] ?? "Unknown location";

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.blue),
                    title: Text(p["name"] ?? "Unnamed Provider"),
                    subtitle: Text(address),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderDetailsPage(
                            providerId: p["id"],
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


