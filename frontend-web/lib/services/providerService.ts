import { apiRequest } from '../auth';

export interface ServiceTemplate {
  id: string;
  name: string;
  items: Array<{
    service_id: string;
  }>;
}

export interface ProviderService {
  service_id: string;
  display_name?: string;
  service?: {
    name: string;
  };
}

export interface ProviderDetails {
  id: string;
  provider_name: string;
  contact_info?: Record<string, any>;
}

export class ProviderServiceAPI {
  /**
   * Get service templates for a provider
   */
  static async getServiceTemplates(providerId: string): Promise<ServiceTemplate[]> {
    const response = await apiRequest(`/api/service-provider-service/providers/${providerId}/templates`);
    
    if (!response?.ok) {
      return [];
    }
    
    const data = await response.json();
    return Array.isArray(data) ? data : [];
  }

  /**
   * Get provider services
   */
  static async getProviderServices(providerId: string): Promise<ProviderService[]> {
    const response = await apiRequest(`/api/service-provider-service/providers/${providerId}/services`);
    
    if (!response?.ok) {
      return [];
    }
    
    const data = await response.json();
    return Array.isArray(data) ? data : [];
  }

  /**
   * Get provider details
   */
  static async getProviderDetails(providerId: string): Promise<ProviderDetails | null> {
    const response = await apiRequest(`/api/service-provider-service/providers/${providerId}`);
    
    if (!response?.ok) {
      return null;
    }
    
    return await response.json();
  }
}

