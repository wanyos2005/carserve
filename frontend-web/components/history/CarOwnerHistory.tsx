import React, { useState, useEffect } from 'react';
import { 
  Calendar, 
  Wrench, 
  Building,
  Car,
  Clock,
  CheckCircle,
  User,
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';
import { useAuth } from '../../lib/auth';

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

interface Vehicle {
  id: string;
  plate?: string;
  make?: string;
  model?: string;
  yom?: number;
}

const CarOwnerHistory: React.FC = () => {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'bookings' | 'logs'>('bookings');
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [serviceLogs, setServiceLogs] = useState<ServiceLog[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  // Lookup caches (like Flutter)
  const [providers, setProviders] = useState<Map<string, string>>(new Map());
  const [vehicles, setVehicles] = useState<Map<string, Vehicle>>(new Map());
  const [services, setServices] = useState<Map<string, string>>(new Map());

  // Fetch bookings and service logs for car owner
  const { data: bookingsData, loading: bookingsLoading } = useApi(
    user?.id ? `/api/bookings/user/${user.id}` : ''
  );
  const { data: serviceLogsData, loading: serviceLogsLoading } = useApi(
    user?.id ? `/api/service-logs/user/${user.id}` : ''
  );
  const { data: vehiclesData } = useApi('/api/vehicles');
  const { data: providersData } = useApi('/api/service-provider-service/providers');

  // Load vehicle info (like Flutter _loadCarOwnerVehicleInfo)
  useEffect(() => {
    if (vehiclesData && Array.isArray(vehiclesData)) {
      const vehicleMap = new Map<string, Vehicle>();
      vehiclesData.forEach((vehicle: any) => {
        const id = vehicle.id?.toString();
        if (id) {
          vehicleMap.set(id, vehicle);
        }
      });
      setVehicles(vehicleMap);
    }
  }, [vehiclesData]);

  // Load provider and service info (like Flutter _loadCarOwnerHistory)
  useEffect(() => {
    if (providersData && Array.isArray(providersData)) {
      const providerMap = new Map<string, string>();
      const serviceMap = new Map<string, string>();

      providersData.forEach((provider: any) => {
        const providerId = provider.provider_id || provider.id;
        const providerName = provider.provider_name || provider.name || 'Unknown';
        if (providerId) {
          providerMap.set(providerId.toString(), providerName);
        }

        // Extract services from provider
        const providerServices = provider.services || [];
        providerServices.forEach((service: any) => {
          const serviceId = service.service_id || service.id;
          const serviceName = service.service_name || service.name || service.display_name || 'Unknown';
          if (serviceId) {
            serviceMap.set(serviceId.toString(), serviceName);
          }
        });
      });

      setProviders(providerMap);
      setServices(serviceMap);
    }
  }, [providersData]);

  // Update bookings and service logs when data loads
  useEffect(() => {
    if (bookingsData && Array.isArray(bookingsData)) {
      setBookings(bookingsData);
    }
    if (serviceLogsData && Array.isArray(serviceLogsData)) {
      setServiceLogs(serviceLogsData);
    }
    setIsLoading(bookingsLoading || serviceLogsLoading);
  }, [bookingsData, serviceLogsData, bookingsLoading, serviceLogsLoading]);

  // Format vehicle name (like Flutter _formatVehicleName)
  const formatVehicleName = (vehicle: Vehicle | undefined): string => {
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
      case 'pending': return 'bg-orange-100 text-orange-800 border-orange-200';
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

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading history...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Tabs */}
      <div className="bg-white rounded-lg shadow-sm">
        <div className="border-b border-gray-200">
          <nav className="flex -mb-px">
            <button
              onClick={() => setActiveTab('bookings')}
              className={`py-4 px-6 text-sm font-medium border-b-2 transition-colors ${
                activeTab === 'bookings'
                  ? 'border-blue-600 text-blue-600'
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
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center space-x-2">
                <Wrench className="h-5 w-5" />
                <span>Service Logs ({serviceLogs.length})</span>
              </div>
            </button>
          </nav>
        </div>
      </div>

      {/* Content */}
      {activeTab === 'bookings' && (
        <div className="space-y-4">
          {bookings.length === 0 ? (
            <div className="bg-white rounded-lg shadow-sm p-12 text-center">
              <Calendar className="h-16 w-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No bookings found</h3>
              <p className="text-gray-600">Your bookings will appear here once you book a service.</p>
            </div>
          ) : (
            bookings.map((booking) => {
              const providerName = providers.get(booking.provider_id) || 'Unknown Provider';
              const vehicle = vehicles.get(booking.vehicle_id);
              const vehicleInfo = vehicle ? formatVehicleName(vehicle) : 'Unknown Vehicle';
              const serviceName = getServiceNames(booking);
              const statusColors = getStatusColor(booking.status);
              
              return (
                <div key={booking.id} className="bg-white rounded-lg shadow-sm p-6">
                  {/* Provider Name */}
                  <div className="flex items-center space-x-3 mb-4">
                    <Building className="h-5 w-5 text-gray-500" />
                    <h3 className="font-semibold text-gray-900">{providerName}</h3>
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
                    <Clock className="h-5 w-5 text-gray-500" />
                    <span className="text-sm text-gray-600">Scheduled: {formatDate(booking.scheduled_at)}</span>
                  </div>
                  
                  {/* Status */}
                  <div className="mt-4 pt-4 border-t border-gray-200">
                    <span className={`px-4 py-2 rounded-full text-sm font-medium border ${statusColors}`}>
                      {booking.status?.replace('_', ' ') || 'Unknown'}
                    </span>
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}

      {activeTab === 'logs' && (
        <div className="space-y-4">
          {serviceLogs.length === 0 ? (
            <div className="bg-white rounded-lg shadow-sm p-12 text-center">
              <Wrench className="h-16 w-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No service logs found</h3>
              <p className="text-gray-600">Service logs will appear here once services are completed.</p>
            </div>
          ) : (
            serviceLogs.map((log) => {
              const vehicle = vehicles.get(log.vehicle_id || '');
              const vehicleInfo = vehicle ? formatVehicleName(vehicle) : (log.vehicle_id || 'Unknown Vehicle');
              const providerName = log.provider_name || providers.get(log.provider_id || '') || 'Unknown Provider';
              
              return (
                <div key={log.id} className="bg-white rounded-lg shadow-sm p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      {/* Provider Name */}
                      <div className="flex items-center space-x-3 mb-4">
                        <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                          <CheckCircle className="h-5 w-5 text-green-600" />
                        </div>
                        <div>
                          <h3 className="font-semibold text-gray-900">{providerName}</h3>
                          <p className="text-sm text-gray-600">{log.service_name || 'Service'}</p>
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
                            <Clock className="h-4 w-4" />
                            <span>Mileage: {log.mileage_km} km</span>
                          </div>
                        )}
                        {log.cost && (
                          <div className="flex items-center space-x-2 text-sm text-gray-600">
                            <span>Cost: {formatCurrency(Number(log.cost))}</span>
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
    </div>
  );
};

export default CarOwnerHistory;

