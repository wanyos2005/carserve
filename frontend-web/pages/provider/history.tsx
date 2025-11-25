import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { 
  Calendar, 
  Wrench, 
  BarChart3,
  ArrowLeft,
  CheckCircle,
  Clock,
  XCircle,
  User,
  Car,
  MapPin,
  DollarSign,
  TrendingUp,
  MoreVertical,
  Play,
  Eye,
  Loader2
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';

interface Booking {
  id: string;
  user_id: number;
  vehicle_id: string;
  provider_id: string;
  service_id?: string;
  service_ids?: string[];
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
  service_id?: string;
  service_name?: string;
  mileage_km?: number;
  performed_at?: string;
  cost?: number;
  created_at: string;
}

const ProviderHistory: React.FC = () => {
  const router = useRouter();
  const [providerId, setProviderId] = useState<string>('');
  const [activeTab, setActiveTab] = useState<'bookings' | 'logs' | 'analytics'>('bookings');
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [serviceLogs, setServiceLogs] = useState<ServiceLog[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  // Lookup caches for customer names and vehicle info (like Flutter)
  const [customers, setCustomers] = useState<Map<string, string>>(new Map());
  const [vehicles, setVehicles] = useState<Map<string, any>>(new Map());
  const [services, setServices] = useState<Map<string, string>>(new Map());
  const [updatingBookingId, setUpdatingBookingId] = useState<string | null>(null);
  const [statusChangeDialog, setStatusChangeDialog] = useState<{ booking: Booking | null; show: boolean }>({ booking: null, show: false });

  useEffect(() => {
    const storedProviderId = localStorage.getItem('providerId') || router.query.providerId as string;
    console.log('🔍 [History] Checking provider ID - Storage:', localStorage.getItem('providerId'), 'Query:', router.query.providerId, 'Resolved:', storedProviderId);
    if (storedProviderId) {
      console.log('✅ [History] Setting provider ID:', storedProviderId);
      setProviderId(storedProviderId);
    } else {
      console.warn('⚠️ [History] No provider ID found! Storage:', localStorage.getItem('providerId'), 'Query:', router.query.providerId);
    }
  }, [router.query.providerId]);

  // API calls - use stats API like Flutter app
  const { data: statsData, loading: statsLoading, refetch: refetchStats } = useApi(providerId ? `/api/service-provider-service/providers/${providerId}/stats` : '');
  const { data: bookingsData, loading: bookingsLoading, refetch: refetchBookings } = useApi(providerId ? `/api/bookings/provider/${providerId}` : '');
  const { data: serviceLogsData, loading: serviceLogsLoading } = useApi(providerId ? `/api/service-logs/provider/${providerId}` : '');

  // Load customer names (like Flutter _loadCustomerNames)
  const loadCustomerNames = async (userIds: number[]) => {
    if (userIds.length === 0) return;

    try {
      console.log('👤 [History] Loading customer names for user IDs:', userIds);
      
      const token = localStorage.getItem('token');
      const response = await fetch('/api/users/lookup', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        },
        body: JSON.stringify(userIds),
      });

      if (response.ok) {
        const users = await response.json();
        console.log('👤 [History] Received users from lookup:', users);
        
        const customerMap = new Map<string, string>();
        for (const user of users) {
          const userId = user.id?.toString();
          if (userId) {
            // Prefer name, then email, then phone as fallback (like Flutter)
            let name = 'Unknown Customer';
            if (user.name && user.name.trim()) {
              name = user.name.trim();
            } else if (user.email && user.email.trim()) {
              name = user.email.trim();
            } else if (user.phone && user.phone.trim()) {
              name = user.phone.trim();
            }
            customerMap.set(userId, name);
            console.log('✅ [History] Mapped user', userId, 'to name:', name);
          }
        }

        // Fallback for any remaining user IDs
        for (const userId of userIds) {
          if (!customerMap.has(userId.toString())) {
            customerMap.set(userId.toString(), `Customer (ID: ${userId})`);
            console.log('⚠️ [History] Fallback mapping for user', userId);
          }
        }

        setCustomers(prev => {
          const merged = new Map(prev);
          customerMap.forEach((value, key) => merged.set(key, value));
          return merged;
        });
        console.log('📋 [History] Final customer map size:', customerMap.size);
      } else {
        console.error('❌ [History] Failed to load customer names:', response.status);
        // Fallback to generic names
        const customerMap = new Map<string, string>();
        userIds.forEach(id => customerMap.set(id.toString(), `Customer (ID: ${id})`));
        setCustomers(prev => {
          const merged = new Map(prev);
          customerMap.forEach((value, key) => merged.set(key, value));
          return merged;
        });
      }
    } catch (error) {
      console.error('❌ [History] Error loading customer names:', error);
      // Fallback to generic names
      const customerMap = new Map<string, string>();
      userIds.forEach(id => customerMap.set(id.toString(), `Customer (ID: ${id})`));
      setCustomers(prev => {
        const merged = new Map(prev);
        customerMap.forEach((value, key) => merged.set(key, value));
        return merged;
      });
    }
  };

  // Load vehicle info (like Flutter _loadProviderVehicleInfo)
  const loadVehicleInfo = async (vehicleIds: string[]) => {
    if (vehicleIds.length === 0) return;

    try {
      console.log('🚗 [History] Loading vehicle info for vehicle IDs:', vehicleIds);
      
      const token = localStorage.getItem('token');
      const vehicleMap = new Map<string, any>();

      for (const vehicleId of vehicleIds) {
        try {
          const response = await fetch(`/api/vehicles/public/${vehicleId}`, {
            headers: {
              'Content-Type': 'application/json',
              ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
            },
          });

          if (response.ok) {
            const vehicle = await response.json();
            vehicleMap.set(vehicleId, vehicle);
            const plate = vehicle.plate || 'No Plate';
            const make = vehicle.make || 'Unknown Make';
            const model = vehicle.model || 'Unknown Model';
            console.log('✅ [History] Loaded vehicle', vehicleId, ':', plate, make, model);
          } else {
            console.log('⚠️ [History] Vehicle', vehicleId, 'not found - storing placeholder');
            vehicleMap.set(vehicleId, { plate: 'Unknown', make: '', model: '', yom: null });
          }
        } catch (error) {
          console.error('❌ [History] Error loading vehicle', vehicleId, ':', error);
          vehicleMap.set(vehicleId, { plate: 'Unknown', make: '', model: '', yom: null });
        }
      }

      setVehicles(prev => {
        const merged = new Map(prev);
        vehicleMap.forEach((value, key) => merged.set(key, value));
        return merged;
      });
      console.log('📋 [History] Final vehicle map size:', vehicleMap.size);
    } catch (error) {
      console.error('❌ [History] Error loading vehicle info:', error);
    }
  };

  // Load service info (like Flutter _loadProviderServiceInfo)
  const loadServiceInfo = async (serviceIds: string[]) => {
    if (serviceIds.length === 0) return;

    try {
      console.log('⚙️ [History] Loading service info for service IDs:', serviceIds);
      
      // Load provider's services to get service names
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/service-provider-service/providers/${providerId}/services`, {
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        },
      });

      if (response.ok) {
        const providerServices = await response.json();
        const serviceMap = new Map<string, string>();
        
        for (const ps of providerServices) {
          const serviceId = ps.service_id?.toString();
          if (serviceId && serviceIds.includes(serviceId)) {
            const serviceName = ps.display_name || ps.service?.name || 'Unknown Service';
            serviceMap.set(serviceId, serviceName);
          }
        }

        setServices(prev => {
          const merged = new Map(prev);
          serviceMap.forEach((value, key) => merged.set(key, value));
          return merged;
        });
        console.log('📋 [History] Final service map size:', serviceMap.size);
      }
    } catch (error) {
      console.error('❌ [History] Error loading service info:', error);
    }
  };

  // Load customer names, vehicle info, and service names (like Flutter _loadProviderLookupData)
  const loadLookupData = async (bookingsList: Booking[], logsList: ServiceLog[]) => {
    console.log('🔍 [History] Loading lookup data for', bookingsList.length, 'bookings and', logsList.length, 'logs');
    
    // Collect unique IDs
    const userIds = new Set<number>();
    const vehicleIds = new Set<string>();
    const serviceIds = new Set<string>();

    for (const booking of bookingsList) {
      if (booking.user_id) userIds.add(booking.user_id);
      if (booking.vehicle_id) vehicleIds.add(booking.vehicle_id);
      if (booking.service_id) serviceIds.add(booking.service_id);
      if (booking.service_ids && Array.isArray(booking.service_ids)) {
        booking.service_ids.forEach(id => serviceIds.add(id));
      }
    }

    for (const log of logsList) {
      if (log.user_id) userIds.add(log.user_id);
      if (log.vehicle_id) vehicleIds.add(log.vehicle_id);
      if (log.service_id) serviceIds.add(log.service_id);
    }

    console.log('🔍 [History] Collected IDs - Users:', Array.from(userIds), 'Vehicles:', Array.from(vehicleIds), 'Services:', Array.from(serviceIds));

    // Load all lookup data in parallel
    await Promise.all([
      loadCustomerNames(Array.from(userIds)),
      loadVehicleInfo(Array.from(vehicleIds)),
      loadServiceInfo(Array.from(serviceIds)),
    ]);
  };

  // Log stats data when it loads
  useEffect(() => {
    if (statsData) {
      console.log('📊 [History] Stats data loaded:', statsData);
      console.log('📊 [History] Provider type:', (statsData as any).provider_type);
    }
  }, [statsData]);

  // Load lookup data when bookings/logs load (like Flutter does)
  useEffect(() => {
    if (bookingsData && Array.isArray(bookingsData)) {
      console.log('📅 [History] Bookings loaded:', bookingsData.length);
      setBookings(bookingsData);
      loadLookupData(bookingsData, serviceLogs || []);
    }
    if (serviceLogsData && Array.isArray(serviceLogsData)) {
      console.log('🔧 [History] Service logs loaded:', serviceLogsData.length);
      setServiceLogs(serviceLogsData);
      loadLookupData(bookings || [], serviceLogsData);
    }
    setIsLoading(statsLoading || bookingsLoading || serviceLogsLoading);
  }, [bookingsData, serviceLogsData, statsData, statsLoading, bookingsLoading, serviceLogsLoading]);

  // Format vehicle name (like Flutter _formatVehicleName)
  const formatVehicleName = (vehicle: any): string => {
    if (!vehicle) return 'Unknown Vehicle';
    
    const plate = (vehicle.plate || '').trim();
    const make = (vehicle.make || '').trim();
    const model = (vehicle.model || '').trim();
    const year = vehicle.yom ? vehicle.yom.toString().trim() : '';

    if (!plate && !make && !model && !year) {
      return 'Unknown Vehicle';
    }

    const details = [make, model, year].filter(s => s).join(' ');
    
    if (details) {
      return plate ? `${plate} (${details})` : details;
    }
    
    return plate || 'Unknown Vehicle';
  };

  // Get service names (like Flutter _getServiceNames)
  const getServiceNames = (booking: Booking): string => {
    if (booking.service_ids && Array.isArray(booking.service_ids) && booking.service_ids.length > 0) {
      const names = booking.service_ids
        .map(id => services.get(id) || 'Unknown')
        .filter(name => name !== 'Unknown');
      return names.length > 0 ? names.join(', ') : 'Unknown';
    } else if (booking.service_id) {
      return services.get(booking.service_id) || 'Unknown';
    }
    return 'N/A';
  };

  const getStatusColor = (status: string) => {
    const statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'completed': return 'bg-green-100 text-green-800 border-green-200';
      case 'accepted': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'confirmed': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'in_progress': return 'bg-purple-100 text-purple-800 border-purple-200';
      case 'pending': return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'cancelled': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const formatDate = (dateStr?: string) => {
    if (!dateStr) return 'N/A';
    try {
      const date = new Date(dateStr);
      return date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch (e) {
      return dateStr;
    }
  };

  const formatCurrency = (amount?: number) => {
    if (!amount) return 'N/A';
    return `KES ${amount.toLocaleString()}`;
  };

  // Handle booking status change (like Flutter _handleStatusChange)
  const handleStatusChange = async (bookingId: string, newStatus: string, booking: Booking) => {
    try {
      console.log(`🔄 [History] Changing booking ${bookingId} status to: ${newStatus}`);
      setUpdatingBookingId(bookingId);

      const token = localStorage.getItem('token');
      const response = await fetch(`/api/bookings/${bookingId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({ status: newStatus }),
      });

      if (response.ok) {
        const updatedBooking = await response.json();
        console.log(`✅ [History] Booking ${bookingId} updated successfully`);
        
        // Update the booking in the local state
        setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, status: updatedBooking.status } : b));
        
        // Refresh bookings to get latest data
        await refetchBookings();
        await refetchStats();
        
        // Show success message
        alert(`Booking status changed to ${newStatus.replace('_', ' ')} successfully!`);
      } else {
        const errorData = await response.json().catch(() => ({ error: 'Failed to change booking status' }));
        console.error(`❌ [History] Failed to update booking ${bookingId}:`, errorData);
        alert(errorData.error || errorData.detail || 'Failed to change booking status');
      }
    } catch (error) {
      console.error('❌ [History] Error changing booking status:', error);
      alert('Error changing booking status. Please try again.');
    } finally {
      setUpdatingBookingId(null);
      setStatusChangeDialog({ booking: null, show: false });
    }
  };

  // Handle booking action (like Flutter _handleBookingAction)
  const handleBookingAction = async (action: string, booking: Booking) => {
    const bookingId = booking.id;
    if (!bookingId) return;

    try {
      let newStatus = '';
      switch (action) {
        case 'accept':
          newStatus = 'accepted';
          break;
        case 'cancel':
          newStatus = 'cancelled';
          break;
        case 'start':
          newStatus = 'in_progress';
          break;
        case 'complete':
          newStatus = 'completed';
          break;
        case 'view':
          // Show booking details (could be a modal)
          alert(`Booking Details:\nID: ${booking.id}\nStatus: ${booking.status}\nVehicle: ${vehicles.get(booking.vehicle_id || '') ? formatVehicleName(vehicles.get(booking.vehicle_id || '')) : 'Unknown'}\nService: ${getServiceNames(booking)}\nScheduled: ${formatDate(booking.scheduled_at)}`);
          return;
        default:
          return;
      }

      await handleStatusChange(bookingId, newStatus, booking);
    } catch (error) {
      console.error('Error handling booking action:', error);
      alert('Error performing action. Please try again.');
    }
  };

  // Show status change dialog (like Flutter _showStatusChangeDialog)
  const showStatusChangeDialog = (booking: Booking) => {
    setStatusChangeDialog({ booking, show: true });
  };

  // Get available status transitions (like Flutter)
  const getAvailableStatuses = (currentStatus: string) => {
    const statusLower = currentStatus.toLowerCase();
    switch (statusLower) {
      case 'pending':
        return [
          { status: 'accepted', label: 'Accept', icon: CheckCircle, color: 'green' },
          { status: 'cancelled', label: 'Cancel', icon: XCircle, color: 'red' },
        ];
      case 'accepted':
        return [
          { status: 'in_progress', label: 'Start Service', icon: Play, color: 'blue' },
          { status: 'cancelled', label: 'Cancel', icon: XCircle, color: 'red' },
        ];
      case 'in_progress':
        return [
          { status: 'completed', label: 'Complete', icon: CheckCircle, color: 'green' },
        ];
      case 'completed':
      case 'cancelled':
        return []; // No status changes allowed
      default:
        return [
          { status: 'accepted', label: 'Accept', icon: CheckCircle, color: 'green' },
          { status: 'cancelled', label: 'Cancel', icon: XCircle, color: 'red' },
        ];
    }
  };

  // Build booking status chip (like Flutter _buildBookingStatusChip)
  const buildBookingStatusChip = (booking: Booking) => {
    const status = booking.status?.toLowerCase() || '';
    const availableStatuses = getAvailableStatuses(status);
    const canChangeStatus = availableStatuses.length > 0;

    const statusColors: Record<string, { bg: string; text: string; border: string }> = {
      completed: { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-300' },
      accepted: { bg: 'bg-blue-100', text: 'text-blue-800', border: 'border-blue-300' },
      in_progress: { bg: 'bg-purple-100', text: 'text-purple-800', border: 'border-purple-300' },
      pending: { bg: 'bg-gray-100', text: 'text-gray-800', border: 'border-gray-300' },
      cancelled: { bg: 'bg-red-100', text: 'text-red-800', border: 'border-red-300' },
    };

    const colors = statusColors[status] || statusColors.pending;

    return (
      <button
        onClick={() => canChangeStatus && showStatusChangeDialog(booking)}
        disabled={!canChangeStatus || updatingBookingId === booking.id}
        className={`h-10 px-4 rounded-full border flex items-center justify-center text-sm font-bold transition-all ${
          canChangeStatus ? 'cursor-pointer hover:shadow-md active:scale-95' : 'cursor-default'
        } ${colors.bg} ${colors.text} ${colors.border} ${updatingBookingId === booking.id ? 'opacity-50' : ''}`}
        title={canChangeStatus ? 'Tap to change status' : ''}
      >
        {updatingBookingId === booking.id ? (
          <div className="flex items-center space-x-2">
            <Loader2 className="h-4 w-4 animate-spin" />
            <span>Updating...</span>
          </div>
        ) : (
          <span>{booking.status?.replace('_', ' ') || 'Unknown'}</span>
        )}
      </button>
    );
  };

  // Build booking action buttons (like Flutter _buildBookingActionButtons)
  const buildBookingActionButtons = (booking: Booking) => {
    const status = booking.status?.toLowerCase() || '';
    const availableStatuses = getAvailableStatuses(status);

    if (availableStatuses.length === 0 && status !== 'completed' && status !== 'cancelled') {
      return null;
    }

    return (
      <div className="relative">
        <button
          onClick={(e) => {
            e.stopPropagation();
            if (status === 'completed' || status === 'cancelled') {
              handleBookingAction('view', booking);
            } else {
              showStatusChangeDialog(booking);
            }
          }}
          className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
          title="More actions"
        >
          <MoreVertical className="h-5 w-5" />
        </button>
      </div>
    );
  };

  // Use stats from API (like Flutter app does) - fallback to calculated if API fails
  // Backend stats API returns: active_bookings, todays_earnings, pending_tasks, total_services_today, completed_services_today, rating
  const stats = statsData as any;
  const analytics = stats ? {
    totalBookings: stats.active_bookings ?? bookings.length,
    completedBookings: stats.completed_services_today ?? bookings.filter(b => b.status?.toLowerCase() === 'completed').length,
    pendingBookings: stats.pending_tasks ?? bookings.filter(b => {
      const status = b.status?.toLowerCase();
      return status === 'pending' || status === 'confirmed';
    }).length,
    totalRevenue: stats.todays_earnings ?? serviceLogs.reduce((sum, log) => sum + (Number(log.cost) || 0), 0),
    totalServices: stats.total_services_today ?? serviceLogs.length,
    averageServiceCost: serviceLogs.length > 0 
      ? serviceLogs.reduce((sum, log) => sum + (Number(log.cost) || 0), 0) / serviceLogs.length 
      : 0,
  } : {
    // Fallback to calculated if stats API not available
    totalBookings: bookings.length,
    completedBookings: bookings.filter(b => b.status?.toLowerCase() === 'completed').length,
    pendingBookings: bookings.filter(b => {
      const status = b.status?.toLowerCase();
      return status === 'pending' || status === 'confirmed';
    }).length,
    totalRevenue: serviceLogs.reduce((sum, log) => sum + (Number(log.cost) || 0), 0),
    totalServices: serviceLogs.length,
    averageServiceCost: serviceLogs.length > 0 
      ? serviceLogs.reduce((sum, log) => sum + (Number(log.cost) || 0), 0) / serviceLogs.length 
      : 0,
  };

  if (!providerId) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Provider History</h2>
          <p className="text-gray-600 mb-6">Please log in as a service provider to access your history.</p>
          <Link href="/login">
            <button className="bg-red-600 text-white px-6 py-2 rounded-lg hover:bg-red-700 transition-colors">
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
          <div className="flex items-center justify-between py-4 sm:py-6">
            <div className="flex items-center space-x-4">
              <Link href={`/provider/dashboard${providerId ? `?providerId=${providerId}` : ''}`}>
                <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors" title="Back to Dashboard">
                  <ArrowLeft className="h-5 w-5" />
                </button>
              </Link>
              <div>
                <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold text-gray-900">WorkFlows</h1>
                <p className="text-sm sm:text-base text-gray-600 mt-1">View your bookings and service history</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6 lg:py-8">
        {/* Tabs */}
        <div className="bg-white rounded-lg shadow-sm mb-6">
          <div className="border-b border-gray-200">
            <nav className="flex -mb-px">
              <button
                onClick={() => setActiveTab('bookings')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === 'bookings'
                    ? 'border-red-600 text-red-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center space-x-2">
                  <Calendar className="h-5 w-5" />
                  <span>Bookings ({bookings.length})</span>
                </div>
              </button>
              <button
                onClick={() => setActiveTab('logs')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === 'logs'
                    ? 'border-red-600 text-red-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center space-x-2">
                  <Wrench className="h-5 w-5" />
                  <span>Service Logs ({serviceLogs.length})</span>
                </div>
              </button>
              <button
                onClick={() => setActiveTab('analytics')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === 'analytics'
                    ? 'border-red-600 text-red-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center space-x-2">
                  <BarChart3 className="h-5 w-5" />
                  <span>Analytics</span>
                </div>
              </button>
            </nav>
          </div>
        </div>

        {/* Content */}
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-600 mx-auto"></div>
              <p className="mt-4 text-gray-600">Loading history...</p>
            </div>
          </div>
        ) : (
          <>
            {activeTab === 'bookings' && (
              <div className="space-y-4">
                {bookings.length === 0 ? (
                  <div className="bg-white rounded-lg shadow-sm p-12 text-center">
                    <Calendar className="h-16 w-16 text-gray-400 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">No bookings found</h3>
                    <p className="text-gray-600">Your bookings will appear here when customers book your services.</p>
                  </div>
                ) : (
                  bookings.map((booking) => {
                    const customerName = customers.get(booking.user_id?.toString() || '') || `Customer (ID: ${booking.user_id})`;
                    const vehicle = vehicles.get(booking.vehicle_id || '');
                    const vehicleInfo = vehicle ? formatVehicleName(vehicle) : (booking.vehicle_id || 'Unknown Vehicle');
                    const serviceName = getServiceNames(booking);
                    
                    return (
                      <div key={booking.id} className="bg-white rounded-lg shadow-sm p-6">
                        {/* Customer Name */}
                        <div className="flex items-center space-x-3 mb-4">
                          <User className="h-5 w-5 text-gray-500" />
                          <h3 className="font-semibold text-gray-900">{customerName}</h3>
                        </div>
                        
                        {/* Vehicle */}
                        <div className="flex items-center space-x-3 mb-4">
                          <Car className="h-5 w-5 text-gray-500" />
                          <span className="text-sm text-gray-700">{vehicleInfo}</span>
                        </div>
                        
                        {/* Service */}
                        <div className="flex items-center space-x-3 mb-4">
                          <Wrench className="h-5 w-5 text-gray-500" />
                          <span className="text-sm text-gray-700">{serviceName}</span>
                        </div>
                        
                        {/* Scheduled Time */}
                        <div className="flex items-center space-x-3 mb-4">
                          <Calendar className="h-5 w-5 text-gray-500" />
                          <span className="text-sm text-gray-600">Scheduled: {formatDate(booking.scheduled_at)}</span>
                        </div>
                        
                        {/* Status and Actions */}
                        <div className="flex items-center space-x-3 mt-4 pt-4 border-t border-gray-200">
                          <div className="flex-1">
                            {buildBookingStatusChip(booking)}
                          </div>
                          {buildBookingActionButtons(booking)}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            )}

            {/* Status Change Dialog */}
            {statusChangeDialog.show && statusChangeDialog.booking && (
              <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                <div className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full mx-4">
                  <h3 className="text-lg font-bold text-gray-900 mb-4">
                    Change Status - {statusChangeDialog.booking.status}
                  </h3>
                  <div className="space-y-2">
                    {getAvailableStatuses(statusChangeDialog.booking.status).map((statusOption) => {
                      const IconComponent = statusOption.icon;
                      const colorClasses: Record<string, string> = {
                        green: 'text-green-600 hover:bg-green-50',
                        red: 'text-red-600 hover:bg-red-50',
                        blue: 'text-blue-600 hover:bg-blue-50',
                      };
                      return (
                        <button
                          key={statusOption.status}
                          onClick={() => handleStatusChange(statusChangeDialog.booking!.id, statusOption.status, statusChangeDialog.booking!)}
                          disabled={updatingBookingId === statusChangeDialog.booking!.id}
                          className={`w-full flex items-center space-x-3 p-3 rounded-lg border transition-colors ${colorClasses[statusOption.color] || 'text-gray-600 hover:bg-gray-50'}`}
                        >
                          <IconComponent className="h-5 w-5" />
                          <span className="font-medium">{statusOption.label}</span>
                        </button>
                      );
                    })}
                  </div>
                  <div className="mt-6 flex space-x-3">
                    <button
                      onClick={() => setStatusChangeDialog({ booking: null, show: false })}
                      className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={() => {
                        setStatusChangeDialog({ booking: null, show: false });
                        handleBookingAction('view', statusChangeDialog.booking!);
                      }}
                      className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                    >
                      View Details
                    </button>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'logs' && (
              <div className="space-y-4">
                {serviceLogs.length === 0 ? (
                  <div className="bg-white rounded-lg shadow-sm p-12 text-center">
                    <Wrench className="h-16 w-16 text-gray-400 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">No service logs found</h3>
                    <p className="text-gray-600">Service logs will appear here when you complete services.</p>
                  </div>
                ) : (
                  serviceLogs.map((log) => {
                    const customerName = customers.get(log.user_id?.toString() || '') || `Customer (ID: ${log.user_id})`;
                    const vehicle = vehicles.get(log.vehicle_id || '');
                    const vehicleInfo = vehicle ? formatVehicleName(vehicle) : (log.vehicle_id || 'Unknown Vehicle');
                    
                    return (
                      <div key={log.id} className="bg-white rounded-lg shadow-sm p-6">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center space-x-3 mb-4">
                              <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                                <CheckCircle className="h-5 w-5 text-green-600" />
                              </div>
                              <div>
                                <h3 className="font-semibold text-gray-900">{log.service_name || 'Service'}</h3>
                                <p className="text-sm text-gray-600">Customer: {customerName}</p>
                              </div>
                            </div>
                            
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                              {log.vehicle_id && (
                                <div className="flex items-center space-x-2 text-sm text-gray-600">
                                  <Car className="h-4 w-4" />
                                  <span>Vehicle: {vehicleInfo}</span>
                                </div>
                              )}
                            {log.mileage_km && (
                              <div className="flex items-center space-x-2 text-sm text-gray-600">
                                <TrendingUp className="h-4 w-4" />
                                <span>Mileage: {log.mileage_km} km</span>
                              </div>
                            )}
                            {log.cost && (
                              <div className="flex items-center space-x-2 text-sm text-gray-600">
                                <DollarSign className="h-4 w-4" />
                                <span>{formatCurrency(Number(log.cost))}</span>
                              </div>
                            )}
                            <div className="flex items-center space-x-2 text-sm text-gray-600">
                              <Calendar className="h-4 w-4" />
                              <span>Performed: {formatDate(log.performed_at || log.created_at)}</span>
                            </div>
                          </div>
                        </div>
                        
                        <div className="ml-4">
                          <span className="px-3 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800 border border-green-200">
                            Completed
                          </span>
                        </div>
                      </div>
                    </div>
                    );
                  })
                )}
              </div>
            )}

            {activeTab === 'analytics' && (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <div className="bg-white rounded-lg shadow-sm p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-600">Total Bookings</p>
                      <p className="text-2xl font-bold text-gray-900 mt-2">{analytics.totalBookings}</p>
                    </div>
                    <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                      <Calendar className="h-6 w-6 text-blue-600" />
                    </div>
                  </div>
                </div>

                <div className="bg-white rounded-lg shadow-sm p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-600">Completed</p>
                      <p className="text-2xl font-bold text-gray-900 mt-2">{analytics.completedBookings}</p>
                    </div>
                    <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                      <CheckCircle className="h-6 w-6 text-green-600" />
                    </div>
                  </div>
                </div>

                <div className="bg-white rounded-lg shadow-sm p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-600">Pending</p>
                      <p className="text-2xl font-bold text-gray-900 mt-2">{analytics.pendingBookings}</p>
                    </div>
                    <div className="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
                      <Clock className="h-6 w-6 text-yellow-600" />
                    </div>
                  </div>
                </div>

                <div className="bg-white rounded-lg shadow-sm p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-600">Total Revenue</p>
                      <p className="text-2xl font-bold text-gray-900 mt-2">{formatCurrency(analytics.totalRevenue)}</p>
                    </div>
                    <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                      <DollarSign className="h-6 w-6 text-green-600" />
                    </div>
                  </div>
                </div>

                <div className="bg-white rounded-lg shadow-sm p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-600">Total Services</p>
                      <p className="text-2xl font-bold text-gray-900 mt-2">{analytics.totalServices}</p>
                    </div>
                    <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                      <Wrench className="h-6 w-6 text-purple-600" />
                    </div>
                  </div>
                </div>

                <div className="bg-white rounded-lg shadow-sm p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-600">Avg Service Cost</p>
                      <p className="text-2xl font-bold text-gray-900 mt-2">{formatCurrency(analytics.averageServiceCost)}</p>
                    </div>
                    <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
                      <TrendingUp className="h-6 w-6 text-orange-600" />
                    </div>
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default ProviderHistory;

