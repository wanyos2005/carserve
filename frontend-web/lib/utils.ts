import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

// Utility function to merge Tailwind classes
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Format date
export function formatDate(date: string | Date): string {
  const d = new Date(date);
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

// Format datetime
export function formatDateTime(date: string | Date): string {
  const d = new Date(date);
  return d.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

// Format relative time
export function formatRelativeTime(date: string | Date): string {
  const d = new Date(date);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - d.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return 'Just now';
  } else if (diffInSeconds < 3600) {
    const minutes = Math.floor(diffInSeconds / 60);
    return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
  } else if (diffInSeconds < 86400) {
    const hours = Math.floor(diffInSeconds / 3600);
    return `${hours} hour${hours > 1 ? 's' : ''} ago`;
  } else {
    const days = Math.floor(diffInSeconds / 86400);
    return `${days} day${days > 1 ? 's' : ''} ago`;
  }
}

// Format number with commas
export function formatNumber(num: number): string {
  return num.toLocaleString();
}

// Format currency
export function formatCurrency(amount: number, currency = 'KES'): string {
  return new Intl.NumberFormat('en-KE', {
    style: 'currency',
    currency,
  }).format(amount);
}

// Truncate text
export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength) + '...';
}

// Generate random ID
export function generateId(): string {
  return Math.random().toString(36).substr(2, 9);
}

// Debounce function
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout;
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

// Throttle function
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean;
  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

// Validate email
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// Validate phone number (Kenya)
export function isValidPhone(phone: string): boolean {
  const phoneRegex = /^(\+254|0)[0-9]{9}$/;
  return phoneRegex.test(phone.replace(/\s/g, ''));
}

// Get status color
export function getStatusColor(status: string): string {
  const statusColors: Record<string, string> = {
    pending: 'text-yellow-600 bg-yellow-100',
    sent: 'text-blue-600 bg-blue-100',
    delivered: 'text-green-600 bg-green-100',
    failed: 'text-red-600 bg-red-100',
    cancelled: 'text-gray-600 bg-gray-100',
  };
  return statusColors[status] || 'text-gray-600 bg-gray-100';
}

// Get priority color
export function getPriorityColor(priority: number): string {
  if (priority >= 4) return 'text-red-600 bg-red-100';
  if (priority >= 3) return 'text-orange-600 bg-orange-100';
  if (priority >= 2) return 'text-yellow-600 bg-yellow-100';
  return 'text-green-600 bg-green-100';
}

// Get alert type icon
export function getAlertTypeIcon(type: string): string {
  const typeIcons: Record<string, string> = {
    insurance_expiry: '🛡️',
    service_due: '🔧',
    promotional: '🎉',
    maintenance_reminder: '⚙️',
    claim_update: '📋',
    payment_reminder: '💳',
  };
  return typeIcons[type] || '🔔';
}

// Get channel icon
export function getChannelIcon(channel: string): string {
  const channelIcons: Record<string, string> = {
    in_app: '📱',
    push: '🔔',
    sms: '💬',
    email: '📧',
    whatsapp: '💬',
  };
  return channelIcons[channel] || '📱';
}
