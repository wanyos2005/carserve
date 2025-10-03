// frontend/lib/pages/edit_provider_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/global_service_api.dart';
import 'manage_templates_page.dart';

class EditProviderPage extends StatefulWidget {
  final String providerId;
  const EditProviderPage({super.key, required this.providerId});

  @override
  State<EditProviderPage> createState() => _EditProviderPageState();
}

class _EditProviderPageState extends State<EditProviderPage> {
  Map<String, dynamic>? _provider;
  List<dynamic> _allServices = [];
  final Map<String, Map<String, TextEditingController>> _serviceFieldControllers = {}; 
  final Map<String, TextEditingController> _displayNameControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final Set<String> _selectedServiceIds = {};
  final Map<String, dynamic> _serviceDetails = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadServiceDetails(String serviceId) async {
    if (_serviceDetails.containsKey(serviceId)) return; // already loaded

    final details = await GlobalServiceApi.getGlobalService(serviceId);
    if (details != null) {
      setState(() {
        _serviceDetails[serviceId] = details;
      });
    }
  }

  Future<void> _loadAll() async {
    final prov = await ProviderService.getProviderDetails(widget.providerId);
    final services = await GlobalServiceApi.getAllGlobalServices();
    final attached = await ProviderService.getProviderServices(widget.providerId);

    setState(() {
      _provider = prov;
      _allServices = services;
    });

    for (var a in attached) {
      final sid = a["service_id"] ?? a["service"]["id"] ?? a["id"];
      if (sid != null) {
        _selectedServiceIds.add(sid);

        _priceControllers.putIfAbsent(
          sid, () => TextEditingController(text: a["price"]?.toString() ?? "")
        );

        _displayNameControllers.putIfAbsent(
          sid, () => TextEditingController(text: a["display_name"] ?? "")
        );

        final meta = a["metadata"] ?? a["requirements"] ?? {};
        _serviceFieldControllers.putIfAbsent(sid, () {
          final map = <String, TextEditingController>{};
          (meta as Map<String, dynamic>).forEach((k, v) {
            map[k] = TextEditingController(text: v?.toString() ?? "");
          });
          return map;
        });
      }
    }
  }

  Widget _buildField(String serviceId, Map<String, dynamic> fieldDef) {
    final fname = fieldDef["name"];
    final ftype = fieldDef["type"];
    final label = fieldDef["label"] ?? fname;
    final controllers = _serviceFieldControllers.putIfAbsent(serviceId, () => {});
    final controller = controllers.putIfAbsent(fname, () => TextEditingController());

    switch (ftype) {
      case "string":
      case "number":
        return TextField(
          controller: controller,
          keyboardType: ftype == "number" ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        );
      case "textarea":
        return TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(labelText: label),
        );
      case "boolean":
        bool current = (controller.text.toLowerCase() == 'true');
        return CheckboxListTile(
          value: current,
          title: Text(label),
          onChanged: (v) {
            controller.text = v == true ? "true" : "false";
            setState(() {}); // update UI
          },
        );
      case "select":
        final options = List<String>.from(fieldDef["options"] ?? []);
        String current = controller.text.isNotEmpty ? controller.text : (options.isNotEmpty ? options[0] : "");
        return DropdownButtonFormField<String>(
          initialValue: current.isNotEmpty ? current : null,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) {
            controller.text = v ?? "";
            setState(() {});
          },
          decoration: InputDecoration(labelText: label),
        );
      default:
        return TextField(controller: controller, decoration: InputDecoration(labelText: label));
    }
  }

  Future<void> _save() async {
    final List<Map<String, dynamic>> payload = [];
    for (var sid in _selectedServiceIds) {
      final metaControllers = _serviceFieldControllers[sid] ?? {};
      final metadata = <String, dynamic>{};
      metaControllers.forEach((k, c) {
        final val = c.text;
        // coerce booleans/numbers if you want; keep strings for simplicity
        metadata[k] = val;
      });

      payload.add({
        "service_id": sid,
        "display_name": _displayNameControllers[sid]?.text.trim().isNotEmpty == true
          ? _displayNameControllers[sid]?.text.trim()
          : null,
        "price": _priceControllers[sid]?.text,
        "metadata": metadata
      });
    }

    await ProviderService.attachServicesToProvider(widget.providerId, payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved")));
      Navigator.pop(context, true);
    }
  }

    @override
  Widget build(BuildContext context) {
    if (_provider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Edit ${_provider!["name"] ?? ""}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_provider!["description"] ?? ""),
            const Divider(),
            const Text("Attach Services", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._allServices.map<Widget>((srv) {
              final sid = srv["id"];
              final isSelected = _selectedServiceIds.contains(sid);
              _priceControllers.putIfAbsent(sid, () => TextEditingController());

              return Card(
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedServiceIds.add(sid);
                            } else {
                              _selectedServiceIds.remove(sid);
                            }
                          });
                        },
                      ),
                      Expanded(child: Text(srv["name"] ?? "")),
                    ],
                  ),
                  onExpansionChanged: (expanded) {
                    if (expanded) {
                      _loadServiceDetails(sid);
                    }
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: [
                          Text(srv["description"] ?? ""),
                          if (isSelected) ...[
                            TextField(
                              controller: _priceControllers[sid],
                              decoration: const InputDecoration(labelText: "Price", prefixText:"\KSH "),
                              keyboardType: TextInputType.textarea,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _displayNameControllers[sid],
                              decoration: const InputDecoration(
                                labelText: "Custom Display Name (optional)",
                                hintText: "e.g., Premium Castrol Oil Change",
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ✅ render requirement-defined fields (from lazy-loaded details)
                            if (_serviceDetails[sid]?["requirements"] != null)
                              ...List<Widget>.from(
                                (_serviceDetails[sid]["requirements"]["fields"] as List<dynamic>? ?? [])
                                    .map((f) => _buildField(sid, f as Map<String, dynamic>))
                              ),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // ✅ Manage Templates button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageTemplatesPage(providerId: widget.providerId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: const Text("Manage Templates"),
            ),

            const SizedBox(height: 12),

            // Existing Save button
            ElevatedButton(onPressed: _save, child: const Text("Save")),
          ],
        ),
      ),
    );
  }

}
