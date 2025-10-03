//provider_details_page
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
  final provider = await ProviderService.getProviderDetails(widget.providerId);
  final services = await ProviderService.getProviderServices(widget.providerId);

  final providerServices = (provider?["provider_services"] as List?) ?? [];

  final serviceWithPricing = services.map((s) {
    final service = Map<String, dynamic>.from(s as Map); // 🔹 force correct typing

    final match = providerServices.firstWhere(
      (ps) => ps["service_id"] == service["id"],
      orElse: () => null,
    );

    if (match != null) {
      final matchMap = Map<String, dynamic>.from(match as Map); // 🔹 cast too
      return {
        ...service,
        "price": matchMap["price"],
        "duration": matchMap["duration"],
        "booking_required": matchMap["booking_required"],
        "extra_data": matchMap["extra_data"],
      };
    }

    return service;
  }).toList();

    setState(() {
      _provider = {...?provider, "services": serviceWithPricing};
      _loading = false;
    });
  }



  Widget _buildInfoRow(IconData icon, String label, String? value,
      {Color color = Colors.black}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text("$label: $value")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final provider = _provider!;
    final services = provider["services"] ?? [];
    final location = provider["location"] ?? {};
    final contact = provider["contact_info"] ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(provider["name"] ?? "Provider")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider["description"] != null &&
                provider["description"].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  provider["description"],
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            // 🔹 Location
            if (location.isNotEmpty) ...[
              const Text("Location",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.location_on, "Address", location["address"],
                  color: Colors.red),
              _buildInfoRow(Icons.map, "Latitude", location["lat"]?.toString()),
              _buildInfoRow(Icons.map, "Longitude", location["lng"]?.toString()),
              const Divider(height: 30),
            ],

            // 🔹 Contact Info
            if (contact.isNotEmpty) ...[
              const Text("Contact Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.phone, "Phone", contact["phone"],
                  color: Colors.green),
              _buildInfoRow(Icons.email, "Email", contact["email"],
                  color: Colors.blue),
              _buildInfoRow(Icons.language, "Website", contact["website"],
                  color: Colors.purple),
              const Divider(height: 30),
            ],

            // 🔹 Services
            const Text("Services",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (services.isEmpty)
              const Text("No services listed",
                  style: TextStyle(color: Colors.grey)),
            if (services.isNotEmpty)
              ListView.builder(
                itemCount: services.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final s = services[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        s["display_name"] ?? s["service"]?["name"] ?? "Unnamed Service"
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (s["service"]?["description"] != null)
                            Text(s["service"]["description"]),
                          if (s["price"] != null)
                            Text("Price: ${s["price"]}",
                                style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
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
          ],
        ),
      ),
    );
  }
}
