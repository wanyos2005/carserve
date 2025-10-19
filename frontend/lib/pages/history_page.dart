// lib/pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/user_context_service.dart';
import 'package:car_platform/services/vehicle_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  List<dynamic> _bookings = [];
  List<dynamic> _serviceLogs = [];
  UserContext? _userContext;

  // Lookup caches
  final Map<String, String> _providers = {};
  final Map<String, String> _services = {};
  final Map<String, String> _vehicles = {};
  final Map<String, String> _customers = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  
  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    try {
      final me = await AuthService.getMe();
      if (me == null) {
        setState(() => _loading = false);
        return;
      }

      final userContext = UserContext.fromUserData(me);
      setState(() => _userContext = userContext);

      // Load data based on user type
      if (userContext.isCarOwner) {
        await _loadCarOwnerHistory(me["id"]);
      } else if (userContext.isProvider) {
        await _loadProviderHistory(userContext.providerId!);
      } else if (userContext.isAdmin) {
        await _loadAdminHistory();
      }

      setState(() => _loading = false);
    } catch (e, st) {
      debugPrint("❌ Error loading history: $e\n$st");
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCarOwnerHistory(int userId) async {
    final bookings = await BookingService.listBookingsForUser(userId);
    final logs = await BookingService.listServiceLogsForUser(userId);
    final providers = await ProviderService.getProviders();

    final Map<String, String> providerMap = {};
    final Map<String, String> serviceMap = {};

    for (final p in providers) {
      final providerId = p["provider_id"];
      final providerName = p["provider_name"] ?? "Unknown";
      providerMap[providerId] = providerName;

      final services = (p["services"] as List?) ?? [];
      for (final s in services) {
        if (s is Map && s["service_id"] != null) {
          serviceMap[s["service_id"]] = s["service_name"] ?? "Unknown";
        }
      }
    }

    // Load vehicle info for car owner's vehicles
    await _loadCarOwnerVehicleInfo(bookings, logs);

    setState(() {
      _bookings = bookings;
      _serviceLogs = logs;
      _providers.addAll(providerMap);
      _services.addAll(serviceMap);
    });
  }

  Future<void> _loadCarOwnerVehicleInfo(List<dynamic> bookings, List<dynamic> logs) async {
    // Collect unique vehicle IDs from bookings and logs
    final vehicleIds = <String>{};
    
    for (final booking in bookings) {
      if (booking["vehicle_id"] != null) vehicleIds.add(booking["vehicle_id"]);
    }
    
    for (final log in logs) {
      if (log["vehicle_id"] != null) vehicleIds.add(log["vehicle_id"]);
    }
    
    // Load vehicle info using VehicleService
    await _loadVehicleInfo(vehicleIds);
  }

  Future<void> _loadProviderHistory(String providerId) async {
    try {
      // Load provider-specific bookings and service logs
      final bookings = await BookingService.listBookingsForProvider(providerId);
      final logs = await BookingService.listServiceLogsForProvider(providerId);
      
      // Load lookup data for customers and vehicles
      await _loadProviderLookupData(bookings, logs);
      
      setState(() {
        _bookings = bookings;
        _serviceLogs = logs;
      });
    } catch (e) {
      debugPrint("Error loading provider history: $e");
      setState(() {
        _bookings = [];
        _serviceLogs = [];
      });
    }
  }

  Future<void> _loadProviderLookupData(List<dynamic> bookings, List<dynamic> logs) async {
    // Collect unique user IDs and vehicle IDs
    final userIds = <int>{};
    final vehicleIds = <String>{};
    
    for (final booking in bookings) {
      if (booking["user_id"] != null) userIds.add(booking["user_id"]);
      if (booking["vehicle_id"] != null) vehicleIds.add(booking["vehicle_id"]);
    }
    
    for (final log in logs) {
      if (log["user_id"] != null) userIds.add(log["user_id"]);
      if (log["vehicle_id"] != null) vehicleIds.add(log["vehicle_id"]);
    }
    
    // Load customer names using AuthService
    await _loadCustomerNames(userIds);
    
    // Load vehicle info using VehicleService
    await _loadVehicleInfo(vehicleIds);
  }

  Future<void> _loadCustomerNames(Set<int> userIds) async {
    try {
      if (userIds.isEmpty) return;
      
      // Use the new lookup endpoint to get user info for specific IDs
      final users = await AuthService.lookupUsersByIds(userIds.toList());
      
      for (final user in users) {
        final userId = user["id"];
        if (userId != null) {
          final name = user["name"] ?? user["email"] ?? "Unknown Customer";
          _customers[userId.toString()] = name;
        }
      }
      
      // For any remaining user IDs not found in the lookup, use a fallback
      for (final userId in userIds) {
        if (!_customers.containsKey(userId.toString())) {
          _customers[userId.toString()] = "Customer #$userId";
        }
      }
      
    } catch (e) {
      debugPrint("Error loading customer names: $e");
      // Fallback to generic names
      for (final userId in userIds) {
        _customers[userId.toString()] = "Customer #$userId";
      }
    }
  }

  Future<void> _loadVehicleInfo(Set<String> vehicleIds) async {
    try {
      // Load vehicle details for each unique vehicle ID
      for (final vehicleId in vehicleIds) {
        try {
          final vehicle = await VehicleService.getByVehicleId(vehicleId);
          if (vehicle != null) {
            final plate = vehicle["plate"] ?? "Unknown Plate";
            final make = vehicle["make"] ?? "";
            final model = vehicle["model"] ?? "";
            final year = vehicle["yom"]?.toString() ?? "";
            
            // Create a descriptive vehicle name
            String vehicleName = plate;
            if (make.isNotEmpty || model.isNotEmpty || year.isNotEmpty) {
              final details = [make, model, year].where((s) => s?.isNotEmpty == true).join(" ");
              vehicleName = "$plate ($details)";
            }
            
            _vehicles[vehicleId] = vehicleName;
          } else {
            _vehicles[vehicleId] = "Vehicle #$vehicleId";
          }
        } catch (e) {
          debugPrint("Error loading vehicle $vehicleId: $e");
          _vehicles[vehicleId] = "Vehicle #$vehicleId";
        }
      }
    } catch (e) {
      debugPrint("Error loading vehicle info: $e");
      // Fallback to generic names
      for (final vehicleId in vehicleIds) {
        _vehicles[vehicleId] = "Vehicle #$vehicleId";
      }
    }
  }

  Future<void> _loadAdminHistory() async {
    // For admins, we might want to show system-wide statistics or all data
    // For now, we'll show a placeholder message
    setState(() {
      _bookings = [];
      _serviceLogs = [];
    });
    
    debugPrint("Admin history loading not yet implemented");
  }


  @override
  Widget build(BuildContext context) {
    final userType = _userContext?.userType;
    final title = _getPageTitle(userType);
    final tabs = _getTabs(userType);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: tabs.length,
              child: Column(
                children: [
                  TabBar(
                    tabs: tabs,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: _getTabViews(userType),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getPageTitle(UserType? userType) {
    switch (userType) {
      case UserType.provider:
        return "WorkFlows";
      case UserType.admin:
        return "Admin Dashboard";
      case UserType.carOwner:
      default:
        return "Past Interactions";
    }
  }

  List<Tab> _getTabs(UserType? userType) {
    switch (userType) {
      case UserType.provider:
        return [
          const Tab(icon: Icon(Icons.book_online), text: "Bookings"),
          const Tab(icon: Icon(Icons.build), text: "Service Logs"),
          const Tab(icon: Icon(Icons.analytics), text: "Analytics"),
        ];
      case UserType.admin:
        return [
          const Tab(icon: Icon(Icons.people), text: "Users"),
          const Tab(icon: Icon(Icons.business), text: "Providers"),
          const Tab(icon: Icon(Icons.analytics), text: "System Stats"),
        ];
      case UserType.carOwner:
      default:
        return [
          const Tab(icon: Icon(Icons.book_online), text: "Bookings"),
          const Tab(icon: Icon(Icons.build), text: "Service Logs"),
        ];
    }
  }

  List<Widget> _getTabViews(UserType? userType) {
    switch (userType) {
      case UserType.provider:
        return [
          _buildProviderBookingsList(),
          _buildProviderLogsList(),
          _buildProviderAnalytics(),
        ];
      case UserType.admin:
        return [
          _buildAdminUsersList(),
          _buildAdminProvidersList(),
          _buildAdminSystemStats(),
        ];
      case UserType.carOwner:
      default:
        return [
          _buildBookingsList(),
          _buildLogsList(),
        ];
    }
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

        final vehicleInfo = _vehicles[b["vehicle_id"]] ?? "Vehicle #${b["vehicle_id"]}";
        
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.book_online)),
            title: Text("Provider: $providerName"),
            subtitle: Text(
              "Vehicle: $vehicleInfo\n"
              "Services: $serviceName\n"
              "Status: ${b["status"]}\n"
              "Scheduled: ${b["scheduled_at"] ?? "N/A"}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBookingStatusChip(b["status"]),
                if (_userContext?.isProvider == true) ...[
                  const SizedBox(width: 8),
                  _buildBookingActionButtons(b),
                ],
              ],
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
        
        // Format the performed_at date
        String performedDate = "N/A";
        if (l["performed_at"] != null) {
          try {
            final date = DateTime.parse(l["performed_at"]);
            performedDate = "${date.day}/${date.month}/${date.year}";
          } catch (e) {
            performedDate = l["performed_at"].toString();
          }
        }
        
        final vehicleInfo = _vehicles[l["vehicle_id"]] ?? "Vehicle #${l["vehicle_id"]}";
        
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.build)),
            title: Text(l["service_name"] ?? "Service"),
            subtitle: Text(
              "Provider: ${l["provider_name"] ?? "N/A"}\n"
              "Vehicle: $vehicleInfo\n"
              "Performed: $performedDate\n"
              "Cost: ${l["cost"] != null ? "₦${l["cost"]}" : "N/A"}\n"
              "Mileage: ${l["mileage_km"] != null ? "${l["mileage_km"]} km" : "N/A"}",
            ),
          ),
        );
      },
    );
  }

  // ==================== PROVIDER-SPECIFIC VIEWS ====================

  Widget _buildProviderBookingsList() {
    if (_bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_online, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No bookings found for your provider."),
            SizedBox(height: 8),
            Text("Bookings will appear here when customers book your services.", 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _bookings.length,
      itemBuilder: (context, i) {
        final b = _bookings[i];
        final customerName = _customers[b["user_id"]] ?? "Customer";
        final vehicleInfo = _vehicles[b["vehicle_id"]] ?? "Vehicle";
        
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text("Customer: $customerName"),
            subtitle: Text(
              "Vehicle: $vehicleInfo\n"
              "Services: ${_getServiceNames(b)}\n"
              "Status: ${b["status"]}\n"
              "Scheduled: ${b["scheduled_at"] ?? "N/A"}",
            ),
            trailing: _buildBookingStatusChip(b["status"]),
          ),
        );
      },
    );
  }

  Widget _buildProviderLogsList() {
    if (_serviceLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No service logs found."),
            SizedBox(height: 8),
            Text("Service logs will appear here when you complete services.", 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _serviceLogs.length,
      itemBuilder: (context, i) {
        final l = _serviceLogs[i];
        final customerName = _customers[l["user_id"]] ?? "Customer";
        final vehicleInfo = _vehicles[l["vehicle_id"]] ?? "Vehicle";
        
        String performedDate = "N/A";
        if (l["performed_at"] != null) {
          try {
            final date = DateTime.parse(l["performed_at"]);
            performedDate = "${date.day}/${date.month}/${date.year}";
          } catch (e) {
            performedDate = l["performed_at"].toString();
          }
        }
        
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.build)),
            title: Text(l["service_name"] ?? "Service"),
            subtitle: Text(
              "Customer: $customerName\n"
              "Vehicle: $vehicleInfo\n"
              "Performed: $performedDate\n"
              "Cost: ${l["cost"] != null ? "₦${l["cost"]}" : "N/A"}\n"
              "Mileage: ${l["mileage_km"] != null ? "${l["mileage_km"]} km" : "N/A"}",
            ),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }

  Widget _buildProviderAnalytics() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("Analytics Dashboard"),
          SizedBox(height: 8),
          Text("Provider analytics and insights will be displayed here.", 
               style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ==================== ADMIN-SPECIFIC VIEWS ====================

  Widget _buildAdminUsersList() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("User Management"),
          SizedBox(height: 8),
          Text("User management features will be displayed here.", 
               style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAdminProvidersList() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("Provider Management"),
          SizedBox(height: 8),
          Text("Provider management features will be displayed here.", 
               style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAdminSystemStats() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("System Statistics"),
          SizedBox(height: 8),
          Text("System-wide statistics and analytics will be displayed here.", 
               style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  String _getServiceNames(Map<String, dynamic> booking) {
    if (booking.containsKey("service_ids") && booking["service_ids"] is List) {
      final ids = (booking["service_ids"] as List).cast<String>();
      final names = ids.map((id) => _services[id] ?? "Unknown").toList();
      return names.isNotEmpty ? names.join(", ") : "Unknown";
    } else if (booking["service_id"] != null) {
      return _services[booking["service_id"]] ?? "Unknown";
    } else {
      return "N/A";
    }
  }

  Widget _buildBookingStatusChip(String? status) {
    Color color;
    switch (status?.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'in_progress':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    
    return Chip(
      label: Text(status ?? "Unknown"),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBookingActionButtons(Map<String, dynamic> booking) {
    final status = booking["status"]?.toString().toLowerCase();
    final bookingId = booking["id"]?.toString();
    
    if (bookingId == null) return const SizedBox.shrink();
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handleBookingAction(action, bookingId, booking),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        switch (status) {
          case 'pending':
            items.addAll([
              const PopupMenuItem(
                value: 'accept',
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Accept'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cancel'),
                  ],
                ),
              ),
            ]);
            break;
          case 'accepted':
            items.addAll([
              const PopupMenuItem(
                value: 'start',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Start Service'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cancel'),
                  ],
                ),
              ),
            ]);
            break;
          case 'in_progress':
            items.addAll([
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Complete'),
                  ],
                ),
              ),
            ]);
            break;
          case 'completed':
            items.add(const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ));
            break;
          case 'cancelled':
            items.add(const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ));
            break;
        }
        
        return items;
      },
    );
  }//end of _buildBookingActionButtons

  Future<void> _handleBookingAction(String action, String bookingId, Map<String, dynamic> booking) async {
    try {
      bool success = false;
      String newStatus = '';
      
      switch (action) {
        case 'accept':
          newStatus = 'accepted';
          success = await BookingService.updateBooking(bookingId, {'status': newStatus});
          break;
        case 'cancel':
          newStatus = 'cancelled';
          success = await BookingService.updateBooking(bookingId, {'status': newStatus});
          break;
        case 'start':
          newStatus = 'in_progress';
          success = await BookingService.updateBooking(bookingId, {'status': newStatus});
          break;
        case 'complete':
          newStatus = 'completed';
          success = await BookingService.updateBooking(bookingId, {'status': newStatus});
          break;
        case 'view':
          _showBookingDetails(booking);
          return;
      }
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking $action successfully!')),
        );
        // Refresh the data
        await _loadHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $action booking')),
        );
      }
    } catch (e) {
      debugPrint('Error handling booking action: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${booking["id"]}'),
            Text('Status: ${booking["status"]}'),
            Text('Vehicle: ${_vehicles[booking["vehicle_id"]] ?? "Unknown"}'),
            Text('Service: ${_services[booking["service_id"]] ?? "Unknown"}'),
            Text('Scheduled: ${booking["scheduled_at"] ?? "Not scheduled"}'),
            if (booking["location"] != null)
              Text('Location: ${booking["location"]}'),
            if (booking["meta"] != null)
              Text('Notes: ${booking["meta"]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
