import 'package:flutter/material.dart';

class ProviderSelector extends StatefulWidget {
  final List<Map<String, dynamic>> filteredProviders;
  final List<Map<String, dynamic>> selectedServices;
  final bool recommendedOnly;
  final Map<String, dynamic>? selectedProvider;
  final Function(Map<String, dynamic>) onSelect;

  const ProviderSelector({
    super.key,
    required this.filteredProviders,
    required this.selectedServices,
    required this.recommendedOnly,
    required this.selectedProvider,
    required this.onSelect,
  });

  @override
  State<ProviderSelector> createState() => _ProviderSelectorState();
}

class _ProviderSelectorState extends State<ProviderSelector> {
  String query = "";

  List<Map<String, dynamic>> get _filteredProviders {
    if (query.isEmpty) return widget.filteredProviders;
    return widget.filteredProviders.where((p) {
      final name = (p["provider_name"] ?? "").toLowerCase();
      final desc = (p["description"] ?? "").toLowerCase();
      final q = query.toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.recommendedOnly
        ? _providerList(_filteredProviders)
        : _groupedProviderList(_filteredProviders);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Select Provider",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            // 🔹 Search bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search providers...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _groupedProviderList(List<Map<String, dynamic>> filtered) {
    final groupedProviders = <String, List<Map<String, dynamic>>>{};
    for (var service in widget.selectedServices) {
      final serviceId = service["id"];
      final serviceName = service["service_name"] ?? service["name"] ?? "Service";

      groupedProviders[serviceName] = filtered.where((p) {
        final providerServices = p["services"] as List? ?? [];
        return providerServices.any((s) => s["service_id"] == serviceId);
      }).toList();
    }

    return ListView(
      children: groupedProviders.entries.map((entry) {
        return ExpansionTile(
          title: Text("Providers for ${entry.key}"),
          children: entry.value.map((p) => _providerTile(p)).toList(),
        );
      }).toList(),
    );
  }

  Widget _providerList(List<Map<String, dynamic>> providers) {
    return ListView.separated(
      itemCount: providers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _providerTile(providers[i]),
    );
  }

  Widget _providerTile(Map<String, dynamic> p) {
    return ListTile(
      title: Text(p["provider_name"] ?? "Provider"),
      subtitle: Text(p["description"] ?? ""),
      trailing: widget.selectedProvider != null &&
              widget.selectedProvider!["id"] == p["id"]
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        Navigator.pop(context);
        widget.onSelect(Map<String, dynamic>.from(p));
      },
    );
  }
}
