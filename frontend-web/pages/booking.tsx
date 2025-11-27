import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { 
  ArrowLeft, 
  Calendar, 
  Clock, 
  MapPin, 
  DollarSign, 
  CheckCircle,
  Phone,
  MessageCircle,
  Mail,
  Filter,
  ShoppingCart,
  Wrench,
  Loader2,
  Search,
  X,
  ChevronDown,
  Droplet,
  Car,
  Wrench as WrenchIcon,
  Shield,
  AlertTriangle,
  Fuel as FuelIcon,
  Wind
} from 'lucide-react';
import { useApi } from '../hooks/useApi';
import { useAuth, apiRequest } from '../lib/auth';
import { FrontendCategoryGroups } from '../lib/config/frontendCategoryGrouping';
import { EnhancedProviderSelector } from '../components/booking/EnhancedProviderSelector';

interface Vehicle {
  id: string;
  plate?: string;
  make?: string;
  model?: string;
  yom?: number;
}

interface Service {
  id: string;
  name: string;
  description?: string;
  price?: string;
  min_price?: number;
  max_price?: number;
  price_type?: string;
  currency?: string;
  unit?: string;
  negotiable?: boolean;
  category?: {
    name: string;
  };
}

interface Provider {
  provider_id: string;
  id?: string;
  provider_name: string;
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
}

type BookingStep = 'vehicle-service' | 'provider' | 'scheduling' | 'pricing' | 'confirmation';

const BookingPage: React.FC = () => {
  const router = useRouter();
  const { user } = useAuth();
  
  // Step management
  const [currentStep, setCurrentStep] = useState<BookingStep>('vehicle-service');
  const [isPurchaseMode, setIsPurchaseMode] = useState(false);
  
  // Data
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [selectedVehicleId, setSelectedVehicleId] = useState<string>('');
  const [selectedServices, setSelectedServices] = useState<Service[]>([]);
  const [matchedProviders, setMatchedProviders] = useState<Provider[]>([]);
  const [selectedProvider, setSelectedProvider] = useState<Provider | null>(null);
  const [recommendedOnly, setRecommendedOnly] = useState(true);
  
  // Service search and filtering
  const [serviceSearchQuery, setServiceSearchQuery] = useState('');
  const [selectedCategoryGroup, setSelectedCategoryGroup] = useState<string | null>(null);
  const [selectedRecommendedService, setSelectedRecommendedService] = useState<string | null>(null);
  const [recommendedKeywords, setRecommendedKeywords] = useState<string[] | null>(null);
  
  // Scheduling
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [selectedTime, setSelectedTime] = useState<string>('');
  const [serviceLocation, setServiceLocation] = useState<any>(null);
  
  // Pricing
  const [servicePrices, setServicePrices] = useState<Record<string, number>>({});
  const [negotiatedPrices, setNegotiatedPrices] = useState<Record<string, number>>({});
  const [hasNegotiated, setHasNegotiated] = useState(false);
  
  // Loading states
  const [isLoading, setIsLoading] = useState(true);
  const [providersLoading, setProvidersLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  
  // Contact history
  const [contactHistory, setContactHistory] = useState<any[]>([]);
  
  // Provider selector modal state
  const [isProviderSelectorOpen, setIsProviderSelectorOpen] = useState(false);

  // Fetch initial data - Use /api/vehicles for authenticated users (same as home.tsx)
  // /api/vehicles/guest only accepts POST, but we need GET, so use /api/vehicles instead
  const { data: vehiclesData, loading: vehiclesLoading, error: vehiclesError } = useApi('/api/vehicles');
  const { data: servicesData, loading: servicesLoading } = useApi('/api/global-service-api/services');
  const { data: userData } = useApi('/api/users/me');

  useEffect(() => {
    if (vehiclesData && Array.isArray(vehiclesData)) {
      setVehicles(vehiclesData);
      if (vehiclesData.length > 0 && !selectedVehicleId) {
        setSelectedVehicleId(vehiclesData[0].id);
      }
    }
  }, [vehiclesData]);

  useEffect(() => {
    if (servicesData && Array.isArray(servicesData)) {
      const normalized = servicesData.map((s: any) => ({
        id: s.id || s.service_id,
        name: s.name || s.service_name,
        description: s.description || s.service_description,
        price: s.price,
        min_price: s.min_price,
        max_price: s.max_price,
        price_type: s.price_type,
        currency: s.currency || 'KES',
        unit: s.unit,
        negotiable: s.negotiable !== false,
        category: s.category || { name: s.service_category_name },
      }));
      setServices(normalized);
      
      // Initialize prices
      const prices: Record<string, number> = {};
      normalized.forEach((s: Service) => {
        prices[s.id] = s.min_price || 0;
      });
      setServicePrices(prices);
    }
  }, [servicesData]);
  
  // Recommended services matching Flutter implementation
  const getRecommendedServicesData = () => {
    if (isPurchaseMode) {
      return [
        {
          name: 'Oil & Engine',
          icon: 'oil',
          color: 'orange',
          keywords: ['oil', 'filter', 'lubrication', 'engine oil', 'motor oil', 'engine', 'motor', 'spark plug', 'belt', 'gasket'],
        },
        {
          name: 'Brake Parts',
          icon: 'brake',
          color: 'red',
          keywords: ['brake', 'brakes', 'pad', 'disc', 'rotor'],
        },
        {
          name: 'Tire & Wheels',
          icon: 'tire',
          color: 'blue',
          keywords: ['tire', 'tyre', 'wheel', 'rim', 'tire'],
        },
        {
          name: 'Car wash',
          icon: 'wash',
          color: 'green',
          keywords: [
            'car wash', 'wash', 'clean', 'cleaning', 'detailing', 'detail', 'package',
            'full wash', 'premium', 'executive', 'superior',
            'body wash', 'exterior', 'foam wash', 'shampoo', 'wax', 'waxing',
            'polish', 'buffing', 'machine polish', 'ceramic', 'coating',
            'interior', 'interior wash', 'deep clean', 'vacuum', 'dashboard',
            'interior polish', 'sanitization', 'sanitizer', 'steam interior',
            'engine', 'engine wash', 'engine cleaning', 'steam engine',
            'light restoration', 'headlight', 'restoration', 'plastic restoration',
            'leather', 'leather care', 'leather restoration',
            'rim', 'rims', 'wheel', 'tire', 'tyre', 'wheel cleaning', 'rim cleaning',
            'water marks', 'water spot', 'roof cleaning', 'floor cleaning',
            'air freshener', 'perfume',
            'carpet', 'small carpet', 'medium carpet', 'large carpet', 'xl carpet',
            'xxl carpet', 'premium carpet', 'mat cleaning'
          ],
        },
        {
          name: 'AC Parts',
          icon: 'ac',
          color: 'cyan',
          keywords: ['ac', 'air conditioning', 'compressor', 'condenser', 'filter'],
        },
        {
          name: 'Fuel',
          icon: 'fuel',
          color: 'amber',
          keywords: ['fuel', 'gas', 'petrol', 'diesel', 'gasoline', 'refuel'],
        },
        {
          name: 'Insurance',
          icon: 'insurance',
          color: 'green',
          keywords: ['insurance', 'policy', 'coverage', 'premium', 'claim'],
          isSpecial: true,
        },
        {
          name: 'Breakdown Assistance',
          icon: 'breakdown',
          color: 'red',
          keywords: ['breakdown', 'assistance', 'roadside', 'towing', 'emergency', 'rescue', 'tow', 'recovery'],
        },
      ];
    } else {
      return [
        {
          name: 'Oil & Engine',
          icon: 'oil',
          color: 'orange',
          keywords: ['oil', 'filter', 'lubrication', 'engine oil', 'motor oil', 'engine', 'motor', 'spark plug', 'belt', 'gasket'],
        },
        {
          name: 'Brake Service',
          icon: 'brake',
          color: 'red',
          keywords: ['brake', 'brakes', 'braking', 'disc', 'pad'],
        },
        {
          name: 'Tire Service',
          icon: 'tire',
          color: 'blue',
          keywords: ['tire', 'tyre', 'wheel', 'alignment', 'balancing'],
        },
        {
          name: 'Car wash',
          icon: 'wash',
          color: 'green',
          keywords: [
            'car wash', 'wash', 'clean', 'cleaning', 'detailing', 'detail', 'package',
            'full wash', 'premium', 'executive', 'superior',
            'body wash', 'exterior', 'foam wash', 'shampoo', 'wax', 'waxing',
            'polish', 'buffing', 'machine polish', 'ceramic', 'coating',
            'interior', 'interior wash', 'deep clean', 'vacuum', 'dashboard',
            'interior polish', 'sanitization', 'sanitizer', 'steam interior',
            'engine', 'engine wash', 'engine cleaning', 'steam engine',
            'light restoration', 'headlight', 'restoration', 'plastic restoration',
            'leather', 'leather care', 'leather restoration',
            'rim', 'rims', 'wheel', 'tire', 'tyre', 'wheel cleaning', 'rim cleaning',
            'water marks', 'water spot', 'roof cleaning', 'floor cleaning',
            'air freshener', 'perfume',
            'carpet', 'small carpet', 'medium carpet', 'large carpet', 'xl carpet',
            'xxl carpet', 'premium carpet', 'mat cleaning'
          ],
        },
        {
          name: 'AC Service',
          icon: 'ac',
          color: 'cyan',
          keywords: ['ac', 'air conditioning', 'cooling', 'refrigerant', 'climate'],
        },
        {
          name: 'Fuel',
          icon: 'fuel',
          color: 'amber',
          keywords: ['fuel', 'gas', 'petrol', 'diesel', 'gasoline', 'refuel'],
        },
        {
          name: 'Insurance',
          icon: 'insurance',
          color: 'green',
          keywords: ['insurance', 'policy', 'coverage', 'premium', 'claim'],
          isSpecial: true,
        },
        {
          name: 'Breakdown Assistance',
          icon: 'breakdown',
          color: 'red',
          keywords: ['breakdown', 'assistance', 'roadside', 'towing', 'emergency', 'rescue', 'tow', 'recovery'],
        },
      ];
    }
  };

  // Filter services based on search, category, and recommended keywords
  const getFilteredServices = () => {
    let filtered = services;
    
    // Filter by recommended keywords (from recommended service selection)
    if (recommendedKeywords && recommendedKeywords.length > 0) {
      filtered = filtered.filter(service => {
        const name = (service.name || '').toLowerCase();
        const description = (service.description || '').toLowerCase();
        const category = (service.category?.name || '').toLowerCase();
        
        // Check if any keyword matches
        return recommendedKeywords.some(keyword => {
          const lowerKeyword = keyword.toLowerCase();
          return name.includes(lowerKeyword) || 
                 description.includes(lowerKeyword) || 
                 category.includes(lowerKeyword);
        });
      });
    }
    
    // Filter by category group
    if (selectedCategoryGroup && !recommendedKeywords) {
      const group = FrontendCategoryGroups.groups.find(g => g.name === selectedCategoryGroup);
      if (group) {
        filtered = filtered.filter(service => {
          const categoryName = service.category?.name || '';
          return group.backendCategories.includes(categoryName);
        });
      }
    }
    
    // Filter by search query
    if (serviceSearchQuery.trim() && !recommendedKeywords) {
      const query = serviceSearchQuery.toLowerCase().trim();
      filtered = filtered.filter(service => 
        service.name.toLowerCase().includes(query) ||
        service.description?.toLowerCase().includes(query) ||
        service.category?.name?.toLowerCase().includes(query)
      );
    }
    
    return filtered;
  };
  
  const handleRecommendedServiceClick = (recommended: any) => {
    // Special handling for insurance
    if (recommended.isSpecial && recommended.name === 'Insurance') {
      router.push('/insurance/marketplace');
      return;
    }
    
    setRecommendedKeywords(recommended.keywords);
    setServiceSearchQuery(recommended.keywords[0] || '');
    setSelectedCategoryGroup(null);
    setSelectedRecommendedService(recommended.name);
  };
  
  const clearFilters = () => {
    setServiceSearchQuery('');
    setSelectedCategoryGroup(null);
    setSelectedRecommendedService(null);
    setRecommendedKeywords(null);
  };

  useEffect(() => {
    setIsLoading(vehiclesLoading || servicesLoading);
  }, [vehiclesLoading, servicesLoading]);

  // Fetch matched providers when services change
  useEffect(() => {
    console.log('🔍 [Provider] useEffect triggered - selectedServices:', selectedServices.length, 'recommendedOnly:', recommendedOnly);
    if (selectedServices.length > 0) {
      fetchMatchedProviders();
    } else {
      console.log('🔍 [Provider] No services selected, clearing providers');
      setMatchedProviders([]);
      setSelectedProvider(null);
    }
  }, [selectedServices, recommendedOnly]);

  const fetchMatchedProviders = async () => {
    if (selectedServices.length === 0) {
      console.log('🔍 [Provider] No services selected, skipping provider fetch');
      return;
    }
    
    console.log('🔍 [Provider] Starting to fetch matched providers');
    console.log('🔍 [Provider] Selected services:', selectedServices);
    console.log('🔍 [Provider] Recommended only:', recommendedOnly);
    
    setProvidersLoading(true);
    try {
      // Extract service IDs - matching Flutter implementation
      const serviceIds = selectedServices.map((s) => {
        const id = s.id;
        if (!id) {
          console.warn('⚠️ [Provider] Service object missing ID:', s);
          return null;
        }
        return id.toString();
      }).filter(id => id !== null);
      
      console.log('🔍 [Provider] Service IDs extracted:', serviceIds);
      
      // Build query string exactly like Flutter: service_ids=id1&service_ids=id2&match_all=true
      const queryString = serviceIds.map(id => `service_ids=${id}`).join('&');
      const matchAll = recommendedOnly ? 'true' : 'false';
      const url = `/api/service-provider-service/providers?${queryString}&match_all=${matchAll}`;
      
      console.log('🔍 [Provider] Fetching from URL:', url);
      console.log('🔍 [Provider] Full URL breakdown:', {
        base: '/api/service-provider-service/providers',
        queryString,
        matchAll,
        fullUrl: url
      });
      
      const response = await apiRequest(url);
      if (!response) {
        console.error('❌ [Provider] No response from apiRequest (likely auth error)');
        setMatchedProviders([]);
        return;
      }
      console.log('🔍 [Provider] Response status:', response.status);
      console.log('🔍 [Provider] Response ok?', response.ok);
      
      if (response.ok) {
        const data = await response.json();
        console.log('✅ [Provider] Providers data received:', data);
        console.log('✅ [Provider] Is array?', Array.isArray(data));
        console.log('✅ [Provider] Providers count:', Array.isArray(data) ? data.length : 'Not an array');
        
        const providers = Array.isArray(data) ? data : [];
        console.log('✅ [Provider] Setting matched providers:', providers);
        setMatchedProviders(providers);
        
        if (providers.length === 0) {
          console.warn('⚠️ [Provider] No providers found matching selected services');
        } else {
          console.log('✅ [Provider] Successfully loaded', providers.length, 'providers');
        }
      } else {
        const errorText = await response.text().catch(() => 'Unknown error');
        console.error('❌ [Provider] Failed to fetch providers. Status:', response.status);
        console.error('❌ [Provider] Error response:', errorText);
        setMatchedProviders([]);
      }
    } catch (error) {
      console.error('❌ [Provider] Error fetching providers:', error);
      console.error('❌ [Provider] Error details:', {
        message: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined
      });
      setMatchedProviders([]);
    } finally {
      setProvidersLoading(false);
      console.log('🔍 [Provider] Provider fetch completed');
    }
  };

  const handleServiceToggle = (service: Service) => {
    setSelectedServices(prev => {
      const exists = prev.find(s => s.id === service.id);
      if (exists) {
        return prev.filter(s => s.id !== service.id);
      } else {
        return [...prev, service];
      }
    });
  };

  const handleNext = () => {
    const steps: BookingStep[] = ['vehicle-service', 'provider', 'scheduling', 'pricing', 'confirmation'];
    const currentIndex = steps.indexOf(currentStep);
    if (currentIndex < steps.length - 1) {
      setCurrentStep(steps[currentIndex + 1]);
    }
  };

  const handleBack = () => {
    const steps: BookingStep[] = ['vehicle-service', 'provider', 'scheduling', 'pricing', 'confirmation'];
    const currentIndex = steps.indexOf(currentStep);
    if (currentIndex > 0) {
      setCurrentStep(steps[currentIndex - 1]);
    }
  };

  const canProceed = () => {
    switch (currentStep) {
      case 'vehicle-service':
        return selectedVehicleId && selectedServices.length > 0;
      case 'provider':
        return selectedProvider !== null;
      case 'scheduling':
        return selectedDate !== null && selectedTime !== '';
      case 'pricing':
        return true;
      default:
        return false;
    }
  };

  const handleSubmit = async () => {
    if (!userData || !selectedVehicleId || selectedServices.length === 0 || !selectedProvider || !selectedDate || !selectedTime) {
      alert('Please complete all required fields');
      return;
    }
    
    const userId = (userData as any)?.id || user?.id;
    if (!userId) {
      alert('Please log in to create a booking');
      router.push('/login');
      return;
    }

    setSubmitting(true);
    try {
      const dateTime = new Date(selectedDate);
      const [hours, minutes] = selectedTime.split(':');
      dateTime.setHours(parseInt(hours), parseInt(minutes));

      for (const service of selectedServices) {
        const serviceId = service.id;
        const providerId = selectedProvider.provider_id || selectedProvider.id;
        const negotiatedPrice = negotiatedPrices[serviceId] ?? servicePrices[serviceId] ?? 0;
        const basePrice = servicePrices[serviceId] ?? 0;

        const bookingData = {
          user_id: typeof userId === 'string' ? parseInt(userId) : userId,
          vehicle_id: selectedVehicleId,
          provider_id: providerId,
          service_id: serviceId,
          scheduled_at: dateTime.toISOString(),
          base_price: basePrice,
          agreed_price: negotiatedPrice,
          has_negotiated: hasNegotiated,
          negotiation_notes: hasNegotiated ? 'Price negotiated with provider' : null,
          service_location: serviceLocation,
        };

        const response = await fetch('/api/bookings', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(bookingData),
        });

        if (!response.ok) {
          throw new Error('Failed to create booking');
        }
      }

      setCurrentStep('confirmation');
    } catch (error) {
      console.error('Booking failed:', error);
      alert('Failed to create booking. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleCallProvider = (provider: Provider) => {
    const phone = provider.contact_info?.phone || provider.phone;
    if (phone) {
      window.location.href = `tel:${phone}`;
      trackCommunication('phone_call', phone);
    }
  };

  const handleWhatsApp = (provider: Provider) => {
    const phone = provider.contact_info?.phone || provider.phone;
    if (phone) {
      const cleanPhone = phone.replace(/\D/g, '');
      const whatsappPhone = cleanPhone.startsWith('254') ? cleanPhone : `254${cleanPhone}`;
      const serviceNames = selectedServices.map(s => s.name).join(', ');
      const message = `Hello! I'm interested in your services for: ${serviceNames}. Can we discuss pricing and availability?`;
      window.open(`https://wa.me/${whatsappPhone}?text=${encodeURIComponent(message)}`, '_blank');
      trackCommunication('whatsapp', phone);
    }
  };

  const handleSMS = (provider: Provider) => {
    const phone = provider.contact_info?.phone || provider.phone;
    if (phone) {
      const serviceNames = selectedServices.map(s => s.name).join(', ');
      const message = `Hello! I'm interested in your services for: ${serviceNames}. Can we discuss pricing and availability?`;
      window.location.href = `sms:${phone}?body=${encodeURIComponent(message)}`;
      trackCommunication('sms', phone);
    }
  };

  const handleEmail = (provider: Provider) => {
    const email = provider.contact_info?.email || provider.email;
    if (email) {
      const serviceNames = selectedServices.map(s => s.name).join(', ');
      const subject = `Service Inquiry - ${serviceNames}`;
      const body = `Hello ${provider.provider_name || 'Provider'},

I'm interested in your services for: ${serviceNames}.

Can we discuss pricing and availability?

Thank you!`;
      window.location.href = `mailto:${email}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
      trackCommunication('email', email);
    }
  };

  const trackCommunication = (method: string, contact: string) => {
    setContactHistory(prev => [...prev, {
      method,
      contact,
      timestamp: new Date(),
      provider_id: selectedProvider?.provider_id || selectedProvider?.id,
      provider_name: selectedProvider?.provider_name || selectedProvider?.name,
    }]);
  };

  const calculateTotalCost = () => {
    return selectedServices.reduce((total, service) => {
      const serviceId = service.id;
      const price = negotiatedPrices[serviceId] ?? servicePrices[serviceId] ?? 0;
      return total + price;
    }, 0);
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              {currentStep !== 'vehicle-service' && (
                <button
                  onClick={handleBack}
                  className="p-2 hover:bg-gray-100 rounded-lg"
                >
                  <ArrowLeft className="h-5 w-5" />
                </button>
              )}
              <h1 className="text-xl font-bold text-gray-900">
                {isPurchaseMode ? 'Order Spare Parts' : 'Book Service'}
              </h1>
            </div>
            <button
              onClick={() => setIsPurchaseMode(!isPurchaseMode)}
              className="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
              style={{
                backgroundColor: isPurchaseMode ? '#3b82f6' : '#f97316',
                color: 'white',
              }}
            >
              {isPurchaseMode ? (
                <>
                  <Wrench className="h-4 w-4 inline mr-2" />
                  Book Service
                </>
              ) : (
                <>
                  <ShoppingCart className="h-4 w-4 inline mr-2" />
                  Spare Parts
                </>
              )}
            </button>
          </div>
          
          {/* Progress indicator */}
          <div className="mt-4 flex space-x-2">
            {['vehicle-service', 'provider', 'scheduling', 'pricing'].map((step, index) => {
              const stepIndex = ['vehicle-service', 'provider', 'scheduling', 'pricing', 'confirmation'].indexOf(currentStep);
              const isActive = index <= stepIndex;
              return (
                <div
                  key={step}
                  className={`flex-1 h-1 rounded ${
                    isActive ? 'bg-blue-600' : 'bg-gray-200'
                  }`}
                />
              );
            })}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 py-8">
        {currentStep === 'vehicle-service' && (
          <VehicleServiceStep
            vehicles={vehicles}
            selectedVehicleId={selectedVehicleId}
            onVehicleChange={setSelectedVehicleId}
            services={services}
            filteredServices={getFilteredServices()}
            recommendedServicesData={getRecommendedServicesData()}
            selectedServices={selectedServices}
            onServiceToggle={handleServiceToggle}
            isPurchaseMode={isPurchaseMode}
            searchQuery={serviceSearchQuery}
            onSearchChange={(query) => {
              setServiceSearchQuery(query);
              if (query.trim()) {
                setSelectedRecommendedService(null);
                setRecommendedKeywords(null);
              }
            }}
            selectedCategoryGroup={selectedCategoryGroup}
            onCategoryGroupChange={(group) => {
              setSelectedCategoryGroup(group);
              setSelectedRecommendedService(null);
              setRecommendedKeywords(null);
            }}
            selectedRecommendedService={selectedRecommendedService}
            onRecommendedServiceClick={handleRecommendedServiceClick}
            onClearFilters={clearFilters}
            hasActiveFilters={!!(serviceSearchQuery || selectedCategoryGroup || selectedRecommendedService)}
          />
        )}

        {currentStep === 'provider' && (
          <ProviderStep
            providers={matchedProviders}
            selectedProvider={selectedProvider}
            onProviderSelect={setSelectedProvider}
            recommendedOnly={recommendedOnly}
            onFilterChange={setRecommendedOnly}
            loading={providersLoading}
            selectedServices={selectedServices}
            onOpenSelector={() => setIsProviderSelectorOpen(true)}
            onCall={handleCallProvider}
            onWhatsApp={handleWhatsApp}
            onSMS={handleSMS}
            onEmail={handleEmail}
            contactHistory={contactHistory}
            serviceLocation={serviceLocation}
          />
        )}
        
        {/* Enhanced Provider Selector Modal */}
        <EnhancedProviderSelector
          isOpen={isProviderSelectorOpen}
          onClose={() => setIsProviderSelectorOpen(false)}
          providers={matchedProviders}
          selectedProvider={selectedProvider}
          onSelect={(provider: Provider) => {
            setSelectedProvider(provider as Provider);
            setIsProviderSelectorOpen(false);
          }}
          recommendedOnly={recommendedOnly}
          onFilterChange={(value) => {
            setRecommendedOnly(value);
            // Refetch providers with new filter
            fetchMatchedProviders();
          }}
          loading={providersLoading}
          selectedServices={selectedServices}
          onCall={(provider: any) => handleCallProvider(provider as Provider)}
          onWhatsApp={(provider: any) => handleWhatsApp(provider as Provider)}
          onSMS={(provider: any) => handleSMS(provider as Provider)}
          onEmail={(provider: any) => handleEmail(provider as Provider)}
          serviceLocation={serviceLocation}
        />

        {currentStep === 'scheduling' && (
          <SchedulingStep
            selectedDate={selectedDate}
            onDateChange={setSelectedDate}
            selectedTime={selectedTime}
            onTimeChange={setSelectedTime}
            serviceLocation={serviceLocation}
            onLocationChange={setServiceLocation}
          />
        )}

        {currentStep === 'pricing' && (
          <PricingStep
            selectedServices={selectedServices}
            selectedProvider={selectedProvider}
            servicePrices={servicePrices}
            negotiatedPrices={negotiatedPrices}
            onPriceUpdate={(serviceId, price) => {
              setNegotiatedPrices(prev => ({ ...prev, [serviceId]: price }));
            }}
            hasNegotiated={hasNegotiated}
            onNegotiatedChange={setHasNegotiated}
            totalCost={calculateTotalCost()}
          />
        )}

        {currentStep === 'confirmation' && (
          <ConfirmationStep
            selectedVehicle={vehicles.find(v => v.id === selectedVehicleId)}
            selectedServices={selectedServices}
            selectedProvider={selectedProvider}
            selectedDate={selectedDate}
            selectedTime={selectedTime}
            totalCost={calculateTotalCost()}
            onFinish={() => {
              // Redirect to home for car owners, or dashboard for providers
              if (user?.providerId || user?.userType === 'provider') {
                router.push(`/provider/dashboard?providerId=${user.providerId}`);
              } else {
                router.push('/home');
              }
            }}
          />
        )}

        {/* Navigation buttons */}
        {currentStep !== 'confirmation' && (
          <div className="mt-8 flex justify-between">
            <button
              onClick={handleBack}
              disabled={currentStep === 'vehicle-service'}
              className="px-6 py-3 rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed bg-gray-200 hover:bg-gray-300"
            >
              Back
            </button>
            <button
              onClick={currentStep === 'pricing' ? handleSubmit : handleNext}
              disabled={!canProceed() || submitting}
              className="px-6 py-3 rounded-lg font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {submitting ? (
                <>
                  <Loader2 className="h-4 w-4 inline animate-spin mr-2" />
                  Submitting...
                </>
              ) : currentStep === 'pricing' ? (
                'Confirm Booking'
              ) : (
                'Continue'
              )}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

// Step Components
const VehicleServiceStep: React.FC<{
  vehicles: Vehicle[];
  selectedVehicleId: string;
  onVehicleChange: (id: string) => void;
  services: Service[];
  filteredServices: Service[];
  recommendedServicesData: any[];
  selectedServices: Service[];
  onServiceToggle: (service: Service) => void;
  isPurchaseMode: boolean;
  searchQuery: string;
  onSearchChange: (query: string) => void;
  selectedCategoryGroup: string | null;
  onCategoryGroupChange: (group: string | null) => void;
  selectedRecommendedService: string | null;
  onRecommendedServiceClick: (recommended: any) => void;
  onClearFilters: () => void;
  hasActiveFilters: boolean;
}> = ({ 
  vehicles, 
  selectedVehicleId, 
  onVehicleChange, 
  services,
  filteredServices,
  recommendedServicesData,
  selectedServices, 
  onServiceToggle, 
  isPurchaseMode,
  searchQuery,
  onSearchChange,
  selectedCategoryGroup,
  onCategoryGroupChange,
  selectedRecommendedService,
  onRecommendedServiceClick,
  onClearFilters,
  hasActiveFilters
}) => {
  const [isVehicleDropdownOpen, setIsVehicleDropdownOpen] = useState(false);
  
  const handleDropdownToggle = () => {
    setIsVehicleDropdownOpen(!isVehicleDropdownOpen);
  };
  
  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h2 className="text-lg font-semibold mb-4">Select Vehicle</h2>
        {/* Custom dropdown to fix visibility issue */}
        <div className="relative">
          <button
            type="button"
            onClick={handleDropdownToggle}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white text-left flex items-center justify-between"
          >
            <span>
              {vehicles.find(v => v.id === selectedVehicleId) 
                ? `${vehicles.find(v => v.id === selectedVehicleId)?.plate || 'No Plate'} - ${vehicles.find(v => v.id === selectedVehicleId)?.make || ''} ${vehicles.find(v => v.id === selectedVehicleId)?.model || ''} ${vehicles.find(v => v.id === selectedVehicleId)?.yom ? `(${vehicles.find(v => v.id === selectedVehicleId)?.yom})` : ''}`
                : vehicles.length > 0 ? 'Select a vehicle' : 'No vehicles available'}
            </span>
            <ChevronDown className={`h-4 w-4 transform transition-transform ${isVehicleDropdownOpen ? 'rotate-180' : ''}`} />
          </button>
          
          {isVehicleDropdownOpen && (
            <>
              <div 
                className="fixed inset-0 z-[100]" 
                onClick={() => {
                  console.log('🚗 [VehicleServiceStep] Dropdown closed by overlay click');
                  setIsVehicleDropdownOpen(false);
                }}
              />
              <div className="absolute z-[200] w-full mt-1 bg-white border-2 border-gray-300 rounded-lg shadow-2xl max-h-60 overflow-y-auto" style={{ position: 'absolute', top: '100%', left: 0, right: 0 }}>
                {(() => {
                  console.log('🚗 [VehicleServiceStep] Rendering dropdown with vehicles:', vehicles);
                  return null;
                })()}
                {vehicles.length === 0 ? (
                  <div className="px-4 py-3 text-gray-500 text-center">
                    No vehicles available
                  </div>
                ) : (
                  vehicles.map(vehicle => {
                    console.log('🚗 [VehicleServiceStep] Rendering vehicle:', vehicle);
                    return (
                      <button
                        key={vehicle.id}
                        type="button"
                        onClick={() => {
                          console.log('🚗 [VehicleServiceStep] Vehicle selected:', vehicle);
                          onVehicleChange(vehicle.id);
                          setIsVehicleDropdownOpen(false);
                        }}
                        className={`w-full px-4 py-3 text-left hover:bg-gray-50 transition-colors border-b border-gray-100 last:border-b-0 ${
                          selectedVehicleId === vehicle.id ? 'bg-blue-50 text-blue-600 font-medium' : 'text-gray-900'
                        }`}
                      >
                        {vehicle.plate || 'No Plate'} - {vehicle.make || ''} {vehicle.model || ''} {vehicle.yom ? `(${vehicle.yom})` : ''}
                      </button>
                    );
                  })
                )}
              </div>
            </>
          )}
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm p-6">
        <h2 className="text-lg font-semibold mb-4">
          {isPurchaseMode ? 'Select Spare Parts' : 'Select Services'}
        </h2>
        
        {/* Search Bar */}
        <div className="mb-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search services..."
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              className="w-full pl-10 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            {searchQuery && (
              <button
                onClick={() => onSearchChange('')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                <X className="h-5 w-5" />
              </button>
            )}
          </div>
        </div>
        
        {/* Category Group Filters */}
        <div className="mb-4">
          <div className="flex flex-wrap gap-2">
            <button
              onClick={() => onCategoryGroupChange(null)}
              className={`px-3 py-1 rounded-full text-sm font-medium transition-colors ${
                selectedCategoryGroup === null
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              All Services
            </button>
            {FrontendCategoryGroups.getAllGroups().map(group => {
              const Icon = group.icon;
              const colorClasses: Record<string, { active: string; inactive: string }> = {
                blue: {
                  active: 'bg-blue-600 text-white',
                  inactive: 'bg-blue-100 text-blue-700 hover:bg-blue-200'
                },
                orange: {
                  active: 'bg-orange-600 text-white',
                  inactive: 'bg-orange-100 text-orange-700 hover:bg-orange-200'
                },
                purple: {
                  active: 'bg-purple-600 text-white',
                  inactive: 'bg-purple-100 text-purple-700 hover:bg-purple-200'
                },
                green: {
                  active: 'bg-green-600 text-white',
                  inactive: 'bg-green-100 text-green-700 hover:bg-green-200'
                },
                teal: {
                  active: 'bg-teal-600 text-white',
                  inactive: 'bg-teal-100 text-teal-700 hover:bg-teal-200'
                },
                cyan: {
                  active: 'bg-cyan-600 text-white',
                  inactive: 'bg-cyan-100 text-cyan-700 hover:bg-cyan-200'
                }
              };
              const colors = colorClasses[group.color] || colorClasses.blue;
              return (
                <button
                  key={group.name}
                  onClick={() => onCategoryGroupChange(group.name)}
                  className={`px-3 py-1 rounded-full text-sm font-medium transition-colors flex items-center space-x-1 ${
                    selectedCategoryGroup === group.name
                      ? colors.active
                      : colors.inactive
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  <span>{group.name}</span>
                </button>
              );
            })}
          </div>
        </div>
        
        {/* Recommended Services - Matching Flutter implementation */}
        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-700 mb-3">
            {isPurchaseMode ? 'Popular Parts' : 'Popular Services'}
          </h3>
          <div className="bg-gray-50 border border-gray-200 rounded-lg p-3">
            {/* First row - 2 services */}
            <div className="grid grid-cols-2 gap-2 mb-2">
              {recommendedServicesData.slice(0, 2).map((recommended) => (
                <RecommendedPill
                  key={recommended.name}
                  recommended={recommended}
                  isSelected={selectedRecommendedService === recommended.name}
                  onClick={() => onRecommendedServiceClick(recommended)}
                />
              ))}
            </div>
            {/* Second row - 2 services */}
            <div className="grid grid-cols-2 gap-2 mb-2">
              {recommendedServicesData.slice(2, 4).map((recommended) => (
                <RecommendedPill
                  key={recommended.name}
                  recommended={recommended}
                  isSelected={selectedRecommendedService === recommended.name}
                  onClick={() => onRecommendedServiceClick(recommended)}
                />
              ))}
            </div>
            {/* Third row - 2 services */}
            <div className="grid grid-cols-2 gap-2 mb-2">
              {recommendedServicesData.slice(4, 6).map((recommended) => (
                <RecommendedPill
                  key={recommended.name}
                  recommended={recommended}
                  isSelected={selectedRecommendedService === recommended.name}
                  onClick={() => onRecommendedServiceClick(recommended)}
                />
              ))}
            </div>
            {/* Fourth row - Insurance and Breakdown Assistance */}
            {recommendedServicesData.length > 6 && (
              <div className="grid grid-cols-2 gap-2">
                {recommendedServicesData.slice(6, 8).map((recommended) => (
                  <RecommendedPill
                    key={recommended.name}
                    recommended={recommended}
                    isSelected={selectedRecommendedService === recommended.name}
                    onClick={() => onRecommendedServiceClick(recommended)}
                  />
                ))}
              </div>
            )}
          </div>
        </div>
        
        {/* All Services List - Only show when filters are active */}
        {hasActiveFilters ? (
          <div className="space-y-2 max-h-96 overflow-y-auto">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-semibold text-gray-700">
                {searchQuery || selectedCategoryGroup || selectedRecommendedService ? 'Search Results' : 'All Services'}
              </h3>
              {hasActiveFilters && (
                <button
                  onClick={onClearFilters}
                  className="text-xs text-blue-600 hover:text-blue-800 flex items-center space-x-1"
                >
                  <X className="h-3 w-3" />
                  <span>Clear filters</span>
                </button>
              )}
            </div>
            {filteredServices.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <p>No services found matching your search.</p>
                <p className="text-sm mt-2">Try adjusting your search or filters</p>
              </div>
            ) : (
              filteredServices.map(service => {
                const isSelected = selectedServices.some(s => s.id === service.id);
                return (
                  <div
                    key={service.id}
                    onClick={() => onServiceToggle(service)}
                    className={`p-4 border-2 rounded-lg cursor-pointer transition-colors ${
                      isSelected
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <h3 className="font-medium">{service.name}</h3>
                        {service.description && (
                          <p className="text-sm text-gray-600 mt-1">{service.description}</p>
                        )}
                        {service.min_price !== undefined && (
                          <p className="text-sm text-blue-600 mt-1">
                            {service.currency} {service.min_price}
                            {service.max_price && service.max_price !== service.min_price && ` - ${service.max_price}`}
                          </p>
                        )}
                      </div>
                      <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                        isSelected ? 'border-blue-500 bg-blue-500' : 'border-gray-300'
                      }`}>
                        {isSelected && <CheckCircle className="h-4 w-4 text-white" />}
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        ) : (
          <div className="text-center py-12 text-gray-500">
            <div className="mb-4">
              <svg className="mx-auto h-16 w-16 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-700 mb-2">Select a service category above</h3>
            <p className="text-sm">
              {isPurchaseMode 
                ? 'Choose from popular parts or search to find what you need'
                : 'Choose from popular services or search to find what you need'}
            </p>
          </div>
        )}
        {selectedServices.length > 0 && (
          <div className="mt-4 p-3 bg-blue-50 rounded-lg">
            <p className="text-sm text-blue-800">
              {selectedServices.length} {isPurchaseMode ? 'part(s)' : 'service(s)'} selected
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

const ProviderStep: React.FC<{
  providers: Provider[];
  selectedProvider: Provider | null;
  onProviderSelect: (provider: Provider) => void;
  recommendedOnly: boolean;
  onFilterChange: (value: boolean) => void;
  loading: boolean;
  selectedServices: Service[];
  onOpenSelector: () => void;
  onCall: (provider: Provider) => void;
  onWhatsApp: (provider: Provider) => void;
  onSMS: (provider: Provider) => void;
  onEmail: (provider: Provider) => void;
  contactHistory: any[];
  serviceLocation?: any;
}> = ({
  providers,
  selectedProvider,
  onProviderSelect,
  recommendedOnly,
  onFilterChange,
  loading,
  selectedServices,
  onOpenSelector,
  onCall,
  onWhatsApp,
  onSMS,
  onEmail,
  contactHistory,
  serviceLocation,
}) => {
  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold">Select Provider</h2>
          <button
            onClick={() => onFilterChange(!recommendedOnly)}
            className="px-4 py-2 text-sm rounded-lg border border-gray-300 hover:bg-gray-50 flex items-center space-x-2"
          >
            <Filter className="h-4 w-4" />
            <span>{recommendedOnly ? 'Recommended Only' : 'All Matching'}</span>
          </button>
        </div>

        {loading ? (
          <div className="text-center py-8">
            <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto" />
            <p className="mt-2 text-gray-600">Loading providers...</p>
          </div>
        ) : providers.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <p>No providers found for selected services</p>
            <button
              onClick={onOpenSelector}
              className="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Browse All Providers
            </button>
          </div>
        ) : (
          <>
            {/* Selected Provider Display */}
            {selectedProvider ? (
              <div className="mb-6">
                <div className="p-4 border-2 border-blue-500 bg-blue-50 rounded-lg">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-2">
                        <h3 className="font-medium text-lg">{selectedProvider.provider_name || selectedProvider.name}</h3>
                        {selectedProvider.is_registered && (
                          <span className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">
                            Verified
                          </span>
                        )}
                        {selectedProvider.rating && (
                          <span className="text-sm text-yellow-600">⭐ {selectedProvider.rating.toFixed(1)}</span>
                        )}
                      </div>
                      {selectedProvider.location && (
                        <p className="text-sm text-gray-600 mt-1">
                          📍 {typeof selectedProvider.location === 'string' 
                            ? selectedProvider.location 
                            : selectedProvider.location.area || 'Location not specified'}
                        </p>
                      )}
                    </div>
                    <button
                      onClick={onOpenSelector}
                      className="ml-4 px-3 py-1 text-sm text-blue-600 hover:text-blue-700 underline"
                    >
                      Change
                    </button>
                  </div>
                  
                  {/* Contact Buttons */}
                  <div className="mt-4 pt-4 border-t border-gray-200 flex flex-wrap gap-2">
                    <button
                      onClick={() => onCall(selectedProvider)}
                      className="flex-1 px-3 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 flex items-center justify-center space-x-2"
                    >
                      <Phone className="h-4 w-4" />
                      <span>Call</span>
                    </button>
                    <button
                      onClick={() => onWhatsApp(selectedProvider)}
                      className="flex-1 px-3 py-2 bg-green-500 text-white rounded-lg text-sm font-medium hover:bg-green-600 flex items-center justify-center space-x-2"
                    >
                      <MessageCircle className="h-4 w-4" />
                      <span>WhatsApp</span>
                    </button>
                    <button
                      onClick={() => onSMS(selectedProvider)}
                      className="px-3 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700"
                    >
                      <MessageCircle className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => onEmail(selectedProvider)}
                      className="px-3 py-2 bg-orange-600 text-white rounded-lg text-sm font-medium hover:bg-orange-700"
                    >
                      <Mail className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-center py-8">
                <button
                  onClick={onOpenSelector}
                  className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium text-lg"
                >
                  Select Provider
                </button>
                <p className="mt-4 text-sm text-gray-500">
                  {providers.length} provider{providers.length !== 1 ? 's' : ''} available
                </p>
              </div>
            )}

            {/* Quick Preview of Available Providers */}
            {!selectedProvider && providers.length > 0 && (
              <div className="mt-6">
                <p className="text-sm text-gray-600 mb-3">Quick preview (tap "Select Provider" above to see all options):</p>
                <div className="space-y-2 max-h-48 overflow-y-auto">
                  {providers.slice(0, 3).map((provider) => {
                    const providerId = provider.provider_id || provider.id;
                    return (
                      <div
                        key={providerId}
                        className="p-3 border border-gray-200 rounded-lg"
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex-1">
                            <div className="flex items-center space-x-2">
                              <h4 className="font-medium text-sm">{provider.provider_name || provider.name}</h4>
                              {provider.rating && (
                                <span className="text-xs text-yellow-600">⭐ {provider.rating.toFixed(1)}</span>
                              )}
                            </div>
                            {provider.location && (
                              <p className="text-xs text-gray-500 mt-1">
                                {typeof provider.location === 'string' 
                                  ? provider.location 
                                  : provider.location.area || 'Location not specified'}
                              </p>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                  {providers.length > 3 && (
                    <p className="text-xs text-gray-500 text-center py-2">
                      +{providers.length - 3} more providers available
                    </p>
                  )}
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

const SchedulingStep: React.FC<{
  selectedDate: Date | null;
  onDateChange: (date: Date | null) => void;
  selectedTime: string;
  onTimeChange: (time: string) => void;
  serviceLocation: any;
  onLocationChange: (location: any) => void;
}> = ({ selectedDate, onDateChange, selectedTime, onTimeChange, serviceLocation, onLocationChange }) => {
  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h2 className="text-lg font-semibold mb-4">Schedule Appointment</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <Calendar className="h-4 w-4 inline mr-2" />
              Date
            </label>
            <input
              type="date"
              value={selectedDate ? selectedDate.toISOString().split('T')[0] : ''}
              onChange={(e) => {
                if (e.target.value) {
                  onDateChange(new Date(e.target.value));
                }
              }}
              min={new Date().toISOString().split('T')[0]}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <Clock className="h-4 w-4 inline mr-2" />
              Time
            </label>
            <input
              type="time"
              value={selectedTime}
              onChange={(e) => onTimeChange(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm p-6">
        <h2 className="text-lg font-semibold mb-4">
          <MapPin className="h-4 w-4 inline mr-2" />
          Service Location
        </h2>
        <textarea
          placeholder="Enter service location (e.g., home address, office, roadside)"
          value={serviceLocation?.address || ''}
          onChange={(e) => onLocationChange({ address: e.target.value })}
          rows={3}
          className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
        <p className="mt-2 text-sm text-gray-500">
          💡 Specify where you need the service (home, office, roadside, etc.)
        </p>
      </div>
    </div>
  );
};

const PricingStep: React.FC<{
  selectedServices: Service[];
  selectedProvider: Provider | null;
  servicePrices: Record<string, number>;
  negotiatedPrices: Record<string, number>;
  onPriceUpdate: (serviceId: string, price: number) => void;
  hasNegotiated: boolean;
  onNegotiatedChange: (value: boolean) => void;
  totalCost: number;
}> = ({ selectedServices, selectedProvider, servicePrices, negotiatedPrices, onPriceUpdate, hasNegotiated, onNegotiatedChange, totalCost }) => {
  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h2 className="text-lg font-semibold mb-4">
          <DollarSign className="h-4 w-4 inline mr-2" />
          Pricing & Negotiation
        </h2>
        <p className="text-sm text-gray-600 mb-4">
          💡 Tip: Contact the provider to discuss pricing before booking!
        </p>
        
        <div className="space-y-4">
          {selectedServices.map(service => {
            const serviceId = service.id;
            const basePrice = servicePrices[serviceId] || 0;
            const negotiatedPrice = negotiatedPrices[serviceId] ?? basePrice;
            const isNegotiated = negotiatedPrices[serviceId] !== undefined && negotiatedPrices[serviceId] !== basePrice;
            
            return (
              <div key={serviceId} className="p-4 border border-gray-200 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <div>
                    <h3 className="font-medium">{service.name}</h3>
                    <p className="text-sm text-gray-600">
                      Base: {service.currency || 'KES'} {basePrice.toLocaleString()}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-lg">
                      {service.currency || 'KES'} {negotiatedPrice.toLocaleString()}
                    </p>
                    {isNegotiated && (
                      <p className="text-xs text-green-600">✅ Negotiated</p>
                    )}
                  </div>
                </div>
                <input
                  type="number"
                  placeholder="Enter negotiated price"
                  value={negotiatedPrice || ''}
                  onChange={(e) => {
                    const price = parseFloat(e.target.value) || 0;
                    onPriceUpdate(serviceId, price);
                  }}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                />
              </div>
            );
          })}
        </div>

        <div className="mt-6 p-4 bg-green-50 rounded-lg border border-green-200">
          <div className="flex items-center justify-between">
            <span className="font-semibold">Total Cost:</span>
            <span className="font-bold text-lg text-green-700">
              KES {totalCost.toLocaleString()}
            </span>
          </div>
          {hasNegotiated && (
            <p className="text-sm text-green-600 mt-2">✅ Negotiated prices included</p>
          )}
        </div>

        <div className="mt-4">
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={hasNegotiated}
              onChange={(e) => onNegotiatedChange(e.target.checked)}
              className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
            />
            <span className="text-sm text-gray-700">I've negotiated prices with the provider</span>
          </label>
        </div>
      </div>
    </div>
  );
};

const ConfirmationStep: React.FC<{
  selectedVehicle: Vehicle | undefined;
  selectedServices: Service[];
  selectedProvider: Provider | null;
  selectedDate: Date | null;
  selectedTime: string;
  totalCost: number;
  onFinish: () => void;
}> = ({ selectedVehicle, selectedServices, selectedProvider, selectedDate, selectedTime, totalCost, onFinish }) => {
  return (
    <div className="bg-white rounded-lg shadow-sm p-8 text-center">
      <CheckCircle className="h-16 w-16 text-green-600 mx-auto mb-4" />
      <h2 className="text-2xl font-bold text-gray-900 mb-2">Booking Complete! 🎉</h2>
      <p className="text-gray-600 mb-8">
        Your service booking has been confirmed successfully.
      </p>
      
      <div className="text-left max-w-md mx-auto space-y-4 mb-8">
        <div>
          <p className="text-sm text-gray-500">Vehicle</p>
          <p className="font-medium">
            {selectedVehicle?.plate || 'N/A'} - {selectedVehicle?.make} {selectedVehicle?.model}
          </p>
        </div>
        <div>
          <p className="text-sm text-gray-500">Services</p>
          <p className="font-medium">
            {selectedServices.map(s => s.name).join(', ')}
          </p>
        </div>
        <div>
          <p className="text-sm text-gray-500">Provider</p>
          <p className="font-medium">
            {selectedProvider?.provider_name || selectedProvider?.name}
          </p>
        </div>
        <div>
          <p className="text-sm text-gray-500">Date & Time</p>
          <p className="font-medium">
            {selectedDate?.toLocaleDateString()} at {selectedTime}
          </p>
        </div>
        <div>
          <p className="text-sm text-gray-500">Total Cost</p>
          <p className="font-medium text-lg">KES {totalCost.toLocaleString()}</p>
        </div>
      </div>

      <button
        onClick={onFinish}
        className="px-8 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
      >
        Done
      </button>
    </div>
  );
};

// Recommended Service Pill Component
const RecommendedPill: React.FC<{
  recommended: any;
  isSelected: boolean;
  onClick: () => void;
}> = ({ recommended, isSelected, onClick }) => {
  const getIcon = () => {
    switch (recommended.icon) {
      case 'oil':
        return <Droplet className="h-4 w-4" />;
      case 'brake':
        return <WrenchIcon className="h-4 w-4" />;
      case 'tire':
        return <Car className="h-4 w-4" />;
      case 'wash':
        return <Droplet className="h-4 w-4" />;
      case 'ac':
        return <Wind className="h-4 w-4" />;
      case 'fuel':
        return <FuelIcon className="h-4 w-4" />;
      case 'insurance':
        return <Shield className="h-4 w-4" />;
      case 'breakdown':
        return <AlertTriangle className="h-4 w-4" />;
      default:
        return <WrenchIcon className="h-4 w-4" />;
    }
  };

  const colorClasses: Record<string, { bg: string; border: string; text: string; shadow: string }> = {
    orange: {
      bg: isSelected ? 'bg-orange-100' : 'bg-white',
      border: isSelected ? 'border-orange-500 border-2' : 'border-orange-300 border',
      text: 'text-orange-600',
      shadow: isSelected ? 'shadow-md' : 'shadow-sm'
    },
    red: {
      bg: isSelected ? 'bg-red-100' : 'bg-white',
      border: isSelected ? 'border-red-500 border-2' : 'border-red-300 border',
      text: 'text-red-600',
      shadow: isSelected ? 'shadow-md' : 'shadow-sm'
    },
    blue: {
      bg: isSelected ? 'bg-blue-100' : 'bg-white',
      border: isSelected ? 'border-blue-500 border-2' : 'border-blue-300 border',
      text: 'text-blue-600',
      shadow: isSelected ? 'shadow-md' : 'shadow-sm'
    },
    green: {
      bg: isSelected ? 'bg-green-100' : 'bg-white',
      border: isSelected ? 'border-green-500 border-2' : 'border-green-300 border',
      text: 'text-green-600',
      shadow: isSelected ? 'shadow-md' : 'shadow-sm'
    },
    cyan: {
      bg: isSelected ? 'bg-cyan-100' : 'bg-white',
      border: isSelected ? 'border-cyan-500 border-2' : 'border-cyan-300 border',
      text: 'text-cyan-600',
      shadow: isSelected ? 'shadow-md' : 'shadow-sm'
    },
    amber: {
      bg: isSelected ? 'bg-amber-100' : 'bg-white',
      border: isSelected ? 'border-amber-500 border-2' : 'border-amber-300 border',
      text: 'text-amber-600',
      shadow: isSelected ? 'shadow-md' : 'shadow-sm'
    }
  };

  const colors = colorClasses[recommended.color] || colorClasses.blue;

  return (
    <button
      onClick={onClick}
      className={`${colors.bg} ${colors.border} ${colors.text} ${colors.shadow} rounded-full px-3 py-2 flex items-center justify-center space-x-1.5 transition-all hover:scale-105`}
    >
      <span className={isSelected ? 'font-bold' : 'font-semibold'}>
        {getIcon()}
      </span>
      <span className={`text-xs ${isSelected ? 'font-bold' : 'font-semibold'}`}>
        {recommended.name}
      </span>
    </button>
  );
};

export default BookingPage;

