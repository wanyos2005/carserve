import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { 
  Dashboard, 
  AutoAwesome, 
  TrendingUp, 
  People, 
  Calendar, 
  DollarSign,
  Star,
  Settings,
  Bell,
  Menu,
  ChevronDown
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';

interface ProviderStats {
  totalBookings: number;
  completedBookings: number;
  totalRevenue: number;
  averageRating: number;
  pendingBookings: number;
  activeServices: number;
}

interface QuickAction {
  id: string;
  title: string;
  subtitle: string;
  icon: React.ComponentType<any>;
  color: string;
  route?: string;
  isComingSoon?: boolean;
}

interface ProviderDetails {
  id: string;
  name: string;
  category: {
    name: string;
    color: string;
    icon: string;
  };
  frontendGroup: {
    name: string;
    color: string;
    icon: string;
  };
}

const ProviderHomepage: React.FC = () => {
  const router = useRouter();
  const { providerId } = router.query;
  const [providerDetails, setProviderDetails] = useState<ProviderDetails | null>(null);
  const [stats, setStats] = useState<ProviderStats | null>(null);
  const [isPrivilegesExpanded, setIsPrivilegesExpanded] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  const { data: providerData, loading: providerLoading } = useApi(`/service-provider-service/providers/${providerId}`);
  const { data: statsData, loading: statsLoading } = useApi(`/service-provider-service/providers/${providerId}/stats`);

  useEffect(() => {
    if (providerData) {
      setProviderDetails(providerData);
    }
  }, [providerData]);

  useEffect(() => {
    if (statsData) {
      setStats(statsData);
    }
  }, [statsData]);

  useEffect(() => {
    setIsLoading(providerLoading || statsLoading);
  }, [providerLoading, statsLoading]);

  const togglePrivileges = () => {
    setIsPrivilegesExpanded(!isPrivilegesExpanded);
  };

  const quickActions: QuickAction[] = [
    {
      id: 'bookings',
      title: 'Manage Bookings',
      subtitle: 'View and manage customer appointments',
      icon: Calendar,
      color: 'text-blue-600',
      route: '/provider/bookings',
    },
    {
      id: 'services',
      title: 'My Services',
      subtitle: 'Add and manage your service offerings',
      icon: Settings,
      color: 'text-green-600',
      route: '/provider/services',
    },
    {
      id: 'analytics',
      title: 'Analytics',
      subtitle: 'View performance metrics and insights',
      icon: TrendingUp,
      color: 'text-purple-600',
      route: '/provider/analytics',
    },
    {
      id: 'reviews',
      title: 'Customer Reviews',
      subtitle: 'Manage customer feedback and ratings',
      icon: Star,
      color: 'text-yellow-600',
      route: '/provider/reviews',
    },
    {
      id: 'profile',
      title: 'Business Profile',
      subtitle: 'Update your business information',
      icon: People,
      color: 'text-orange-600',
      route: '/provider/profile',
    },
    {
      id: 'notifications',
      title: 'Notifications',
      subtitle: 'Manage alerts and notifications',
      icon: Bell,
      color: 'text-red-600',
      route: '/provider/notifications',
    },
  ];

  const statCards = [
    {
      title: 'Total Bookings',
      value: stats?.totalBookings?.toString() || '0',
      icon: Calendar,
      color: 'text-blue-600',
    },
    {
      title: 'Completed',
      value: stats?.completedBookings?.toString() || '0',
      icon: TrendingUp,
      color: 'text-green-600',
    },
    {
      title: 'Total Revenue',
      value: `KSh ${stats?.totalRevenue?.toLocaleString() || '0'}`,
      icon: DollarSign,
      color: 'text-green-600',
    },
    {
      title: 'Average Rating',
      value: stats?.averageRating?.toString() || '0',
      icon: Star,
      color: 'text-yellow-600',
    },
  ];

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50">
      <div className="safe-area">
        <div className="flex flex-col h-screen">
          {/* Top Header with Provider Info and Menu Toggle */}
          <div className="p-5">
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <h1 className="text-2xl font-bold text-gray-800 mb-1">
                  Welcome Back!
                </h1>
                <p className="text-gray-600 font-semibold">
                  {providerDetails?.name || 'Provider'}
                </p>
                {providerDetails?.frontendGroup && (
                  <div className="mt-2">
                    <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800 border border-blue-200">
                      <span className="w-2 h-2 bg-blue-600 rounded-full mr-2"></span>
                      {providerDetails.frontendGroup.name}
                    </span>
                  </div>
                )}
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
            /* Full Height Provider Dashboard */
            <div className="flex-1 mx-5 mb-5">
              <div className="bg-white rounded-2xl shadow-xl h-full overflow-hidden">
                <div className="p-5 h-full overflow-y-auto">
                  {/* Provider Dashboard Stats */}
                  <h2 className="text-xl font-bold text-gray-800 mb-4">
                    Dashboard Overview
                  </h2>
                  
                  <div className="grid grid-cols-2 gap-3 mb-6">
                    {statCards.map((card, index) => (
                      <div key={index} className="bg-gray-50 rounded-xl p-4">
                        <div className="flex items-center justify-center mb-2">
                          <card.icon className={`h-6 w-6 ${card.color}`} />
                        </div>
                        <p className="text-sm text-gray-600 text-center mb-1">
                          {card.title}
                        </p>
                        <p className={`text-lg font-bold text-center ${card.color}`}>
                          {card.value}
                        </p>
                      </div>
                    ))}
                  </div>

                  {/* Quick Actions */}
                  <h2 className="text-xl font-bold text-gray-800 mb-3">
                    Quick Actions
                  </h2>
                  
                  <div className="space-y-2">
                    {quickActions.map((action) => (
                      <button
                        key={action.id}
                        onClick={() => {
                          if (action.isComingSoon) {
                            alert(`${action.title} section coming soon...`);
                          } else if (action.route) {
                            router.push(action.route);
                          }
                        }}
                        className="w-full p-4 hover:bg-gray-50 transition-colors rounded-xl"
                      >
                        <div className="flex items-center space-x-4">
                          <div className={`p-3 rounded-xl bg-opacity-10 ${action.color.replace('text-', 'bg-')}`}>
                            <action.icon className={`h-6 w-6 ${action.color}`} />
                          </div>
                          <div className="flex-1 text-left">
                            <h3 className="font-semibold text-gray-900">
                              {action.title}
                            </h3>
                            <p className="text-sm text-gray-600">
                              {action.subtitle}
                            </p>
                          </div>
                          <ChevronDown className="h-4 w-4 text-gray-400" />
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          ) : (
            /* Main Content Area - Provider Hub (Clean & Modern) */
            <div className="flex-1 m-5">
              <div className="bg-white bg-opacity-30 backdrop-blur-sm rounded-2xl border border-white border-opacity-50 h-full flex items-center justify-center">
                <div className="text-center">
                  <div className="w-24 h-24 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-8">
                    <Dashboard className="h-12 w-12 text-blue-600" />
                  </div>
                  
                  <h2 className="text-3xl font-bold text-gray-700 mb-4">
                    Your Business Hub
                  </h2>
                  
                  <p className="text-lg text-gray-600 mb-10 max-w-md mx-auto">
                    Manage your services, track bookings, and grow your business with DriveOn.
                  </p>
                  
                  <div className="flex justify-center space-x-6">
                    {/* Dashboard Button */}
                    <button
                      onClick={togglePrivileges}
                      className="bg-blue-600 text-white px-8 py-4 rounded-full hover:bg-blue-700 transition-colors shadow-lg hover:shadow-xl flex flex-col items-center space-y-2"
                    >
                      <Dashboard className="h-6 w-6" />
                      <span className="font-semibold">Dashboard</span>
                    </button>
                    
                    {/* Social Hub Button */}
                    <button
                      onClick={() => router.push('/provider/social-hub')}
                      className="bg-red-600 text-white px-8 py-4 rounded-full hover:bg-red-700 transition-colors shadow-lg hover:shadow-xl flex flex-col items-center space-y-2"
                    >
                      <AutoAwesome className="h-6 w-6" />
                      <span className="font-semibold">Social Hub</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ProviderHomepage;
