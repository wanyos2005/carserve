// lib/pages/service_provider_management_page.dart

import 'package:flutter/material.dart';
import 'package:car_platform/services/service_provider_service.dart';

class ServiceProviderManagementPage extends StatefulWidget {
  const ServiceProviderManagementPage({super.key});

  @override
  State<ServiceProviderManagementPage> createState() =>
      _ServiceProviderManagementPageState();
}

class _ServiceProviderManagementPageState
    extends State<ServiceProviderManagementPage> {
  late Future<List<dynamic>> _providerCategoriesFuture;

  @override
  void initState() {
    super.initState();
    _reloadCategories();
  }

  void _reloadCategories() {
    setState(() {
      _providerCategoriesFuture =
          ServiceProviderService.getProviderCategories();
    });
  }

  Future<List<dynamic>> _fetchProviders(int categoryId) {
    return ServiceProviderService.getProviders(categoryId: categoryId);
  }

  Future<List<dynamic>> _fetchServiceCategories() {
    return ServiceProviderService.getServiceCategories();
  }

  Future<Map<String, dynamic>?> _fetchProviderDetails(String providerId) {
    return ServiceProviderService.getProviderDetails(providerId);
  }

  // -------------------------
  // Dialog Helpers
  // -------------------------
  Future<void> _showAddProviderCategoryDialog() async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Provider Category"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Category Name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ServiceProviderService.createProviderCategory({
                  "name": nameController.text,
                });
                _reloadCategories();
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddServiceCategoryDialog() async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Service Category"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Service Category Name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ServiceProviderService.createServiceCategory({
                  "name": nameController.text,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProviderDialog(int categoryId) async {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final websiteController = TextEditingController();

  final serviceCategories = await _fetchServiceCategories();

  // 🔹 Each service = Map of controllers + state
  final List<Map<String, dynamic>> serviceForms = [
    _buildServiceForm(serviceCategories)
  ];

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text("Add Provider & Services"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Provider fields ---
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Provider Name"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 2,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location Address"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: websiteController,
                decoration: const InputDecoration(labelText: "Website"),
                keyboardType: TextInputType.url,
              ),
              const Divider(height: 30),

              // --- Service forms ---
              const Text("Service Details",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              Column(
                children: serviceForms.map((form) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: form["nameController"],
                            decoration: const InputDecoration(
                                labelText: "Service Name"),
                          ),
                          TextField(
                            controller: form["descController"],
                            decoration: const InputDecoration(
                                labelText: "Service Description"),
                          ),
                          TextField(
                            controller: form["priceController"],
                            decoration: const InputDecoration(
                                labelText: "Price Range"),
                          ),
                          DropdownButtonFormField<int>(
                            value: form["selectedCategoryId"],
                            items: serviceCategories
                                .map<DropdownMenuItem<int>>((cat) =>
                                    DropdownMenuItem<int>(
                                        value: cat["id"], child: Text(cat["name"])))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                form["selectedCategoryId"] = val;
                              });
                            },
                            decoration: const InputDecoration(
                                labelText: "Service Category"),
                          ),
                          Row(
                            children: [
                              const Text("Booking Required"),
                              Switch(
                                value: form["bookingRequired"],
                                onChanged: (val) {
                                  setState(() {
                                    form["bookingRequired"] = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          TextField(
                            controller: form["durationController"],
                            decoration: const InputDecoration(
                                labelText: "Duration (e.g. 30min)"),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  serviceForms.remove(form);
                                });
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ➕ Add another service
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    serviceForms.add(_buildServiceForm(serviceCategories));
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Another Service"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final services = serviceForms.map((form) {
                  return {
                    "name": form["nameController"].text,
                    "description": form["descController"].text,
                    "price_range": form["priceController"].text,
                    "category_id": form["selectedCategoryId"],
                    "requirements": {
                      "booking": form["bookingRequired"],
                      "duration": form["durationController"].text
                    }
                  };
                }).where((s) => (s["name"] as String).isNotEmpty).toList();

                await ServiceProviderService.createProvider({
                  "category_id": categoryId,
                  "name": nameController.text,
                  "description": descController.text,
                  "location": {"address": locationController.text},
                  "contact_info": {
                    "phone": phoneController.text,
                    "email": emailController.text,
                    "website": websiteController.text,
                  },
                  "is_registered": true,
                  "services": services,
                });

                _reloadCategories();
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    ),
  );
}

// 🔹 Helper to create a new service form
Map<String, dynamic> _buildServiceForm(List<dynamic> serviceCategories) {
  return {
    "nameController": TextEditingController(),
    "descController": TextEditingController(),
    "priceController": TextEditingController(),
    "durationController": TextEditingController(),
    "bookingRequired": true,
    "selectedCategoryId": serviceCategories.isNotEmpty ? serviceCategories.first["id"] : null,
  };
}



  Future<void> _showAddServiceDialog(String providerId) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int? selectedCategoryId;

    final serviceCategories = await _fetchServiceCategories();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Service"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Service Name")),
            TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description")),
            DropdownButtonFormField<int>(
              value: selectedCategoryId,
              items: serviceCategories
                  .map<DropdownMenuItem<int>>((cat) =>
                      DropdownMenuItem<int>(value: cat["id"], child: Text(cat["name"])))
                  .toList(),
              onChanged: (val) {
                selectedCategoryId = val;
              },
              decoration: const InputDecoration(labelText: "Service Category"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ServiceProviderService.createProviderService(providerId, {
                  "name": nameController.text,
                  "description": descController.text,
                  "category_id": selectedCategoryId,
                });
                _reloadCategories();
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Service Providers"),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _showAddProviderCategoryDialog,
            tooltip: "Add Provider Category",
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showAddServiceCategoryDialog,
            tooltip: "Add Service Category",
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _providerCategoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No categories found"));
          }

          final providerCategories = snapshot.data!;

          return ListView.builder(
            itemCount: providerCategories.length,
            itemBuilder: (context, index) {
              final category = providerCategories[index];
              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category["name"]),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: "Add Provider",
                      onPressed: () => _showAddProviderDialog(category["id"]),
                    ),
                  ],
                ),
                children: [
                  FutureBuilder<List<dynamic>>(
                    future: _fetchProviders(category["id"]),
                    builder: (context, provSnap) {
                      if (provSnap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (!provSnap.hasData || provSnap.data!.isEmpty) {
                        return const ListTile(title: Text("No providers"));
                      }

                      final providers = provSnap.data!;
                      return Column(
                        children: providers.map((prov) {
                          return ExpansionTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(prov["name"]),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  tooltip: "Add Service",
                                  onPressed: () => _showAddServiceDialog(prov["id"]),
                                ),
                              ],
                            ),
                            subtitle: Text(prov["description"] ?? ""),
                            children: [
                              FutureBuilder<Map<String, dynamic>?>(
                                future: _fetchProviderDetails(prov["id"]),
                                builder: (context, servSnap) {
                                  if (servSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (servSnap.data == null ||
                                      servSnap.data!["services"].isEmpty) {
                                    return const ListTile(
                                        title: Text("No services"));
                                  }

                                  final services = servSnap.data!["services"];
                                  return Column(
                                    children: services.map<Widget>((srv) {
                                      return ListTile(
                                        title: Text(srv["name"]),
                                        subtitle:
                                            Text(srv["description"] ?? ""),
                                        trailing: Text(
                                          "Category: ${srv["category_id"] ?? "Uncategorized"}",
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              )
                            ],
                          );
                        }).toList(),
                      );
                    },
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}
