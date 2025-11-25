import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { 
  ArrowLeft, 
  Save, 
  Settings, 
  DollarSign,
  Tag,
  Check,
  ChevronDown,
  ChevronRight,
  Plus,
  Minus,
  Building,
  Info,
  FileText
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';

interface ProviderDetails {
  id: string;
  name?: string;
  provider_name?: string;
  description?: string;
  provider_description?: string;
  category?: {
    name: string;
  };
}

interface GlobalService {
  service_id: string;
  service_name: string;
  service_description: string;
  service_requirements?: {
    fields: Array<{
      name: string;
      label: string;
      type: string;
      options?: string[];
    }>;
  };
}

interface AttachedService {
  service_id: string;
  display_name?: string;
  price?: string;
  min_price?: number;
  max_price?: number;
  price_type?: string;
  unit?: string;
  negotiable?: boolean;
  metadata?: Record<string, any>;
  service: {
    name: string;
    description?: string;
  };
}

interface ServiceFieldData {
  [key: string]: string;
}

const EditProviderPage: React.FC = () => {
  const router = useRouter();
  const { providerId } = router.query;
  const [provider, setProvider] = useState<ProviderDetails | null>(null);
  const [allServices, setAllServices] = useState<GlobalService[]>([]);
  const [attachedServices, setAttachedServices] = useState<AttachedService[]>([]);
  const [selectedServiceIds, setSelectedServiceIds] = useState<Set<string>>(new Set());
  const [serviceDetails, setServiceDetails] = useState<Record<string, GlobalService>>({});
  const [serviceFieldData, setServiceFieldData] = useState<Record<string, ServiceFieldData>>({});
  const [displayNames, setDisplayNames] = useState<Record<string, string>>({});
  const [prices, setPrices] = useState<Record<string, string>>({});
  const [minPrices, setMinPrices] = useState<Record<string, string>>({});
  const [maxPrices, setMaxPrices] = useState<Record<string, string>>({});
  const [priceTypes, setPriceTypes] = useState<Record<string, string>>({});
  const [priceUnits, setPriceUnits] = useState<Record<string, string>>({});
  const [negotiableFlags, setNegotiableFlags] = useState<Record<string, boolean>>({});
  const [expandedServices, setExpandedServices] = useState<Set<string>>(new Set());
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [showServiceSelector, setShowServiceSelector] = useState(false);

  const { data: providerData, loading: providerLoading } = useApi(`/api/service-provider-service/providers/${providerId}`);
  const { data: servicesData, loading: servicesLoading } = useApi('/api/global-service-api/services');
  const { data: attachedData, loading: attachedLoading } = useApi(`/api/service-provider-service/providers/${providerId}/services`);

  useEffect(() => {
    if (providerData && typeof providerData === 'object' && !Array.isArray(providerData)) {
      setProvider(providerData as ProviderDetails);
    }
  }, [providerData]);

  useEffect(() => {
    if (servicesData && Array.isArray(servicesData)) {
      setAllServices(servicesData);
    }
  }, [servicesData]);

  useEffect(() => {
    if (attachedData && Array.isArray(attachedData)) {
      setAttachedServices(attachedData);
      
      // Initialize form data from attached services
      const newSelectedIds = new Set<string>();
      const newDisplayNames: Record<string, string> = {};
      const newPrices: Record<string, string> = {};
      const newMinPrices: Record<string, string> = {};
      const newMaxPrices: Record<string, string> = {};
      const newPriceTypes: Record<string, string> = {};
      const newPriceUnits: Record<string, string> = {};
      const newNegotiableFlags: Record<string, boolean> = {};
      const newFieldData: Record<string, ServiceFieldData> = {};

      attachedData.forEach((service: AttachedService) => {
        const serviceId = service.service_id;
        newSelectedIds.add(serviceId);
        newDisplayNames[serviceId] = service.display_name || '';
        newPrices[serviceId] = service.price || '';
        newMinPrices[serviceId] = service.min_price?.toString() || '';
        newMaxPrices[serviceId] = service.max_price?.toString() || '';
        newPriceTypes[serviceId] = service.price_type || 'range';
        newPriceUnits[serviceId] = service.unit || '';
        newNegotiableFlags[serviceId] = service.negotiable ?? true;
        newFieldData[serviceId] = service.metadata || {};
      });

      setSelectedServiceIds(newSelectedIds);
      setDisplayNames(newDisplayNames);
      setPrices(newPrices);
      setMinPrices(newMinPrices);
      setMaxPrices(newMaxPrices);
      setPriceTypes(newPriceTypes);
      setPriceUnits(newPriceUnits);
      setNegotiableFlags(newNegotiableFlags);
      setServiceFieldData(newFieldData);
    }
  }, [attachedData]);

  useEffect(() => {
    setIsLoading(providerLoading || servicesLoading || attachedLoading);
  }, [providerLoading, servicesLoading, attachedLoading]);

  const loadServiceDetails = async (serviceId: string) => {
    if (serviceDetails[serviceId]) return;

    try {
      const response = await fetch(`/api/global-service-api/services/${serviceId}`);
      if (response.ok) {
        const details = await response.json();
        setServiceDetails(prev => ({ ...prev, [serviceId]: details }));
      }
    } catch (error) {
      console.error('Error loading service details:', error);
    }
  };

  const toggleServiceSelection = (serviceId: string) => {
    const newSelection = new Set(selectedServiceIds);
    if (newSelection.has(serviceId)) {
      newSelection.delete(serviceId);
    } else {
      newSelection.add(serviceId);
    }
    setSelectedServiceIds(newSelection);
  };

  const toggleServiceExpansion = (serviceId: string) => {
    const newExpanded = new Set(expandedServices);
    if (newExpanded.has(serviceId)) {
      newExpanded.delete(serviceId);
    } else {
      newExpanded.add(serviceId);
      loadServiceDetails(serviceId);
    }
    setExpandedServices(newExpanded);
  };

  const updateFieldData = (serviceId: string, fieldName: string, value: string) => {
    setServiceFieldData(prev => ({
      ...prev,
      [serviceId]: {
        ...prev[serviceId],
        [fieldName]: value,
      },
    }));
  };

  const renderField = (serviceId: string, fieldDef: any) => {
    const fieldName = fieldDef.name;
    const fieldType = fieldDef.type;
    const label = fieldDef.label || fieldName;
    const currentValue = serviceFieldData[serviceId]?.[fieldName] || '';

    switch (fieldType) {
      case 'string':
      case 'text':
        return (
          <input
            type="text"
            value={currentValue}
            onChange={(e) => updateFieldData(serviceId, fieldName, e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            placeholder={label}
          />
        );
      case 'number':
        return (
          <input
            type="number"
            value={currentValue}
            onChange={(e) => updateFieldData(serviceId, fieldName, e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            placeholder={label}
          />
        );
      case 'textarea':
        return (
          <textarea
            value={currentValue}
            onChange={(e) => updateFieldData(serviceId, fieldName, e.target.value)}
            rows={4}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            placeholder={label}
          />
        );
      case 'boolean':
        const boolValue = currentValue.toLowerCase() === 'true';
        return (
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={boolValue}
              onChange={(e) => updateFieldData(serviceId, fieldName, e.target.checked.toString())}
              className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
            />
            <span className="text-sm text-gray-700">{label}</span>
          </label>
        );
      case 'select':
        const options = fieldDef.options || [];
        return (
          <select
            value={currentValue}
            onChange={(e) => updateFieldData(serviceId, fieldName, e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          >
            <option value="">Select {label}</option>
            {options.map((option: string) => (
              <option key={option} value={option}>{option}</option>
            ))}
          </select>
        );
      default:
        return (
          <input
            type="text"
            value={currentValue}
            onChange={(e) => updateFieldData(serviceId, fieldName, e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            placeholder={label}
          />
        );
    }
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const payload = Array.from(selectedServiceIds).map(serviceId => {
        const fieldData = serviceFieldData[serviceId] || {};
        const metadata: Record<string, any> = {};
        
        // Process field data with proper type conversion
        Object.entries(fieldData).forEach(([key, value]) => {
          if (value.toLowerCase() === 'true') {
            metadata[key] = true;
          } else if (value.toLowerCase() === 'false') {
            metadata[key] = false;
          } else if (value && /^\d+$/.test(value)) {
            metadata[key] = parseInt(value);
          } else if (value && /^\d*\.?\d+$/.test(value)) {
            metadata[key] = parseFloat(value);
          } else {
            metadata[key] = value;
          }
        });

        return {
          service_id: serviceId,
          display_name: displayNames[serviceId] || null,
          price: prices[serviceId] || null,
          min_price: minPrices[serviceId] ? parseFloat(minPrices[serviceId]) : null,
          max_price: maxPrices[serviceId] ? parseFloat(maxPrices[serviceId]) : null,
          price_type: priceTypes[serviceId] || 'range',
          currency: 'KES',
          unit: priceUnits[serviceId] || null,
          negotiable: negotiableFlags[serviceId] ?? true,
          metadata,
        };
      });

      const response = await fetch(`/api/service-provider-service/providers/${providerId}/services`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        const data = await response.json();
        console.log('✅ Services saved successfully:', data);
        alert(`Services saved successfully! ${payload.length} service${payload.length !== 1 ? 's' : ''} attached.`);
        // Redirect to dashboard with providerId
        if (providerId) {
          router.push(`/provider/dashboard?providerId=${providerId}`);
        } else {
          router.push('/provider/dashboard');
        }
      } else {
        const errorData = await response.json().catch(() => ({ error: 'Failed to save services' }));
        console.error('❌ Failed to save services:', errorData);
        alert(errorData.error || errorData.detail || 'Failed to save services. Please check your connection and try again.');
      }
    } catch (error) {
      console.error('Error saving services:', error);
      alert('Error saving services');
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center space-x-4">
              <Link href={providerId ? `/provider/dashboard?providerId=${providerId}` : '/provider/dashboard'}>
                <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
                  <ArrowLeft className="h-5 w-5" />
                </button>
              </Link>
              <div>
                <h1 className="text-3xl font-bold text-gray-900">
                  Edit Our Services - {provider?.name || provider?.provider_name || 'Provider'}
                </h1>
                <p className="text-gray-600 mt-1">Manage your services, pricing, and service requirements</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header Card */}
        <div className="bg-white rounded-xl shadow-lg p-6 mb-8">
          <div className="flex items-start space-x-4">
            <div className="p-3 bg-blue-100 rounded-lg">
              <Building className="h-7 w-7 text-blue-700" />
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-blue-700 mb-2">Service Management</h2>
              <p className="text-gray-600 mb-4">{provider?.description || provider?.provider_description || ''}</p>
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div className="flex items-start space-x-3">
                  <Info className="h-5 w-5 text-blue-700 mt-0.5" />
                  <p className="text-sm text-blue-700">
                    Select services you offer and configure their pricing. This information will be visible to customers.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Services Section Header */}
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-lg font-bold text-gray-900">Our Services</h2>
          <button
            onClick={() => setShowServiceSelector(!showServiceSelector)}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center space-x-2"
          >
            <Plus className="h-4 w-4" />
            <span>{selectedServiceIds.size} Services</span>
          </button>
        </div>

        {/* Selected Services Summary */}
        {selectedServiceIds.size > 0 && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
            <div className="flex items-center space-x-3">
              <Check className="h-5 w-5 text-green-700" />
              <div>
                <p className="font-bold text-green-700">
                  Selected Services ({selectedServiceIds.size})
                </p>
                <p className="text-sm text-green-600 mt-1">
                  Tap on services below to configure pricing and requirements for each service.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Services List */}
        <div className="bg-white rounded-xl shadow-sm">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">Available Services</h2>
            <p className="text-sm text-gray-600 mt-1">Select and configure services for your business</p>
          </div>

          <div className="p-6">
            {allServices.length === 0 ? (
              <div className="text-center py-12">
                <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600">No services available</p>
              </div>
            ) : (
              <div className="space-y-4">
                {allServices.map((service) => {
                const serviceId = service.service_id;
                const isSelected = selectedServiceIds.has(serviceId);
                const isExpanded = expandedServices.has(serviceId);
                const currentServiceDetails = serviceDetails[serviceId];

                return (
                  <div key={serviceId} id={`service-${serviceId}`} className="border border-gray-200 rounded-lg">
                    <div className="p-4">
                      <div className="flex items-center space-x-3">
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => toggleServiceSelection(serviceId)}
                          className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                        />
                        <div className="flex-1">
                          <h3 className="font-medium text-gray-900">{service.service_name}</h3>
                          <p className="text-sm text-gray-600">{service.service_description}</p>
                        </div>
                        <button
                          onClick={() => toggleServiceExpansion(serviceId)}
                          className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
                        >
                          {isExpanded ? <ChevronDown className="h-5 w-5" /> : <ChevronRight className="h-5 w-5" />}
                        </button>
                      </div>
                    </div>

                    {isExpanded && (
                      <div className="px-4 pb-4 border-t border-gray-200 bg-gray-50">
                        <div className="space-y-6 pt-4">
                          {/* Display Name */}
                          <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                              Custom Display Name (optional)
                            </label>
                            <input
                              type="text"
                              value={displayNames[serviceId] || ''}
                              onChange={(e) => setDisplayNames(prev => ({ ...prev, [serviceId]: e.target.value }))}
                              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                              placeholder="e.g., Premium Castrol Oil Change"
                            />
                          </div>

                          {/* Legacy Price Field */}
                          <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                              Display Price (e.g., KSh 3,500 - 8,000)
                            </label>
                            <input
                              type="text"
                              value={prices[serviceId] || ''}
                              onChange={(e) => setPrices(prev => ({ ...prev, [serviceId]: e.target.value }))}
                              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                              placeholder="KSh 3,500 - 8,000"
                            />
                          </div>

                          {/* Structured Pricing */}
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                              <label className="block text-sm font-medium text-gray-700 mb-2">
                                Min Price
                              </label>
                              <div className="relative">
                                <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500">KES</span>
                                <input
                                  type="number"
                                  value={minPrices[serviceId] || ''}
                                  onChange={(e) => setMinPrices(prev => ({ ...prev, [serviceId]: e.target.value }))}
                                  className="w-full pl-12 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                                  placeholder="0"
                                />
                              </div>
                            </div>
                            <div>
                              <label className="block text-sm font-medium text-gray-700 mb-2">
                                Max Price
                              </label>
                              <div className="relative">
                                <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500">KES</span>
                                <input
                                  type="number"
                                  value={maxPrices[serviceId] || ''}
                                  onChange={(e) => setMaxPrices(prev => ({ ...prev, [serviceId]: e.target.value }))}
                                  className="w-full pl-12 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                                  placeholder="0"
                                />
                              </div>
                            </div>
                          </div>

                          {/* Price Type */}
                          <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                              Price Type
                            </label>
                            <select
                              value={priceTypes[serviceId] || 'range'}
                              onChange={(e) => setPriceTypes(prev => ({ ...prev, [serviceId]: e.target.value }))}
                              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                            >
                              <option value="fixed">Fixed Price</option>
                              <option value="range">Price Range</option>
                              <option value="per_unit">Per Unit</option>
                              <option value="free">Free Service</option>
                              <option value="variable">Variable Price</option>
                            </select>
                          </div>

                          {/* Unit Field (for per_unit pricing) */}
                          {priceTypes[serviceId] === 'per_unit' && (
                            <div>
                              <label className="block text-sm font-medium text-gray-700 mb-2">
                                Unit (e.g., per_liter, per_hour)
                              </label>
                              <input
                                type="text"
                                value={priceUnits[serviceId] || ''}
                                onChange={(e) => setPriceUnits(prev => ({ ...prev, [serviceId]: e.target.value }))}
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                                placeholder="per_liter"
                              />
                            </div>
                          )}

                          {/* Negotiable Checkbox */}
                          <div>
                            <label className="flex items-center space-x-2">
                              <input
                                type="checkbox"
                                checked={negotiableFlags[serviceId] ?? true}
                                onChange={(e) => setNegotiableFlags(prev => ({ ...prev, [serviceId]: e.target.checked }))}
                                className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                              />
                              <span className="text-sm text-gray-700">Price is negotiable</span>
                            </label>
                          </div>

                          {/* Service Requirements Fields */}
                          {currentServiceDetails?.service_requirements?.fields && (
                            <div>
                              <h4 className="text-sm font-medium text-gray-700 mb-3">Service Requirements</h4>
                              <div className="space-y-4">
                                {currentServiceDetails.service_requirements.fields.map((field: any, index: number) => (
                                  <div key={index}>
                                    <label className="block text-sm font-medium text-gray-700 mb-2">
                                      {field.label}
                                    </label>
                                    {renderField(serviceId, field)}
                                  </div>
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                );
                })}
              </div>
            )}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            onClick={() => {
              // Scroll to services or show expanded view
              const firstSelected = Array.from(selectedServiceIds)[0];
              if (firstSelected) {
                toggleServiceExpansion(firstSelected);
                document.getElementById(`service-${firstSelected}`)?.scrollIntoView({ behavior: 'smooth' });
              } else {
                setShowServiceSelector(true);
              }
            }}
            disabled={selectedServiceIds.size === 0}
            className="px-6 py-4 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center space-x-2"
          >
            <Settings className="h-5 w-5" />
            <span>Manage Services</span>
          </button>
          
          <Link href={providerId ? `/provider/manage-templates?providerId=${providerId}` : '/provider/manage-templates'}>
            <button className="w-full px-6 py-4 bg-blue-gray-600 text-white rounded-lg hover:bg-blue-gray-700 transition-colors flex items-center justify-center space-x-2">
              <FileText className="h-5 w-5" />
              <span>Templates</span>
            </button>
          </Link>
          
          <button
            onClick={handleSave}
            disabled={isSaving || selectedServiceIds.size === 0}
            className="px-6 py-4 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center space-x-2"
          >
            <Save className="h-5 w-5" />
            <span>{isSaving ? 'Saving...' : 'Save'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default EditProviderPage;
