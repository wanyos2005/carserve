import 'package:flutter/material.dart';
import 'package:car_platform/components/modal_bottom_sheet.dart';
import 'package:car_platform/services/auth_service.dart';

class EnhancedUserSelector extends StatefulWidget {
  final Map<String, dynamic>? selectedUser;
  final Function(Map<String, dynamic>) onSelect;

  const EnhancedUserSelector({
    super.key,
    required this.selectedUser,
    required this.onSelect,
  });

  @override
  State<EnhancedUserSelector> createState() => _EnhancedUserSelectorState();
}

class _EnhancedUserSelectorState extends State<EnhancedUserSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  String _sortBy = 'name'; // name, email, created

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await AuthService.getAllUsers();
      setState(() {
        _users = users.cast<Map<String, dynamic>>();
        _filteredUsers = _users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _filteredUsers = _users);
      return;
    }

    if (query.trim().length < 2) {
      setState(() => _filteredUsers = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final searchResults = await AuthService.searchUsers(query);
      setState(() {
        _filteredUsers = searchResults.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> users) {
    final sorted = List<Map<String, dynamic>>.from(users);
    sorted.sort((a, b) {
      switch (_sortBy) {
        case 'email':
          final emailA = a['email'] ?? '';
          final emailB = b['email'] ?? '';
          return emailA.compareTo(emailB);
        case 'created':
          // Assuming we have a created_at field, otherwise use id as proxy
          final idA = a['id'] ?? 0;
          final idB = b['id'] ?? 0;
          return idB.compareTo(idA); // Descending (newest first)
        case 'name':
        default:
          final nameA = a['name'] ?? a['email'] ?? '';
          final nameB = b['name'] ?? b['email'] ?? '';
          return nameA.compareTo(nameB);
      }
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedUsers = _applySorting(_filteredUsers);

    return ModalBottomSheet(
      title: 'Select User',
      subtitle: '${sortedUsers.length} users found',
      content: Column(
        children: [
          // Search and sort controls
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search users...',
                    hintText: 'Enter email, name, or phone',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    _searchUsers(value);
                  },
                ),
                const SizedBox(height: 8),
                
                // Sort dropdown
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(value: 'created', child: Text('Recently Added')),
                  ],
                  onChanged: (value) => setState(() => _sortBy = value!),
                ),
              ],
            ),
          ),

          const Divider(),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.trim().isEmpty
                                  ? 'No users found'
                                  : 'No users match your search',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchController.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Try a different search term',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: sortedUsers.length,
                        itemBuilder: (context, index) {
                          final user = sortedUsers[index];
                          final isSelected = widget.selectedUser?['id'] == user['id'];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            color: isSelected ? Colors.blue[50] : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user['provider_id'] != null ? Colors.green : Colors.blue,
                                child: Text(
                                  _getUserInitials(user),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['name'] ?? user['email'] ?? 'Unknown User',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user['name'] != null && user['email'] != null)
                                    Text(user['email']),
                                  if (user['phone'] != null)
                                    Text('Phone: ${user['phone']}'),
                                  Row(
                                    children: [
                                      Icon(
                                        user['provider_id'] != null ? Icons.business : Icons.person,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user['provider_id'] != null ? 'Linked to Provider' : 'Regular User',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.blue)
                                  : null,
                              onTap: () {
                                widget.onSelect(user);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      footer: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: 16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.selectedUser != null
                ? () => Navigator.pop(context)
                : null,
            child: Text(
              widget.selectedUser != null
                  ? 'Confirm ${widget.selectedUser!['name'] ?? widget.selectedUser!['email']}'
                  : 'Select a User',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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
