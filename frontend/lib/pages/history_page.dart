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

  // Caches for name lookups
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

      setState(() {
        _me = me;
        _bookings = bookings;
        _serviceLogs = logs;
        _loading = false;
      });

      // Enrich booking names
      for (final b in bookings) {
        if (b["provider_id"] != null && !_providers.containsKey(b["provider_id"])) {
          final provider = await BookingService.getProvider(b["provider_id"]);
          if (provider != null) {
            setState(() => _providers[b["provider_id"]] = provider["name"] ?? "Unknown");
          }
        }
        if (b["service_id"] != null && !_services.containsKey(b["service_id"])) {
          final service = await ProviderService.getService(b["service_id"]);
          if (service != null) {
            setState(() => _services[b["service_id"]] = service["name"] ?? "Unknown");
          }
        }
      }
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
        final providerName = _providers[b["provider_id"]] ?? "Loading...";
        final serviceName = b["service_id"] != null
            ? _services[b["service_id"]] ?? "Loading..."
            : "N/A";

        return Card(
          child: ListTile(
            title: Text("Provider: $providerName"),
            subtitle: Text(
              "Service: $serviceName\n"
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
