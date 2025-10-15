import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/components/enhanced_user_selector.dart';
import 'package:car_platform/BookingPageHelpers/enhanced_provider_selector.dart';

class ProviderUserLinkPage extends StatefulWidget {
  const ProviderUserLinkPage({super.key});

  @override
  State<ProviderUserLinkPage> createState() => _ProviderUserLinkPageState();
}

class _ProviderUserLinkPageState extends State<ProviderUserLinkPage> {
  Map<String, dynamic>? selectedUser;
  Map<String, dynamic>? selectedProvider;
  List<Map<String, dynamic>> allProviders = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => isLoading = true);
    try {
      final providers = await ProviderService.getProviders();
      setState(() {
        allProviders = providers.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading providers: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _linkUser() async {
    if (selectedUser == null || selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a user and a provider')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final success = await AuthService.linkUserToProvider(
        selectedUser!['id'],
        selectedProvider!['provider_id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "User linked successfully!"
                : "Failed to link user. Please try again."),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          setState(() {
            selectedUser = null;
            selectedProvider = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error linking user: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showUserSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedUserSelector(
        selectedUser: selectedUser,
        onSelect: (user) {
          setState(() {
            selectedUser = user;
          });
        },
      ),
    );
  }

  void _showProviderSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedProviderSelector(
        filteredProviders: allProviders,
        selectedServices: [], // Not needed for this use case
        recommendedOnly: false,
        selectedProvider: selectedProvider,
        onSelect: (provider) {
          setState(() {
            selectedProvider = provider;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Link User to Provider"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                "User-Provider Linking",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Associate users with service providers to enable provider-specific features and access.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "1. Select User",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _showUserSelector,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: selectedUser == null
                                  ? Row(
                                      children: [
                                        Icon(Icons.person_add, color: Colors.grey[600]),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Tap to select a user",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: selectedUser!['provider_id'] != null 
                                              ? Colors.green 
                                              : Colors.blue,
                                          child: Text(
                                            _getUserInitials(selectedUser!),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedUser!['name'] ?? selectedUser!['email'] ?? 'Unknown User',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (selectedUser!['name'] != null && selectedUser!['email'] != null)
                                                Text(
                                                  selectedUser!['email'],
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              if (selectedUser!['provider_id'] != null)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[100],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    'Already linked to provider',
                                                    style: TextStyle(
                                                      color: Colors.orange[800],
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Provider Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "2. Select Provider",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _showProviderSelector,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: selectedProvider == null
                                  ? Row(
                                      children: [
                                        Icon(Icons.business, color: Colors.grey[600]),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Tap to select a provider",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: selectedProvider!['is_registered'] 
                                              ? Colors.green 
                                              : Colors.orange,
                                          child: Text(
                                            selectedProvider!['provider_name']?.substring(0, 1).toUpperCase() ?? 'P',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedProvider!['provider_name'] ?? 'Unknown Provider',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                selectedProvider!['location']?['area'] ?? 'Nairobi',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.star, size: 16, color: Colors.amber[600]),
                                                  Text(' ${selectedProvider!['rating']?.toString() ?? '0.0'}'),
                                                  const SizedBox(width: 16),
                                                  if (selectedProvider!['is_registered'])
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        'Verified',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Link Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (selectedUser != null && selectedProvider != null && !isLoading)
                          ? _linkUser
                          : null,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.link),
                      label: Text(
                        isLoading
                            ? 'Linking...'
                            : 'Link User to Provider',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Status Info
                  if (selectedUser != null && selectedProvider != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ready to link ${selectedUser!['name'] ?? selectedUser!['email']} to ${selectedProvider!['provider_name']}. This will enable provider-specific features for the user.',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _getUserInitials(Map<String, dynamic> user) {
    final name = user['name'] as String?;
    final email = user['email'] as String?;
    
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return name.substring(0, 1).toUpperCase();
      }
    } else if (email != null && email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }
    
    return 'U';
  }
}
