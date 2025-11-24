import { apiRequest } from '../auth';

export interface GuestUserRequest {
  email?: string;
  phone?: string;
  name: string;
  provider_id?: string;
}

export interface VehicleSearchResult {
  id: string;
  plate: string;
  make: string;
  model: string;
  fuel_type?: string;
  yom?: number;
  mileage?: number;
}

export interface GuestVehicleRequest {
  owner_id: string;
  plate: string;
  make: string;
  model: string;
  mileage?: number;
  yom?: number;
  fuel_type?: string;
  created_by_provider_id: string;
}

export interface ServiceLogPayload {
  provider_id: string;
  provider_name: string;
  provider_contact: Record<string, any>;
  vehicle_id: string;
  user_id: string;
  service_id: string;
  service_name: string;
  service_items: {
    notes: string;
    checked: boolean;
  };
  performed_at?: string;
  next_service_km?: number;
  next_service_date?: string;
  mileage_km: number;
  served_by: string;
  served_by_contact: string;
  logged_by: string;
  notes: string;
  cost: number;
}

export class BookingService {
  /**
   * Create a guest user
   */
  static async createGuestUser(data: GuestUserRequest): Promise<any> {
    const response = await apiRequest('/api/users/guest', {
      method: 'POST',
      body: JSON.stringify(data),
    });
    
    if (!response?.ok) {
      const error = await response?.json();
      throw new Error(error?.detail || error?.error || 'Failed to create guest user');
    }
    
    return await response.json();
  }

  /**
   * Search vehicles by plate number
   */
  static async searchVehicles(plate: string): Promise<VehicleSearchResult[]> {
    if (!plate || plate.length < 3) return [];
    
    const response = await apiRequest(`/api/vehicles/search?plate=${encodeURIComponent(plate)}`);
    
    if (!response?.ok) {
      return [];
    }
    
    const data = await response.json();
    return Array.isArray(data) ? data : [];
  }

  /**
   * Create a guest vehicle
   */
  static async createGuestVehicle(data: GuestVehicleRequest): Promise<any> {
    const response = await apiRequest('/api/vehicles/guest', {
      method: 'POST',
      body: JSON.stringify(data),
    });
    
    if (!response?.ok) {
      const error = await response?.json();
      throw new Error(error?.detail || error?.error || 'Failed to create guest vehicle');
    }
    
    return await response.json();
  }

  /**
   * Create bulk service logs
   */
  static async createBulkServiceLogs(logs: ServiceLogPayload[]): Promise<any[]> {
    const response = await apiRequest('/api/service-logs/bulk', {
      method: 'POST',
      body: JSON.stringify(logs),
    });
    
    if (!response?.ok) {
      const error = await response?.json();
      throw new Error(error?.detail || error?.error || 'Failed to create service logs');
    }
    
    const data = await response.json();
    return Array.isArray(data) ? data : [];
  }
}

