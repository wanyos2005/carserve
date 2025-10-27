import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/global_service_api.dart';

class ServiceManagementPage extends StatefulWidget {
  const ServiceManagementPage({super.key});

  @override
  State<ServiceManagementPage> createState() => _ServiceManagementPageState();
}

class _ServiceManagementPageState extends State<ServiceManagementPage> {
  late Future<List<dynamic>> _serviceCategoriesFuture;

  @override
  void initState() {
    super.initState();
    _reloadServiceCategories();
  }


  void _reloadServiceCategories() {
    setState(() {
      _serviceCategoriesFuture = GlobalServiceApi.getServiceCategories();
    });
  }

  // -------------------------
  // Dialogs
  // -------------------------
  Future<void> _showAddServiceCategoryDialog() async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Service Category"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Category Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await GlobalServiceApi.createServiceCategory({
                  "name": nameController.text,
                });
                _reloadServiceCategories();
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

Future<void> _showAddServiceDialog(int categoryId) async {
  final nameController = TextEditingController();
  final descController = TextEditingController();

  // Each requirement: name, type, label, options
  final List<Map<String, TextEditingController>> requirementControllers = [];

  void addRequirementField() {
    requirementControllers.add({
      "name": TextEditingController(),
      "label": TextEditingController(),
      "type": TextEditingController(text: "string"), // default
      "options": TextEditingController(),
    });
  }

  addRequirementField(); // start with one row

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: const Text("Add Global Service"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Service Name"),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 16),
                const Text("Requirements",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (int i = 0; i < requirementControllers.length; i++)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: requirementControllers[i]["name"],
                                decoration: const InputDecoration(
                                    labelText: "Field name (e.g. policy)"),
                              ),
                              TextField(
                                controller: requirementControllers[i]["label"],
                                decoration: const InputDecoration(
                                    labelText: "Field label (user friendly)"),
                              ),
                              DropdownButtonFormField<String>(
                                initialValue: requirementControllers[i]["type"]!.text,
                                items: const [
                                  DropdownMenuItem(
                                      value: "string", child: Text("String")),
                                  DropdownMenuItem(
                                      value: "number", child: Text("Number")),
                                  DropdownMenuItem(
                                      value: "boolean", child: Text("Boolean")),
                                  DropdownMenuItem(
                                      value: "textarea",
                                      child: Text("Textarea")),
                                  DropdownMenuItem(
                                      value: "select", child: Text("Select")),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    requirementControllers[i]["type"]!.text =
                                        v ?? "string";
                                  });
                                },
                                decoration:
                                    const InputDecoration(labelText: "Type"),
                              ),
                              if (requirementControllers[i]["type"]!.text ==
                                  "select")
                                TextField(
                                  controller: requirementControllers[i]
                                      ["options"],
                                  decoration: const InputDecoration(
                                    labelText:
                                        "Options (comma separated: A,B,C)",
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      requirementControllers.removeAt(i);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Requirement"),
                      onPressed: () {
                        setState(() => addRequirementField());
                      },
                    ),
                  ],
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
                  final fields = [];
                  for (var entry in requirementControllers) {
                    final name = entry["name"]!.text.trim();
                    final label = entry["label"]!.text.trim();
                    final type = entry["type"]!.text.trim();
                    final optionsRaw = entry["options"]!.text.trim();

                    if (name.isNotEmpty && type.isNotEmpty) {
                      fields.add({
                        "name": name,
                        "label": label.isNotEmpty ? label : name,
                        "type": type,
                        "options": optionsRaw.isNotEmpty
                            ? optionsRaw.split(",").map((s) => s.trim()).toList()
                            : null,
                      });
                    }
                  }

                  await GlobalServiceApi.createGlobalService({
                    "name": nameController.text,
                    "description": descController.text,
                    "category_id": categoryId,
                    "requirements":
                        fields.isNotEmpty ? {"fields": fields} : null,
                  });

                  _reloadServiceCategories();
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
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
        title: const Text("Manage Services"),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showAddServiceCategoryDialog,
            tooltip: "Add Service Category",
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _serviceCategoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No service categories found"));
          }

          final serviceCategories = snapshot.data!;
          return ListView.builder(
            itemCount: serviceCategories.length,
            itemBuilder: (context, index) {
              final category = serviceCategories[index];
              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category["name"]),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: "Add Service",
                      onPressed: () => _showAddServiceDialog(category["id"]),
                    ),
                  ],
                ),
                children: [
                  FutureBuilder<List<dynamic>>(
                    future: GlobalServiceApi.getGlobalServicesByCategory(category["id"]), // optional: fetch global services by category
                    builder: (context, serviceSnap) {
                      if (serviceSnap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (!serviceSnap.hasData || serviceSnap.data!.isEmpty) {
                        return const ListTile(title: Text("No services in this category"));
                      }

                      final services = serviceSnap.data!;
                      return Column(
                        children: services.map((srv) {
                          final requirements = srv["requirements"] as Map<String, dynamic>?;

                          return ExpansionTile(
                            title: Text(srv["name"]),
                            subtitle: Text(srv["description"] ?? ""),
                            trailing: Text(
                              "Price: ${srv["price_range"] ?? "N/A"}",
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                            children: [
                              if (requirements != null && requirements.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Requirements:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          )),
                                      const SizedBox(height: 4),
                                      ...requirements.entries.map((e) => Text("• ${e.key}: ${e.value}")),
                                    ],
                                  ),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Text("No requirements defined"),
                                ),
                            ],
                          );
                        }).toList(),
                      );

                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
