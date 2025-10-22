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
  final Map<String, dynamic> _vehicles = {};
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
    // Fetch all user vehicles once
    try {
      final userVehicles = await VehicleService.listVehicles();
      
      // Create a map of vehicle_id -> vehicle object for quick lookup
      for (final vehicle in userVehicles) {
        final id = vehicle["id"]?.toString();
        if (id != null) {
          _vehicles[id] = vehicle; // Store the full vehicle object, not just the name
        }
      }
    } catch (e) {
      debugPrint("Error loading user vehicles: $e");
    }
  }

  Future<void> _loadProviderHistory(String providerId) async {
    try {
      debugPrint("Loading provider history for provider ID: $providerId");
      
      // Load provider-specific bookings and service logs
      final bookings = await BookingService.listBookingsForProvider(providerId);
      final logs = await BookingService.listServiceLogsForProvider(providerId);
      
      debugPrint("Loaded ${bookings.length} bookings and ${logs.length} service logs");
      
      // Debug: Log sample booking and log data
      if (bookings.isNotEmpty) {
        debugPrint("Sample booking data: ${bookings.first}");
      }
      if (logs.isNotEmpty) {
        debugPrint("Sample service log data: ${logs.first}");
      }
      
      // Load lookup data for customers and vehicles
      await _loadProviderLookupData(bookings, logs);
      
      setState(() {
        _bookings = bookings;
        _serviceLogs = logs;
      });
      
      debugPrint("Provider history loading completed successfully");
      debugPrint("Final state - Customers: ${_customers.length}, Vehicles: ${_vehicles.length}, Services: ${_services.length}");
    } catch (e) {
      debugPrint("Error loading provider history: $e");
      setState(() {
        _bookings = [];
        _serviceLogs = [];
      });
    }
  }

  Future<void> _loadProviderLookupData(List<dynamic> bookings, List<dynamic> logs) async {
    // Collect unique user IDs, vehicle IDs, and service IDs
    final userIds = <int>{};
    final vehicleIds = <String>{};
    final serviceIds = <String>{};
    
    debugPrint("Processing ${bookings.length} bookings and ${logs.length} logs for provider lookup data");
    
    for (final booking in bookings) {
      debugPrint("Booking data: user_id=${booking["user_id"]}, vehicle_id=${booking["vehicle_id"]}, service_id=${booking["service_id"]}");
      if (booking["user_id"] != null) userIds.add(booking["user_id"]);
      if (booking["vehicle_id"] != null) vehicleIds.add(booking["vehicle_id"]);
      if (booking["service_id"] != null) serviceIds.add(booking["service_id"]);
      if (booking["service_ids"] != null && booking["service_ids"] is List) {
        serviceIds.addAll((booking["service_ids"] as List).cast<String>());
      }
    }
    
    for (final log in logs) {
      debugPrint("Log data: user_id=${log["user_id"]}, vehicle_id=${log["vehicle_id"]}, service_id=${log["service_id"]}");
      if (log["user_id"] != null) userIds.add(log["user_id"]);
      if (log["vehicle_id"] != null) vehicleIds.add(log["vehicle_id"]);
      if (log["service_id"] != null) serviceIds.add(log["service_id"]);
    }
    
    debugPrint("Collected IDs - Users: $userIds, Vehicles: $vehicleIds, Services: $serviceIds");
    
    // Load all lookup data in parallel
    await Future.wait([
      _loadCustomerNames(userIds),
      _loadProviderVehicleInfo(vehicleIds),
      _loadProviderServiceInfo(serviceIds),
    ]);
  }

  Future<void> _loadCustomerNames(Set<int> userIds) async {
    try {
      if (userIds.isEmpty) return;
      
      debugPrint("🔍 Loading customer names for user IDs: $userIds");
      
      // Test lookup first (for debugging)
      for (final userId in userIds) {
        debugPrint("🧪 Testing lookup for user ID: $userId");
        final testResult = await AuthService.testLookupUser(userId);
        debugPrint("🧪 Test result: $testResult");
      }
      
      // Use the new lookup endpoint to get user info for specific IDs
      final users = await AuthService.lookupUsersByIds(userIds.toList());
      debugPrint("📥 Received users from lookup: $users");
      debugPrint("📥 Users type: ${users.runtimeType}, length: ${users.length}");
      
      if (users.isEmpty) {
        debugPrint("⚠️ No users returned from lookup API");
        // Fallback to generic names
        for (final userId in userIds) {
          _customers[userId.toString()] = "Customer (ID: $userId)";
        }
        return;
      }
      
      for (final user in users) {
        debugPrint("👤 Processing user: $user");
        final userId = user["id"];
        if (userId != null) {
          // Prefer name, then email, then phone as fallback
          String name = "Unknown Customer";
          if (user["name"] != null && user["name"].toString().trim().isNotEmpty) {
            name = user["name"].toString().trim();
          } else if (user["email"] != null && user["email"].toString().trim().isNotEmpty) {
            name = user["email"].toString().trim();
          } else if (user["phone"] != null && user["phone"].toString().trim().isNotEmpty) {
            name = user["phone"].toString().trim();
          }
          
          _customers[userId.toString()] = name;
          debugPrint("✅ Mapped user $userId to name: $name");
        } else {
          debugPrint("❌ User has no ID: $user");
        }
      }
      
      // For any remaining user IDs not found in the lookup, use a fallback
      for (final userId in userIds) {
        if (!_customers.containsKey(userId.toString())) {
          _customers[userId.toString()] = "Customer (ID: $userId)";
          debugPrint("⚠️ Fallback mapping for user $userId - user not found in database");
        }
      }
      
      debugPrint("📋 Final customer map: $_customers");
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error loading customer names: $e");
      debugPrint("❌ Stack trace: $stackTrace");
      // Fallback to generic names
      for (final userId in userIds) {
        _customers[userId.toString()] = "Customer (ID: $userId)";
      }
    }
  }

  Future<void> _loadProviderVehicleInfo(Set<String> vehicleIds) async {
    try {
      if (vehicleIds.isEmpty) return;
      
      debugPrint("🚗 Loading vehicle info for vehicle IDs: $vehicleIds");
      
      // For providers, we need to fetch vehicle details by ID since they don't own the vehicles
      for (final vehicleId in vehicleIds) {
        try {
          debugPrint("🔍 Fetching vehicle with ID: $vehicleId");
          final vehicle = await VehicleService.getByVehicleIdPublic(vehicleId);
          debugPrint("📥 Vehicle response: $vehicle");
          
          if (vehicle != null) {
            _vehicles[vehicleId] = vehicle; // Store the full vehicle object
            final plate = vehicle["plate"] ?? "No Plate";
            final make = vehicle["make"] ?? "Unknown Make";
            final model = vehicle["model"] ?? "Unknown Model";
            debugPrint("✅ Loaded vehicle $vehicleId: $plate $make $model");
          } else {
            debugPrint("⚠️ Vehicle $vehicleId not found - storing placeholder");
            // Store a placeholder to indicate vehicle not found
            _vehicles[vehicleId] = {"plate": "Unknown", "make": "", "model": "", "yom": null};
          }
        } catch (e, stackTrace) {
          debugPrint("❌ Error loading vehicle $vehicleId: $e");
          debugPrint("❌ Stack trace: $stackTrace");
          // Store a placeholder to indicate vehicle not found
          _vehicles[vehicleId] = {"plate": "Unknown", "make": "", "model": "", "yom": null};
        }
      }
      
      debugPrint("📋 Final vehicle map keys: ${_vehicles.keys.toList()}");
      debugPrint("📋 Final vehicle map values: ${_vehicles.values.map((v) => "${v["plate"]} ${v["make"]} ${v["model"]}").toList()}");
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error loading provider vehicle info: $e");
      debugPrint("❌ Stack trace: $stackTrace");
    }
  }

  Future<void> _loadProviderServiceInfo(Set<String> serviceIds) async {
    try {
      if (serviceIds.isEmpty) return;
      
      // Load provider's services to get service names
      final providers = await ProviderService.getProviders();
      
      for (final provider in providers) {
        final services = (provider["services"] as List?) ?? [];
        for (final service in services) {
          if (service is Map && service["service_id"] != null) {
            final serviceId = service["service_id"].toString();
            if (serviceIds.contains(serviceId)) {
              _services[serviceId] = service["service_name"] ?? "Unknown Service";
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading provider service info: $e");
    }
  }


  String _formatVehicleName(Map<String, dynamic> vehicle) {
    final plate = (vehicle["plate"] ?? "").toString().trim();
    final make = (vehicle["make"] ?? "").toString().trim();
    final model = (vehicle["model"] ?? "").toString().trim();
    final year = vehicle["yom"] != null ? vehicle["yom"].toString().trim() : "";

    // If we have no meaningful data, return a generic name
    if (plate.isEmpty && make.isEmpty && model.isEmpty && year.isEmpty) {
      return "Unknown Vehicle";
    }

    // Build the vehicle details
    final details = [make, model, year].where((s) => s.isNotEmpty).join(" ");
    
    // If we have details, format as "Plate (Make Model Year)" or "Details" if no plate
    if (details.isNotEmpty) {
      return plate.isNotEmpty ? "$plate ($details)" : details;
    }
    
    // If we only have a plate, return just the plate
    return plate.isNotEmpty ? plate : "Unknown Vehicle";
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

        final vehicleKey = b["vehicle_id"]?.toString() ?? "";
        final vehicle = _vehicles[vehicleKey];
        final vehicleInfo = vehicle != null ? _formatVehicleName(vehicle) : "Vehicle";
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Provider name
                Row(
                  children: [
                    const Icon(Icons.business, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        providerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 2: Vehicle
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vehicleInfo,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 3: Service details
                Row(
                  children: [
                    const Icon(Icons.build, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        serviceName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 4: Scheduled time
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Scheduled: ${b["scheduled_at"] ?? "N/A"}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Line 5: Status chip (horizontal button)
                Row(
                  children: [
                    Expanded(
                      child: _buildBookingStatusChip(
                        b["status"],
                        booking: b,
                        onTap: _userContext?.isProvider == true 
                          ? () => _showStatusChangeDialog(b)
                          : null,
                      ),
                    ),
                    if (_userContext?.isProvider == true) ...[
                      const SizedBox(width: 8),
                      _buildBookingActionButtons(b),
                    ],
                  ],
                ),
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
        
        final vehicleKey = l["vehicle_id"]?.toString() ?? "";
        final vehicle = _vehicles[vehicleKey];
        final vehicleInfo = vehicle != null ? _formatVehicleName(vehicle) : "Vehicle";
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Provider name
                Row(
                  children: [
                    const Icon(Icons.business, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l["provider_name"] ?? "N/A",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 2: Vehicle
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vehicleInfo,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 3: Service details
                Row(
                  children: [
                    const Icon(Icons.build, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l["service_name"] ?? "Service",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 4: Service details (cost, mileage, date)
                Row(
                  children: [
                    const Icon(Icons.info, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cost: ${l["cost"] != null ? "₦${l["cost"]}" : "N/A"} • Mileage: ${l["mileage_km"] != null ? "${l["mileage_km"]} km" : "N/A"} • Performed: $performedDate",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Line 5: Status chip (completed service)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Service Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
        
        // Get customer name with better fallback logic
        String customerName = "Unknown Customer";
        final userId = b["user_id"]?.toString();
        if (userId != null && _customers.containsKey(userId)) {
          customerName = _customers[userId]!;
        } else if (userId != null) {
          customerName = "Customer (ID: $userId)";
        }
        
        // Get vehicle info with better fallback logic
        String vehicleInfo = "Unknown Vehicle";
        final vehicleId = b["vehicle_id"]?.toString();
        if (vehicleId != null && _vehicles.containsKey(vehicleId)) {
          final vehicle = _vehicles[vehicleId];
          vehicleInfo = _formatVehicleName(vehicle);
        } else if (vehicleId != null) {
          vehicleInfo = "Vehicle (ID: $vehicleId)";
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Customer name
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 2: Vehicle
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vehicleInfo,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 3: Service details
                Row(
                  children: [
                    const Icon(Icons.build, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getServiceNames(b),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 4: Scheduled time
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Scheduled: ${b["scheduled_at"] ?? "N/A"}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Line 5: Status chip (horizontal button)
                Row(
                  children: [
                    Expanded(
                      child: _buildBookingStatusChip(
                        b["status"],
                        booking: b,
                        onTap: () => _showStatusChangeDialog(b),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildBookingActionButtons(b),
                  ],
                ),
              ],
            ),
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
        
        // Get customer name with better fallback logic
        String customerName = "Unknown Customer";
        final userId = l["user_id"]?.toString();
        if (userId != null && _customers.containsKey(userId)) {
          customerName = _customers[userId]!;
        } else if (userId != null) {
          customerName = "Customer (ID: $userId)";
        }
        
        // Get vehicle info with better fallback logic
        String vehicleInfo = "Unknown Vehicle";
        final vehicleId = l["vehicle_id"]?.toString();
        if (vehicleId != null && _vehicles.containsKey(vehicleId)) {
          final vehicle = _vehicles[vehicleId];
          vehicleInfo = _formatVehicleName(vehicle);
        } else if (vehicleId != null) {
          vehicleInfo = "Vehicle (ID: $vehicleId)";
        }
        
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Customer name
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 2: Vehicle
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vehicleInfo,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 3: Service details
                Row(
                  children: [
                    const Icon(Icons.build, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l["service_name"] ?? "Service",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Line 4: Service details (cost, mileage, date)
                Row(
                  children: [
                    const Icon(Icons.info, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cost: ${l["cost"] != null ? "₦${l["cost"]}" : "N/A"} • Mileage: ${l["mileage_km"] != null ? "${l["mileage_km"]} km" : "N/A"} • Performed: $performedDate",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Line 5: Status chip (completed service)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Service Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  Widget _buildBookingStatusChip(String? status, {Map<String, dynamic>? booking, VoidCallback? onTap}) {
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
    
    Widget chipWidget = Container(
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onTap != null) ...[
              Icon(Icons.touch_app, size: 16, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              status ?? "Unknown",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Tooltip(
        message: "Tap to change status",
        child: GestureDetector(
          onTap: onTap,
          child: chipWidget,
        ),
      );
    } else {
      return chipWidget;
    }
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

  Future<void> _handleStatusChange(String bookingId, String newStatus, Map<String, dynamic> booking) async {
    try {
      debugPrint('🔄 Changing booking $bookingId status to: $newStatus');
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Updating status...'),
            ],
          ),
        ),
      );
      
      final success = await BookingService.updateBooking(bookingId, {'status': newStatus});
      
      // Hide loading indicator
      Navigator.of(context).pop();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking status changed to ${newStatus.replaceAll('_', ' ')} successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Refresh the data
        await _loadHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change booking status'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if it's still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      debugPrint('❌ Error changing booking status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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

  void _showStatusChangeDialog(Map<String, dynamic> booking) {
    final currentStatus = booking["status"]?.toString().toLowerCase();
    final bookingId = booking["id"]?.toString();
    
    if (bookingId == null) return;
    
    // Define available status transitions
    List<Map<String, dynamic>> availableStatuses = [];
    
    switch (currentStatus) {
      case 'pending':
        availableStatuses = [
          {'status': 'accepted', 'label': 'Accept', 'icon': Icons.check, 'color': Colors.green},
          {'status': 'cancelled', 'label': 'Cancel', 'icon': Icons.cancel, 'color': Colors.red},
        ];
        break;
      case 'accepted':
        availableStatuses = [
          {'status': 'in_progress', 'label': 'Start Service', 'icon': Icons.play_arrow, 'color': Colors.blue},
          {'status': 'cancelled', 'label': 'Cancel', 'icon': Icons.cancel, 'color': Colors.red},
        ];
        break;
      case 'in_progress':
        availableStatuses = [
          {'status': 'completed', 'label': 'Complete', 'icon': Icons.check_circle, 'color': Colors.green},
        ];
        break;
      case 'completed':
      case 'cancelled':
        // No status changes allowed for completed or cancelled bookings
        _showBookingDetails(booking);
        return;
      default:
        availableStatuses = [
          {'status': 'accepted', 'label': 'Accept', 'icon': Icons.check, 'color': Colors.green},
          {'status': 'cancelled', 'label': 'Cancel', 'icon': Icons.cancel, 'color': Colors.red},
        ];
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Status - ${booking["status"]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((statusOption) {
            return ListTile(
              leading: Icon(
                statusOption['icon'],
                color: statusOption['color'],
              ),
              title: Text(statusOption['label']),
              onTap: () {
                Navigator.pop(context);
                _handleStatusChange(bookingId, statusOption['status'], booking);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBookingDetails(booking);
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
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
