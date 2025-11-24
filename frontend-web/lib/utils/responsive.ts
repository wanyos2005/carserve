/**
 * Responsive utility functions and breakpoints
 * Mobile-first approach: <480px, 768px, 1024px+
 */

export const breakpoints = {
  mobile: '480px',
  tablet: '768px',
  desktop: '1024px',
} as const;

/**
 * Tailwind responsive classes helper
 */
export const responsive = {
  // Mobile (< 480px) - default/base styles
  mobile: {
    container: 'w-full px-4',
    grid: 'grid-cols-1',
    text: 'text-sm',
    padding: 'p-4',
  },
  
  // Tablet (≥ 768px)
  tablet: {
    container: 'md:w-full md:px-6',
    grid: 'md:grid-cols-2',
    text: 'md:text-base',
    padding: 'md:p-6',
  },
  
  // Desktop (≥ 1024px)
  desktop: {
    container: 'lg:max-w-6xl lg:mx-auto lg:px-8',
    grid: 'lg:grid-cols-3',
    text: 'lg:text-lg',
    padding: 'lg:p-8',
  },
} as const;

/**
 * Get responsive class names
 */
export const getResponsiveClasses = (type: 'container' | 'grid' | 'text' | 'padding') => {
  return `${responsive.mobile[type]} ${responsive.tablet[type]} ${responsive.desktop[type]}`;
};

