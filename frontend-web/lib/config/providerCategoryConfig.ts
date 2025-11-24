import {
  Wrench,
  Shield,
  Fuel,
  Car,
  Package,
  Calendar,
  TrendingUp,
  CheckCircle,
  List,
  Star,
  Settings,
  History,
  ShoppingCart,
  FileText,
  Users,
  BarChart3,
  AlertTriangle,
  LocalGasStation,
  LocalCarWash,
  Inventory2,
  Policy,
  Assignment,
  Queue,
  Business,
  LucideIcon
} from 'lucide-react';

export enum ProviderBusinessType {
  SERVICE_MAINTENANCE = 'serviceMaintenance',
  SUPPORT_SERVICES = 'supportServices',
  SALES_PARTS = 'salesParts',
  INSURANCE_DOCUMENTATION = 'insuranceDocumentation',
  RENTAL_LEASING = 'rentalLeasing',
  UNREGISTERED = 'unregistered'
}

export interface QuickAction {
  title: string;
  subtitle: string;
  icon: LucideIcon;
  color: string;
  route?: string;
  onClick?: () => void;
  isComingSoon?: boolean;
}

export interface StatCard {
  title: string;
  value: string;
  icon: LucideIcon;
  color: string;
}

export interface ProviderCategoryConfig {
  name: string;
  id: number;
  businessType: ProviderBusinessType;
  description: string;
  icon: LucideIcon;
  primaryColor: string;
  quickActions: QuickAction[];
  statCards: StatCard[];
  welcomeMessage: string;
}

// Stats cache for real-time data
const statsCache: Map<string, Record<string, any>> = new Map();

export class ProviderCategoryConfigs {
  private static configs: Map<string, ProviderCategoryConfig> = new Map([
    ['garage / mechanic', {
      name: 'Garage / Mechanic',
      id: 2,
      businessType: ProviderBusinessType.SERVICE_MAINTENANCE,
      description: 'Manage your garage, bookings, and automotive services',
      icon: Wrench,
      primaryColor: 'blue',
      welcomeMessage: 'Manage your garage, bookings, and services',
      statCards: [
        { title: 'Active Bookings', value: '0', icon: Calendar, color: 'blue' },
        { title: "Today's Earnings", value: 'KES 0', icon: TrendingUp, color: 'green' },
        { title: 'Pending Tasks', value: '0', icon: List, color: 'orange' },
        { title: 'Total Services Today', value: '0', icon: Wrench, color: 'purple' },
        { title: 'Completed Services Today', value: '0', icon: CheckCircle, color: 'teal' },
        { title: 'Rating', value: '0.0 ★', icon: Star, color: 'amber' },
      ],
      quickActions: [
        {
          title: 'Log Service',
          subtitle: 'Log completed services and maintenance',
          icon: CheckCircle,
          color: 'green',
          route: '/provider/log-service',
        },
        {
          title: 'Orders & Parts',
          subtitle: 'Manage parts orders and inventory',
          icon: ShoppingCart,
          color: 'orange',
          isComingSoon: true,
        },
        {
          title: 'WorkFlows',
          subtitle: 'View past services and transactions',
          icon: History,
          color: 'purple',
          route: '/history',
        },
        {
          title: 'Settings',
          subtitle: 'Manage provider settings and templates',
          icon: Settings,
          color: 'grey',
          route: '/provider-settings',
        },
      ],
    }],
    ['insurance agency', {
      name: 'Insurance Agency',
      id: 7,
      businessType: ProviderBusinessType.INSURANCE_DOCUMENTATION,
      description: 'Manage your insurance services and clients',
      icon: Shield,
      primaryColor: 'green',
      welcomeMessage: 'Manage your insurance services and clients',
      statCards: [
        { title: 'Active Policies', value: '0', icon: Policy, color: 'green' },
        { title: "Today's Revenue", value: 'KES 0', icon: TrendingUp, color: 'blue' },
        { title: 'Pending Claims', value: '0', icon: Assignment, color: 'orange' },
        { title: 'Client Rating', value: '0.0 ★', icon: Star, color: 'amber' },
      ],
      quickActions: [
        {
          title: 'Policy Management',
          subtitle: 'View and manage insurance policies',
          icon: Policy,
          color: 'green',
          isComingSoon: true,
        },
        {
          title: 'Claims Processing',
          subtitle: 'Log insurance services and claims',
          icon: Assignment,
          color: 'blue',
          isComingSoon: true,
        },
        {
          title: 'Log Insurance Policy',
          subtitle: 'Create and log new insurance policies',
          icon: Policy,
          color: 'green',
          route: '/insurance-log-service',
        },
        {
          title: 'Client Portal',
          subtitle: 'Manage client information and documents',
          icon: Users,
          color: 'purple',
          isComingSoon: true,
        },
        {
          title: 'WorkFlows',
          subtitle: 'View past policies and transactions',
          icon: History,
          color: 'purple',
          route: '/history',
        },
        {
          title: 'Reports',
          subtitle: 'View policy and claims reports',
          icon: BarChart3,
          color: 'orange',
          isComingSoon: true,
        },
        {
          title: 'Settings',
          subtitle: 'Manage provider settings and templates',
          icon: Settings,
          color: 'grey',
          route: '/provider-settings',
        },
      ],
    }],
    ['fuel station', {
      name: 'Fuel Station',
      id: 3,
      businessType: ProviderBusinessType.SUPPORT_SERVICES,
      description: 'Manage fuel sales, inventory, and station operations',
      icon: LocalGasStation,
      primaryColor: 'orange',
      welcomeMessage: 'Manage fuel sales and station operations',
      statCards: [
        { title: 'Fuel Sales', value: '0L', icon: LocalGasStation, color: 'orange' },
        { title: "Today's Revenue", value: 'KES 0', icon: TrendingUp, color: 'green' },
        { title: 'Inventory Alert', value: '0', icon: AlertTriangle, color: 'red' },
        { title: 'Customer Rating', value: '0.0 ★', icon: Star, color: 'amber' },
      ],
      quickActions: [
        {
          title: 'Sales Dashboard',
          subtitle: 'View fuel sales and transactions',
          icon: BarChart3,
          color: 'orange',
          isComingSoon: true,
        },
        {
          title: 'Log Service',
          subtitle: 'Log fuel services and transactions',
          icon: CheckCircle,
          color: 'green',
          route: '/provider/log-service',
        },
        {
          title: 'Inventory',
          subtitle: 'Manage fuel and station inventory',
          icon: Inventory2,
          color: 'blue',
          isComingSoon: true,
        },
        {
          title: 'Pump Management',
          subtitle: 'Monitor pump status and maintenance',
          icon: Settings,
          color: 'green',
          isComingSoon: true,
        },
        {
          title: 'WorkFlows',
          subtitle: 'View past sales and transactions',
          icon: History,
          color: 'purple',
          route: '/history',
        },
        {
          title: 'Reports',
          subtitle: 'View sales and operational reports',
          icon: BarChart3,
          color: 'purple',
          isComingSoon: true,
        },
        {
          title: 'Settings',
          subtitle: 'Manage provider settings and templates',
          icon: Settings,
          color: 'grey',
          route: '/provider-settings',
        },
      ],
    }],
    ['car wash & detailing', {
      name: 'Car Wash & Detailing',
      id: 4,
      businessType: ProviderBusinessType.SUPPORT_SERVICES,
      description: 'Manage car wash services, bookings, and facility operations',
      icon: LocalCarWash,
      primaryColor: 'cyan',
      welcomeMessage: 'Manage car wash services and bookings',
      statCards: [
        { title: "Today's Services", value: '0', icon: LocalCarWash, color: 'cyan' },
        { title: "Today's Revenue", value: 'KES 0', icon: TrendingUp, color: 'green' },
        { title: 'Queue Length', value: '0', icon: Queue, color: 'orange' },
        { title: 'Rating', value: '0.0 ★', icon: Star, color: 'amber' },
      ],
      quickActions: [
        {
          title: 'Service Queue',
          subtitle: 'Manage current wash and detailing queue',
          icon: Queue,
          color: 'cyan',
          isComingSoon: true,
        },
        {
          title: 'Log Service',
          subtitle: 'Log completed wash and detailing services',
          icon: CheckCircle,
          color: 'green',
          route: '/provider/log-service',
        },
        {
          title: 'Facility Status',
          subtitle: 'Monitor equipment and facility status',
          icon: Wrench,
          color: 'blue',
          isComingSoon: true,
        },
        {
          title: 'WorkFlows',
          subtitle: 'View past wash and detailing services',
          icon: History,
          color: 'purple',
          route: '/history',
        },
        {
          title: 'Packages',
          subtitle: 'Manage service packages and pricing',
          icon: List,
          color: 'purple',
          isComingSoon: true,
        },
        {
          title: 'Settings',
          subtitle: 'Manage provider settings and templates',
          icon: Settings,
          color: 'grey',
          route: '/provider-settings',
        },
      ],
    }],
    ['spare parts dealer', {
      name: 'Spare Parts Dealer',
      id: 8,
      businessType: ProviderBusinessType.SALES_PARTS,
      description: 'Manage parts inventory, sales, and customer orders',
      icon: Package,
      primaryColor: 'purple',
      welcomeMessage: 'Manage parts inventory and sales',
      statCards: [
        { title: 'Active Orders', value: '0', icon: ShoppingCart, color: 'purple' },
        { title: "Today's Sales", value: 'KES 0', icon: TrendingUp, color: 'green' },
        { title: 'Low Stock', value: '0', icon: AlertTriangle, color: 'red' },
        { title: 'Rating', value: '0.0 ★', icon: Star, color: 'amber' },
      ],
      quickActions: [
        {
          title: 'Inventory',
          subtitle: 'Manage parts inventory and stock levels',
          icon: Inventory2,
          color: 'purple',
          isComingSoon: true,
        },
        {
          title: 'Log Service',
          subtitle: 'Log parts installation and services',
          icon: CheckCircle,
          color: 'green',
          route: '/provider/log-service',
        },
        {
          title: 'Orders',
          subtitle: 'Process customer orders and deliveries',
          icon: ShoppingCart,
          color: 'blue',
          isComingSoon: true,
        },
        {
          title: 'Catalog',
          subtitle: 'Manage parts catalog and pricing',
          icon: FileText,
          color: 'green',
          isComingSoon: true,
        },
        {
          title: 'WorkFlows',
          subtitle: 'View past parts sales and services',
          icon: History,
          color: 'purple',
          route: '/history',
        },
        {
          title: 'Suppliers',
          subtitle: 'Manage supplier relationships and orders',
          icon: Business,
          color: 'orange',
          isComingSoon: true,
        },
        {
          title: 'Settings',
          subtitle: 'Manage provider settings and templates',
          icon: Settings,
          color: 'grey',
          route: '/provider-settings',
        },
      ],
    }],
  ]);

  static getConfig(categoryName: string): ProviderCategoryConfig {
    const normalizedName = categoryName.toLowerCase().trim();
    return this.configs.get(normalizedName) || this.getDefaultConfig(categoryName);
  }

  static getDefaultConfig(categoryName: string): ProviderCategoryConfig {
    return {
      name: categoryName,
      id: 0,
      businessType: ProviderBusinessType.UNREGISTERED,
      description: 'Manage your business operations and services',
      icon: Business,
      primaryColor: 'grey',
      welcomeMessage: 'Manage your business operations',
      statCards: [
        { title: 'Active Items', value: '0', icon: List, color: 'grey' },
        { title: "Today's Activity", value: '0', icon: TrendingUp, color: 'grey' },
        { title: 'Pending Tasks', value: '0', icon: AlertTriangle, color: 'grey' },
        { title: 'Rating', value: 'N/A', icon: Star, color: 'grey' },
      ],
      quickActions: [
        {
          title: 'Dashboard',
          subtitle: 'View your business overview',
          icon: BarChart3,
          color: 'grey',
          isComingSoon: true,
        },
        {
          title: 'Services',
          subtitle: 'Manage your services',
          icon: Wrench,
          color: 'grey',
          isComingSoon: true,
        },
        {
          title: 'Settings',
          subtitle: 'Configure your business settings',
          icon: Settings,
          color: 'grey',
          route: '/provider-settings',
        },
      ],
    };
  }

  static getAllConfigs(): ProviderCategoryConfig[] {
    return Array.from(this.configs.values());
  }

  static updateStatsCache(providerId: string, stats: Record<string, any>): void {
    statsCache.set(providerId, stats);
  }

  static getCachedStats(providerId: string): Record<string, any> | null {
    return statsCache.get(providerId) || null;
  }

  static getDynamicStatCards(providerId: string, categoryName: string, realStats?: Record<string, any>): StatCard[] {
    const stats = realStats || this.getCachedStats(providerId);
    const config = this.getConfig(categoryName);
    
    if (!stats) {
      return config.statCards;
    }

    // Map real stats to stat cards based on category
    switch (config.businessType) {
      case ProviderBusinessType.INSURANCE_DOCUMENTATION:
        return this.getInsuranceStatCards(stats);
      case ProviderBusinessType.SUPPORT_SERVICES:
        if (categoryName.toLowerCase().includes('fuel')) {
          return this.getFuelStationStatCards(stats);
        } else if (categoryName.toLowerCase().includes('wash') || categoryName.toLowerCase().includes('detailing')) {
          return this.getCarWashStatCards(stats);
        }
        return config.statCards;
      case ProviderBusinessType.SALES_PARTS:
        return this.getSparePartsStatCards(stats);
      case ProviderBusinessType.SERVICE_MAINTENANCE:
      default:
        return this.getGarageStatCards(stats);
    }
  }

  private static getInsuranceStatCards(stats: Record<string, any>): StatCard[] {
    return [
      {
        title: 'Active Policies',
        value: `${stats.active_policies || stats.activeBookings || 0}`,
        icon: Policy,
        color: 'green',
      },
      {
        title: "Today's Revenue",
        value: `KES ${this.formatCurrency(stats.todays_revenue || stats.totalRevenue || 0)}`,
        icon: TrendingUp,
        color: 'blue',
      },
      {
        title: 'Pending Claims',
        value: `${stats.pending_claims || stats.pendingBookings || 0}`,
        icon: Assignment,
        color: 'orange',
      },
      {
        title: 'Client Rating',
        value: `${(stats.rating || 0).toFixed(1)} ★`,
        icon: Star,
        color: 'amber',
      },
    ];
  }

  private static getFuelStationStatCards(stats: Record<string, any>): StatCard[] {
    return [
      {
        title: 'Fuel Sales',
        value: `${stats.fuel_sales_liters || 0}L`,
        icon: LocalGasStation,
        color: 'orange',
      },
      {
        title: "Today's Revenue",
        value: `KES ${this.formatCurrency(stats.todays_revenue || stats.totalRevenue || 0)}`,
        icon: TrendingUp,
        color: 'green',
      },
      {
        title: 'Inventory Alert',
        value: `${stats.inventory_alerts || stats.pendingBookings || 0}`,
        icon: AlertTriangle,
        color: 'red',
      },
      {
        title: 'Customer Rating',
        value: `${(stats.rating || 0).toFixed(1)} ★`,
        icon: Star,
        color: 'amber',
      },
    ];
  }

  private static getCarWashStatCards(stats: Record<string, any>): StatCard[] {
    return [
      {
        title: "Today's Services",
        value: `${stats.todays_services || stats.completedBookings || 0}`,
        icon: LocalCarWash,
        color: 'cyan',
      },
      {
        title: "Today's Revenue",
        value: `KES ${this.formatCurrency(stats.todays_revenue || stats.totalRevenue || 0)}`,
        icon: TrendingUp,
        color: 'green',
      },
      {
        title: 'Queue Length',
        value: `${stats.queue_length || stats.pendingBookings || 0}`,
        icon: Queue,
        color: 'orange',
      },
      {
        title: 'Rating',
        value: `${(stats.rating || 0).toFixed(1)} ★`,
        icon: Star,
        color: 'amber',
      },
    ];
  }

  private static getSparePartsStatCards(stats: Record<string, any>): StatCard[] {
    return [
      {
        title: 'Active Orders',
        value: `${stats.active_orders || stats.totalBookings || 0}`,
        icon: ShoppingCart,
        color: 'purple',
      },
      {
        title: "Today's Sales",
        value: `KES ${this.formatCurrency(stats.todays_sales || stats.totalRevenue || 0)}`,
        icon: TrendingUp,
        color: 'green',
      },
      {
        title: 'Low Stock',
        value: `${stats.low_stock || stats.pendingBookings || 0}`,
        icon: AlertTriangle,
        color: 'red',
      },
      {
        title: 'Rating',
        value: `${(stats.rating || 0).toFixed(1)} ★`,
        icon: Star,
        color: 'amber',
      },
    ];
  }

  private static getGarageStatCards(stats: Record<string, any>): StatCard[] {
    return [
      {
        title: 'Active Bookings',
        value: `${stats.active_bookings || stats.totalBookings || 0}`,
        icon: Calendar,
        color: 'blue',
      },
      {
        title: "Today's Earnings",
        value: `KES ${this.formatCurrency(stats.todays_earnings || stats.totalRevenue || 0)}`,
        icon: TrendingUp,
        color: 'green',
      },
      {
        title: 'Pending Tasks',
        value: `${stats.pending_tasks || stats.pendingBookings || 0}`,
        icon: List,
        color: 'orange',
      },
      {
        title: 'Total Services Today',
        value: `${stats.total_services_today || stats.activeServices || 0}`,
        icon: Wrench,
        color: 'purple',
      },
      {
        title: 'Completed Services Today',
        value: `${stats.completed_services_today || stats.completedBookings || 0}`,
        icon: CheckCircle,
        color: 'teal',
      },
      {
        title: 'Rating',
        value: `${(stats.rating || 0).toFixed(1)} ★`,
        icon: Star,
        color: 'amber',
      },
    ];
  }

  private static formatCurrency(amount: number): string {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }
}

