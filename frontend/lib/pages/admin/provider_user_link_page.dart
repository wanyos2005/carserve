import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart';

class ProviderUserLinkPage extends StatefulWidget {
  const ProviderUserLinkPage({super.key});

  @override
  State<ProviderUserLinkPage> createState() => _ProviderUserLinkPageState();
}

class _ProviderUserLinkPageState extends State<ProviderUserLinkPage> {
  List<dynamic> users = [];
  List<dynamic> providers = [];
  int? selectedUserId;
  String? selectedProviderId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final fetchedUsers = await AuthService.getAllUsers();
    final fetchedProviders = await ProviderService.getProviders();
    setState(() {
      users = fetchedUsers;
      providers = fetchedProviders;
      isLoading = false;
    });
  }

  Future<void> _linkUser() async {
    if (selectedUserId == null || selectedProviderId == null) return;

    final success = await AuthService.linkUserToProvider(
      selectedUserId!, selectedProviderId!,
    );


    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? "User linked successfully!"
          : "Failed to link user. Please try again."),
    ));

    if (success) {
      setState(() {
        selectedUserId = null;
        selectedProviderId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Link User to Provider")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: selectedUserId,
              hint: const Text("Select User"),
              items: users.map<DropdownMenuItem<int>>((user) {
                return DropdownMenuItem<int>(
                  value: user['id'],
                  child: Text("${user['email']}"),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedUserId = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedProviderId,
              hint: const Text("Select Provider"),
              items: providers.map<DropdownMenuItem<String>>((prov) {
                return DropdownMenuItem<String>(
                  value: prov['id'], // UUID string
                  child: Text("${prov['name']}"),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedProviderId = val),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _linkUser,
              child: const Text("Link User"),
            ),
          ],
        ),
      ),
    );
  }
}
