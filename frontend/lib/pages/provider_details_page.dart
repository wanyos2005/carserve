// lib/pages/provider_details_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/provider_service.dart';
import 'booking_page.dart';

class ProviderDetailsPage extends StatefulWidget {
  final String providerId; // UUID string
  const ProviderDetailsPage({super.key, required this.providerId});

  @override
  State<ProviderDetailsPage> createState() => _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends State<ProviderDetailsPage> {
  Map<String, dynamic>? _provider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProvider();
  }

  Future<void> _fetchProvider() async {
    final data = await ProviderService.getProvider(widget.providerId);
    setState(() {
      _provider = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final provider = _provider!;
    final services = provider["services"] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(provider["name"] ?? "Provider")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider["description"] ?? "",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            if (provider["location"] != null)
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  Text(provider["location"]["address"] ?? "Unknown location"),
                ],
              ),
            const SizedBox(height: 5),
            if (provider["contact_info"] != null)
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green),
                  Text(provider["contact_info"]["phone"] ?? "No phone"),
                ],
              ),
            const Divider(height: 30),
            const Text("Services",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final s = services[index];
                  return Card(
                    child: ListTile(
                      title: Text(s["name"] ?? ""),
                      subtitle: Text(s["description"] ?? ""),
                      trailing: Text(s["price_range"] ?? ""),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingPage(
                              provider: provider,
                              service: s,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
