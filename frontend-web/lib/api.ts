import axios, { AxiosInstance, AxiosResponse } from 'axios';

// API Configuration
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// Create axios instance
const api: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    // Add auth token if available
    const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response: AxiosResponse) => {
    return response;
  },
  (error) => {
    // Handle common errors
    if (error.response?.status === 401) {
      // Redirect to login or clear auth
      if (typeof window !== 'undefined') {
        localStorage.removeItem('auth_token');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// API Service Class
export class ApiService {
  // Alert Rules API
  static async getAlertRules() {
    const response = await api.get('/alert-rules');
    return response.data;
  }

  static async createAlertRule(ruleData: any) {
    const response = await api.post('/alert-rules', ruleData);
    return response.data;
  }

  static async updateAlertRule(ruleId: string, ruleData: any) {
    const response = await api.patch(`/alert-rules/${ruleId}`, ruleData);
    return response.data;
  }

  static async deleteAlertRule(ruleId: string) {
    const response = await api.delete(`/alert-rules/${ruleId}`);
    return response.data;
  }

  // Alerts API
  static async getAlerts(params?: any) {
    const response = await api.get('/alerts', { params });
    return response.data;
  }

  static async getAlert(alertId: string) {
    const response = await api.get(`/alerts/${alertId}`);
    return response.data;
  }

  static async markAlertRead(alertId: string) {
    const response = await api.patch(`/alerts/${alertId}/mark-read`);
    return response.data;
  }

  // Users API
  static async getUsers() {
    const response = await api.get('/users');
    return response.data;
  }

  static async getUser(userId: string) {
    const response = await api.get(`/users/${userId}`);
    return response.data;
  }

  static async updateUser(userId: string, userData: any) {
    const response = await api.patch(`/users/${userId}`, userData);
    return response.data;
  }

  // FCM Token API
  static async registerFCMToken(userId: string, fcmToken: string) {
    const response = await api.post(`/users/${userId}/fcm-token`, { fcm_token: fcmToken });
    return response.data;
  }

  static async removeFCMToken(userId: string) {
    const response = await api.delete(`/users/${userId}/fcm-token`);
    return response.data;
  }

  // Service Providers API
  static async getProviders() {
    const response = await api.get('/providers');
    return response.data;
  }

  static async createProvider(providerData: any) {
    const response = await api.post('/providers', providerData);
    return response.data;
  }

  static async updateProvider(providerId: string, providerData: any) {
    const response = await api.patch(`/providers/${providerId}`, providerData);
    return response.data;
  }

  // Analytics API
  static async getSystemMetrics() {
    const response = await api.get('/analytics/metrics');
    return response.data;
  }

  static async getAlertStats() {
    const response = await api.get('/analytics/alerts');
    return response.data;
  }

  static async getUserStats() {
    const response = await api.get('/analytics/users');
    return response.data;
  }

  // Rule Engine API
  static async triggerInsuranceExpiryCheck() {
    const response = await api.post('/alerts/trigger/insurance-expiry');
    return response.data;
  }

  static async triggerServiceDueCheck() {
    const response = await api.post('/alerts/trigger/service-due');
    return response.data;
  }

  static async runAllAlertRules() {
    const response = await api.post('/alert-rules/run-all');
    return response.data;
  }
}

export default api;
