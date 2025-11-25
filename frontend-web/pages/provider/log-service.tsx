import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/router';
import { 
  Save, 
  User, 
  Car, 
  Wrench, 
  UserCog, 
  Info,
  Loader2
} from 'lucide-react';
import { BookingService, ServiceLogPayload } from '../../lib/services/bookingService';
import { ProviderServiceAPI } from '../../lib/services/providerService';
import { InputField } from '../../components/shared/InputField';
import { DatePicker } from '../../components/shared/DatePicker';
import { AutocompleteInput } from '../../components/shared/AutocompleteInput';
import { ServiceItem } from '../../components/shared/ServiceItem';
import { CostSummary } from '../../components/shared/CostSummary';
import { TemplateSelector } from '../../components/shared/TemplateSelector';
import { carModels } from '../../lib/data/carModels';

interface Service {
  service_id: string;
  display_name: string;
  done: boolean;
  notes: string;
  cost?: string | number;
}

interface Template {
  id: string;
  name: string;
  items?: Array<{ service_id: string }>;
}

const ProviderLogServicePage: React.FC = () => {
  const router = useRouter();
  const { providerId } = router.query; // get the provider id from the query params
  
  // Form state
  const [guestContact, setGuestContact] = useState('');
  const [vehiclePlate, setVehiclePlate] = useState('');
  const [vehicleMake, setVehicleMake] = useState('');
  const [vehicleModel, setVehicleModel] = useState('');
  const [fuelType, setFuelType] = useState('');
  const [yom, setYom] = useState('');
  const [mileage, setMileage] = useState('');
  const [mechanicName, setMechanicName] = useState('');
  const [mechanicContact, setMechanicContact] = useState('');
  const [nextServiceKm, setNextServiceKm] = useState('');
  
  // Service state
  const [performedAt, setPerformedAt] = useState<Date | null>(null);
  const [nextServiceDate, setNextServiceDate] = useState<Date | null>(null);
  const [services, setServices] = useState<Service[]>([]);
  const [templates, setTemplates] = useState<Template[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<Template | null>(null);
  
  // Cost controllers for each service
  const [serviceCosts, setServiceCosts] = useState<Record<number, string>>({});
  
  // UI state
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedMake, setSelectedMake] = useState('');
  
  // Debounce timer for vehicle search
  const [debounceTimer, setDebounceTimer] = useState<NodeJS.Timeout | null>(null);

  // Fetch templates on mount
  useEffect(() => {
    if (providerId && typeof providerId === 'string') {
      fetchTemplates();
    }
  }, [providerId]);

  // Auto-select first template if available
  useEffect(() => {
    if (templates.length > 0 && !selectedTemplate) {
      setSelectedTemplate(templates[0]);
      loadTemplateServices(templates[0]);
    }
  }, [templates]);

  const fetchTemplates = async () => {
    if (!providerId || typeof providerId !== 'string') return;
    
    setLoading(true);
    try {
      const data = await ProviderServiceAPI.getServiceTemplates(providerId);
      setTemplates(data);
    } catch (err) {
      console.error('Error fetching templates:', err);
      setError('Failed to load templates');
    } finally {
      setLoading(false);
    }
  };

  const loadTemplateServices = async (template: Template) => {
    if (!providerId || typeof providerId !== 'string') return;
    
    setLoading(true);
    try {
      const providerServices = await ProviderServiceAPI.getProviderServices(providerId);
      const serviceMap = new Map(
        providerServices.map(ps => [ps.service_id, ps])
      );

      const resolvedItems: Service[] = (template.items || []).map((item) => {
        const ps = serviceMap.get(item.service_id);
        return {
          service_id: item.service_id,
          display_name: ps?.display_name || ps?.service?.name || 'Unnamed Service',
          done: false,
          notes: '',
          cost: 0,
        };
      });

      // Initialize cost controllers
      const costs: Record<number, string> = {};
      resolvedItems.forEach((_, index) => {
        costs[index] = '';
      });
      setServiceCosts(costs);
      setServices(resolvedItems);
    } catch (err) {
      console.error('Error loading template services:', err);
      setError('Failed to load services');
    } finally {
      setLoading(false);
    }
  };

  // Vehicle search with debounce
  useEffect(() => {
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }

    if (vehiclePlate.length < 3) {
      return;
    }

    const timer = setTimeout(async () => {
      try {
        const results = await BookingService.searchVehicles(vehiclePlate);
        if (results.length > 0) {
          const vehicle = results[0];
          if (vehicle.plate.toUpperCase() === vehiclePlate.toUpperCase()) {
            setVehicleMake(vehicle.make || '');
            setVehicleModel(vehicle.model || '');
            setSelectedMake(vehicle.make || '');
            setFuelType(vehicle.fuel_type || '');
            setYom(vehicle.yom?.toString() || '');
            setMileage(vehicle.mileage?.toString() || '');
          }
        }
      } catch (err) {
        console.error('Vehicle search error:', err);
      }
    }, 400);

    setDebounceTimer(timer);

    return () => {
      if (debounceTimer) {
        clearTimeout(debounceTimer);
      }
    };
  }, [vehiclePlate]);

  const handleTemplateChange = (template: Template | null) => {
    setSelectedTemplate(template);
    if (template) {
      loadTemplateServices(template);
    } else {
      setServices([]);
    }
  };

  const handleToggleDone = (index: number, done: boolean) => {
    setServices(prev => {
      const updated = [...prev];
      updated[index] = { ...updated[index], done };
      return updated;
    });
  };

  const handleNotesChange = (index: number, notes: string) => {
    setServices(prev => {
      const updated = [...prev];
      updated[index] = { ...updated[index], notes };
      return updated;
    });
  };

  const handleCostChange = (index: number, cost: string) => {
    setServiceCosts(prev => ({ ...prev, [index]: cost }));
    setServices(prev => {
      const updated = [...prev];
      updated[index] = { ...updated[index], cost };
      return updated;
    });
  };

  const handleMakeChange = (make: string) => {
    setVehicleMake(make);
    setSelectedMake(make);
    // Clear model when make changes
    setVehicleModel('');
  };

  const handleMakeSelect = (make: string) => {
    setSelectedMake(make);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!providerId || typeof providerId !== 'string') {
      setError('Provider ID is required');
      return;
    }

    if (services.length === 0) {
      setError('Please select a template with services');
      return;
    }

    const completedServices = services.filter(s => s.done === true);
    if (completedServices.length === 0) {
      setError('Please mark at least one service as completed');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // 1. Create guest user
      const guestUser = await BookingService.createGuestUser({
        email: guestContact.includes('@') ? guestContact.trim() : undefined,
        phone: !guestContact.includes('@') ? guestContact.trim() : undefined,
        name: 'Guest User',
        provider_id: providerId,
      });

      if (!guestUser || !guestUser.id) {
        throw new Error('Failed to create guest user');
      }

      // 2. Find or create vehicle
      const plate = vehiclePlate.trim();
      const existing = await BookingService.searchVehicles(plate);
      let vehicle;

      if (existing.length > 0 && existing[0].plate.toUpperCase() === plate.toUpperCase()) {
        vehicle = existing[0];
      } else {
        vehicle = await BookingService.createGuestVehicle({
          owner_id: guestUser.id.toString(),
          plate: plate,
          make: vehicleMake.trim(),
          model: vehicleModel.trim(),
          mileage: parseInt(mileage) || 0,
          yom: parseInt(yom) || 0,
          fuel_type: fuelType.trim(),
          created_by_provider_id: providerId,
        });
      }

      if (!vehicle || !vehicle.id) {
        throw new Error('Failed to create or find vehicle');
      }

      // 3. Get provider details
      const provider = await ProviderServiceAPI.getProviderDetails(providerId);
      const providerName = provider?.provider_name || 'Unknown Provider';
      const providerContact = provider?.contact_info || {};

      // 4. Create service logs
      const logsPayload: ServiceLogPayload[] = completedServices.map((service) => {
        const cost = parseInt(serviceCosts[services.indexOf(service)] || '0') || 0;
        
        return {
          provider_id: providerId,
          provider_name: providerName,
          provider_contact: providerContact,
          vehicle_id: vehicle.id.toString(),
          user_id: guestUser.id.toString(),
          service_id: service.service_id,
          service_name: service.display_name,
          service_items: {
            notes: service.notes,
            checked: service.done,
          },
          performed_at: performedAt ? performedAt.toISOString().split('.')[0] : undefined,
          next_service_km: parseInt(nextServiceKm) || 0,
          next_service_date: nextServiceDate ? nextServiceDate.toISOString().split('.')[0] : undefined,
          mileage_km: parseInt(mileage) || 0,
          served_by: mechanicName.trim(),
          served_by_contact: mechanicContact.trim(),
          logged_by: 'provider',
          notes: service.notes,
          cost: cost,
        };
      });

      const response = await BookingService.createBulkServiceLogs(logsPayload);

      // Success - redirect or show success message
      alert(`Successfully logged ${response.length} service(s) for ${plate}`);
      router.back();
    } catch (err: any) {
      console.error('Error submitting logs:', err);
      setError(err.message || 'Failed to submit service logs');
    } finally {
      setLoading(false);
    }
  };

  // Get available models for selected make
  const getModelOptions = (): string[] => {
    if (!selectedMake) return [];
    if (carModels[selectedMake]) {
      return carModels[selectedMake];
    }
    // Fuzzy match
    const matches = Object.keys(carModels).filter(k =>
      k.toLowerCase().includes(selectedMake.toLowerCase())
    );
    const allModels: string[] = [];
    matches.forEach(key => {
      allModels.push(...carModels[key]);
    });
    return allModels;
  };

  if (!providerId) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-600">Provider ID is required</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-4 sm:py-6 lg:py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-6">
          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">
            Log Provider Services
          </h1>
        </div>

        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-700">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Template Selection */}
          <TemplateSelector
            templates={templates}
            selectedTemplate={selectedTemplate}
            onTemplateChange={handleTemplateChange}
            loading={loading}
          />

          {selectedTemplate ? (
            <>
              {/* Guest & Vehicle Info */}
              <div className="bg-white rounded-xl shadow-sm p-4 sm:p-6">
                <div className="flex items-center gap-2 mb-4">
                  <User className="w-5 h-5 text-green-700" />
                  <h2 className="text-base sm:text-lg font-bold text-green-700">
                    Guest & Vehicle Info
                  </h2>
                </div>

                <div className="space-y-4">
                  <InputField
                    label="Guest Contact (phone/email)"
                    value={guestContact}
                    onChange={setGuestContact}
                    type="text"
                    placeholder="Phone or email"
                    required
                  />

                  <InputField
                    label="Vehicle Plate (type to autofill)"
                    value={vehiclePlate}
                    onChange={setVehiclePlate}
                    type="text"
                    placeholder="e.g., KCA 123A"
                    required
                  />

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <AutocompleteInput
                      label="Make"
                      value={vehicleMake}
                      onChange={handleMakeChange}
                      onSelect={handleMakeSelect}
                      options={Object.keys(carModels)}
                      placeholder="Select or type make"
                    />

                    <AutocompleteInput
                      label="Model"
                      value={vehicleModel}
                      onChange={setVehicleModel}
                      options={getModelOptions()}
                      placeholder="Select or type model"
                      disabled={!selectedMake}
                    />
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <InputField
                      label="Year"
                      value={yom}
                      onChange={setYom}
                      type="number"
                      placeholder="e.g., 2020"
                    />

                    <InputField
                      label="Fuel Type"
                      value={fuelType}
                      onChange={setFuelType}
                      type="text"
                      placeholder="e.g., Petrol, Diesel"
                    />
                  </div>

                  <InputField
                    label="Mileage (km)"
                    value={mileage}
                    onChange={setMileage}
                    type="number"
                    placeholder="e.g., 50000"
                  />
                </div>
              </div>

              {/* Service Details */}
              <div className="bg-white rounded-xl shadow-sm p-4 sm:p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <Wrench className="w-5 h-5 text-orange-700" />
                    <h2 className="text-base sm:text-lg font-bold text-orange-700">
                      Service Details
                    </h2>
                  </div>
                  {services.length > 0 && (
                    <div className="bg-green-100 px-3 py-1 rounded-full">
                      <span className="text-sm font-bold text-green-700">
                        {services.filter(s => s.done).length}/{services.length}
                      </span>
                    </div>
                  )}
                </div>

                <div className="space-y-4">
                  <DatePicker
                    label="Date Performed"
                    value={performedAt}
                    onChange={setPerformedAt}
                  />

                  {services.length === 0 ? (
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                      <div className="flex items-center gap-2">
                        <Info className="w-4 h-4 text-blue-700" />
                        <span className="text-sm font-bold text-blue-700">
                          No services in selected template
                        </span>
                      </div>
                    </div>
                  ) : (
                    <>
                      <div className="space-y-3">
                        {services.map((service, index) => (
                          <ServiceItem
                            key={index}
                            index={index}
                            service={service}
                            onToggleDone={handleToggleDone}
                            onNotesChange={handleNotesChange}
                            onCostChange={handleCostChange}
                            costController={serviceCosts[index] || ''}
                          />
                        ))}
                      </div>

                      <CostSummary services={services} />
                    </>
                  )}
                </div>
              </div>

              {/* Mechanic & Next Service */}
              <div className="bg-white rounded-xl shadow-sm p-4 sm:p-6">
                <div className="flex items-center gap-2 mb-4">
                  <UserCog className="w-5 h-5 text-purple-700" />
                  <h2 className="text-base sm:text-lg font-bold text-purple-700">
                    Mechanic & Next Service
                  </h2>
                </div>

                <div className="space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <InputField
                      label="Mechanic Name"
                      value={mechanicName}
                      onChange={setMechanicName}
                      type="text"
                      placeholder="Mechanic name"
                    />

                    <InputField
                      label="Mechanic Contact"
                      value={mechanicContact}
                      onChange={setMechanicContact}
                      type="text"
                      placeholder="Contact info"
                    />
                  </div>

                  <InputField
                    label="Next Service (km)"
                    value={nextServiceKm}
                    onChange={setNextServiceKm}
                    type="number"
                    placeholder="e.g., 55000"
                  />

                  <DatePicker
                    label="Next Service Date"
                    value={nextServiceDate}
                    onChange={setNextServiceDate}
                  />
                </div>
              </div>

              {/* Submit Button */}
              <div className="flex justify-end">
                <button
                  type="submit"
                  disabled={loading}
                  className="
                    w-full sm:w-auto px-6 py-3 bg-red-600 text-white rounded-lg
                    hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500
                    font-semibold text-base disabled:opacity-50 disabled:cursor-not-allowed
                    flex items-center justify-center gap-2
                  "
                >
                  {loading ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      <span>Submitting...</span>
                    </>
                  ) : (
                    <>
                      <Save className="w-5 h-5" />
                      <span>Submit Log</span>
                    </>
                  )}
                </button>
              </div>
            </>
          ) : (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 sm:p-8 text-center">
              <Info className="w-12 h-12 text-blue-700 mx-auto mb-4" />
              <h3 className="text-lg sm:text-xl font-bold text-blue-700 mb-2">
                Please Select a Template First
              </h3>
              <p className="text-sm sm:text-base text-blue-600">
                Choose a service template above to continue with logging services.
              </p>
            </div>
          )}
        </form>
      </div>
    </div>
  );
};

export default ProviderLogServicePage;

