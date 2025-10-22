import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { useAuth } from '../lib/auth';
import { useApi } from '../hooks/useApi';
import Link from 'next/link';
import { 
  Users, 
  Building, 
  Settings, 
  BarChart3, 
  Bell, 
  Shield, 
  Activity,
  AlertTriangle,
  CheckCircle,
  Clock,
  TrendingUp,
  Calendar,
  DollarSign,
  Star,
  LogOut,
  Plus, 
  Edit, 
  Eye, 
  MapPin,
  Phone,
  Mail,
  Home
} from 'lucide-react';

interface UserStats {
  total_users: number;
  active_users: number;
  inactive_users: number;
  admin_users: number;
  provider_users: number;
  car_owner_users: number;
}

interface ProviderStats {
  total_providers: number;
  active_providers: number;
  inactive_providers: number;
  service_categories: number;
  provider_categories: number;
  total_services: number;
}

// Provider-specific interfaces
interface Booking {
  id: string;
  user_id: number;
  vehicle_id: string;
  provider_id: string;
  service_id?: string;
  status: string;
  scheduled_at?: string;
  location?: any;
  meta?: any;
  created_at?: string;
}

interface ServiceLog {
  id: string;
  user_id: number;
  vehicle_id?: string;
  provider_id?: string;
  provider_name?: string;
  provider_contact?: any;
  service_id?: string;
  service_name?: string;
  service_items?: any;
  mileage_km?: number;
  performed_at?: string;
  next_service_km?: number;
  next_service_date?: string;
  served_by?: string;
  served_by_contact?: string;
  cost?: number;
  logged_by?: string;
  notes?: string;
  created_at: string;
}

interface ProviderService {
  service_id: string;
  display_name?: string;
  price?: string;
  min_price?: number;
  max_price?: number;
  price_type?: string;
  currency?: string;
  unit?: string;
  negotiable?: boolean;
  duration?: string;
  booking_required?: boolean;
  metadata?: any;
  service?: {
    id: string;
    name: string;
    description?: string;
    category_id?: number;
    requirements?: any;
    created_at?: string;
  };
}

interface Alert {
  id: string;
  user_id: number;
  vehicle_id?: string;
  provider_id?: string;
  provider_name?: string;
  service_name?: string;
  current_mileage?: number;
  next_service_km?: number;
  next_service_date?: string;
  last_service_date?: string;
  service_type: string;
}

const Dashboard: React.FC = () => {
  const router = useRouter();
  const { user, isAuthenticated, isLoading } = useAuth();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login');
    }
  }, [isAuthenticated, isLoading, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  if (!isAuthenticated || !user) {
    return null;
  }

  const getDashboardContent = () => {
    switch (user.userType) {
      case 'admin':
        return <AdminDashboardContent />;
      case 'provider':
        return <ProviderDashboardContent />;
      default:
        return <CarOwnerDashboardContent />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
              <p className="text-gray-600 mt-1">
                Welcome back, {user.name}
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <span className="text-sm text-gray-600">Online</span>
              </div>
              <Link href="/settings">
                <button className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 transition-colors">
                  <Settings className="h-4 w-4 mr-2 inline" />
                  Settings
                </button>
              </Link>
              <button 
                onClick={() => {
                  if (window.confirm('Are you sure you want to logout?')) {
                    localStorage.removeItem('token');
                    window.location.href = '/login';
                  }
                }}
                className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
              >
                <LogOut className="h-4 w-4 mr-2 inline" />
                Logout
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {getDashboardContent()}
      </div>
    </div>
  );
};

// Admin Dashboard Content
const AdminDashboardContent: React.FC = () => {
  const { data: userStats, loading: userStatsLoading } = useApi<UserStats>('/api/users/stats');
  const { data: providerStats, loading: providerStatsLoading } = useApi<ProviderStats>('/api/service-providers/stats');

  const isLoading = userStatsLoading || providerStatsLoading;

  return (
    <>
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Users</p>
              <p className="text-3xl font-bold text-gray-900">
                {isLoading ? '...' : (userStats?.total_users || 0).toLocaleString()}
              </p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Users className="h-6 w-6 text-blue-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-green-600">
            <CheckCircle className="h-4 w-4 mr-1" />
            <span>{userStats?.active_users || 0} active</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Active Providers</p>
              <p className="text-3xl font-bold text-gray-900">
                {isLoading ? '...' : (providerStats?.active_providers || 0).toLocaleString()}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <Building className="h-6 w-6 text-green-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-gray-500">
            <span>{providerStats?.total_providers || 0} total providers</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Service Categories</p>
              <p className="text-3xl font-bold text-gray-900">
                {isLoading ? '...' : (providerStats?.service_categories || 0).toLocaleString()}
              </p>
            </div>
            <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
              <Settings className="h-6 w-6 text-orange-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-gray-500">
            <span>{providerStats?.total_services || 0} total services</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Admin Users</p>
              <p className="text-3xl font-bold text-gray-900">
                {isLoading ? '...' : (userStats?.admin_users || 0).toLocaleString()}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
              <Shield className="h-6 w-6 text-purple-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-blue-600">
            <Users className="h-4 w-4 mr-1" />
            <span>{userStats?.provider_users || 0} providers</span>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Link href="/admin/users">
          <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <Users className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">User Management</h3>
                <p className="text-sm text-gray-600">Manage users and permissions</p>
              </div>
            </div>
          </div>
        </Link>

        <Link href="/admin/providers">
          <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                <Building className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">Provider Management</h3>
                <p className="text-sm text-gray-600">Manage service providers</p>
              </div>
            </div>
          </div>
        </Link>

        <Link href="/admin/alert-rules">
          <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-yellow-100 rounded-lg flex items-center justify-center">
                <Bell className="h-5 w-5 text-yellow-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">Alert Rules</h3>
                <p className="text-sm text-gray-600">Configure alert rules</p>
              </div>
            </div>
          </div>
        </Link>

        <Link href="/admin/analytics">
          <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                <BarChart3 className="h-5 w-5 text-purple-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">Analytics</h3>
                <p className="text-sm text-gray-600">View platform metrics</p>
              </div>
            </div>
          </div>
        </Link>
      </div>
    </>
  );
};

// Provider Dashboard Content - Comprehensive Dashboard
const ProviderDashboardContent: React.FC = () => {
  const { user } = useAuth();
  const [providerId, setProviderId] = useState<string>('');
  const [recentBookings, setRecentBookings] = useState<Booking[]>([]);
  const [services, setServices] = useState<ProviderService[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Derive provider ID from authenticated user first, fallback to localStorage
  useEffect(() => {
    const idFromUser = (user?.providerId as string) || '';
    const storedProviderId = localStorage.getItem('providerId') || '';
    const resolved = idFromUser || storedProviderId;
    if (resolved && resolved !== providerId) {
      setProviderId(resolved);
      localStorage.setItem('providerId', resolved);
    }
  }, [user?.providerId]);

  // Fetch real data
  const { data: bookingsData, loading: bookingsLoading } = useApi(providerId ? `/bookings/provider/${providerId}` : '');
  const { data: servicesData, loading: servicesLoading } = useApi(providerId ? `/service-providers/${providerId}/services` : '');
  // Make alerts optional - don't block dashboard loading if alerts fail
  const { data: alertsData, loading: alertsLoading, error: alertsError } = useApi('/service-logs/due');

  useEffect(() => {
    if (bookingsData && Array.isArray(bookingsData)) setRecentBookings(bookingsData);
    if (servicesData && Array.isArray(servicesData)) setServices(servicesData);
    if (alertsData && Array.isArray(alertsData)) setAlerts(alertsData);
  }, [bookingsData, servicesData, alertsData]);

  useEffect(() => {
    setIsLoading(bookingsLoading || servicesLoading);
  }, [bookingsLoading, servicesLoading]);

  // Calculate derived stats for display
  const displayStats = {
    totalBookings: recentBookings.length,
    completedBookings: recentBookings.filter(b => b.status === 'completed').length,
    pendingBookings: recentBookings.filter(b => b.status === 'pending' || b.status === 'confirmed').length,
    totalRevenue: recentBookings
      .filter(b => b.status === 'completed')
      .reduce((sum, b) => sum + (b.meta?.cost || 0), 0),
    averageRating: 4.5, // This would need to be calculated from reviews
    totalReviews: 0, // This would need to be fetched from reviews service
    activeServices: services.length
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'text-green-600 bg-green-100';
      case 'confirmed': return 'text-blue-600 bg-blue-100';
      case 'in_progress': return 'text-yellow-600 bg-yellow-100';
      case 'pending': return 'text-gray-600 bg-gray-100';
      case 'cancelled': return 'text-red-600 bg-red-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading dashboard data...</p>
        </div>
      </div>
    );
  }

  return (
    <>
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Bookings</p>
              <p className="text-3xl font-bold text-gray-900">{displayStats.totalBookings}</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Calendar className="h-6 w-6 text-blue-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-green-600">
            <TrendingUp className="h-4 w-4 mr-1" />
            <span>Recent bookings</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Completed</p>
              <p className="text-3xl font-bold text-gray-900">{displayStats.completedBookings}</p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <CheckCircle className="h-6 w-6 text-green-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-gray-500">
            <span>Successfully completed</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Revenue</p>
              <p className="text-3xl font-bold text-gray-900">KSh {displayStats.totalRevenue.toLocaleString()}</p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <DollarSign className="h-6 w-6 text-green-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-green-600">
            <TrendingUp className="h-4 w-4 mr-1" />
            <span>From completed bookings</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Active Services</p>
              <p className="text-3xl font-bold text-gray-900">{displayStats.activeServices}</p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
              <Settings className="h-6 w-6 text-yellow-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-gray-500">
            <span>Services offered</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Recent Bookings */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-xl shadow-sm">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-semibold text-gray-900">Recent Bookings</h2>
                <Link href="/provider/bookings">
                  <button className="text-primary-600 hover:text-primary-700 font-medium">
                    View All
                  </button>
                </Link>
              </div>
            </div>
            <div className="p-6">
              {recentBookings.length === 0 ? (
                <div className="text-center py-8">
                  <Calendar className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No bookings yet</h3>
                  <p className="text-gray-600">Your bookings will appear here once customers start booking your services.</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {recentBookings.slice(0, 5).map((booking) => (
                    <div key={booking.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                      <div className="flex items-center space-x-4">
                        <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                          <Users className="h-5 w-5 text-primary-600" />
                        </div>
                        <div>
                          <h3 className="font-medium text-gray-900">User #{booking.user_id}</h3>
                          <p className="text-sm text-gray-600">Vehicle: {booking.vehicle_id}</p>
                          <p className="text-xs text-gray-500">
                            {booking.scheduled_at ? new Date(booking.scheduled_at).toLocaleDateString() : 'No date set'}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(booking.status)}`}>
                          {booking.status.replace('_', ' ')}
                        </span>
                        <p className="text-sm font-medium text-gray-900 mt-1">
                          {booking.meta?.cost ? `KSh ${booking.meta.cost.toLocaleString()}` : 'No cost set'}
                        </p>
                        <p className="text-xs text-gray-500">
                          {booking.created_at ? new Date(booking.created_at).toLocaleDateString() : 'No date'}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Alerts and Services */}
        <div className="space-y-6">
          {/* Alerts */}
          <div className="bg-white rounded-xl shadow-sm">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-lg font-semibold text-gray-900">Alerts</h2>
            </div>
            <div className="p-6">
              {alertsError ? (
                <div className="text-center py-4">
                  <AlertTriangle className="h-8 w-8 text-yellow-400 mx-auto mb-2" />
                  <p className="text-sm text-gray-600">Unable to load alerts</p>
                </div>
              ) : alerts.length === 0 ? (
                <div className="text-center py-4">
                  <Bell className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                  <p className="text-sm text-gray-600">No service alerts</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {alerts.slice(0, 3).map((alert) => (
                    <div key={alert.id} className="flex items-start space-x-3 p-3 bg-gray-50 rounded-lg">
                      <AlertTriangle className="h-5 w-5 text-yellow-600" />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900">
                          {alert.service_name || 'Service Due'}
                        </p>
                        <p className="text-xs text-gray-600">
                          Vehicle: {alert.vehicle_id} | Next service: {alert.next_service_date ? new Date(alert.next_service_date).toLocaleDateString() : 'Not set'}
                        </p>
                        <p className="text-xs text-gray-500 mt-1">
                          {alert.current_mileage ? `Current: ${alert.current_mileage}km` : ''}
                          {alert.next_service_km ? ` | Next: ${alert.next_service_km}km` : ''}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Services */}
          <div className="bg-white rounded-xl shadow-sm">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-gray-900">Your Services</h2>
                <Link href="/provider/services">
                  <button className="text-primary-600 hover:text-primary-700 text-sm font-medium">
                    Manage
                  </button>
                </Link>
              </div>
            </div>
            <div className="p-6">
              {services.length === 0 ? (
                <div className="text-center py-4">
                  <Settings className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                  <p className="text-sm text-gray-600 mb-3">No services added</p>
                  <Link href="/provider/services">
                    <button className="text-primary-600 hover:text-primary-700 text-sm font-medium">
                      Add Services
                    </button>
                  </Link>
                </div>
              ) : (
                <div className="space-y-3">
                  {services.slice(0, 3).map((service) => (
                    <div key={service.service_id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <div>
                        <h3 className="font-medium text-gray-900">
                          {service.display_name || service.service?.name || 'Service'}
                        </h3>
                        <p className="text-sm text-gray-600">
                          {service.price || 
                           (service.min_price && service.max_price ? 
                            `KSh ${service.min_price} - ${service.max_price}` : 
                            'Price not set')}
                        </p>
                        {service.duration && (
                          <p className="text-xs text-gray-500">{service.duration}</p>
                        )}
                      </div>
                      <div className="text-right">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          service.booking_required ? 'bg-blue-100 text-blue-800' : 'bg-green-100 text-green-800'
                        }`}>
                          {service.booking_required ? 'Booking Required' : 'Walk-in'}
                        </span>
                        <p className="text-xs text-gray-500 mt-1">
                          {service.currency || 'KES'} {service.unit || ''}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Link href="/provider/services">
            <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                  <Settings className="h-5 w-5 text-blue-600" />
                </div>
                <div>
                  <h3 className="font-medium text-gray-900">Manage Services</h3>
                  <p className="text-sm text-gray-600">Add or edit services</p>
                </div>
              </div>
            </div>
          </Link>

          <Link href="/provider/bookings">
            <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                  <Calendar className="h-5 w-5 text-green-600" />
                </div>
                <div>
                  <h3 className="font-medium text-gray-900">View Bookings</h3>
                  <p className="text-sm text-gray-600">Manage appointments</p>
                </div>
              </div>
            </div>
          </Link>

          <Link href="/provider/analytics">
            <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                  <BarChart3 className="h-5 w-5 text-purple-600" />
                </div>
                <div>
                  <h3 className="font-medium text-gray-900">Analytics</h3>
                  <p className="text-sm text-gray-600">View performance</p>
                </div>
              </div>
            </div>
          </Link>

          <Link href="/provider/profile">
            <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
                  <Users className="h-5 w-5 text-orange-600" />
                </div>
                <div>
                  <h3 className="font-medium text-gray-900">Edit Profile</h3>
                  <p className="text-sm text-gray-600">Update business info</p>
                </div>
              </div>
            </div>
          </Link>
        </div>
      </div>
    </>
  );
};

// Car Owner Dashboard Content
const CarOwnerDashboardContent: React.FC = () => {
  return (
    <>
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">My Vehicles</p>
              <p className="text-3xl font-bold text-gray-900">2</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Building className="h-6 w-6 text-blue-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-gray-500">
            <span>Registered vehicles</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Active Alerts</p>
              <p className="text-3xl font-bold text-gray-900">3</p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
              <Bell className="h-6 w-6 text-yellow-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-yellow-600">
            <AlertTriangle className="h-4 w-4 mr-1" />
            <span>Needs attention</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Service History</p>
              <p className="text-3xl font-bold text-gray-900">12</p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <CheckCircle className="h-6 w-6 text-green-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-gray-500">
            <span>Completed services</span>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Spent</p>
              <p className="text-3xl font-bold text-gray-900">KSh 45,000</p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <DollarSign className="h-6 w-6 text-green-600" />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm text-gray-500">
            <span>This year</span>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Link href="/vehicles">
          <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <Building className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">My Vehicles</h3>
                <p className="text-sm text-gray-600">Manage your cars</p>
              </div>
            </div>
          </div>
        </Link>

        <Link href="/alerts">
          <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-yellow-100 rounded-lg flex items-center justify-center">
                <Bell className="h-5 w-5 text-yellow-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">Alerts</h3>
                <p className="text-sm text-gray-600">View notifications</p>
              </div>
            </div>
          </div>
        </Link>

        <Link href="/services">
          <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                <Settings className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">Book Service</h3>
                <p className="text-sm text-gray-600">Find service providers</p>
              </div>
            </div>
          </div>
        </Link>

        <Link href="/profile">
          <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
                <Users className="h-5 w-5 text-orange-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">Profile</h3>
                <p className="text-sm text-gray-600">Manage account</p>
              </div>
            </div>
          </div>
        </Link>
      </div>
    </>
  );
};

export default Dashboard;
