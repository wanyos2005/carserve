import { NextSeoProps } from 'next-seo';

export const defaultSEO: NextSeoProps = {
  title: 'DriveOn - Smart Car Management Platform',
  description: 'Never miss insurance renewal or service reminders. DriveOn helps you manage your vehicle maintenance, insurance, and service appointments with smart alerts.',
  canonical: 'https://driveon.co.ke',
  openGraph: {
    type: 'website',
    locale: 'en_KE',
    url: 'https://driveon.co.ke',
    siteName: 'DriveOn',
    title: 'DriveOn - Smart Car Management Platform',
    description: 'Never miss insurance renewal or service reminders. DriveOn helps you manage your vehicle maintenance, insurance, and service appointments with smart alerts.',
    images: [
      {
        url: 'https://driveon.co.ke/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'DriveOn - Smart Car Management Platform',
      },
    ],
  },
  twitter: {
    handle: '@driveon_ke',
    site: '@driveon_ke',
    cardType: 'summary_large_image',
  },
  additionalMetaTags: [
    {
      name: 'viewport',
      content: 'width=device-width, initial-scale=1',
    },
    {
      name: 'theme-color',
      content: '#3b82f6',
    },
    {
      name: 'apple-mobile-web-app-capable',
      content: 'yes',
    },
    {
      name: 'apple-mobile-web-app-status-bar-style',
      content: 'default',
    },
    {
      name: 'apple-mobile-web-app-title',
      content: 'DriveOn',
    },
    {
      name: 'application-name',
      content: 'DriveOn',
    },
    {
      name: 'msapplication-TileColor',
      content: '#3b82f6',
    },
  ],
};

export const adminSEO: NextSeoProps = {
  title: 'Admin Dashboard - DriveOn',
  description: 'Manage alert rules, monitor system metrics, and oversee the DriveOn platform.',
  noindex: true,
  nofollow: true,
};

export const providerSEO: NextSeoProps = {
  title: 'Service Provider Portal - DriveOn',
  description: 'Manage your service offerings, bookings, and customer relationships on the DriveOn platform.',
  noindex: true,
  nofollow: true,
};
