import React, { useEffect } from 'react';
import { useRouter } from 'next/router';
import { NextSeo } from 'next-seo';
import Head from 'next/head';
import Link from 'next/link';
import { useAuth } from '../lib/auth';
import Header from '../components/layout/Header';
import Footer from '../components/layout/Footer';
import HeroSection from '../components/sections/HeroSection';
import FeaturesSection from '../components/sections/FeaturesSection';
import HowItWorksSection from '../components/sections/HowItWorksSection';
import TestimonialsSection from '../components/sections/TestimonialsSection';
import PricingSection from '../components/sections/PricingSection';
import ContactSection from '../components/sections/ContactSection';
import DownloadSection from '../components/sections/DownloadSection';
import { defaultSEO } from '../lib/seo';
import { ArrowRight, LogIn, UserPlus, Shield, Building, Car } from 'lucide-react';

const HomePage: React.FC = () => {
  const router = useRouter();
  const { isAuthenticated, isLoading, user } = useAuth();

  useEffect(() => {
    if (!isLoading && isAuthenticated && user) {
      if (user.providerId) {
        // Redirect to provider dashboard with user's providerId
        router.push(`/provider/dashboard?providerId=${user.providerId}`);
      } else {
        // If no providerId, stay on home page or redirect to appropriate page
        // For now, we'll stay on home page
      }
    }
  }, [isAuthenticated, isLoading, user, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <>
      <NextSeo {...defaultSEO} />
      <Head>
        <link rel="icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
        <link rel="manifest" href="/manifest.json" />
      </Head>
      
      <div className="min-h-screen bg-white">
        <Header />
        
        <main>
          <HeroSection />
          <FeaturesSection />
          <HowItWorksSection />
          <TestimonialsSection />
          <PricingSection />
          <ContactSection />
          <DownloadSection />
          
          {/* Login/Signup CTA Section */}
          <section className="bg-gray-50 py-16">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div className="text-center">
                <h2 className="text-3xl font-bold text-gray-900 mb-4">
                  Ready to Get Started?
                </h2>
                <p className="text-xl text-gray-600 mb-8">
                  Join thousands of car owners and service providers on DriveOn
                </p>
                
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  <Link href="/demo-login">
                    <button className="bg-primary-600 text-white px-8 py-3 rounded-lg hover:bg-primary-700 transition-colors flex items-center justify-center">
                      <LogIn className="h-5 w-5 mr-2" />
                      Try Demo
                    </button>
                  </Link>
                  
                  <Link href="/login">
                    <button className="bg-white text-primary-600 border-2 border-primary-600 px-8 py-3 rounded-lg hover:bg-primary-50 transition-colors flex items-center justify-center">
                      <UserPlus className="h-5 w-5 mr-2" />
                      Sign In
                    </button>
                  </Link>
                </div>
                
                <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8">
                  <div className="text-center">
                    <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <Car className="h-8 w-8 text-blue-600" />
                    </div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">Car Owners</h3>
                    <p className="text-gray-600">Manage your vehicles, get alerts, and book services</p>
                  </div>
                  
                  <div className="text-center">
                    <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <Building className="h-8 w-8 text-green-600" />
                    </div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">Service Providers</h3>
                    <p className="text-gray-600">Grow your business with our platform</p>
                  </div>
                  
                  <div className="text-center">
                    <div className="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <Shield className="h-8 w-8 text-purple-600" />
                    </div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">Administrators</h3>
                    <p className="text-gray-600">Manage the platform and monitor performance</p>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </main>
        
        <Footer />
      </div>
    </>
  );
};

export default HomePage;
