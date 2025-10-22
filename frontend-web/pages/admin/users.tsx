import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { 
  Plus, 
  Edit, 
  Trash2, 
  Search, 
  Filter,
  User,
  Mail,
  Phone,
  Calendar,
  Shield,
  Building,
  MoreVertical,
  CheckCircle,
  XCircle
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';
import { apiRequest } from '../../lib/auth';

interface User {
  id: number;
  name: string;
  email: string;
  phone?: string;
  userType: 'carOwner' | 'provider' | 'admin';
  isActive: boolean;
  createdAt: string;
  lastLogin?: string;
  providerId?: number;
  providerName?: string;
}

interface AdminUser {
  id: number;
  name: string;
  email: string;
  createdAt: string;
  isActive: boolean;
}

const UsersPage: React.FC = () => {
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [adminUsers, setAdminUsers] = useState<AdminUser[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'carOwner' | 'provider' | 'admin'>('all');
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'inactive'>('all');
  const [showCreateAdmin, setShowCreateAdmin] = useState(false);
  const [newAdminEmail, setNewAdminEmail] = useState('');
  const [newAdminName, setNewAdminName] = useState('');

  // Use backend endpoints via proxy (nginx -> user_service)
  const { data: usersData, loading: usersLoading, refetch: refetchUsers } = useApi<any>('/api/users/all');
  const { data: adminData, loading: adminLoading, refetch: refetchAdmins } = useApi<any>('/api/users/admin/list');

  useEffect(() => {
    if (usersData) {
      // Users can come as an array or wrapped
      const list = Array.isArray(usersData) ? usersData : (usersData.users || []);
      setUsers(list);
    }
  }, [usersData]);

  useEffect(() => {
    if (adminData) {
      // Admins usually come as { admins: [...] }
      const list = Array.isArray(adminData) ? adminData : (adminData.admins || []);
      setAdminUsers(list);
    }
  }, [adminData]);

  useEffect(() => {
    setIsLoading(usersLoading || adminLoading);
  }, [usersLoading, adminLoading]);

  const filteredUsers = users.filter(user => {
    const searchLower = searchTerm.toLowerCase();
    const matchesSearch = 
      (user.name && user.name.toLowerCase().includes(searchLower)) ||
      user.email.toLowerCase().includes(searchLower) ||
      (user.phone && user.phone.toLowerCase().includes(searchLower));
    const matchesType = filterType === 'all' || user.userType === filterType;
    const matchesStatus = filterStatus === 'all' || 
                         (filterStatus === 'active' && user.isActive) ||
                         (filterStatus === 'inactive' && !user.isActive);
    return matchesSearch && matchesType && matchesStatus;
  });

  const handleCreateAdmin = async () => {
    if (!newAdminEmail.trim()) {
      alert('Email is required');
      return;
    }

    try {
      const response = await apiRequest(`/api/users/admin/create?email=${encodeURIComponent(newAdminEmail)}${newAdminName ? `&name=${encodeURIComponent(newAdminName)}` : ''}`, {
        method: 'POST',
      });

      if (response && response.ok) {
        setShowCreateAdmin(false);
        setNewAdminEmail('');
        setNewAdminName('');
        await refetchAdmins();
        alert('Admin privileges granted successfully');
      } else {
        alert('Failed to create admin');
      }
    } catch (error) {
      console.error('Error creating admin:', error);
      alert('Error creating admin');
    }
  };

  const handleRemoveAdmin = async (email: string) => {
    if (confirm(`Are you sure you want to remove admin privileges from ${email}?`)) {
      try {
        const response = await apiRequest(`/api/users/admin/remove?email=${encodeURIComponent(email)}`, {
          method: 'DELETE',
        });

        if (response && response.ok) {
          await refetchAdmins();
          alert('Admin privileges removed successfully');
        } else {
          alert('Failed to remove admin privileges');
        }
      } catch (error) {
        console.error('Error removing admin:', error);
        alert('Error removing admin');
      }
    }
  };

  const handleToggleUserStatus = async (userId: number, isActive: boolean) => {
    try {
      const response = await apiRequest(`/api/users/${userId}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ isActive }),
      });

      if (response && response.ok) {
        await refetchUsers();
      }
    } catch (error) {
      console.error('Error toggling user status:', error);
    }
  };

  const getUserTypeIcon = (userType: string) => {
    switch (userType) {
      case 'admin':
        return <Shield className="h-4 w-4 text-red-600" />;
      case 'provider':
        return <Building className="h-4 w-4 text-green-600" />;
      default:
        return <User className="h-4 w-4 text-blue-600" />;
    }
  };

  const getUserTypeColor = (userType: string) => {
    switch (userType) {
      case 'admin':
        return 'bg-red-100 text-red-800';
      case 'provider':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-blue-100 text-blue-800';
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">User Management</h1>
              <p className="text-gray-600 mt-1">Manage users, providers, and admin privileges</p>
            </div>
            <div className="flex items-center space-x-4">
              <Link href="/dashboard">
                <button className="text-gray-600 hover:text-gray-900 px-4 py-2 rounded-lg border border-gray-300 hover:border-gray-400 transition-colors">
                  Back to Dashboard
                </button>
              </Link>
              <button
                onClick={() => setShowCreateAdmin(true)}
                className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 transition-colors flex items-center"
              >
                <Plus className="h-4 w-4 mr-2" />
                Add Admin
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Admin Users Section */}
        <div className="bg-white rounded-xl shadow-sm mb-8">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">Admin Users ({adminUsers.length})</h2>
          </div>
          <div className="p-6">
            {adminUsers.length === 0 ? (
              <div className="text-center py-8">
                <Shield className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No admin users</h3>
                <p className="text-gray-600 mb-4">Add the first admin user to get started</p>
                <button
                  onClick={() => setShowCreateAdmin(true)}
                  className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 transition-colors"
                >
                  Add First Admin
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {adminUsers.map((admin) => (
                  <div key={admin.id} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                          <Shield className="h-5 w-5 text-red-600" />
                        </div>
                        <div>
                          <h3 className="font-medium text-gray-900">{admin.name || 'No name'}</h3>
                          <p className="text-sm text-gray-600">{admin.email}</p>
                        </div>
                      </div>
                      <button
                        onClick={() => handleRemoveAdmin(admin.email)}
                        className="p-2 text-red-400 hover:text-red-600 transition-colors"
                        title="Remove admin privileges"
                      >
                        <XCircle className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Regular Users Section */}
        <div className="bg-white rounded-xl shadow-sm">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-semibold text-gray-900">
                All Users ({filteredUsers.length})
              </h2>
            </div>
          </div>

          {/* Filters */}
          <div className="px-6 py-4 border-b border-gray-200 bg-gray-50">
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <input
                    type="text"
                    placeholder="Search by email or phone..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                  />
                </div>
              </div>
              <div className="flex space-x-2">
                <select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value as any)}
                  className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                >
                  <option value="all">All Types</option>
                  <option value="carOwner">Car Owners</option>
                  <option value="provider">Providers</option>
                  <option value="admin">Admins</option>
                </select>
                <select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value as any)}
                  className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                >
                  <option value="all">All Status</option>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>
            </div>
          </div>

          {/* Users List */}
          <div className="divide-y divide-gray-200">
            {filteredUsers.length === 0 ? (
              <div className="p-12 text-center">
                <User className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No users found</h3>
                <p className="text-gray-600">
                  {searchTerm || filterType !== 'all' || filterStatus !== 'all'
                    ? 'Try adjusting your search or filter criteria'
                    : 'No users have registered yet'}
                </p>
              </div>
            ) : (
              filteredUsers.map((user) => (
                <div key={user.id} className="p-6 hover:bg-gray-50 transition-colors">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <div className="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center">
                        {getUserTypeIcon(user.userType)}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center space-x-2 mb-1">
                          <h3 className="text-lg font-medium text-gray-900">{user.name || 'No name'}</h3>
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${getUserTypeColor(user.userType)}`}>
                            {user.userType === 'carOwner' ? 'Car Owner' : user.userType}
                          </span>
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                            user.isActive ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                          }`}>
                            {user.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </div>
                        <div className="flex items-center space-x-4 text-sm text-gray-600">
                          <div className="flex items-center space-x-1">
                            <Mail className="h-4 w-4" />
                            <span>{user.email}</span>
                          </div>
                          {user.phone && (
                            <div className="flex items-center space-x-1">
                              <Phone className="h-4 w-4" />
                              <span>{user.phone}</span>
                            </div>
                          )}
                          <div className="flex items-center space-x-1">
                            <Calendar className="h-4 w-4" />
                            <span>Joined {user.createdAt}</span>
                          </div>
                        </div>
                        {user.providerName && (
                          <p className="text-sm text-gray-600 mt-1">
                            Provider: {user.providerName}
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => handleToggleUserStatus(user.id, !user.isActive)}
                        className={`p-2 rounded-lg transition-colors ${
                          user.isActive 
                            ? 'text-yellow-600 hover:bg-yellow-50' 
                            : 'text-green-600 hover:bg-green-50'
                        }`}
                        title={user.isActive ? 'Deactivate User' : 'Activate User'}
                      >
                        {user.isActive ? <XCircle className="h-4 w-4" /> : <CheckCircle className="h-4 w-4" />}
                      </button>
                      <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
                        <MoreVertical className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Create Admin Modal */}
      {showCreateAdmin && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl max-w-md w-full mx-4">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-xl font-semibold text-gray-900">Add Admin User</h2>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Email Address *
                </label>
                <input
                  type="email"
                  required
                  value={newAdminEmail}
                  onChange={(e) => setNewAdminEmail(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                  placeholder="admin@driveon.com"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Display Name (Optional)
                </label>
                <input
                  type="text"
                  value={newAdminName}
                  onChange={(e) => setNewAdminName(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                  placeholder="John Doe"
                />
              </div>
              <div className="flex justify-end space-x-3 pt-4">
                <button
                  onClick={() => setShowCreateAdmin(false)}
                  className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCreateAdmin}
                  className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
                >
                  Grant Admin Privileges
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UsersPage;
