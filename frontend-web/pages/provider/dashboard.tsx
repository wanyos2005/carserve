import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { 
  Plus, 
  Edit, 
  Eye, 
  BarChart3, 
  Users, 
  Calendar, 
  Star,
  MapPin,
  Phone,
  Mail,
  Settings,
  Bell,
  TrendingUp,
  DollarSign,
  Clock,
  CheckCircle,
  AlertTriangle,
  Home
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';

// Updated interfaces to match backend schemas
interface ProviderStats {
  total_providers: number;
  active_providers: number;
  inactive_providers: number;
  service_categories: number;
  provider_categories: number;
  total_services: number;
}

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

const ProviderDashboard: React.FC = () => {
  const router = useRouter();
  const [stats, setStats] = useState<ProviderStats | null>(null);
  const [recentBookings, setRecentBookings] = useState<Booking[]>([]);
  const [services, setServices] = useState<ProviderService[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Get provider ID from router or localStorage (assuming it's stored there)
  const [providerId, setProviderId] = useState<string>('');

  useEffect(() => {
    // Get provider ID from localStorage or router query
    const storedProviderId = localStorage.getItem('providerId') || router.query.providerId as string;
    if (storedProviderId) {
      setProviderId(storedProviderId);
    }
  }, [router.query.providerId]);

  // Updated API calls to match backend endpoints
  const { data: statsData, loading: statsLoading } = useApi('/service-providers/stats');
  const { data: bookingsData, loading: bookingsLoading } = useApi(providerId ? `/bookings/provider/${providerId}` : '');
  const { data: servicesData, loading: servicesLoading } = useApi(providerId ? `/service-providers/${providerId}/services` : '');
  const { data: alertsData, loading: alertsLoading } = useApi('/service-logs/due');

  useEffect(() => {
    if (statsData && typeof statsData === 'object') setStats(statsData as ProviderStats);
    if (bookingsData && Array.isArray(bookingsData)) setRecentBookings(bookingsData);
    if (servicesData && Array.isArray(servicesData)) setServices(servicesData);
    if (alertsData && Array.isArray(alertsData)) setAlerts(alertsData);
  }, [statsData, bookingsData, servicesData, alertsData]);

  useEffect(() => {
    setIsLoading(statsLoading || bookingsLoading || servicesLoading || alertsLoading);
  }, [statsLoading, bookingsLoading, servicesLoading, alertsLoading]);

  // Calculate derived stats for display
  const displayStats = {
    totalBookings: recentBookings.length,
    completedBookings: recentBookings.filter(b => b.status
       === 'completed').length,
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

  const getAlertIcon = (type: string) => {
    switch (type) {
      case 'success': return <CheckCircle className="h-5 w-5 text-green-600" />;
      case 'warning': return <AlertTriangle className="h-5 w-5 text-yellow-600" />;
      case 'error': return <AlertTriangle className="h-5 w-5 text-red-600" />;
      default: return <Bell className="h-5 w-5 text-blue-600" />;
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading dashboard data...</p>
        </div>
      </div>
    );
  }

  // Handle case where provider ID is not available
  if (!providerId) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Provider Dashboard</h2>
          <p className="text-gray-600 mb-6">Please log in as a service provider to access your dashboard.</p>
          <Link href="/provider/login">
            <button className="bg-primary-600 text-white px-6 py-2 rounded-lg hover:bg-primary-700 transition-colors">
              Go to Login
            </button>
          </Link>
        </div>
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
              <h1 className="text-3xl font-bold text-gray-900">Provider Dashboard</h1>
              <p className="text-gray-600 mt-1">Manage your services and bookings</p>
            </div>
            <div className="flex items-center space-x-4">
              <Link href="/provider/homepage">
                <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
                  <Home className="h-5 w-5" />
                </button>
              </Link>
              <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
                <Bell className="h-5 w-5" />
              </button>
              <Link href="/provider/settings">
                <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
                  <Settings className="h-5 w-5" />
                </button>
              </Link>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Success Message */}
        {router.query.success && (
          <div className="mb-8 bg-green-50 border border-green-200 rounded-lg p-4">
            <div className="flex items-center space-x-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <span className="text-green-800 font-medium">
                Registration completed successfully! Welcome to DriveOn.
              </span>
            </div>
          </div>
        )}

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
                {alerts.length === 0 ? (
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

            <Link href="/provider/edit-provider">
              <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
                    <Edit className="h-5 w-5 text-orange-600" />
                  </div>
                  <div>
                    <h3 className="font-medium text-gray-900">Edit Services</h3>
                    <p className="text-sm text-gray-600">Manage service offerings</p>
                  </div>
                </div>
              </div>
            </Link>

            <Link href="/provider/manage-templates">
              <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
                    <Settings className="h-5 w-5 text-indigo-600" />
                  </div>
                  <div>
                    <h3 className="font-medium text-gray-900">Manage Templates</h3>
                    <p className="text-sm text-gray-600">Create service templates</p>
                  </div>
                </div>
              </div>
            </Link>

            <Link href="/provider/profile">
              <div className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                    <Users className="h-5 w-5 text-gray-600" />
                  </div>
                  <div>
                    <h3 className="font-medium text-gray-900">Business Profile</h3>
                    <p className="text-sm text-gray-600">Update business info</p>
                  </div>
                </div>
              </div>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProviderDashboard;
