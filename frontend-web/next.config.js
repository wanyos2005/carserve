/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['localhost', 'your-backend-domain.com'],
  },
  // Windows file system optimizations for network access
  experimental: {
    // Reduce file system operations that cause Windows locking issues
    optimizePackageImports: ['lucide-react', 'antd'],
  },
  // Reduce file system operations on Windows
  generateBuildId: async () => {
    // Use a simpler build ID to reduce file operations
    return 'dev-build';
  },
  // Windows file system optimizations for network access
  webpack: (config, { isServer, dev }) => {
    if (process.platform === 'win32') {
      // Reduce file system watchers and improve Windows compatibility
      config.watchOptions = {
        ...config.watchOptions,
        ignored: ['**/node_modules/**', '**/.git/**', '**/.next/**'],
        poll: false,
        aggregateTimeout: 300,
      };
      // Reduce file system operations
      if (dev) {
        config.optimization = {
          ...config.optimization,
          removeAvailableModules: false,
          removeEmptyChunks: false,
        };
      }
    }
    return config;
  },
  async rewrites() {
    // Next.js API routes in pages/api/ take precedence over rewrites
    // The rewrites were intercepting API routes before Next.js handlers could process them
    // Removing rewrites so Next.js API route handlers work correctly
    return [];
  },
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin',
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
