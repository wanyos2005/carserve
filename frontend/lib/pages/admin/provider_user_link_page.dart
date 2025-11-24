import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/auth_service.dart';
import 'package:driveon_car_platform/services/provider_service.dart';
import 'package:driveon_car_platform/components/enhanced_user_selector.dart';
import 'package:driveon_car_platform/BookingPageHelpers/enhanced_provider_selector.dart';

class ProviderUserLinkPage extends StatefulWidget {
  const ProviderUserLinkPage({super.key});

  @override
  State<ProviderUserLinkPage> createState() => _ProviderUserLinkPageState();
}

class _ProviderUserLinkPageState extends State<ProviderUserLinkPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab 1: Create/Delete Links
  Map<String, dynamic>? selectedUser;
  Map<String, dynamic>? selectedProvider;
  List<Map<String, dynamic>> allProviders = [];
  Map<String, dynamic>? existingLinkedProvider;
  bool isLoading = false;
  bool isDeleting = false;

  // Tab 2: View Links by Provider
  Map<String, dynamic>? selectedProviderForView;
  List<Map<String, dynamic>> providerLinks = [];
  bool isLoadingProviderLinks = false;
  int providerLinksPage = 1;
  int providerLinksTotalPages = 1;
  int providerLinksTotal = 0;

  // Tab 3: View All Links
  List<Map<String, dynamic>> allLinks = [];
  bool isLoadingAllLinks = false;
  int allLinksPage = 1;
  int allLinksTotalPages = 1;
  int allLinksTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProviders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  // ========== TAB 1: CREATE/DELETE LINKS ==========
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
        selectedProvider!['provider_id'] ?? selectedProvider!['id'],
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
            selectedUser = {
              ...selectedUser!,
              'provider_id': selectedProvider!['provider_id'] ?? selectedProvider!['id'],
            };
            selectedProvider = null;
          });
          await _loadLinkedProvider();
          // Refresh other tabs
          if (selectedProviderForView != null) {
            _loadProviderLinks();
          }
          _loadAllLinks();
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

  Future<void> _unlinkUser() async {
    if (selectedUser == null || existingLinkedProvider == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink User from Provider'),
        content: Text(
          'Are you sure you want to unlink ${selectedUser!['name'] ?? selectedUser!['email']} from ${existingLinkedProvider!['provider_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isDeleting = true);
    try {
      final providerId = existingLinkedProvider!['provider_id'] ?? existingLinkedProvider!['id'];
      final success = await AuthService.unlinkUserFromProvider(
        selectedUser!['id'],
        providerId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "User unlinked successfully!"
                : "Failed to unlink user. Please try again."),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          setState(() {
            selectedUser = {
              ...selectedUser!,
              'provider_id': null,
            };
            existingLinkedProvider = null;
          });
          // Refresh other tabs
          if (selectedProviderForView != null) {
            _loadProviderLinks();
          }
          _loadAllLinks();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking user: $e')),
        );
      }
    } finally {
      setState(() => isDeleting = false);
    }
  }

  Future<void> _loadLinkedProvider() async {
    if (selectedUser == null || selectedUser!['provider_id'] == null) {
      setState(() {
        existingLinkedProvider = null;
      });
      return;
    }

    try {
      final providerId = selectedUser!['provider_id'] as String;
      
      try {
        final provider = allProviders.firstWhere(
          (p) => (p['provider_id'] ?? p['id']) == providerId,
        );
        setState(() {
          existingLinkedProvider = provider;
        });
        return;
      } catch (e) {
        // Provider not in list, fetch from API
      }
      
      final providerDetails = await ProviderService.getProviderDetails(providerId);
      if (providerDetails != null) {
        setState(() {
          existingLinkedProvider = {
            ...providerDetails,
            'provider_id': providerId,
            'id': providerId,
          };
        });
      } else {
        setState(() {
          existingLinkedProvider = {
            'provider_id': providerId,
            'provider_name': 'Unknown Provider',
            'id': providerId,
          };
        });
      }
    } catch (e) {
      if (selectedUser != null && selectedUser!['provider_id'] != null) {
        setState(() {
          existingLinkedProvider = {
            'provider_id': selectedUser!['provider_id'],
            'provider_name': 'Unknown Provider',
            'id': selectedUser!['provider_id'],
          };
        });
      } else {
        setState(() {
          existingLinkedProvider = null;
        });
      }
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
            selectedProvider = null;
            existingLinkedProvider = null;
          });
          _loadLinkedProvider();
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
        selectedServices: [],
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

  // ========== TAB 2: VIEW LINKS BY PROVIDER ==========
  void _showProviderSelectorForView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedProviderSelector(
        filteredProviders: allProviders,
        selectedServices: [],
        recommendedOnly: false,
        selectedProvider: selectedProviderForView,
        onSelect: (provider) {
          setState(() {
            selectedProviderForView = provider;
            providerLinksPage = 1;
          });
          _loadProviderLinks();
        },
      ),
    );
  }

  Future<void> _loadProviderLinks() async {
    if (selectedProviderForView == null) {
      setState(() {
        providerLinks = [];
      });
      return;
    }

    setState(() => isLoadingProviderLinks = true);
    try {
      final providerId = selectedProviderForView!['provider_id'] ?? selectedProviderForView!['id'];
      final result = await AuthService.getProviderLinks(
        providerId,
        page: providerLinksPage,
        pageSize: 20,
      );

      if (mounted && result != null) {
        setState(() {
          providerLinks = (result['links'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          providerLinksTotal = result['total'] ?? 0;
          providerLinksTotalPages = result['total_pages'] ?? 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading provider links: $e')),
        );
      }
    } finally {
      setState(() => isLoadingProviderLinks = false);
    }
  }

  Future<void> _deleteLinkFromProviderView(Map<String, dynamic> link) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink User from Provider'),
        content: Text(
          'Are you sure you want to unlink ${link['user_name'] ?? link['user_email'] ?? 'User'} from this provider?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await AuthService.unlinkUserFromProvider(
        link['user_id'],
        link['provider_id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "User unlinked successfully!"
                : "Failed to unlink user. Please try again."),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadProviderLinks();
          _loadAllLinks();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking user: $e')),
        );
      }
    }
  }

  // ========== TAB 3: VIEW ALL LINKS ==========
  Future<void> _loadAllLinks() async {
    setState(() => isLoadingAllLinks = true);
    try {
      final result = await AuthService.getAllLinks(
        page: allLinksPage,
        pageSize: 20,
      );

      if (mounted && result != null) {
        setState(() {
          allLinks = (result['links'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          allLinksTotal = result['total'] ?? 0;
          allLinksTotalPages = result['total_pages'] ?? 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading all links: $e')),
        );
      }
    } finally {
      setState(() => isLoadingAllLinks = false);
    }
  }

  Future<void> _deleteLinkFromAllView(Map<String, dynamic> link) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink User from Provider'),
        content: Text(
          'Are you sure you want to unlink ${link['user_name'] ?? link['user_email'] ?? 'User'} from provider ${link['provider_id']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await AuthService.unlinkUserFromProvider(
        link['user_id'],
        link['provider_id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "User unlinked successfully!"
                : "Failed to unlink user. Please try again."),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadAllLinks();
          if (selectedProviderForView != null) {
            _loadProviderLinks();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User-Provider Links"),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.link), text: 'Create/Delete'),
            Tab(icon: Icon(Icons.business), text: 'By Provider'),
            Tab(icon: Icon(Icons.list), text: 'All Links'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateDeleteTab(),
          _buildProviderViewTab(),
          _buildAllLinksTab(),
        ],
      ),
    );
  }

  Widget _buildCreateDeleteTab() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                if (selectedUser != null && existingLinkedProvider != null) ...[
                  Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Text(
                                "Existing Link",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      existingLinkedProvider!['provider_name'] ?? 'Unknown Provider',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (existingLinkedProvider!['location']?['area'] != null)
                                      Text(
                                        existingLinkedProvider!['location']?['area'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: isDeleting ? null : _unlinkUser,
                                icon: isDeleting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.delete_outline, size: 18),
                                label: Text(isDeleting ? 'Deleting...' : 'Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                if (selectedUser != null && existingLinkedProvider == null) ...[
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
                ],
              ],
            ),
          );
  }

  Widget _buildProviderViewTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Provider",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _showProviderSelectorForView,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: selectedProviderForView == null
                        ? Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(
                                "Search and select a provider",
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
                                backgroundColor: Colors.blue,
                                child: Text(
                                  selectedProviderForView!['provider_name']?.substring(0, 1).toUpperCase() ?? 'P',
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
                                      selectedProviderForView!['provider_name'] ?? 'Unknown Provider',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      selectedProviderForView!['location']?['area'] ?? 'Nairobi',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
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
                if (selectedProviderForView != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Links: $providerLinksTotal",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (providerLinksTotalPages > 1)
                        Text(
                          "Page $providerLinksPage of $providerLinksTotalPages",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: selectedProviderForView == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "Select a provider to view linked users",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : isLoadingProviderLinks
                  ? const Center(child: CircularProgressIndicator())
                  : providerLinks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                "No users linked to this provider",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: providerLinks.length,
                                itemBuilder: (context, index) {
                                  final link = providerLinks[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Text(
                                          _getUserInitialsFromLink(link),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        link['user_name'] ?? link['user_email'] ?? 'Unknown User',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (link['user_email'] != null)
                                            Text(link['user_email']),
                                          if (link['user_phone'] != null)
                                            Text(link['user_phone']),
                                          if (link['created_at'] != null)
                                            Text(
                                              'Linked: ${_formatDate(link['created_at'])}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteLinkFromProviderView(link),
                                        tooltip: 'Unlink user',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (providerLinksTotalPages > 1)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: providerLinksPage > 1
                                          ? () {
                                              setState(() {
                                                providerLinksPage--;
                                              });
                                              _loadProviderLinks();
                                            }
                                          : null,
                                    ),
                                    Text(
                                      'Page $providerLinksPage of $providerLinksTotalPages',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: providerLinksPage < providerLinksTotalPages
                                          ? () {
                                              setState(() {
                                                providerLinksPage++;
                                              });
                                              _loadProviderLinks();
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildAllLinksTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "All User-Provider Links",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total: $allLinksTotal",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAllLinks,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: isLoadingAllLinks
              ? const Center(child: CircularProgressIndicator())
              : allLinks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "No links found",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _loadAllLinks,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: allLinks.length,
                            itemBuilder: (context, index) {
                              final link = allLinks[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      _getUserInitialsFromLink(link),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    link['user_name'] ?? link['user_email'] ?? 'Unknown User',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (link['user_email'] != null)
                                        Text(link['user_email']),
                                      Text(
                                        'Provider: ${link['provider_id']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (link['created_at'] != null)
                                        Text(
                                          'Linked: ${_formatDate(link['created_at'])}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteLinkFromAllView(link),
                                    tooltip: 'Unlink user',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (allLinksTotalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: allLinksPage > 1
                                      ? () {
                                          setState(() {
                                            allLinksPage--;
                                          });
                                          _loadAllLinks();
                                        }
                                      : null,
                                ),
                                Text(
                                  'Page $allLinksPage of $allLinksTotalPages',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: allLinksPage < allLinksTotalPages
                                      ? () {
                                          setState(() {
                                            allLinksPage++;
                                          });
                                          _loadAllLinks();
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
        ),
      ],
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

  String _getUserInitialsFromLink(Map<String, dynamic> link) {
    final name = link['user_name'] as String?;
    final email = link['user_email'] as String?;
    
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

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      if (date is String) {
        final dt = DateTime.parse(date);
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return date.toString();
    }
    return 'Unknown';
  }
}
