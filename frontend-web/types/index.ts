// User Types
export interface User {
  id: number;
  email: string;
  name?: string;
  phone?: string;
  provider_id?: string;
  is_admin?: boolean;
  role?: string;
  fcm_token?: string;
  created_at: string;
  updated_at: string;
}

// Alert Types
export interface Alert {
  id: string;
  user_id: number;
  type: AlertType;
  title: string;
  message: string;
  priority: number;
  vehicle_id?: string;
  policy_id?: string;
  booking_id?: string;
  provider_id?: string;
  channels: string[];
  status: AlertStatus;
  scheduled_at?: string;
  sent_at?: string;
  delivered_at?: string;
  action_url?: string;
  action_text?: string;
  alert_metadata?: Record<string, any>;
  retry_count: number;
  error_message?: string;
  created_at: string;
  updated_at: string;
}

export enum AlertType {
  INSURANCE_EXPIRY = 'insurance_expiry',
  SERVICE_DUE = 'service_due',
  PROMOTIONAL = 'promotional',
  MAINTENANCE_REMINDER = 'maintenance_reminder',
  CLAIM_UPDATE = 'claim_update',
  PAYMENT_REMINDER = 'payment_reminder',
}

export enum AlertStatus {
  PENDING = 'pending',
  SENT = 'sent',
  DELIVERED = 'delivered',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}

// Alert Rule Types
export interface AlertRule {
  id: string;
  name: string;
  description?: string;
  alert_type: AlertType;
  trigger_conditions: Record<string, any>;
  message_template: string;
  title_template: string;
  channels: string[];
  priority: number;
  is_active: boolean;
  schedule_expression?: string;
  created_by?: string;
  version: string;
  created_at: string;
  updated_at: string;
}

export interface AlertRuleCreate {
  name: string;
  description?: string;
  alert_type: AlertType;
  trigger_conditions: Record<string, any>;
  message_template: string;
  title_template: string;
  channels: string[];
  priority: number;
  is_active: boolean;
  schedule_expression?: string;
  created_by?: string;
}

// Service Provider Types
export interface ServiceProvider {
  id: string;
  name: string;
  type: string;
  location: string;
  contact: string;
  services: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Analytics Types
export interface SystemMetrics {
  total_users: number;
  total_alerts: number;
  active_rules: number;
  providers_count: number;
  alerts_today: number;
  alerts_this_week: number;
  alerts_this_month: number;
}

export interface AlertStats {
  total_alerts: number;
  alerts_by_type: Record<string, number>;
  alerts_by_status: Record<string, number>;
  alerts_by_channel: Record<string, number>;
  recent_alerts: Alert[];
}

export interface UserStats {
  total_users: number;
  new_users_today: number;
  new_users_this_week: number;
  new_users_this_month: number;
  active_users: number;
}

// API Response Types
export interface ApiResponse<T> {
  data: T;
  message?: string;
  success: boolean;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  has_next: boolean;
  has_prev: boolean;
}

// Form Types
export interface AlertRuleFormData {
  name: string;
  description: string;
  alert_type: AlertType;
  trigger_conditions: Record<string, any>;
  message_template: string;
  title_template: string;
  channels: string[];
  priority: number;
  is_active: boolean;
  schedule_expression: string;
}

export interface UserFormData {
  email: string;
  name: string;
  phone: string;
  role: string;
  is_admin: boolean;
}

export interface ProviderFormData {
  name: string;
  type: string;
  location: string;
  contact: string;
  services: string[];
  is_active: boolean;
}

// Dashboard Types
export interface DashboardStats {
  metrics: SystemMetrics;
  alert_stats: AlertStats;
  user_stats: UserStats;
  recent_alerts: Alert[];
  active_rules: AlertRule[];
}

// Navigation Types
export interface NavItem {
  label: string;
  href: string;
  icon?: string;
  children?: NavItem[];
}

export interface BreadcrumbItem {
  label: string;
  href?: string;
}
