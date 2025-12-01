import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { 
  ArrowLeft, 
  ArrowRight, 
  Check, 
  Building, 
  MapPin, 
  Settings, 
  Users,
  Star,
  Phone,
  Mail,
  Globe
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';

interface OnboardingStep {
  id: string;
  title: string;
  description: string;
  component: React.ComponentType<any>;
  validator: (data: any) => boolean;
}

interface OnboardingData {
  businessType?: string;
  selectedGroup?: string;
  selectedBackendCategory?: string;
  name?: string;
  description?: string;
  phone?: string;
  email?: string;
  location?: string;
  locationData?: any;
  selectedServices?: string[];
  availableServices?: any[];
  serviceValues?: Record<string, any>;
}

interface BusinessType {
  id: string;
  name: string;
  description: string;
  icon: string;
  groups: string[];
}

interface ServiceCategory {
  id: number;
  name: string;
  description: string;
  services: Service[];
}

interface Service {
  id: string;
  name: string;
  description: string;
  category: string;
  requirements?: any[];
}

const ProviderOnboarding: React.FC = () => {
  const router = useRouter();
  const [currentStep, setCurrentStep] = useState(0);
  const [onboardingData, setOnboardingData] = useState<OnboardingData>({});
  const [isLoading, setIsLoading] = useState(false);
  const [businessTypes, setBusinessTypes] = useState<BusinessType[]>([]);
  const [serviceCategories, setServiceCategories] = useState<ServiceCategory[]>([]);

  const { data: categoriesData } = useApi<ServiceCategory[]>('/api/service-provider-service/categories');
  const { data: servicesData } = useApi<any[]>('/api/service-provider-service/services');

  useEffect(() => {
    if (categoriesData && Array.isArray(categoriesData)) {
      setServiceCategories(categoriesData);
    }
  }, [categoriesData]);

  const steps: OnboardingStep[] = [
    {
      id: 'business_type',
      title: 'Business Type',
      description: 'What type of business do you run?',
      component: BusinessTypeSelection,
      validator: (data) => !!data.selectedGroup,
    },
    {
      id: 'category',
      title: 'Service Category',
      description: 'Which specific service do you provide?',
      component: CategorySelection,
      validator: (data) => !!data.selectedBackendCategory,
    },
    {
      id: 'details',
      title: 'Business Details',
      description: 'Tell us about your business',
      component: BusinessDetailsForm,
      validator: (data) => {
        return !!(data.name?.trim() && data.description?.trim() && data.phone?.trim() && data.location?.trim());
      },
    },
    {
      id: 'location',
      title: 'Business Location',
      description: 'Pinpoint your exact business location',
      component: LocationSelection,
      validator: (data) => !!data.locationData,
    },
    {
      id: 'services',
      title: 'Select Services',
      description: 'Choose the services you offer',
      component: ServiceSelection,
      validator: (data) => !!(data.selectedServices && data.selectedServices.length > 0),
    },
  ];

  const currentStepConfig = steps[currentStep];
  const isLastStep = currentStep === steps.length - 1;
  const canProceed = currentStepConfig.validator(onboardingData);

  const handleNext = () => {
    if (canProceed) {
      if (isLastStep) {
        handleCompleteRegistration();
      } else {
        setCurrentStep(currentStep + 1);
      }
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleCompleteRegistration = async () => {
    setIsLoading(true);
    try {
      const response = await fetch('/api/service-provider-service/providers', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...onboardingData,
          is_registered: true,
        }),
      });

      if (response.ok) {
        router.push('/provider/dashboard?success=true');
      } else {
        throw new Error('Registration failed');
      }
    } catch (error) {
      console.error('Registration error:', error);
      alert('Registration failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const updateData = (key: string, value: any) => {
    setOnboardingData(prev => ({
      ...prev,
      [key]: value,
    }));
  };

  const progress = ((currentStep + 1) / steps.length) * 100;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between py-6">
            <div className="flex items-center space-x-4">
              {currentStep > 0 && (
                <button
                  onClick={handleBack}
                  className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <ArrowLeft className="h-5 w-5" />
                </button>
              )}
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Service Provider Registration</h1>
                <p className="text-gray-600">Join our network of trusted service providers</p>
              </div>
            </div>
            <div className="text-sm text-gray-500">
              Step {currentStep + 1} of {steps.length}
            </div>
          </div>
          
          {/* Progress Bar */}
          <div className="w-full bg-gray-200 rounded-full h-2 mb-6">
            <div 
              className="bg-primary-600 h-2 rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            ></div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-xl shadow-sm">
          <div className="px-8 py-6 border-b border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900">{currentStepConfig.title}</h2>
            <p className="text-gray-600 mt-1">{currentStepConfig.description}</p>
          </div>
          
          <div className="p-8">
            <currentStepConfig.component
              data={onboardingData}
              onUpdate={updateData}
              businessTypes={businessTypes}
              serviceCategories={serviceCategories}
            />
          </div>

          {/* Navigation */}
          <div className="px-8 py-6 border-t border-gray-200 bg-gray-50 rounded-b-xl">
            <div className="flex justify-between">
              <button
                onClick={handleBack}
                disabled={currentStep === 0}
                className="px-6 py-3 text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ArrowLeft className="h-4 w-4 mr-2 inline" />
                Back
              </button>
              
              <button
                onClick={handleNext}
                disabled={!canProceed || isLoading}
                className="px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center"
              >
                {isLoading ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Processing...
                  </>
                ) : isLastStep ? (
                  <>
                    Complete Registration
                    <Check className="h-4 w-4 ml-2" />
                  </>
                ) : (
                  <>
                    Continue
                    <ArrowRight className="h-4 w-4 ml-2" />
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// Business Type Selection Component
const BusinessTypeSelection: React.FC<{
  data: OnboardingData;
  onUpdate: (key: string, value: any) => void;
  businessTypes: BusinessType[];
}> = ({ data, onUpdate, businessTypes }) => {
  const businessTypeOptions = [
    {
      id: 'automotive',
      name: 'Automotive Services',
      description: 'Car repair, maintenance, and related services',
      icon: '🚗',
      groups: ['Mechanical', 'Electrical', 'Bodywork', 'Tires', 'Oil Change']
    },
    {
      id: 'fuel',
      name: 'Fuel Services',
      description: 'Fuel delivery and related services',
      icon: '⛽',
      groups: ['Fuel Delivery', 'Emergency Fuel', 'Bulk Fuel']
    },
    {
      id: 'towing',
      name: 'Towing Services',
      description: 'Vehicle towing and recovery',
      icon: '🚛',
      groups: ['Emergency Towing', 'Recovery', 'Long Distance']
    },
    {
      id: 'cleaning',
      name: 'Vehicle Cleaning',
      description: 'Car wash and detailing services',
      icon: '🧽',
      groups: ['Car Wash', 'Detailing', 'Interior Cleaning']
    }
  ];

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {businessTypeOptions.map((type) => (
          <div
            key={type.id}
            onClick={() => {
              onUpdate('businessType', type.id);
              onUpdate('selectedGroup', type.groups[0]);
            }}
            className={`p-6 border-2 rounded-xl cursor-pointer transition-all ${
              data.businessType === type.id
                ? 'border-primary-500 bg-primary-50'
                : 'border-gray-200 hover:border-gray-300'
            }`}
          >
            <div className="text-4xl mb-4">{type.icon}</div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">{type.name}</h3>
            <p className="text-gray-600 text-sm">{type.description}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

// Category Selection Component
const CategorySelection: React.FC<{
  data: OnboardingData;
  onUpdate: (key: string, value: any) => void;
  serviceCategories: ServiceCategory[];
}> = ({ data, onUpdate, serviceCategories }) => {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {serviceCategories.map((category) => (
          <div
            key={category.id}
            onClick={() => onUpdate('selectedBackendCategory', category.name)}
            className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
              data.selectedBackendCategory === category.name
                ? 'border-primary-500 bg-primary-50'
                : 'border-gray-200 hover:border-gray-300'
            }`}
          >
            <h3 className="font-semibold text-gray-900">{category.name}</h3>
            <p className="text-sm text-gray-600">{category.description}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

// Business Details Form Component
const BusinessDetailsForm: React.FC<{
  data: OnboardingData;
  onUpdate: (key: string, value: any) => void;
}> = ({ data, onUpdate }) => {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Business Name *
          </label>
          <input
            type="text"
            value={data.name || ''}
            onChange={(e) => onUpdate('name', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            placeholder="Your business name"
          />
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Phone Number *
          </label>
          <input
            type="tel"
            value={data.phone || ''}
            onChange={(e) => onUpdate('phone', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            placeholder="+254 700 000 000"
          />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Email Address
        </label>
        <input
          type="email"
          value={data.email || ''}
          onChange={(e) => onUpdate('email', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          placeholder="business@example.com"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Business Description *
        </label>
        <textarea
          value={data.description || ''}
          onChange={(e) => onUpdate('description', e.target.value)}
          rows={4}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          placeholder="Describe your business and services..."
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          General Location *
        </label>
        <input
          type="text"
          value={data.location || ''}
          onChange={(e) => onUpdate('location', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          placeholder="Nairobi, Kenya"
        />
      </div>
    </div>
  );
};

// Location Selection Component
const LocationSelection: React.FC<{
  data: OnboardingData;
  onUpdate: (key: string, value: any) => void;
}> = ({ data, onUpdate }) => {
  const [location, setLocation] = useState('');

  const handleLocationSelect = () => {
    // In a real implementation, this would integrate with a map service
    const mockLocationData = {
      name: location || 'Nairobi',
      lat: -1.2921,
      lng: 36.8219,
      address: location || 'Nairobi, Kenya',
      latitude: -1.2921,
      longitude: 36.8219,
      area: location || 'Nairobi',
      readable_name: location || 'Nairobi',
    };
    onUpdate('locationData', mockLocationData);
  };

  return (
    <div className="space-y-6">
      <div className="bg-blue-50 rounded-lg p-6">
        <div className="flex items-start space-x-3">
          <MapPin className="h-6 w-6 text-blue-600 mt-1" />
          <div>
            <h3 className="font-semibold text-blue-900">Business Location</h3>
            <p className="text-blue-700 text-sm mt-1">
              Pinpoint your exact business location to help customers find you easily.
            </p>
          </div>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Business Address
        </label>
        <input
          type="text"
          value={location}
          onChange={(e) => setLocation(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          placeholder="Enter your business address"
        />
      </div>

      <div className="bg-green-50 rounded-lg p-6">
        <div className="flex items-start space-x-3">
          <Users className="h-6 w-6 text-green-600 mt-1" />
          <div>
            <h3 className="font-semibold text-green-900">Service Coverage Area</h3>
            <p className="text-green-700 text-sm mt-1">
              Your service area will be automatically set based on your location. 
              You can adjust this later in your provider dashboard.
            </p>
          </div>
        </div>
      </div>

      <button
        onClick={handleLocationSelect}
        className="w-full bg-primary-600 text-white py-3 px-4 rounded-lg hover:bg-primary-700 transition-colors"
      >
        Confirm Location
      </button>
    </div>
  );
};

// Service Selection Component
const ServiceSelection: React.FC<{
  data: OnboardingData;
  onUpdate: (key: string, value: any) => void;
  serviceCategories: ServiceCategory[];
}> = ({ data, onUpdate, serviceCategories }) => {
  const [selectedServices, setSelectedServices] = useState<string[]>(data.selectedServices || []);

  const handleServiceToggle = (serviceId: string) => {
    const newSelection = selectedServices.includes(serviceId)
      ? selectedServices.filter(id => id !== serviceId)
      : [...selectedServices, serviceId];
    
    setSelectedServices(newSelection);
    onUpdate('selectedServices', newSelection);
  };

  return (
    <div className="space-y-6">
      <div className="text-center">
        <h3 className="text-lg font-semibold text-gray-900 mb-2">Choose Your Services</h3>
        <p className="text-gray-600">Select all the services you offer to your customers</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {serviceCategories.map((category) => (
          <div key={category.id} className="border border-gray-200 rounded-lg p-4">
            <h4 className="font-semibold text-gray-900 mb-3">{category.name}</h4>
            <div className="space-y-2">
              {category.services.map((service) => (
                <label key={service.id} className="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={selectedServices.includes(service.id)}
                    onChange={() => handleServiceToggle(service.id)}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  />
                  <div>
                    <span className="text-sm font-medium text-gray-900">{service.name}</span>
                    {service.description && (
                      <p className="text-xs text-gray-600">{service.description}</p>
                    )}
                  </div>
                </label>
              ))}
            </div>
          </div>
        ))}
      </div>

      {selectedServices.length > 0 && (
        <div className="bg-green-50 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <Check className="h-5 w-5 text-green-600" />
            <span className="text-green-800 font-medium">
              {selectedServices.length} service{selectedServices.length !== 1 ? 's' : ''} selected
            </span>
          </div>
        </div>
      )}
    </div>
  );
};

export default ProviderOnboarding;
