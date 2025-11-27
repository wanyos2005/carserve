import React, { useState, useEffect, useMemo } from 'react';
import {
  X,
  Search,
  Filter,
  Star,
  MapPin,
  Phone,
  MessageCircle,
  Mail,
  CheckCircle,
  ChevronDown,
  Loader2,
} from 'lucide-react';

// Provider interface matching booking.tsx structure
interface Provider {
  provider_id?: string;
  id?: string;
  provider_name?: string;
  name?: string;
  location?: any;
  contact_info?: {
    phone?: string;
    email?: string;
  };
  phone?: string;
  email?: string;
  rating?: number;
  is_registered?: boolean;
  services?: any[];
  distance_km?: number;
  distance_display?: string;
}

interface EnhancedProviderSelectorProps {
  providers: Provider[];
  selectedProvider: Provider | null;
  onSelect: (provider: any) => void; // Use any to match booking.tsx Provider type
  recommendedOnly: boolean;
  onFilterChange: (value: boolean) => void;
  loading: boolean;
  selectedServices: any[];
  onCall?: (provider: any) => void;
  onWhatsApp?: (provider: any) => void;
  onSMS?: (provider: any) => void;
  onEmail?: (provider: any) => void;
  serviceLocation?: any;
  isOpen: boolean;
  onClose: () => void;
}

type SortBy = 'rating' | 'price' | 'distance' | 'name';
type FilterBy = 'all' | 'registered' | 'unregistered';

export const EnhancedProviderSelector: React.FC<EnhancedProviderSelectorProps> = ({
  providers,
  selectedProvider,
  onSelect,
  recommendedOnly,
  onFilterChange,
  loading,
  selectedServices,
  onCall,
  onWhatsApp,
  onSMS,
  onEmail,
  serviceLocation,
  isOpen,
  onClose,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortBy>('rating');
  const [filterBy, setFilterBy] = useState<FilterBy>('all');
  const [minRating, setMinRating] = useState(0);
  const [selectedArea, setSelectedArea] = useState<string>('all');
  const [showManualProvider, setShowManualProvider] = useState(false);
  const [manualProviderName, setManualProviderName] = useState('');

  // Get unique areas from providers
  const areas = useMemo(() => {
    const areaSet = new Set<string>();
    providers.forEach((p) => {
      const area = p.location?.area;
      if (area && typeof area === 'string') {
        areaSet.add(area);
      }
    });
    return Array.from(areaSet).sort();
  }, [providers]);

  // Filter and sort providers
  const filteredAndSortedProviders = useMemo(() => {
    let filtered = providers.filter((provider) => {
      // Search filter
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase();
        const name = (provider.provider_name || provider.name || '').toLowerCase();
        const area = (provider.location?.area || '').toLowerCase();
        const address = (provider.location?.address || '').toLowerCase();
        
        if (!name.includes(query) && !area.includes(query) && !address.includes(query)) {
          return false;
        }
      }

      // Registration filter
      if (filterBy === 'registered' && !provider.is_registered) return false;
      if (filterBy === 'unregistered' && provider.is_registered) return false;

      // Area filter
      if (selectedArea !== 'all') {
        const area = provider.location?.area;
        if (area !== selectedArea) return false;
      }

      // Rating filter
      const rating = provider.rating || 0;
      if (rating < minRating) return false;

      return true;
    });

    // Sort providers
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'rating':
          const ratingA = a.rating || 0;
          const ratingB = b.rating || 0;
          return ratingB - ratingA; // Descending
        case 'distance':
          if (serviceLocation) {
            const distanceA = a.distance_km ?? Infinity;
            const distanceB = b.distance_km ?? Infinity;
            return distanceA - distanceB; // Ascending (closest first)
          }
          // Fallback to rating if no service location
          return (b.rating || 0) - (a.rating || 0);
        case 'name':
          const nameA = (a.provider_name || a.name || '').toLowerCase();
          const nameB = (b.provider_name || b.name || '').toLowerCase();
          return nameA.localeCompare(nameB);
        case 'price':
          // For price sorting, we'd need to calculate average price
          // For now, fallback to rating
          return (b.rating || 0) - (a.rating || 0);
        default:
          return 0;
      }
    });

    return filtered;
  }, [providers, searchQuery, filterBy, selectedArea, minRating, sortBy, serviceLocation]);

  const clearFilters = () => {
    setSearchQuery('');
    setSortBy('rating');
    setFilterBy('all');
    setMinRating(0);
    setSelectedArea('all');
  };

  const handleCreateManualProvider = async () => {
    if (!manualProviderName.trim()) {
      alert('Please enter a provider name');
      return;
    }

    try {
      const response = await fetch('/api/service-provider-service/providers', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: manualProviderName.trim(),
        }),
      });

      if (response.ok) {
        const newProvider = await response.json();
        const providerData: Provider = {
          id: String(newProvider.id || newProvider.provider_id || ''),
          provider_id: String(newProvider.id || newProvider.provider_id || ''),
          name: newProvider.name || newProvider.provider_name || '',
          provider_name: newProvider.name || newProvider.provider_name || '',
          is_registered: false,
        };
        onSelect(providerData);
        setShowManualProvider(false);
        setManualProviderName('');
        onClose();
      } else {
        throw new Error('Failed to create provider');
      }
    } catch (error) {
      console.error('Error creating provider:', error);
      alert('Failed to create provider. Please try again.');
    }
  };

  const getPriceRange = (provider: Provider): string => {
    const services = provider.services || [];
    if (services.length === 0) return 'N/A';

    // Extract prices from services (assuming price structure)
    const prices: number[] = [];
    services.forEach((s: any) => {
      if (s.price) {
        const priceStr = typeof s.price === 'string' ? s.price : String(s.price);
        const match = priceStr.match(/[\d,]+/);
        if (match) {
          const price = parseFloat(match[0].replace(/,/g, ''));
          if (!isNaN(price)) prices.push(price);
        }
      }
    });

    if (prices.length === 0) return 'N/A';
    
    const min = Math.min(...prices);
    const max = Math.max(...prices);
    
    if (min === max) {
      return `KES ${min.toLocaleString()}`;
    } else {
      return `KES ${min.toLocaleString()}-${max.toLocaleString()}`;
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="relative bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] flex flex-col">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b">
            <div>
              <h2 className="text-xl font-semibold text-gray-900">Select Provider</h2>
              <p className="text-sm text-gray-500 mt-1">
                {filteredAndSortedProviders.length} provider{filteredAndSortedProviders.length !== 1 ? 's' : ''} found
              </p>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <X className="h-5 w-5 text-gray-500" />
            </button>
          </div>

          {/* Filter Controls */}
          <div className="p-6 border-b space-y-4 overflow-y-auto">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-semibold text-gray-700">Filter & Sort Providers</h3>
              <button
                onClick={clearFilters}
                className="text-xs text-gray-600 hover:text-gray-800 flex items-center space-x-1"
              >
                <X className="h-3 w-3" />
                <span>Clear</span>
              </button>
            </div>

            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search providers..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            {/* Sort and Filter Row */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Sort by</label>
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value as SortBy)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="rating">Rating</option>
                  <option value="name">Name</option>
                  {serviceLocation && <option value="distance">Distance</option>}
                  <option value="price">Price</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Filter</label>
                <select
                  value={filterBy}
                  onChange={(e) => setFilterBy(e.target.value as FilterBy)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="all">All</option>
                  <option value="registered">Registered</option>
                  <option value="unregistered">Unregistered</option>
                </select>
              </div>
            </div>

            {/* Area and Rating Row */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Area</label>
                <select
                  value={selectedArea}
                  onChange={(e) => setSelectedArea(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="all">All Areas</option>
                  {areas.map((area) => (
                    <option key={area} value={area}>
                      {area}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">
                  Min Rating: {minRating.toFixed(1)}
                </label>
                <input
                  type="range"
                  min="0"
                  max="5"
                  step="0.5"
                  value={minRating}
                  onChange={(e) => setMinRating(parseFloat(e.target.value))}
                  className="w-full"
                />
              </div>
            </div>

            {/* Recommended Filter Toggle */}
            <div className="flex items-center space-x-2">
              <button
                onClick={() => onFilterChange(!recommendedOnly)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors flex items-center space-x-2 ${
                  recommendedOnly
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                <Filter className="h-4 w-4" />
                <span>{recommendedOnly ? 'Recommended Only' : 'All Matching'}</span>
              </button>
            </div>
          </div>

          {/* Provider List */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {loading ? (
              <div className="text-center py-8">
                <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto" />
                <p className="mt-2 text-gray-600">Loading providers...</p>
              </div>
            ) : filteredAndSortedProviders.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <p>No providers found matching your criteria</p>
                <p className="text-sm mt-2">Try adjusting your filters</p>
              </div>
            ) : (
              <>
                {filteredAndSortedProviders.map((provider) => {
                  const providerId = provider.provider_id || provider.id || '';
                  const selectedProviderId = selectedProvider?.provider_id || selectedProvider?.id || '';
                  const isSelected = providerId && selectedProviderId && providerId === selectedProviderId;

                  return (
                    <div
                      key={providerId}
                      onClick={() => {
                        onSelect(provider);
                        onClose();
                      }}
                      className={`p-4 border-2 rounded-lg cursor-pointer transition-colors ${
                        isSelected
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center space-x-2">
                            <h3 className="font-medium text-gray-900">
                              {provider.provider_name || provider.name}
                            </h3>
                            {provider.is_registered && (
                              <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">
                                Verified
                              </span>
                            )}
                            {provider.rating && (
                              <div className="flex items-center space-x-1">
                                <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
                                <span className="text-sm text-gray-700">
                                  {provider.rating.toFixed(1)}
                                </span>
                              </div>
                            )}
                          </div>
                          <div className="mt-2 space-y-1">
                            {provider.location && (
                              <p className="text-sm text-gray-600 flex items-center space-x-1">
                                <MapPin className="h-4 w-4" />
                                <span>
                                  {typeof provider.location === 'string'
                                    ? provider.location
                                    : provider.location.area || provider.location.address || 'Location not specified'}
                                </span>
                                {provider.distance_display && (
                                  <span className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded text-xs">
                                    {provider.distance_display}
                                  </span>
                                )}
                              </p>
                            )}
                            {provider.services && provider.services.length > 0 && (
                              <p className="text-xs text-gray-500">
                                {provider.services.length} service{provider.services.length !== 1 ? 's' : ''} available
                              </p>
                            )}
                          </div>
                        </div>
                        <div className="ml-4 flex flex-col items-end space-y-2">
                          <div
                            className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                              isSelected
                                ? 'border-blue-500 bg-blue-500'
                                : 'border-gray-300'
                            }`}
                          >
                            {isSelected && <CheckCircle className="h-4 w-4 text-white" />}
                          </div>
                          <span className="text-xs font-semibold text-gray-700">
                            {getPriceRange(provider)}
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })}

                {/* Manual Provider Option */}
                <div
                  onClick={() => setShowManualProvider(true)}
                  className="p-4 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-gray-400 transition-colors"
                >
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center">
                      <X className="h-5 w-5 text-gray-600" />
                    </div>
                    <div>
                      <h3 className="font-medium text-gray-900">Other / Not Listed</h3>
                      <p className="text-sm text-gray-500">Add a provider not in the list</p>
                    </div>
                    <ChevronDown className="h-5 w-5 text-gray-400 ml-auto" />
                  </div>
                </div>
              </>
            )}
          </div>

          {/* Footer */}
          <div className="p-4 border-t">
            <button
              onClick={onClose}
              disabled={!selectedProvider}
              className={`w-full py-3 rounded-lg font-medium transition-colors ${
                selectedProvider
                  ? 'bg-blue-600 text-white hover:bg-blue-700'
                  : 'bg-gray-200 text-gray-500 cursor-not-allowed'
              }`}
            >
              {selectedProvider
                ? `Confirm ${selectedProvider.provider_name || selectedProvider.name || 'Provider'}`
                : 'Select a Provider'}
            </button>
          </div>
        </div>
      </div>

      {/* Manual Provider Dialog */}
      {showManualProvider && (
        <div className="fixed inset-0 z-60 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setShowManualProvider(false)} />
          <div className="relative bg-white rounded-lg shadow-xl w-full max-w-md p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Add New Provider</h3>
            <p className="text-sm text-gray-600 mb-4">Enter the name of the provider</p>
            <input
              type="text"
              placeholder="e.g., ABC Auto Shop"
              value={manualProviderName}
              onChange={(e) => setManualProviderName(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent mb-4"
              autoFocus
            />
            <div className="flex space-x-3">
              <button
                onClick={() => {
                  setShowManualProvider(false);
                  setManualProviderName('');
                }}
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateManualProvider}
                disabled={!manualProviderName.trim()}
                className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                Create
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

