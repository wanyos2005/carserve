// lib/pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  List<dynamic> _bookings = [];
  List<dynamic> _serviceLogs = [];
  Map<String, dynamic>? _me;

  // Lookup caches
  final Map<String, String> _providers = {};
  final Map<String, String> _services = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    final me = await AuthService.getMe();
    if (me != null) {
      final bookings = await BookingService.listBookingsForUser(me["id"]);
      final logs = await BookingService.listServiceLogsForUser(me["id"]);

      // ✅ Fetch all providers using ProviderService
      final providers = await ProviderService.getProviders();

      final Map<String, String> providerMap = {};
      final Map<String, String> serviceMap = {};

      for (final p in providers) {
        providerMap[p["id"]] = p["name"] ?? "Unknown";

        final services = p["services"] as List? ?? [];
        final providerServices = p["provider_services"] as List? ?? [];

        for (final s in services) {
          if (s is Map && s["id"] != null) {
            final matched = providerServices.firstWhere(
              (ps) => ps["service_id"] == s["id"],
              orElse: () => null,
            );
            // For now we only keep service name, but matched has price/duration
            serviceMap[s["id"]] = s["name"] ?? "Unknown";
          }
        }
      }

      setState(() {
        _me = me;
        _bookings = bookings;
        _serviceLogs = logs;
        _providers.addAll(providerMap);
        _services.addAll(serviceMap);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.book_online), text: "Bookings"),
                      Tab(icon: Icon(Icons.build), text: "Service Logs"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBookingsList(),
                        _buildLogsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingsList() {
    if (_bookings.isEmpty) {
      return const Center(child: Text("No bookings found."));
    }
    return ListView.builder(
      itemCount: _bookings.length,
      itemBuilder: (context, i) {
        final b = _bookings[i];

        final providerName = _providers[b["provider_id"]] ?? "Unknown";

        // Handle multi-service bookings
        String serviceName;
        if (b.containsKey("service_ids") && b["service_ids"] is List) {
          final ids = (b["service_ids"] as List).cast<String>();
          final names = ids.map((id) => _services[id] ?? "Unknown").toList();
          serviceName = names.isNotEmpty ? names.join(", ") : "Unknown";
        } else if (b["service_id"] != null) {
          serviceName = _services[b["service_id"]] ?? "Unknown";
        } else {
          serviceName = "N/A";
        }

        return Card(
          child: ListTile(
            title: Text("Provider: $providerName"),
            subtitle: Text(
              "Services: $serviceName\n"
              "Status: ${b["status"]}\n"
              "Scheduled: ${b["scheduled_at"] ?? "N/A"}",
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogsList() {
    if (_serviceLogs.isEmpty) {
      return const Center(child: Text("No service logs found."));
    }
    return ListView.builder(
      itemCount: _serviceLogs.length,
      itemBuilder: (context, i) {
        final l = _serviceLogs[i];
        return Card(
          child: ListTile(
            title: Text(l["service_name"] ?? "Service"),
            subtitle: Text(
              "Provider: ${l["provider_name"] ?? "N/A"}\n"
              "Performed: ${l["performed_at"] ?? "N/A"}",
            ),
          ),
        );
      },
    );
  }
}
