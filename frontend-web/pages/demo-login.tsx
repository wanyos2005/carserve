import React, { useState } from 'react';
import { useRouter } from 'next/router';
import { useAuth } from '../lib/auth';
import { Mail, ArrowRight, CheckCircle, AlertCircle, User, Building, Shield } from 'lucide-react';

const DemoLoginPage: React.FC = () => {
  const router = useRouter();
  const { login } = useAuth();
  const [selectedUserType, setSelectedUserType] = useState<'carOwner' | 'provider' | 'admin'>('carOwner');
  const [isLoading, setIsLoading] = useState(false);

  const demoUsers = {
    carOwner: {
      email: 'carowner@demo.com',
      code: '123456',
      name: 'John Doe',
      description: 'Car Owner - Manage your vehicles and get service alerts'
    },
    provider: {
      email: 'provider@demo.com', 
      code: '123456',
      name: 'AutoCare Services',
      description: 'Service Provider - Manage your business and bookings'
    },
    admin: {
      email: 'admin@demo.com',
      code: '123456', 
      name: 'Platform Admin',
      description: 'Administrator - Manage the platform and users'
    }
  };

  const handleDemoLogin = async (userType: 'carOwner' | 'provider' | 'admin') => {
    setIsLoading(true);
    
    try {
      // Mock login - in real app this would call the API
      const user = demoUsers[userType];
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Mock successful login
      const mockUser = {
        id: '1',
        email: user.email,
        name: user.name,
        userType: userType,
        providerId: userType === 'provider' ? 'provider-123' : undefined,
        isActive: true,
        createdAt: new Date().toISOString(),
      };
      
      // Store in localStorage (mimicking real auth)
      localStorage.setItem('token', 'mock-token-123');
      localStorage.setItem('user', JSON.stringify(mockUser));
      
      // Redirect to dashboard
      router.push('/dashboard');
    } catch (error) {
      console.error('Demo login error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white flex flex-col justify-center">
      <div className="max-w-md mx-auto px-6 py-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">DriveOn Demo</h1>
          <h2 className="text-2xl font-semibold text-gray-900 mb-2">
            Choose a Demo Account
          </h2>
          <p className="text-gray-600">
            Select a user type to experience the platform
          </p>
        </div>

        <div className="bg-white">
          <div className="space-y-4">
            {/* Car Owner Demo */}
            <button
              onClick={() => handleDemoLogin('carOwner')}
              disabled={isLoading}
              className={`w-full p-4 border-2 rounded-lg text-left transition-colors ${
                selectedUserType === 'carOwner'
                  ? 'border-primary-500 bg-primary-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                  <User className="h-6 w-6 text-blue-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 text-lg">Car Owner</h3>
                  <p className="text-gray-600">Manage vehicles, get alerts, book services</p>
                </div>
              </div>
            </button>

            {/* Provider Demo */}
            <button
              onClick={() => handleDemoLogin('provider')}
              disabled={isLoading}
              className={`w-full p-4 border-2 rounded-lg text-left transition-colors ${
                selectedUserType === 'provider'
                  ? 'border-primary-500 bg-primary-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                  <Building className="h-6 w-6 text-green-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 text-lg">Service Provider</h3>
                  <p className="text-gray-600">Manage business, bookings, and services</p>
                </div>
              </div>
            </button>

            {/* Admin Demo */}
            <button
              onClick={() => handleDemoLogin('admin')}
              disabled={isLoading}
              className={`w-full p-4 border-2 rounded-lg text-left transition-colors ${
                selectedUserType === 'admin'
                  ? 'border-primary-500 bg-primary-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
                  <Shield className="h-6 w-6 text-purple-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 text-lg">Administrator</h3>
                  <p className="text-gray-600">Manage platform, users, and analytics</p>
                </div>
              </div>
            </button>
          </div>

          {isLoading && (
            <div className="mt-6 flex items-center justify-center">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary-600"></div>
              <span className="ml-2 text-sm text-gray-600">Signing in...</span>
            </div>
          )}

          <div className="mt-8 text-center">
            <a
              href="/login"
              className="text-primary-600 hover:text-primary-500 text-sm font-medium"
            >
              Use Real Login Instead
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DemoLoginPage;
