// provider_selector.dart
import 'package:flutter/material.dart';

class ProviderSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (recommendedOnly) {
      // Show providers that match all (already pre-filtered by booking page)
      return SafeArea(
        child: _providerList(context, filteredProviders),
      );
    }

    // Group providers by selected services
    final groupedProviders = <String, List<Map<String, dynamic>>>{};
    for (var service in selectedServices) {
      groupedProviders[service["name"]] = filteredProviders.where((p) {
        final providerServices = p["services"] as List? ?? [];
        return providerServices.any((s) => s["id"] == service["id"]);
      }).toList();
    }

    return SafeArea(
      child: ListView(
        children: groupedProviders.entries.map((entry) {
          return ExpansionTile(
            title: Text("Providers for ${entry.key}"),
            children: entry.value.map((p) {
              return ListTile(
                title: Text(p["name"] ?? "Provider"),
                subtitle: Text(p["description"] ?? ""),
                trailing: selectedProvider != null &&
                        selectedProvider!["id"] == p["id"]
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(Map<String, dynamic>.from(p));
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _providerList(BuildContext context, List<Map<String, dynamic>> providers) {
    return ListView.separated(
      itemCount: providers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = providers[i];
        return ListTile(
          title: Text(p["name"] ?? "Provider"),
          subtitle: Text(p["description"] ?? ""),
          trailing: selectedProvider != null && selectedProvider!["id"] == p["id"]
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () {
            Navigator.pop(context);
            onSelect(Map<String, dynamic>.from(p));
          },
        );
      },
    );
  }
}
