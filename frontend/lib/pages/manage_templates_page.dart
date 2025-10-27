import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/provider_service.dart';

class ManageTemplatesPage extends StatefulWidget {
  final String providerId;
  const ManageTemplatesPage({super.key, required this.providerId});

  @override
  State<ManageTemplatesPage> createState() => _ManageTemplatesPageState();
}

class _ManageTemplatesPageState extends State<ManageTemplatesPage> {
  List<dynamic> _templates = [];
  List<dynamic> _attachedServices = [];

  final _nameController = TextEditingController();
  final Set<String> _selectedServiceIds = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final templates = await ProviderService.getServiceTemplates(widget.providerId);
    final attached = await ProviderService.getProviderServices(widget.providerId);

    setState(() {
      _templates = templates;
      _attachedServices = attached;
    });
  }

  Future<void> _createTemplate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and at least one service required")),
      );
      return;
    }

    final payload = {
      "provider_id": widget.providerId,
      "name": name,
      "items": _selectedServiceIds.map((id) => {"service_id": id}).toList(),
    };

    await ProviderService.createServiceTemplate(widget.providerId, payload);

    _nameController.clear();
    _selectedServiceIds.clear();

    await _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Template created")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Templates")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing Templates
            const Text("Existing Templates",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._templates.map((tpl) {
              final items = (tpl["items"] as List?) ?? [];
              return Card(
                child: ListTile(
                  title: Text(tpl["name"] ?? ""),
                  subtitle: Text("Includes ${items.length} services"),
                ),
              );
            }),

            const Divider(height: 40),

            // Create New Template
            const Text("Create New Template",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Template Name"),
            ),
            const SizedBox(height: 12),

            const Text("Select Services"),
            const SizedBox(height: 8),
            ..._attachedServices.map((srv) {
              final sid = srv["service_id"];
              final alias = srv["display_name"]; // ✅ correct field
              final globalName = srv["service"]?["name"] ?? "Unnamed Service";
              final displayName = (alias != null && alias.isNotEmpty) ? alias : globalName;

              return CheckboxListTile(
                value: _selectedServiceIds.contains(sid),
                title: Text(displayName),
                subtitle: alias != null && alias.isNotEmpty
                    ? Text("Global: $globalName", style: const TextStyle(fontSize: 12, color: Colors.grey))
                    : null,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedServiceIds.add(sid);
                    } else {
                      _selectedServiceIds.remove(sid);
                    }
                  });
                },
              );
            }),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createTemplate,
              child: const Text("Save Template"),
            ),
          ],
        ),
      ),
    );
  }
}
