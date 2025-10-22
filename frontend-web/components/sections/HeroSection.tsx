import React from 'react';
import Link from 'next/link';
import { ArrowRight, Shield, Wrench, Bell, Smartphone } from 'lucide-react';

const HeroSection: React.FC = () => {
  return (
    <section className="relative bg-gradient-to-br from-primary-50 to-primary-100 py-20 lg:py-32">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Left Column - Content */}
          <div className="space-y-8">
            <div className="space-y-4">
              <h1 className="text-4xl lg:text-6xl font-bold text-gray-900 leading-tight">
                Never Miss Your
                <span className="text-primary-600"> Car Service</span>
                <br />
                Again
              </h1>
              <p className="text-xl text-gray-600 leading-relaxed">
                DriveOn is your smart car management platform that sends you timely reminders 
                for insurance renewal, service appointments, and maintenance schedules.
              </p>
            </div>

            {/* Key Benefits */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
                  <Shield className="h-4 w-4 text-primary-600" />
                </div>
                <span className="text-gray-700 font-medium">Insurance Reminders</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
                  <Wrench className="h-4 w-4 text-primary-600" />
                </div>
                <span className="text-gray-700 font-medium">Service Alerts</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
                  <Bell className="h-4 w-4 text-primary-600" />
                </div>
                <span className="text-gray-700 font-medium">Smart Notifications</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
                  <Smartphone className="h-4 w-4 text-primary-600" />
                </div>
                <span className="text-gray-700 font-medium">Mobile App</span>
              </div>
            </div>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              <Link
                href="/download"
                className="inline-flex items-center justify-center px-8 py-4 bg-primary-600 text-white font-semibold rounded-lg hover:bg-primary-700 transition-colors shadow-lg hover:shadow-xl"
              >
                Download App
                <ArrowRight className="ml-2 h-5 w-5" />
              </Link>
              <Link
                href="/#how-it-works"
                className="inline-flex items-center justify-center px-8 py-4 border-2 border-primary-600 text-primary-600 font-semibold rounded-lg hover:bg-primary-50 transition-colors"
              >
                Learn More
              </Link>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-8 pt-8 border-t border-gray-200">
              <div className="text-center">
                <div className="text-3xl font-bold text-primary-600">10K+</div>
                <div className="text-sm text-gray-600">Active Users</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-primary-600">50K+</div>
                <div className="text-sm text-gray-600">Alerts Sent</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-primary-600">95%</div>
                <div className="text-sm text-gray-600">Satisfaction</div>
              </div>
            </div>
          </div>

          {/* Right Column - Visual */}
          <div className="relative">
            <div className="relative z-10">
              {/* Mock phone with app interface */}
              <div className="mx-auto w-80 h-[600px] bg-gray-900 rounded-[3rem] p-4 shadow-2xl">
                <div className="w-full h-full bg-white rounded-[2.5rem] overflow-hidden">
                  {/* Status bar */}
                  <div className="bg-primary-600 text-white px-6 py-3 flex justify-between items-center">
                    <span className="text-sm font-medium">DriveOn</span>
                    <div className="flex space-x-1">
                      <div className="w-1 h-1 bg-white rounded-full"></div>
                      <div className="w-1 h-1 bg-white rounded-full"></div>
                      <div className="w-1 h-1 bg-white rounded-full"></div>
                    </div>
                  </div>
                  
                  {/* App content */}
                  <div className="p-6 space-y-4">
                    <div className="text-center">
                      <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Bell className="h-8 w-8 text-primary-600" />
                      </div>
                      <h3 className="text-lg font-semibold text-gray-900">Smart Alerts</h3>
                      <p className="text-sm text-gray-600">Never miss important reminders</p>
                    </div>
                    
                    {/* Sample alerts */}
                    <div className="space-y-3">
                      <div className="bg-yellow-50 border-l-4 border-yellow-400 p-3 rounded">
                        <div className="text-sm font-medium text-yellow-800">Insurance Expires Soon</div>
                        <div className="text-xs text-yellow-600">7 days remaining</div>
                      </div>
                      <div className="bg-blue-50 border-l-4 border-blue-400 p-3 rounded">
                        <div className="text-sm font-medium text-blue-800">Service Due</div>
                        <div className="text-xs text-blue-600">5,000 km milestone</div>
                      </div>
                      <div className="bg-green-50 border-l-4 border-green-400 p-3 rounded">
                        <div className="text-sm font-medium text-green-800">Maintenance Complete</div>
                        <div className="text-xs text-green-600">Oil change done</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            {/* Background decoration */}
            <div className="absolute -top-4 -right-4 w-72 h-72 bg-primary-200 rounded-full opacity-20"></div>
            <div className="absolute -bottom-8 -left-8 w-96 h-96 bg-primary-300 rounded-full opacity-10"></div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;
