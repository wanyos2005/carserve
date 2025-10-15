import 'package:flutter/material.dart';

class StaffManagementPage extends StatefulWidget {
  final String providerId;

  const StaffManagementPage({
    super.key,
    required this.providerId,
  });

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  List<Map<String, dynamic>> _staffMembers = [];
  bool _isLoading = false;
//we are not using dispose() because we are not using any controllers or other state management
  @override
  void initState() {
    super.initState();
    _loadStaffMembers();
  }

  Future<void> _loadStaffMembers() async {
    setState(() => _isLoading = true);
    
    // TODO: Replace with actual API call to fetch staff members
    // For now, we'll show a placeholder
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _staffMembers = [
        // Placeholder data - replace with real API call
        {
          'id': '1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'Mechanic',
          'phone': '+254 700 000 001',
          'isActive': true,
        },
        {
          'id': '2',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'role': 'Service Advisor',
          'phone': '+254 700 000 002',
          'isActive': true,
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff Management"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addStaffMember,
            tooltip: "Add Staff Member",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staffMembers.isEmpty
              ? _buildEmptyState()
              : _buildStaffList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStaffMember,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No Staff Members Yet",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your first team member to get started",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addStaffMember,
            icon: const Icon(Icons.person_add),
            label: const Text("Add Staff Member"),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staffMembers.length,
      itemBuilder: (context, index) {
        final staff = _staffMembers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: staff['isActive'] ? Colors.green : Colors.grey,
              child: Text(
                _getInitials(staff['name']),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              staff['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff['email']),
                Text(staff['role']),
                if (staff['phone'] != null) Text(staff['phone']),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    staff['isActive'] ? Icons.pause : Icons.play_arrow,
                    color: staff['isActive'] ? Colors.orange : Colors.green,
                  ),
                  onPressed: () => _toggleStaffStatus(staff),
                  tooltip: staff['isActive'] ? "Deactivate" : "Activate",
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editStaffMember(staff),
                  tooltip: "Edit",
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStaffMember(staff),
                  tooltip: "Delete",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  void _addStaffMember() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Staff Member"),
        content: const Text("Staff member management feature coming soon!\n\nYou'll be able to:\n• Add new team members\n• Assign roles and permissions\n• Manage access levels\n• Track staff performance"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _editStaffMember(Map<String, dynamic> staff) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Edit ${staff['name']} - Coming soon!")),
    );
  }

  void _deleteStaffMember(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Staff Member"),
        content: Text("Are you sure you want to remove ${staff['name']} from your team?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${staff['name']} removed - Coming soon!")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _toggleStaffStatus(Map<String, dynamic> staff) {
    setState(() {
      staff['isActive'] = !staff['isActive'];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${staff['name']} ${staff['isActive'] ? 'activated' : 'deactivated'} - Coming soon!",
        ),
      ),
    );
  }
}
