import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { 
  Menu,
  ChevronRight,
  RefreshCw,
  LayoutDashboard as DashboardIcon,
  Sparkles as AutoAwesome,
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';
import { ProviderServiceAPI } from '../../lib/services/providerService';
import { ProviderCategoryConfigs } from '../../lib/config/providerCategoryConfig';
import { FrontendCategoryGroups } from '../../lib/config/frontendCategoryGrouping';

interface ProviderDetails {
    id: string;
    name: string;
  category?: {
    name: string;
  };
  provider_category?: {
    name: string;
  };
  category_name?: string;
}

const ProviderDashboard: React.FC = () => {
  const router = useRouter();
  const { providerId: queryProviderId } = router.query;
  
  const [providerId, setProviderId] = useState<string>('');
  const [providerDetails, setProviderDetails] = useState<ProviderDetails | null>(null);
  const [categoryName, setCategoryName] = useState<string>('');
  const [categoryConfig, setCategoryConfig] = useState<any>(null);
  const [frontendGroup, setFrontendGroup] = useState<any>(null);
  const [isPrivilegesExpanded, setIsPrivilegesExpanded] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [dynamicStatCards, setDynamicStatCards] = useState<any[]>([]);
  const [providerStats, setProviderStats] = useState<any>(null);

  // Get provider ID from router or localStorage
  useEffect(() => {
    const storedProviderId = localStorage.getItem('providerId') || (queryProviderId as string) || '';
    if (storedProviderId) {
      setProviderId(storedProviderId);
      localStorage.setItem('providerId', storedProviderId);
    }
  }, [queryProviderId]);

  // Fetch stats from backend API
  const { data: statsData, loading: statsDataLoading, refetch: refetchStats } = useApi(
    providerId ? `/api/service-provider-service/providers/${providerId}/stats` : ''
  );

  // Load provider details
  useEffect(() => {
    if (providerId) {
      setIsLoading(true);
      ProviderServiceAPI.getProviderDetails(providerId)
        .then((details) => {
          if (details) {
            setProviderDetails(details as unknown as ProviderDetails);
            
            // Extract and normalize category name (lowercase, trimmed)
            const rawCatName = 
              (details as any).category?.name || 
              (details as any).provider_category?.name ||
              (details as any).category_name ||
              (details as any).name ||
              'garage / mechanic';
            
            // Normalize to match config keys (lowercase, trimmed)
            const normalizedCatName = rawCatName.toLowerCase().trim();
            
            console.log('📊 Provider category extraction:', {
              raw: rawCatName,
              normalized: normalizedCatName,
              categoryField: (details as any).category,
              providerCategoryField: (details as any).provider_category,
              categoryNameField: (details as any).category_name,
              allKeys: Object.keys(details as any)
            });
            
            setCategoryName(normalizedCatName);
            const config = ProviderCategoryConfigs.getConfig(normalizedCatName);
            setCategoryConfig(config);
            const group = FrontendCategoryGroups.getGroupForBackendCategory(rawCatName);
            setFrontendGroup(group);
            
            console.log('📊 Category config loaded:', {
              configName: config.name,
              quickActionsCount: config.quickActions.length,
              statCardsCount: config.statCards.length
            });
            
            setIsLoading(false);
            
            // Stats will be loaded automatically when statsData is available via useEffect
          } else {
            setIsLoading(false);
          }
        })
        .catch((error) => {
          console.error('Failed to load provider details:', error);
          setIsLoading(false);
        });
    }
  }, [providerId]);

  // Update stats when API data loads
  useEffect(() => {
    if (statsData && providerId && categoryName) {
      console.log('📊 Stats data loaded from API:', statsData);
      setProviderStats(statsData);
      ProviderCategoryConfigs.updateStatsCache(providerId, statsData);
      const dynamicStats = ProviderCategoryConfigs.getDynamicStatCards(
        providerId,
        categoryName,
        statsData
      );
      console.log('📊 Dynamic stat cards generated from API:', dynamicStats);
      setDynamicStatCards(dynamicStats);
    }
  }, [statsData, providerId, categoryName]);

  const togglePrivileges = () => {
    setIsPrivilegesExpanded(!isPrivilegesExpanded);
  };

  const getColorClasses = (color: string) => {
    const colorMap: Record<string, { bg: string; text: string; border: string }> = {
      blue: { bg: 'bg-blue-100', text: 'text-blue-600', border: 'border-blue-200' },
      green: { bg: 'bg-green-100', text: 'text-green-600', border: 'border-green-200' },
      orange: { bg: 'bg-orange-100', text: 'text-orange-600', border: 'border-orange-200' },
      purple: { bg: 'bg-purple-100', text: 'text-purple-600', border: 'border-purple-200' },
      teal: { bg: 'bg-teal-100', text: 'text-teal-600', border: 'border-teal-200' },
      amber: { bg: 'bg-amber-100', text: 'text-amber-600', border: 'border-amber-200' },
      red: { bg: 'bg-red-100', text: 'text-red-600', border: 'border-red-200' },
      cyan: { bg: 'bg-cyan-100', text: 'text-cyan-600', border: 'border-cyan-200' },
      grey: { bg: 'bg-gray-100', text: 'text-gray-600', border: 'border-gray-200' },
    };
    return colorMap[color] || colorMap.grey;
  };

  const getGroupColorClasses = (color: string) => {
    const colorMap: Record<string, { bg: string; text: string; border: string }> = {
      blue: { bg: 'bg-blue-50', text: 'text-blue-800', border: 'border-blue-300' },
      green: { bg: 'bg-green-50', text: 'text-green-800', border: 'border-green-300' },
      orange: { bg: 'bg-orange-50', text: 'text-orange-800', border: 'border-orange-300' },
      purple: { bg: 'bg-purple-50', text: 'text-purple-800', border: 'border-purple-300' },
      teal: { bg: 'bg-teal-50', text: 'text-teal-800', border: 'border-teal-300' },
    };
    return colorMap[color] || colorMap.blue;
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!providerId) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Provider Dashboard</h2>
          <p className="text-gray-600 mb-6">Please log in as a service provider to access your dashboard.</p>
        </div>
      </div>
    );
  }

  // Use category config if available, otherwise get default
  const config = categoryConfig || ProviderCategoryConfigs.getDefaultConfig(categoryName || 'garage / mechanic');
  
  // Use dynamic stat cards if available, otherwise use config stat cards
  const statCards = dynamicStatCards.length > 0 ? dynamicStatCards : (config.statCards || []);
  const quickActions = config.quickActions || [];
  
  console.log('📊 Dashboard render:', {
    categoryName,
    hasCategoryConfig: !!categoryConfig,
    configName: config.name,
    statCardsCount: statCards.length,
    quickActionsCount: quickActions.length,
    quickActions: quickActions.map((a: any) => ({ title: a.title, route: a.route }))
  });

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
                  {(providerDetails as any)?.name || (providerDetails as any)?.provider_name || 'Provider'}
                </p>
                {frontendGroup && (
                  <div className="mt-2">
                    <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${getGroupColorClasses(frontendGroup.color).bg} ${getGroupColorClasses(frontendGroup.color).text} ${getGroupColorClasses(frontendGroup.color).border}`}>
                      <span className={`w-2 h-2 rounded-full mr-2 ${
                        frontendGroup.color === 'blue' ? 'bg-blue-600' :
                        frontendGroup.color === 'green' ? 'bg-green-600' :
                        frontendGroup.color === 'orange' ? 'bg-orange-600' :
                        frontendGroup.color === 'purple' ? 'bg-purple-600' :
                        frontendGroup.color === 'teal' ? 'bg-teal-600' :
                        'bg-blue-600'
                      }`}></span>
                      {frontendGroup.name}
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
                  <div className="mb-6">
                    <div className="flex items-center justify-between mb-4">
                      <h2 className="text-xl font-bold text-gray-800">
                        Statistics
                      </h2>
                      <button
                        onClick={() => {
                          // Force reload stats
                          refetchStats();
                        }}
                        disabled={statsDataLoading}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Refresh Statistics"
                      >
                        {statsDataLoading ? (
                          <RefreshCw className="h-5 w-5 text-blue-600 animate-spin" />
                        ) : (
                          <RefreshCw className="h-5 w-5 text-blue-600" />
                        )}
                      </button>
          </div>

                    {/* Stats grid - 2x2 layout */}
                    <div className="grid grid-cols-2 gap-3">
                      {statCards.slice(0, 4).map((statCard: any, index: number) => {
                        const IconComponent = statCard.icon;
                        const colors = getColorClasses(statCard.color);
                        
                        return (
                          <div key={index} className="bg-gray-50 rounded-xl p-4">
                            <div className="flex items-center justify-center mb-2">
                              <IconComponent className={`h-6 w-6 ${colors.text}`} />
                </div>
                            <p className="text-sm text-gray-600 text-center mb-1">
                              {statCard.title}
                            </p>
                            {statsDataLoading ? (
                              <div className="flex justify-center">
                                <div className={`animate-spin rounded-full h-5 w-5 border-2 ${colors.text} border-t-transparent`}></div>
                  </div>
                ) : (
                              <p className={`text-lg font-bold text-center ${colors.text}`}>
                                {statCard.value}
                              </p>
                )}
              </div>
                        );
                      })}
            </div>
          </div>

                  {/* Quick Actions */}
                  <h2 className="text-xl font-bold text-gray-800 mb-3">
                    Quick Actions
                  </h2>
                  
                  <div className="space-y-2">
                    {quickActions.map((action: any, index: number) => {
                      const IconComponent = action.icon;
                      const colors = getColorClasses(action.color);
                      
                      const handleClick = () => {
                        if (action.isComingSoon) {
                          alert(`${action.title} section coming soon...`);
                          return;
                        }
                        if (action.route) {
                          router.push({
                            pathname: action.route,
                            query: { providerId },
                          });
                        }
                        if (action.onClick) {
                          action.onClick();
                        }
                      };
                      
                      return (
                        <button
                          key={index}
                          onClick={handleClick}
                          className="w-full p-4 hover:bg-gray-50 transition-colors rounded-xl text-left"
                        >
                          <div className="flex items-center space-x-4">
                            <div className={`p-3 rounded-xl ${colors.bg}`}>
                              <IconComponent className={`h-6 w-6 ${colors.text}`} />
                </div>
                            <div className="flex-1">
                              <h3 className="font-semibold text-gray-900">
                                {action.title}
                          </h3>
                          <p className="text-sm text-gray-600">
                                {action.subtitle}
                          </p>
                        </div>
                            <ChevronRight className="h-4 w-4 text-gray-400" />
                      </div>
                        </button>
                      );
                    })}
              </div>
            </div>
          </div>
        </div>
          ) : (
            /* Main Content Area - Provider Hub (Clean & Modern) */
            <div className="flex-1 m-5">
              <div className="bg-white bg-opacity-30 backdrop-blur-sm rounded-2xl border border-white border-opacity-50 h-full flex items-center justify-center">
                <div className="text-center">
                  <div className={`w-24 h-24 rounded-full flex items-center justify-center mx-auto mb-8 ${
                    frontendGroup?.color === 'blue' ? 'bg-blue-100' :
                    frontendGroup?.color === 'green' ? 'bg-green-100' :
                    frontendGroup?.color === 'orange' ? 'bg-orange-100' :
                    frontendGroup?.color === 'purple' ? 'bg-purple-100' :
                    frontendGroup?.color === 'teal' ? 'bg-teal-100' :
                    'bg-blue-100'
                  }`}>
                    {frontendGroup ? (
                      <frontendGroup.icon className={`h-12 w-12 ${
                        frontendGroup.color === 'blue' ? 'text-blue-600' :
                        frontendGroup.color === 'green' ? 'text-green-600' :
                        frontendGroup.color === 'orange' ? 'text-orange-600' :
                        frontendGroup.color === 'purple' ? 'text-purple-600' :
                        frontendGroup.color === 'teal' ? 'text-teal-600' :
                        'text-blue-600'
                      }`} />
                    ) : (
                      <DashboardIcon className="h-12 w-12 text-blue-600" />
                    )}
              </div>
                  
                  <h2 className="text-3xl font-bold text-gray-700 mb-4">
                    Your Business Hub
                  </h2>
                  
                  <p className="text-lg text-gray-600 mb-10 max-w-md mx-auto">
                    {config.welcomeMessage}
                  </p>
                  
                  <div className="flex justify-center space-x-6">
                    {/* Dashboard Button */}
                    <button
                      onClick={togglePrivileges}
                      className={`px-8 py-4 rounded-full text-white transition-colors shadow-lg hover:shadow-xl flex flex-col items-center space-y-2 ${
                        frontendGroup?.color === 'blue' ? 'bg-blue-600 hover:bg-blue-700' :
                        frontendGroup?.color === 'green' ? 'bg-green-600 hover:bg-green-700' :
                        frontendGroup?.color === 'orange' ? 'bg-orange-600 hover:bg-orange-700' :
                        frontendGroup?.color === 'purple' ? 'bg-purple-600 hover:bg-purple-700' :
                        frontendGroup?.color === 'teal' ? 'bg-teal-600 hover:bg-teal-700' :
                        'bg-blue-600 hover:bg-blue-700'
                      }`}
                    >
                      <DashboardIcon className="h-6 w-6" />
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

export default ProviderDashboard;
