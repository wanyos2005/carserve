import 'package:flutter/material.dart';
import 'package:car_platform/services/provider_service.dart';

class ProviderLogServicePage extends StatefulWidget {
  final String providerId;

  const ProviderLogServicePage({super.key, required this.providerId});

  @override
  State<ProviderLogServicePage> createState() => _ProviderLogServicePageState();
}

class _ProviderLogServicePageState extends State<ProviderLogServicePage> {
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplateServices();
  }

  Future<void> _fetchTemplateServices() async {
    setState(() {
      _loading = true;
    });

    try {
      // Fetch all templates for the provider
      final templates = await ProviderService.getServiceTemplates(widget.providerId);

      if (templates.isNotEmpty) {
        // Pick the first template as the "active" template
        final activeTemplate = templates[0];

        // Map template items to local state with logging fields
        final items = List<Map<String, dynamic>>.from(
          activeTemplate['items'] ?? [],
        ).map((item) {
          return {
            'service_id': item['service_id'],
            'display_name': item['service']['name'] ?? 'Unnamed Service',
            'done': false,
            'notes': '',
          };
        }).toList();

        setState(() {
          _services = items;
        });
      }
    } catch (e) {
      debugPrint("Error fetching template services: $e");
    }

    setState(() {
      _loading = false;
    });
  }

  void _toggleDone(int index, bool? value) {
    setState(() {
      _services[index]['done'] = value ?? false;
    });
  }

  void _updateNotes(int index, String value) {
    setState(() {
      _services[index]['notes'] = value;
    });
  }

  void _submitLog() {
    // Prepare payload
    final payload = _services.map((s) {
      return {
        'service_id': s['service_id'],
        'done': s['done'],
        'notes': s['notes'],
      };
    }).toList();

    debugPrint("Submitting provider log: $payload");

    // TODO: Call backend API to save log
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Provider log submitted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Services"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text("No services in active template"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    service['display_name'],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Checkbox(
                                  value: service['done'],
                                  onChanged: (value) =>
                                      _toggleDone(index, value),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              decoration: const InputDecoration(
                                labelText: "Notes",
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              onChanged: (value) => _updateNotes(index, value),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _services.isEmpty ? null : _submitLog,
          child: const Text("Submit Log"),
        ),
      ),
    );
  }
}
