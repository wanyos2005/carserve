# DriveOn Web Application

A modern, responsive web application for the DriveOn car management platform built with Next.js, TypeScript, and Tailwind CSS.

## 🚀 Features

### Marketing Website
- **SEO Optimized**: Built for search engine visibility
- **Responsive Design**: Works perfectly on all devices
- **Modern UI**: Clean, professional design with Tailwind CSS
- **Performance**: Fast loading with Next.js optimizations

### Admin Dashboard
- **User Management**: Manage users, providers, and admin privileges
- **Alert Rules**: Configure automated alert rules and triggers
- **Analytics**: View platform metrics and performance data
- **System Monitoring**: Real-time system health monitoring

### Provider Portal
- **Onboarding Flow**: Step-by-step provider registration
- **Service Management**: Add and manage service offerings
- **Booking Management**: Handle customer appointments
- **Analytics**: Track performance and revenue

### Authentication
- **OTP-based Login**: Secure email verification system
- **Role-based Access**: Different dashboards for different user types
- **Session Management**: Secure token-based authentication

## 🛠️ Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Authentication**: Custom OTP system
- **API Integration**: RESTful API with FastAPI backend
- **Deployment**: Vercel (recommended)

## 📁 Project Structure

```
frontend-web/
├── components/           # Reusable UI components
│   ├── layout/          # Layout components (Header, Footer)
│   └── sections/        # Page sections (Hero, Features, etc.)
├── hooks/               # Custom React hooks
├── lib/                 # Utility functions and configurations
├── pages/               # Next.js pages
│   ├── api/            # API routes
│   ├── admin/          # Admin dashboard pages
│   └── provider/       # Provider portal pages
├── types/               # TypeScript type definitions
└── styles/              # Global styles and Tailwind config
```

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Backend API running (FastAPI)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/driveon/web.git
   cd frontend-web
   ```

2. **Install dependencies**
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Environment Setup**
   ```bash
   cp env.example .env.local
   ```
   
   Update `.env.local` with your configuration:
   ```bash
   NEXT_PUBLIC_API_URL=http://localhost:8000
   ```

4. **Start development server**
   ```bash
   npm run dev
   # or
   yarn dev
   ```

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NEXT_PUBLIC_API_URL` | Backend API URL | Yes |
| `NEXT_PUBLIC_GA_ID` | Google Analytics ID | No |
| `SENTRY_DSN` | Sentry error tracking | No |

### API Integration

The application integrates with the FastAPI backend through:

- **Authentication**: `/api/users/send-code`, `/api/users/verify-code`
- **User Management**: `/api/users/me`, `/api/users/all`
- **Admin Functions**: `/api/admin/*`
- **Provider Services**: `/api/service-provider-service/*`
- **Alert System**: `/api/alert-service/*`

## 📱 Pages and Routes

### Marketing Website
- `/` - Landing page
- `/about` - About page
- `/contact` - Contact page
- `/pricing` - Pricing plans

### Authentication
- `/login` - Login page
- `/dashboard` - Main dashboard (role-based)

### Admin Dashboard
- `/admin/dashboard` - Admin overview
- `/admin/users` - User management
- `/admin/alert-rules` - Alert rules management
- `/admin/analytics` - Analytics dashboard

### Provider Portal
- `/provider/onboarding` - Provider registration
- `/provider/dashboard` - Provider dashboard
- `/provider/services` - Service management
- `/provider/bookings` - Booking management

## 🎨 UI Components

### Layout Components
- `Header` - Navigation header
- `Footer` - Site footer
- `Layout` - Main layout wrapper

### Section Components
- `HeroSection` - Landing page hero
- `FeaturesSection` - Features showcase
- `PricingSection` - Pricing plans
- `ContactSection` - Contact form
- `TestimonialsSection` - User testimonials

### Form Components
- `LoginForm` - Authentication form
- `ContactForm` - Contact submission
- `OnboardingForm` - Provider registration

## 🔐 Authentication Flow

1. **Email Input**: User enters email address
2. **OTP Generation**: System sends verification code
3. **Code Verification**: User enters 6-digit code
4. **Token Generation**: JWT token created and stored
5. **Role-based Redirect**: User redirected based on role

### User Types
- **Car Owner**: Basic user dashboard
- **Provider**: Service provider portal
- **Admin**: Administrative dashboard

## 📊 Performance Optimization

### Next.js Features
- **Static Generation**: Pre-built pages for better performance
- **Image Optimization**: Automatic image optimization
- **Code Splitting**: Automatic code splitting for smaller bundles
- **Caching**: Built-in caching strategies

### Tailwind CSS
- **Utility-first**: Rapid UI development
- **Responsive**: Mobile-first design approach
- **Customizable**: Easy theme customization
- **Optimized**: Purged CSS for smaller bundle size

## 🧪 Testing

### Test Commands
```bash
# Run tests
npm run test

# Run tests in watch mode
npm run test:watch

# Run E2E tests
npm run test:e2e

# Run tests with coverage
npm run test:coverage
```

### Test Structure
```
tests/
├── components/          # Component tests
├── pages/              # Page tests
├── api/                # API route tests
└── e2e/                # End-to-end tests
```

## 🚀 Deployment

### Vercel (Recommended)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Production deployment
vercel --prod
```

### Environment Variables
Set the following in your deployment platform:
- `NEXT_PUBLIC_API_URL` - Your backend API URL
- `NEXT_PUBLIC_GA_ID` - Google Analytics ID (optional)

### Custom Domain
1. Add domain in Vercel dashboard
2. Configure DNS records
3. SSL certificate automatically provisioned

## 📈 Analytics and Monitoring

### Google Analytics
- Page view tracking
- User interaction tracking
- Conversion tracking
- Performance monitoring

### Error Tracking
- Sentry integration for error monitoring
- Performance monitoring
- User session tracking

## 🔒 Security

### Security Features
- **HTTPS Only**: All traffic encrypted
- **CORS Configuration**: Proper cross-origin setup
- **Security Headers**: XSS and CSRF protection
- **Input Validation**: Client and server-side validation
- **Authentication**: Secure token-based auth

### Best Practices
- Regular dependency updates
- Security audit with `npm audit`
- Environment variable protection
- API rate limiting

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards
- TypeScript for type safety
- ESLint for code quality
- Prettier for code formatting
- Conventional commits for commit messages

## 📚 Documentation

### API Documentation
- [Backend API Docs](https://api.driveon.co.ke/docs)
- [Authentication Guide](./docs/auth.md)
- [Component Library](./docs/components.md)

### Deployment Guides
- [Vercel Deployment](./DEPLOYMENT.md)
- [Environment Setup](./docs/environment.md)
- [Troubleshooting](./docs/troubleshooting.md)

## 🐛 Troubleshooting

### Common Issues

1. **Build Errors**
   ```bash
   # Clear cache and reinstall
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **API Connection Issues**
   - Check `NEXT_PUBLIC_API_URL` environment variable
   - Verify backend API is running
   - Check CORS configuration

3. **Authentication Issues**
   - Clear browser storage
   - Check token expiration
   - Verify API endpoints

### Debug Mode
```bash
# Enable debug logging
DEBUG=* npm run dev
```

## 📞 Support

- **Documentation**: [docs.driveon.co.ke](https://docs.driveon.co.ke)
- **Issues**: [GitHub Issues](https://github.com/driveon/web/issues)
- **Email**: support@driveon.co.ke
- **Discord**: [DriveOn Community](https://discord.gg/driveon)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Next.js team for the amazing framework
- Tailwind CSS for the utility-first CSS framework
- Vercel for the deployment platform
- All contributors and users of DriveOn

---

**DriveOn** - Smart Car Management Made Simple 🚗✨
