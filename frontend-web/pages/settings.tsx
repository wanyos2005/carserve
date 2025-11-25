import React, { useState } from 'react';
import { useRouter } from 'next/router';
import { useAuth } from '../lib/auth';
import Link from 'next/link';
import { 
  ArrowLeft,
  User,
  Bell,
  Shield,
  Settings as SettingsIcon,
  LogOut,
  Users,
  Clock,
  Wrench,
  CheckCircle
} from 'lucide-react';

const Settings: React.FC = () => {
  const router = useRouter();
  const { user, logout } = useAuth();
  
  // Helper to get dashboard URL with providerId
  const getDashboardUrl = () => {
    if (user?.providerId) {
      return `/provider/dashboard?providerId=${user.providerId}`;
    }
    return '/provider/dashboard'; // Fallback if no providerId
  };
  const [recommendedOnly, setRecommendedOnly] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  const handleLogout = async () => {
    setIsLoggingOut(true);
    try {
      await logout();
      router.push('/login');
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setIsLoggingOut(false);
    }
  };

  const showLogoutDialog = () => {
    if (window.confirm('Are you sure you want to logout? You\'ll need to sign in again to access your account.')) {
      handleLogout();
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center py-6">
            <Link href={getDashboardUrl()}>
              <button className="flex items-center text-gray-600 hover:text-gray-900 mr-4">
                <ArrowLeft className="h-5 w-5 mr-2" />
                Back to Dashboard
              </button>
            </Link>
            <div className="flex items-center">
              <SettingsIcon className="h-6 w-6 text-blue-600 mr-3" />
              <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="space-y-8">
          {/* Profile & Account Section */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Profile & Account</h2>
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                    <User className="h-6 w-6 text-blue-600" />
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">Profile Information</h3>
                    <p className="text-sm text-gray-600">Logged in as: {user?.name || 'User'}</p>
                    <p className="text-sm text-gray-500">Email: {user?.email}</p>
                    <p className="text-sm text-gray-500">Role: {user?.userType}</p>
                  </div>
                </div>
                <div className="mt-4">
                  <button className="text-blue-600 hover:text-blue-800 text-sm font-medium">
                    Edit Profile Information →
                  </button>
                </div>
              </div>
            </div>

            {/* Staff Management (for providers) */}
            {user?.userType === 'provider' && (
              <div className="mt-4 bg-white rounded-lg shadow-sm border">
                <div className="p-6">
                  <div className="flex items-center space-x-4">
                    <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                      <Users className="h-6 w-6 text-green-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-medium text-gray-900">Manage Staff</h3>
                      <p className="text-sm text-gray-600">Add and manage your team members</p>
                    </div>
                  </div>
                  <div className="mt-4">
                    <button className="text-green-600 hover:text-green-800 text-sm font-medium">
                      Manage Team Members →
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Service Settings */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Service Settings</h2>
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                    <Wrench className="h-6 w-6 text-blue-600" />
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">Service Categories</h3>
                    <p className="text-sm text-gray-600">Manage your preferred service types</p>
                  </div>
                </div>
                <div className="mt-4">
                  <button className="text-blue-600 hover:text-blue-800 text-sm font-medium">
                    Configure Service Preferences →
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Provider Filtering */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Provider Filtering</h2>
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <div className="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center">
                      <CheckCircle className="h-6 w-6 text-orange-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-medium text-gray-900">Show Recommended Providers Only</h3>
                      <p className="text-sm text-gray-600">Providers that offer ALL selected services</p>
                    </div>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      className="sr-only peer"
                      checked={recommendedOnly}
                      onChange={(e) => setRecommendedOnly(e.target.checked)}
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
              </div>
            </div>
          </div>

          {/* Alert Preferences */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Alert Preferences</h2>
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center">
                    <Bell className="h-6 w-6 text-orange-600" />
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">Alert Configuration</h3>
                    <p className="text-sm text-gray-600">Configure alert types and channels</p>
                  </div>
                </div>
                <div className="mt-4">
                  <button className="text-orange-600 hover:text-orange-800 text-sm font-medium">
                    Configure Alert Preferences →
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Time Slot Preferences (for providers) */}
          {user?.userType === 'provider' && (
            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Booking Settings</h2>
              <div className="bg-white rounded-lg shadow-sm border">
                <div className="p-6">
                  <div className="flex items-center space-x-4">
                    <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
                      <Clock className="h-6 w-6 text-purple-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-medium text-gray-900">Default Time Slots</h3>
                      <p className="text-sm text-gray-600">Set preferred booking times</p>
                    </div>
                  </div>
                  <div className="mt-4">
                    <button className="text-purple-600 hover:text-purple-800 text-sm font-medium">
                      Configure Time Slots →
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Security Settings */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Security</h2>
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                    <Shield className="h-6 w-6 text-red-600" />
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">Account Security</h3>
                    <p className="text-sm text-gray-600">Manage your account security settings</p>
                  </div>
                </div>
                <div className="mt-4">
                  <button className="text-red-600 hover:text-red-800 text-sm font-medium">
                    Security Settings →
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Logout Section */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Account Actions</h2>
            <div className="bg-white rounded-lg shadow-sm border border-red-200">
              <div className="p-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                    <LogOut className="h-6 w-6 text-red-600" />
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">Sign Out</h3>
                    <p className="text-sm text-gray-600">Sign out of your account</p>
                  </div>
                </div>
                <div className="mt-4">
                  <button
                    onClick={showLogoutDialog}
                    disabled={isLoggingOut}
                    className="bg-red-600 hover:bg-red-700 disabled:bg-red-300 text-white px-4 py-2 rounded-lg font-medium transition-colors"
                  >
                    {isLoggingOut ? 'Signing Out...' : 'Sign Out'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
