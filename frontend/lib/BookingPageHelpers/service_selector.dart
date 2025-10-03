//lib/helpers/service_selector.dart
import 'package:flutter/material.dart';

class ServiceSelector extends StatefulWidget {
  final List<Map<String, dynamic>> allServices;
  final List<Map<String, dynamic>> selectedServices;
  final Function(List<Map<String, dynamic>>) onConfirm;

  const ServiceSelector({
    super.key,
    required this.allServices,
    required this.selectedServices,
    required this.onConfirm,
  });

  @override
  State<ServiceSelector> createState() => _ServiceSelectorState();
}

class _ServiceSelectorState extends State<ServiceSelector> {
  String query = "";
  late List<Map<String, dynamic>> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedServices);
  }

  bool isSelected(Map<String, dynamic> service) {
    return _tempSelected.any((s) => s["id"] == service["id"]);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allServices.where((s) {
      final name = (s["name"] ?? "").toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search services...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          SizedBox(
            height: 360,
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = filtered[i];
                return CheckboxListTile(
                  title: Text(s["name"] ?? "Unnamed"),
                  subtitle: (s["price_range"] != null)
                      ? Text(s["price_range"])
                      : null,
                  value: isSelected(s),
                  onChanged: (_) {
                    setState(() {
                      if (isSelected(s)) {
                        _tempSelected.removeWhere((x) => x["id"] == s["id"]);
                      } else {
                        _tempSelected.add(Map<String, dynamic>.from(s));
                      }
                    });
                  },
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_tempSelected);
                      Navigator.pop(context);
                    },
                    child: const Text("Confirm"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
