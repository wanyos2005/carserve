import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import {
  Menu,
  ChevronRight,
  Car,
  Wrench,
  Shield,
  Wallet,
  History,
  Star,
  Bell,
  Settings,
  Sparkles,
  Plus,
  ArrowRight,
} from 'lucide-react';
import { useAuth } from '../lib/auth';
import { useApi } from '../hooks/useApi';

interface Vehicle {
  id: string;
  plate?: string;
  make?: string;
  model?: string;
  yom?: number;
  mileage?: number;
}

const CarOwnerHomePage: React.FC = () => {
  const router = useRouter();
  const { user, isAuthenticated, isLoading: authLoading } = useAuth();
  const [isPrivilegesExpanded, setIsPrivilegesExpanded] = useState(false);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [vehiclesLoading, setVehiclesLoading] = useState(true);

  // Fetch vehicles
  const { data: vehiclesData, loading: vehiclesDataLoading } = useApi('/api/vehicles');

  useEffect(() => {
    if (vehiclesData && Array.isArray(vehiclesData)) {
      setVehicles(vehiclesData);
      setVehiclesLoading(false);
    } else if (!vehiclesDataLoading) {
      setVehiclesLoading(false);
    }
  }, [vehiclesData, vehiclesDataLoading]);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [authLoading, isAuthenticated, router]);

  const togglePrivileges = () => {
    setIsPrivilegesExpanded(!isPrivilegesExpanded);
  };

  const buildPrivilegeItem = (
    title: string,
    icon: React.ElementType,
    color: string,
    onClick: () => void
  ) => {
    const Icon = icon;
    const colorClasses = {
      blue: 'bg-blue-100 text-blue-600',
      green: 'bg-green-100 text-green-600',
      orange: 'bg-orange-100 text-orange-600',
      purple: 'bg-purple-100 text-purple-600',
      amber: 'bg-amber-100 text-amber-600',
      red: 'bg-red-100 text-red-600',
      indigo: 'bg-indigo-100 text-indigo-600',
      teal: 'bg-teal-100 text-teal-600',
    }[color] || 'bg-gray-100 text-gray-600';

    return (
      <button
        onClick={onClick}
        className="w-full p-4 hover:bg-gray-50 transition-colors rounded-xl text-left"
      >
        <div className="flex items-center space-x-4">
          <div className={`p-3 rounded-xl ${colorClasses}`}>
            <Icon className="h-6 w-6" />
          </div>
          <div className="flex-1">
            <h3 className="font-semibold text-gray-900">{title}</h3>
          </div>
          <ChevronRight className="h-4 w-4 text-gray-400" />
        </div>
      </button>
    );
  };

  const buildQuickActionCard = (
    icon: React.ElementType,
    title: string,
    color: string,
    onTap: () => void
  ) => {
    const Icon = icon;
    const colorClasses = {
      green: 'bg-green-100 text-green-600',
      orange: 'bg-orange-100 text-orange-600',
      purple: 'bg-purple-100 text-purple-600',
      indigo: 'bg-indigo-100 text-indigo-600',
    }[color] || 'bg-blue-100 text-blue-600';

    return (
      <button
        onClick={onTap}
        className="flex-1 p-4 bg-white rounded-xl shadow-sm hover:shadow-md transition-shadow"
      >
        <div className="flex flex-col items-center">
          <div className={`p-3 rounded-lg ${colorClasses} mb-2`}>
            <Icon className="h-6 w-6" />
          </div>
          <span className="text-sm font-semibold text-gray-900">{title}</span>
        </div>
      </button>
    );
  };

  if (authLoading || vehiclesLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return null; // Will redirect
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50">
      <div className="safe-area">
        <div className="flex flex-col h-screen">
          {/* Top Header with Privileges Toggle */}
          <div className="p-5">
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <h1 className="text-2xl font-bold text-gray-800 mb-1">
                  Welcome Back!
                </h1>
                <p className="text-gray-600 font-semibold">
                  Your mobility hub awaits
                </p>
              </div>
              
              <button
                onClick={togglePrivileges}
                className="p-3 bg-white rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300"
              >
                <div className={`transform transition-transform duration-300 ${isPrivilegesExpanded ? 'rotate-180' : ''}`}>
                  <Menu className="h-6 w-6 text-gray-800" />
                </div>
              </button>
            </div>
          </div>

          {/* Conditional Layout: Either Privileges (full height) or Main Content */}
          {isPrivilegesExpanded ? (
            /* Full Height Privileges Menu */
            <div className="flex-1 mx-5 mb-5">
              <div className="bg-white rounded-2xl shadow-xl h-full overflow-hidden">
                <div className="p-5 h-full overflow-y-auto">
                  <div className="space-y-2">
                    {buildPrivilegeItem(
                      'My Vehicles',
                      Car,
                      'blue',
                      () => router.push('/vehicles')
                    )}
                    {buildPrivilegeItem(
                      'Services & Booking',
                      Wrench,
                      'green',
                      () => router.push('/booking')
                    )}
                    {buildPrivilegeItem(
                      'Insurance',
                      Shield,
                      'orange',
                      () => router.push('/insurance/dashboard')
                    )}
                    {buildPrivilegeItem(
                      'Expenses',
                      Wallet,
                      'purple',
                      () => router.push('/expenses')
                    )}
                    {buildPrivilegeItem(
                      'Top Providers',
                      Star,
                      'amber',
                      () => router.push('/providers')
                    )}
                    {buildPrivilegeItem(
                      'Alerts',
                      Bell,
                      'red',
                      () => router.push('/alerts')
                    )}
                    {buildPrivilegeItem(
                      'History',
                      History,
                      'indigo',
                      () => router.push('/history')
                    )}
                    {buildPrivilegeItem(
                      'Profile & Settings',
                      Settings,
                      'teal',
                      () => router.push('/settings')
                    )}
                  </div>
                </div>
              </div>
            </div>
          ) : (
            /* Main Content Area - Vehicle Dashboard */
            <div className="flex-1 overflow-y-auto">
              <div className="px-5 pb-5">
                {/* My Vehicles Section */}
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-xl font-bold text-gray-800">My Vehicles</h2>
                  <button
                    onClick={() => router.push('/vehicles')}
                    className="text-sm text-blue-600 font-medium flex items-center space-x-1"
                  >
                    <span>View All</span>
                    <ArrowRight className="h-4 w-4" />
                  </button>
                </div>

                {/* Vehicles List */}
                {vehiclesLoading ? (
                  <div className="flex justify-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  </div>
                ) : vehicles.length === 0 ? (
                  <div className="bg-white rounded-xl p-8 text-center border border-gray-200">
                    <Car className="h-16 w-16 text-gray-400 mx-auto mb-4" />
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">No vehicles yet</h3>
                    <p className="text-sm text-gray-600 mb-6">Add your first vehicle to get started</p>
                    <button
                      onClick={() => router.push('/vehicles/add')}
                      className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors flex items-center space-x-2 mx-auto"
                    >
                      <Plus className="h-5 w-5" />
                      <span>Add Vehicle</span>
                    </button>
                  </div>
                ) : (
                  <div className="space-y-3 mb-6">
                    {vehicles.slice(0, 3).map((vehicle) => (
                      <div
                        key={vehicle.id}
                        onClick={() => router.push('/vehicles')}
                        className="bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition-shadow cursor-pointer"
                      >
                        <div className="flex items-center space-x-4">
                          <div className="p-3 bg-blue-50 rounded-lg">
                            <Car className="h-6 w-6 text-blue-600" />
                          </div>
                          <div className="flex-1">
                            <h3 className="font-semibold text-gray-900">
                              {vehicle.make || 'Unknown'} {vehicle.model || ''}
                            </h3>
                            <p className="text-sm text-gray-600">
                              Plate: {vehicle.plate || 'N/A'}
                            </p>
                            {vehicle.mileage && (
                              <p className="text-sm text-gray-600">
                                Mileage: {vehicle.mileage} km
                              </p>
                            )}
                          </div>
                          <ChevronRight className="h-5 w-5 text-gray-400" />
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {vehicles.length > 3 && (
                  <div className="text-center mb-6">
                    <button
                      onClick={() => router.push('/vehicles')}
                      className="text-sm text-blue-600 font-medium"
                    >
                      View {vehicles.length - 3} more vehicle{vehicles.length - 3 > 1 ? 's' : ''}
                    </button>
                  </div>
                )}

                {/* Quick Actions Section */}
                <h2 className="text-xl font-bold text-gray-800 mb-4">Quick Actions</h2>
                <div className="grid grid-cols-2 gap-3 mb-6">
                  {buildQuickActionCard(
                    Wrench,
                    'Book Service',
                    'green',
                    () => router.push('/booking')
                  )}
                  {buildQuickActionCard(
                    Shield,
                    'Insurance',
                    'orange',
                    () => router.push('/insurance/dashboard')
                  )}
                  {buildQuickActionCard(
                    Wallet,
                    'Expenses',
                    'purple',
                    () => router.push('/expenses')
                  )}
                  {buildQuickActionCard(
                    History,
                    'History',
                    'indigo',
                    () => router.push('/history')
                  )}
                </div>

                {/* Social Hub Link */}
                <div className="bg-gradient-to-r from-purple-50 to-pink-50 rounded-xl p-4 border border-purple-200">
                  <button
                    onClick={() => router.push('/social-hub')}
                    className="w-full flex items-center space-x-4"
                  >
                    <div className="p-3 bg-purple-100 rounded-lg">
                      <Sparkles className="h-6 w-6 text-purple-600" />
                    </div>
                    <div className="flex-1 text-left">
                      <h3 className="font-semibold text-gray-900">Social Hub</h3>
                      <p className="text-sm text-gray-600">Connect with the community</p>
                    </div>
                    <ChevronRight className="h-5 w-5 text-gray-400" />
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default CarOwnerHomePage;

