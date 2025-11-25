import { 
  Wrench, 
  Droplets as LocalCarWash, 
  Package, 
  Shield, 
  Car,
  LucideIcon
} from 'lucide-react';

export interface FrontendCategoryGroup {
  name: string;
  description: string;
  icon: LucideIcon;
  color: string;
  backendCategories: string[];
  onboardingDescription: string;
}

export class FrontendCategoryGroups {
  static readonly groups: FrontendCategoryGroup[] = [
    {
      name: 'Repair & Maintenance',
      description: 'Automotive repair, maintenance, and diagnostic services',
      icon: Wrench,
      color: 'blue',
      onboardingDescription: 'Perfect for garages, mechanics, and specialized repair shops',
      backendCategories: [
        'Garage / Mechanic',
        'Tyre & Wheel Center',
        'Battery & Electrical Specialist',
        'Auto Body & Paint Shop',
        'Diagnostics & ECU Specialist',
        'Hybrid / EV Specialist',
      ],
    },
    {
      name: 'Vehicle Care & Support',
      description: 'Vehicle care, fuel, carwash and support services',
      icon: LocalCarWash,
      color: 'orange',
      onboardingDescription: 'Ideal for fuel stations, car washes, and support services',
      backendCategories: [
        'Fuel Station',
        'Car Wash & Detailing',
        'Roadside Assistance / Towing Service',
        'Vehicle Pickup & Delivery',
      ],
    },
    {
      name: 'Parts & Accessories',
      description: 'Automotive parts, accessories, and customization',
      icon: Package,
      color: 'purple',
      onboardingDescription: 'Great for parts dealers and customization shops',
      backendCategories: [
        'Spare Parts Dealer',
        'Car Accessories / Customization Shop',
      ],
    },
    {
      name: 'Insurance & Documentation',
      description: 'Insurance, registration, and compliance services',
      icon: Shield,
      color: 'green',
      onboardingDescription: 'Perfect for insurance agencies and documentation services',
      backendCategories: [
        'Insurance Agency',
        'Vehicle Registration & Documentation Agency',
        'Inspection & Emission Testing Center',
      ],
    },
    {
      name: 'Vehicle Rental',
      description: 'Vehicle rental and leasing services',
      icon: Car,
      color: 'teal',
      onboardingDescription: 'Ideal for car rental and leasing companies',
      backendCategories: [
        'Car Rental / Leasing Company',
      ],
    },
  ];

  static getGroupForBackendCategory(backendCategory: string): FrontendCategoryGroup | null {
    for (const group of this.groups) {
      if (group.backendCategories.includes(backendCategory)) {
        return group;
      }
    }
    return null;
  }

  static getBackendCategoriesForGroup(groupName: string): string[] {
    const group = this.groups.find(g => g.name === groupName);
    if (!group) {
      throw new Error(`Group not found: ${groupName}`);
    }
    return group.backendCategories;
  }

  static getAllGroups(): FrontendCategoryGroup[] {
    return this.groups;
  }

  static isValidBackendCategory(category: string): boolean {
    return this.groups.some(group => group.backendCategories.includes(category));
  }
}

