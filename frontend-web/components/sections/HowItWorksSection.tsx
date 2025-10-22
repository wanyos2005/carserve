import React from 'react';
import { User, Car, Bell, CheckCircle } from 'lucide-react';

const HowItWorksSection: React.FC = () => {
  const steps = [
    {
      number: '01',
      title: 'Sign Up & Add Your Vehicle',
      description: 'Create your account and add your vehicle details including make, model, year, and current mileage.',
      icon: User,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      number: '02',
      title: 'Set Up Insurance & Service Info',
      description: 'Add your insurance details and service history. We\'ll calculate when your next service is due.',
      icon: Car,
      color: 'text-green-600',
      bgColor: 'bg-green-100',
    },
    {
      number: '03',
      title: 'Receive Smart Alerts',
      description: 'Get timely reminders for insurance renewal, service appointments, and maintenance schedules.',
      icon: Bell,
      color: 'text-purple-600',
      bgColor: 'bg-purple-100',
    },
    {
      number: '04',
      title: 'Book Services & Stay Protected',
      description: 'Book services with trusted providers and keep your vehicle in top condition year-round.',
      icon: CheckCircle,
      color: 'text-orange-600',
      bgColor: 'bg-orange-100',
    },
  ];

  return (
    <section id="how-it-works" className="py-20 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            How DriveOn Works
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Getting started with DriveOn is simple. Follow these four easy steps 
            to begin managing your vehicle like never before.
          </p>
        </div>

        {/* Steps */}
        <div className="relative">
          {/* Connection Line */}
          <div className="hidden lg:block absolute top-24 left-0 right-0 h-0.5 bg-gradient-to-r from-primary-200 via-primary-300 to-primary-200"></div>
          
          <div className="grid grid-cols-1 lg:grid-cols-4 gap-8 lg:gap-4">
            {steps.map((step, index) => (
              <div key={index} className="relative">
                {/* Step Number */}
                <div className="flex items-center justify-center mb-6">
                  <div className={`w-16 h-16 ${step.bgColor} rounded-full flex items-center justify-center relative z-10`}>
                    <step.icon className={`h-8 w-8 ${step.color}`} />
                  </div>
                  <div className="absolute -top-2 -right-2 w-8 h-8 bg-primary-600 text-white rounded-full flex items-center justify-center text-sm font-bold">
                    {step.number}
                  </div>
                </div>

                {/* Step Content */}
                <div className="text-center">
                  <h3 className="text-xl font-semibold text-gray-900 mb-3">
                    {step.title}
                  </h3>
                  <p className="text-gray-600 leading-relaxed">
                    {step.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Process Flow Visualization */}
        <div className="mt-16 bg-white rounded-2xl shadow-lg p-8 lg:p-12">
          <div className="text-center mb-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-4">
              Your Vehicle Management Journey
            </h3>
            <p className="text-gray-600">
              From setup to ongoing maintenance, DriveOn guides you every step of the way
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Setup Phase */}
            <div className="text-center">
              <div className="w-20 h-20 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <User className="h-10 w-10 text-blue-600" />
              </div>
              <h4 className="text-lg font-semibold text-gray-900 mb-2">Setup Phase</h4>
              <p className="text-gray-600 text-sm">
                Add your vehicle and insurance details. Takes just 5 minutes.
              </p>
            </div>

            {/* Monitoring Phase */}
            <div className="text-center">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Bell className="h-10 w-10 text-green-600" />
              </div>
              <h4 className="text-lg font-semibold text-gray-900 mb-2">Smart Monitoring</h4>
              <p className="text-gray-600 text-sm">
                Our system continuously monitors your vehicle's needs and sends timely alerts.
              </p>
            </div>

            {/* Action Phase */}
            <div className="text-center">
              <div className="w-20 h-20 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckCircle className="h-10 w-10 text-purple-600" />
              </div>
              <h4 className="text-lg font-semibold text-gray-900 mb-2">Take Action</h4>
              <p className="text-gray-600 text-sm">
                Book services, renew insurance, and keep your vehicle in perfect condition.
              </p>
            </div>
          </div>
        </div>

        {/* Benefits Summary */}
        <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="text-center p-6 bg-white rounded-xl shadow-sm">
            <div className="text-3xl font-bold text-primary-600 mb-2">5 min</div>
            <div className="text-gray-600">Setup Time</div>
          </div>
          <div className="text-center p-6 bg-white rounded-xl shadow-sm">
            <div className="text-3xl font-bold text-primary-600 mb-2">24/7</div>
            <div className="text-gray-600">Monitoring</div>
          </div>
          <div className="text-center p-6 bg-white rounded-xl shadow-sm">
            <div className="text-3xl font-bold text-primary-600 mb-2">100%</div>
            <div className="text-gray-600">Free to Start</div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HowItWorksSection;
