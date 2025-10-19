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
  final Map<String, TextEditingController> _priceControllers = {}; // Legacy price field
  final Map<String, TextEditingController> _minPriceControllers = {}; // New structured pricing
  final Map<String, TextEditingController> _maxPriceControllers = {};
  final Map<String, String> _priceTypes = {}; // price_type for each service
  final Map<String, String> _priceUnits = {}; // unit for each service
  final Map<String, bool> _negotiableFlags = {}; // negotiable flag for each service
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
      // Handle the new data structure - service_id is directly available
      final sid = a["service_id"]?.toString();
      if (sid != null && sid.isNotEmpty) {
        _selectedServiceIds.add(sid);

        // Handle legacy price field
        final price = a["price"]?.toString() ?? "";
        _priceControllers.putIfAbsent(
          sid, () => TextEditingController(text: price)
        );

        // Handle new structured pricing fields
        final minPrice = a["min_price"]?.toString() ?? "";
        final maxPrice = a["max_price"]?.toString() ?? "";
        _minPriceControllers.putIfAbsent(
          sid, () => TextEditingController(text: minPrice)
        );
        _maxPriceControllers.putIfAbsent(
          sid, () => TextEditingController(text: maxPrice)
        );
        
        // Set pricing metadata
        _priceTypes[sid] = a["price_type"]?.toString() ?? "range";
        _priceUnits[sid] = a["unit"]?.toString() ?? "";
        _negotiableFlags[sid] = a["negotiable"] ?? true;

        // Handle display_name
        final displayName = a["display_name"]?.toString() ?? "";
        _displayNameControllers.putIfAbsent(
          sid, () => TextEditingController(text: displayName)
        );

        // Handle metadata/extra_data - the new structure uses extra_data
        final meta = a["extra_data"] as Map<String, dynamic>? ?? {};
        _serviceFieldControllers.putIfAbsent(sid, () {
          final map = <String, TextEditingController>{};
          meta.forEach((k, v) {
            map[k] = TextEditingController(text: v?.toString() ?? "");
          });
          return map;
        });
      }
    }
  }

  Widget _buildField(String serviceId, Map<String, dynamic> fieldDef) {
    final fname = fieldDef["name"]?.toString() ?? "";
    final ftype = fieldDef["type"]?.toString() ?? "string";
    final label = fieldDef["label"]?.toString() ?? fname;
    final controllers = _serviceFieldControllers.putIfAbsent(serviceId, () => {});
    final controller = controllers.putIfAbsent(fname, () => TextEditingController());

    switch (ftype) {
      case "string":
      case "text":
        return TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(labelText: label),
        );
      case "number":
        return TextField(
          controller: controller,
          keyboardType: TextInputType.number,
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
          value: current.isNotEmpty ? current : null,
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
        final val = c.text.trim();
        // Handle different data types
        if (val.toLowerCase() == 'true') {
          metadata[k] = true;
        } else if (val.toLowerCase() == 'false') {
          metadata[k] = false;
        } else if (val.isNotEmpty && RegExp(r'^\d+$').hasMatch(val)) {
          metadata[k] = int.tryParse(val);
        } else if (val.isNotEmpty && RegExp(r'^\d*\.?\d+$').hasMatch(val)) {
          metadata[k] = double.tryParse(val);
        } else {
          metadata[k] = val;
        }
      });

      final displayName = _displayNameControllers[sid]?.text.trim();
      final price = _priceControllers[sid]?.text.trim(); // Legacy field
      final minPrice = _minPriceControllers[sid]?.text.trim();
      final maxPrice = _maxPriceControllers[sid]?.text.trim();

      payload.add({
        "service_id": sid,
        "display_name": displayName?.isNotEmpty == true ? displayName : null,
        
        // Legacy price field (kept for backward compatibility)
        "price": price?.isNotEmpty == true ? price : null,
        
        // New structured pricing fields
        "min_price": minPrice?.isNotEmpty == true ? double.tryParse(minPrice!) : null,
        "max_price": maxPrice?.isNotEmpty == true ? double.tryParse(maxPrice!) : null,
        "price_type": _priceTypes[sid] ?? "range",
        "currency": "KES", // Default to KES
        "unit": _priceUnits[sid],
        "negotiable": _negotiableFlags[sid] ?? true,
        
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
      appBar: AppBar(title: Text("Edit ${_provider!["name"] ?? _provider!["provider_name"] ?? ""}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_provider!["description"]?.toString() ?? ""),
            const Divider(),
            const Text("Attach Services", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._allServices.map<Widget>((srv) {
              final sid = srv["service_id"]?.toString() ?? srv["id"]?.toString();
              if (sid == null || sid.isEmpty) return const SizedBox.shrink();
              
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
                      Expanded(child: Text(srv["service_name"]?.toString() ?? srv["name"]?.toString() ?? "")),
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
                          Text(srv["service_description"]?.toString() ?? srv["description"]?.toString() ?? ""),
                          if (isSelected) ...[
                            // Legacy price field (for display compatibility)
                            TextField(
                              controller: _priceControllers[sid],
                              decoration: const InputDecoration(
                                labelText: "Display Price (e.g., KSh 3,500 - 8,000)",
                                hintText: "KSh 3,500 - 8,000",
                              ),
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 8),
                            
                            // New structured pricing fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _minPriceControllers.putIfAbsent(sid, () => TextEditingController()),
                                    decoration: const InputDecoration(
                                      labelText: "Min Price",
                                      prefixText: "KES ",
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _maxPriceControllers.putIfAbsent(sid, () => TextEditingController()),
                                    decoration: const InputDecoration(
                                      labelText: "Max Price",
                                      prefixText: "KES ",
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Price type selector
                            DropdownButtonFormField<String>(
                              value: _priceTypes[sid] ?? "range",
                              decoration: const InputDecoration(labelText: "Price Type"),
                              items: const [
                                DropdownMenuItem(value: "fixed", child: Text("Fixed Price")),
                                DropdownMenuItem(value: "range", child: Text("Price Range")),
                                DropdownMenuItem(value: "per_unit", child: Text("Per Unit")),
                                DropdownMenuItem(value: "free", child: Text("Free Service")),
                                DropdownMenuItem(value: "variable", child: Text("Variable Price")),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _priceTypes[sid] = value ?? "range";
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            
                            // Unit field (for per_unit pricing)
                            if (_priceTypes[sid] == "per_unit")
                              TextField(
                                controller: TextEditingController(text: _priceUnits[sid] ?? ""),
                                decoration: const InputDecoration(
                                  labelText: "Unit (e.g., per_liter, per_hour)",
                                  hintText: "per_liter",
                                ),
                                onChanged: (value) {
                                  _priceUnits[sid] = value.trim();
                                },
                              ),
                            const SizedBox(height: 8),
                            
                            // Negotiable checkbox
                            CheckboxListTile(
                              title: const Text("Price is negotiable"),
                              value: _negotiableFlags[sid] ?? true,
                              onChanged: (value) {
                                setState(() {
                                  _negotiableFlags[sid] = value ?? true;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
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
                            if (_serviceDetails[sid]?["service_requirements"] != null)
                              ...List<Widget>.from(
                                (_serviceDetails[sid]["service_requirements"]["fields"] as List<dynamic>? ?? [])
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
