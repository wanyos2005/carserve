import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { useAuth } from '../lib/auth';
import CarOwnerHistory from '../components/history/CarOwnerHistory';
import ProviderHistory from './provider/history';

const HistoryPage: React.FC = () => {
  const router = useRouter();
  const { user, isLoading: authLoading, isAuthenticated } = useAuth();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!authLoading) {
      setIsLoading(false);
      
      // Redirect if not authenticated
      if (!isAuthenticated) {
        router.push('/login');
        return;
      }
    }
  }, [authLoading, isAuthenticated, router]);

  // Determine user type and render appropriate component
  const getUserType = () => {
    if (!user) return null;
    
    if (user.providerId || user.userType === 'provider') {
      return 'provider';
    } else if (user.userType === 'carOwner' || !user.providerId) {
      return 'carOwner';
    } else if (user.userType === 'admin') {
      return 'admin';
    }
    return 'carOwner'; // Default to car owner
  };

  const getPageTitle = () => {
    const userType = getUserType();
    switch (userType) {
      case 'provider':
        return 'WorkFlows';
      case 'admin':
        return 'Admin Dashboard';
      case 'carOwner':
      default:
        return 'Past Interactions';
    }
  };

  if (isLoading || authLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return null; // Will redirect
  }

  const userType = getUserType();
  const title = getPageTitle();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between py-4 sm:py-6">
            <div className="flex items-center space-x-4">
              {userType === 'provider' ? (
                <Link href={`/provider/dashboard${user?.providerId ? `?providerId=${user.providerId}` : ''}`}>
                  <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors" title="Back to Dashboard">
                    <ArrowLeft className="h-5 w-5" />
                  </button>
                </Link>
              ) : (
                <Link href="/home">
                  <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors" title="Back to Home">
                    <ArrowLeft className="h-5 w-5" />
                  </button>
                </Link>
              )}
              <div>
                <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold text-gray-900">{title}</h1>
                <p className="text-sm sm:text-base text-gray-600 mt-1">
                  {userType === 'provider' 
                    ? 'View your bookings and service history' 
                    : 'View your past bookings and service logs'}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6 lg:py-8">
        {/* Render appropriate component based on user type */}
        {userType === 'provider' ? (
          <ProviderHistory />
        ) : (
          <CarOwnerHistory />
        )}
      </div>
    </div>
  );
};

export default HistoryPage;

