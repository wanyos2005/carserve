# DriveOn Web Application Deployment Guide

This guide covers deploying the DriveOn Next.js web application to Vercel and setting up the production environment.

## 🚀 Deployment Options

### Option 1: Vercel (Recommended)

Vercel is the recommended platform for Next.js applications due to its seamless integration and excellent performance.

#### Prerequisites
- Vercel account (free tier available)
- GitHub repository with the code
- Backend API URL

#### Deployment Steps

1. **Connect to Vercel**
   ```bash
   # Install Vercel CLI
   npm i -g vercel
   
   # Login to Vercel
   vercel login
   
   # Deploy from project directory
   cd frontend-web
   vercel
   ```

2. **Environment Variables**
   Set the following environment variables in Vercel dashboard:
   ```
   NEXT_PUBLIC_API_URL=https://your-backend-api.com
   ```

3. **Custom Domain (Optional)**
   - Go to Vercel Dashboard → Project Settings → Domains
   - Add your custom domain
   - Configure DNS records as instructed

### Option 2: Netlify

Alternative deployment option with similar features.

#### Deployment Steps

1. **Build Configuration**
   ```toml
   # netlify.toml
   [build]
     command = "npm run build"
     publish = ".next"
   
   [build.environment]
     NODE_VERSION = "18"
   ```

2. **Environment Variables**
   Set in Netlify dashboard:
   ```
   NEXT_PUBLIC_API_URL=https://your-backend-api.com
   ```

### Option 3: Self-Hosted (VPS/Cloud)

For full control over the deployment environment.

#### Prerequisites
- Node.js 18+ installed
- PM2 for process management
- Nginx for reverse proxy
- SSL certificate

#### Deployment Steps

1. **Build the Application**
   ```bash
   cd frontend-web
   npm install
   npm run build
   ```

2. **PM2 Configuration**
   ```javascript
   // ecosystem.config.js
   module.exports = {
     apps: [{
       name: 'driveon-web',
       script: 'npm',
       args: 'start',
       cwd: '/path/to/frontend-web',
       env: {
         NODE_ENV: 'production',
         NEXT_PUBLIC_API_URL: 'https://your-backend-api.com'
       }
     }]
   };
   ```

3. **Nginx Configuration**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       
       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

## 🔧 Environment Configuration

### Required Environment Variables

```bash
# API Configuration
NEXT_PUBLIC_API_URL=https://your-backend-api.com

# Optional: Analytics
NEXT_PUBLIC_GA_ID=your-google-analytics-id

# Optional: Sentry for error tracking
SENTRY_DSN=your-sentry-dsn
```

### Environment Files

1. **Development** (`.env.local`)
   ```bash
   NEXT_PUBLIC_API_URL=http://localhost:8000
   ```

2. **Production** (Set in deployment platform)
   ```bash
   NEXT_PUBLIC_API_URL=https://api.driveon.co.ke
   ```

## 📊 Performance Optimization

### Next.js Optimizations

1. **Image Optimization**
   ```typescript
   // next.config.js
   module.exports = {
     images: {
       domains: ['your-image-domain.com'],
       formats: ['image/webp', 'image/avif'],
     },
   };
   ```

2. **Bundle Analysis**
   ```bash
   npm install --save-dev @next/bundle-analyzer
   npm run analyze
   ```

3. **Caching Strategy**
   ```typescript
   // next.config.js
   module.exports = {
     async headers() {
       return [
         {
           source: '/api/:path*',
           headers: [
             { key: 'Cache-Control', value: 'public, max-age=60' },
           ],
         },
       ];
     },
   };
   ```

## 🔒 Security Configuration

### Security Headers

```typescript
// next.config.js
module.exports = {
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
```

### CORS Configuration

```typescript
// pages/api/_middleware.ts
export function middleware(req: NextRequest) {
  const response = NextResponse.next();
  
  response.headers.set('Access-Control-Allow-Origin', 'https://your-domain.com');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  return response;
}
```

## 📈 Monitoring and Analytics

### 1. Google Analytics
```typescript
// lib/analytics.ts
export const GA_TRACKING_ID = process.env.NEXT_PUBLIC_GA_ID;

export const pageview = (url: string) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('config', GA_TRACKING_ID, {
      page_path: url,
    });
  }
};
```

### 2. Error Tracking (Sentry)
```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
});
```

### 3. Performance Monitoring
```typescript
// lib/performance.ts
export const reportWebVitals = (metric: any) => {
  if (metric.label === 'web-vital') {
    // Send to analytics service
    console.log(metric);
  }
};
```

## 🚀 CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy to Vercel

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend-web/package-lock.json
      
      - name: Install dependencies
        run: |
          cd frontend-web
          npm ci
      
      - name: Run tests
        run: |
          cd frontend-web
          npm run test
      
      - name: Build application
        run: |
          cd frontend-web
          npm run build
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
          working-directory: frontend-web
```

## 🔄 Database Migrations

### Prisma Setup (if using Prisma)

```typescript
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

## 📱 Mobile Optimization

### PWA Configuration

```typescript
// next.config.js
const withPWA = require('next-pwa')({
  dest: 'public',
  register: true,
  skipWaiting: true,
});

module.exports = withPWA({
  // Next.js config
});
```

## 🧪 Testing Strategy

### Test Configuration

```typescript
// jest.config.js
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/$1',
  },
};
```

### E2E Testing with Playwright

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
  },
});
```

## 📋 Deployment Checklist

- [ ] Environment variables configured
- [ ] API endpoints tested
- [ ] SSL certificate installed
- [ ] Domain DNS configured
- [ ] Analytics tracking setup
- [ ] Error monitoring configured
- [ ] Performance monitoring active
- [ ] Security headers implemented
- [ ] CORS properly configured
- [ ] Database connections tested
- [ ] Backup strategy in place
- [ ] Monitoring alerts setup

## 🆘 Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Node.js version compatibility
   - Verify all dependencies are installed
   - Review build logs for specific errors

2. **API Connection Issues**
   - Verify `NEXT_PUBLIC_API_URL` is set correctly
   - Check CORS configuration on backend
   - Ensure API endpoints are accessible

3. **Performance Issues**
   - Enable Next.js optimizations
   - Implement proper caching strategies
   - Use CDN for static assets

4. **Authentication Issues**
   - Verify JWT token handling
   - Check session management
   - Review CORS settings

### Support Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Vercel Documentation](https://vercel.com/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [TypeScript Documentation](https://www.typescriptlang.org/docs)

## 📞 Contact

For deployment support or questions:
- Email: support@driveon.co.ke
- Documentation: https://docs.driveon.co.ke
- GitHub Issues: https://github.com/driveon/web/issues
