// lib/pages/provider_management_page.dart

import 'package:flutter/material.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/components/location_picker.dart';
import 'package:car_platform/pages/AdminPages/edit_our_services_page.dart';

class ProviderManagementPage extends StatefulWidget {
  const ProviderManagementPage({super.key});

  @override
  State<ProviderManagementPage> createState() => _ProviderManagementPageState();
}

class _ProviderManagementPageState extends State<ProviderManagementPage> {
  late Future<List<dynamic>> _providerCategoriesFuture;

  @override
  void initState() {
    super.initState();
    _reloadCategories();
  }

  void _reloadCategories() {
    setState(() {
      _providerCategoriesFuture = ProviderService.getProviderCategories();
    });
  }

  Future<List<dynamic>> _fetchProviders(int categoryId) {
    return ProviderService.getProviders(categoryId: categoryId);
  }


  // -------------------------
  // Dialogs
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ProviderService.createProviderCategory({
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

  Future<void> _showAddProviderDialog(int categoryId) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final websiteController = TextEditingController();

    final allServices = await ProviderService.getProviderServices(""); // Fetch global services
    final selectedServiceIds = <String>{};
    Map<String, dynamic>? locationData;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Add Provider"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Provider info
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Provider Name")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                
                // Location picker
                const SizedBox(height: 16),
                LocationPicker(
                  label: "Business Location",
                  hint: "Tap to select location",
                  onLocationSelected: (location) {
                    setState(() {
                      locationData = location;
                    });
                  },
                  showCurrentLocationButton: true,
                  required: true,
                ),
                
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
                TextField(controller: websiteController, decoration: const InputDecoration(labelText: "Website")),
                const Divider(height: 30),

                // Select services
                const Text("Select Services", style: TextStyle(fontWeight: FontWeight.bold)),
                Column(
                  children: allServices.map<Widget>((srv) {
                    final isSelected = selectedServiceIds.contains(srv["id"]);
                    return CheckboxListTile(
                      title: Text(srv["name"]),
                      subtitle: Text(srv["description"] ?? ""),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedServiceIds.add(srv["id"]);
                          } else {
                            selectedServiceIds.remove(srv["id"]);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && locationData != null) {
                  await ProviderService.createProvider({
                    "category_id": categoryId,
                    "name": nameController.text,
                    "description": descController.text,
                    "location": locationData,  // Use legacy-compatible location data
                    "contact_info": {
                      "phone": phoneController.text,
                      "email": emailController.text,
                      "website": websiteController.text,
                    },
                    "is_registered": true,
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

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _showAddProviderCategoryDialog,
            tooltip: "Add Provider Category",
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
                          return ListTile(
                            title: Text(prov["provider_name"] ?? "Unnamed Provider"),
                            subtitle: Text(prov["description"] ?? ""),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  tooltip: "View / Edit",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditOurServicesPage(providerId: prov["provider_id"]),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
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
