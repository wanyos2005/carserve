import React from 'react';
import { Shield, Wrench, Bell, Smartphone, MapPin, Clock, Users, BarChart3 } from 'lucide-react';

const FeaturesSection: React.FC = () => {
  const features = [
    {
      icon: Shield,
      title: 'Insurance Reminders',
      description: 'Never miss insurance renewal deadlines with smart alerts sent 30, 7, and 1 day before expiry.',
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      icon: Wrench,
      title: 'Service Alerts',
      description: 'Get notified when your vehicle needs service based on mileage or time intervals.',
      color: 'text-green-600',
      bgColor: 'bg-green-100',
    },
    {
      icon: Bell,
      title: 'Smart Notifications',
      description: 'Receive alerts via SMS, email, push notifications, or in-app messages.',
      color: 'text-purple-600',
      bgColor: 'bg-purple-100',
    },
    {
      icon: Smartphone,
      title: 'Mobile App',
      description: 'Access all features on your mobile device with our intuitive Flutter app.',
      color: 'text-orange-600',
      bgColor: 'bg-orange-100',
    },
    {
      icon: MapPin,
      title: 'Provider Network',
      description: 'Find and book services with trusted service providers in your area.',
      color: 'text-red-600',
      bgColor: 'bg-red-100',
    },
    {
      icon: Clock,
      title: 'Maintenance Tracking',
      description: 'Keep track of all your vehicle maintenance history and upcoming services.',
      color: 'text-indigo-600',
      bgColor: 'bg-indigo-100',
    },
    {
      icon: Users,
      title: 'Family Management',
      description: 'Manage multiple vehicles and family members from one account.',
      color: 'text-pink-600',
      bgColor: 'bg-pink-100',
    },
    {
      icon: BarChart3,
      title: 'Analytics Dashboard',
      description: 'View insights about your vehicle usage, maintenance costs, and service history.',
      color: 'text-teal-600',
      bgColor: 'bg-teal-100',
    },
  ];

  return (
    <section id="features" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Everything You Need to Manage Your Vehicle
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            DriveOn provides comprehensive tools to keep your vehicle in top condition 
            and never miss important maintenance or insurance deadlines.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <div
              key={index}
              className="group p-6 rounded-xl border border-gray-200 hover:border-primary-300 hover:shadow-lg transition-all duration-300 bg-white"
            >
              <div className={`w-12 h-12 ${feature.bgColor} rounded-lg flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-300`}>
                <feature.icon className={`h-6 w-6 ${feature.color}`} />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-2">
                {feature.title}
              </h3>
              <p className="text-gray-600 text-sm leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>

        {/* Additional Info */}
        <div className="mt-16 bg-gradient-to-r from-primary-50 to-primary-100 rounded-2xl p-8 lg:p-12">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
            <div>
              <h3 className="text-2xl lg:text-3xl font-bold text-gray-900 mb-4">
                Why Choose DriveOn?
              </h3>
              <p className="text-lg text-gray-600 mb-6">
                Our platform is designed specifically for Kenyan drivers, with local service providers, 
                insurance partners, and maintenance schedules tailored to your needs.
              </p>
              <div className="space-y-4">
                <div className="flex items-center space-x-3">
                  <div className="w-6 h-6 bg-primary-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">✓</span>
                  </div>
                  <span className="text-gray-700">Local service provider network</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-6 h-6 bg-primary-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">✓</span>
                  </div>
                  <span className="text-gray-700">Kenyan insurance partner integration</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-6 h-6 bg-primary-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">✓</span>
                  </div>
                  <span className="text-gray-700">Multi-language support (English & Swahili)</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-6 h-6 bg-primary-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">✓</span>
                  </div>
                  <span className="text-gray-700">24/7 customer support</span>
                </div>
              </div>
            </div>
            <div className="relative">
              <div className="bg-white rounded-xl shadow-lg p-6">
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Shield className="h-8 w-8 text-primary-600" />
                  </div>
                  <h4 className="text-lg font-semibold text-gray-900">Smart Protection</h4>
                  <p className="text-gray-600 text-sm">Never miss important deadlines</p>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between items-center py-2 border-b border-gray-100">
                    <span className="text-sm text-gray-600">Insurance Coverage</span>
                    <span className="text-sm font-medium text-green-600">Active</span>
                  </div>
                  <div className="flex justify-between items-center py-2 border-b border-gray-100">
                    <span className="text-sm text-gray-600">Next Service</span>
                    <span className="text-sm font-medium text-blue-600">5,000 km</span>
                  </div>
                  <div className="flex justify-between items-center py-2">
                    <span className="text-sm text-gray-600">Last Maintenance</span>
                    <span className="text-sm font-medium text-gray-900">2 weeks ago</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default FeaturesSection;
