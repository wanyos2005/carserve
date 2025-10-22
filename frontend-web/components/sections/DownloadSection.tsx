import React from 'react';
import { ArrowRight, Smartphone, Download, Star, CheckCircle } from 'lucide-react';

const DownloadSection: React.FC = () => {
  const features = [
    'Insurance expiry reminders',
    'Service alerts and tracking',
    'Provider network access',
    'Maintenance history',
    'Multi-vehicle support',
    'Offline functionality',
  ];

  const appStats = [
    { number: '4.8', label: 'App Store Rating' },
    { number: '10K+', label: 'Downloads' },
    { number: '95%', label: 'User Satisfaction' },
  ];

  return (
    <section className="py-20 bg-gradient-to-br from-primary-600 to-primary-700 text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Left Column - Content */}
          <div className="space-y-8">
            <div className="space-y-4">
              <h2 className="text-3xl lg:text-4xl font-bold">
                Download DriveOn Today
              </h2>
              <p className="text-xl opacity-90 leading-relaxed">
                Get the full DriveOn experience on your mobile device. 
                Never miss important vehicle reminders again.
              </p>
            </div>

            {/* Features List */}
            <div className="space-y-3">
              {features.map((feature, index) => (
                <div key={index} className="flex items-center space-x-3">
                  <CheckCircle className="h-5 w-5 text-green-300 flex-shrink-0" />
                  <span className="opacity-90">{feature}</span>
                </div>
              ))}
            </div>

            {/* App Stats */}
            <div className="grid grid-cols-3 gap-6 py-6 border-t border-white/20">
              {appStats.map((stat, index) => (
                <div key={index} className="text-center">
                  <div className="text-2xl font-bold">{stat.number}</div>
                  <div className="text-sm opacity-80">{stat.label}</div>
                </div>
              ))}
            </div>

            {/* Download Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              <a
                href="#"
                className="inline-flex items-center justify-center px-6 py-4 bg-white text-primary-600 font-semibold rounded-lg hover:bg-gray-100 transition-colors shadow-lg"
              >
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-gray-900 rounded flex items-center justify-center">
                    <span className="text-white text-sm font-bold">A</span>
                  </div>
                  <div className="text-left">
                    <div className="text-xs opacity-75">Download on the</div>
                    <div className="text-sm font-semibold">App Store</div>
                  </div>
                </div>
              </a>
              <a
                href="#"
                className="inline-flex items-center justify-center px-6 py-4 bg-white text-primary-600 font-semibold rounded-lg hover:bg-gray-100 transition-colors shadow-lg"
              >
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-gray-900 rounded flex items-center justify-center">
                    <span className="text-white text-sm font-bold">G</span>
                  </div>
                  <div className="text-left">
                    <div className="text-xs opacity-75">Get it on</div>
                    <div className="text-sm font-semibold">Google Play</div>
                  </div>
                </div>
              </a>
            </div>

            {/* Additional Info */}
            <div className="flex items-center space-x-2 text-sm opacity-80">
              <Star className="h-4 w-4" />
              <span>Free to download • No hidden fees • 14-day free trial</span>
            </div>
          </div>

          {/* Right Column - Visual */}
          <div className="relative">
            {/* Mock Phone */}
            <div className="mx-auto w-80 h-[600px] bg-gray-900 rounded-[3rem] p-4 shadow-2xl">
              <div className="w-full h-full bg-white rounded-[2.5rem] overflow-hidden">
                {/* Status Bar */}
                <div className="bg-primary-600 text-white px-6 py-3 flex justify-between items-center">
                  <span className="text-sm font-medium">DriveOn</span>
                  <div className="flex items-center space-x-1">
                    <div className="w-1 h-1 bg-white rounded-full"></div>
                    <div className="w-1 h-1 bg-white rounded-full"></div>
                    <div className="w-1 h-1 bg-white rounded-full"></div>
                    <div className="w-6 h-3 bg-white rounded-sm ml-2"></div>
                  </div>
                </div>

                {/* App Content */}
                <div className="p-6 space-y-4">
                  {/* Welcome Section */}
                  <div className="text-center mb-6">
                    <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <Smartphone className="h-8 w-8 text-primary-600" />
                    </div>
                    <h3 className="text-lg font-semibold text-gray-900">Welcome to DriveOn</h3>
                    <p className="text-sm text-gray-600">Your smart car management assistant</p>
                  </div>

                  {/* Quick Actions */}
                  <div className="grid grid-cols-2 gap-3 mb-6">
                    <div className="bg-blue-50 rounded-lg p-3 text-center">
                      <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2">
                        <span className="text-blue-600 text-sm">🛡️</span>
                      </div>
                      <div className="text-xs font-medium text-blue-800">Insurance</div>
                    </div>
                    <div className="bg-green-50 rounded-lg p-3 text-center">
                      <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2">
                        <span className="text-green-600 text-sm">🔧</span>
                      </div>
                      <div className="text-xs font-medium text-green-800">Service</div>
                    </div>
                  </div>

                  {/* Recent Alerts */}
                  <div className="space-y-3">
                    <h4 className="text-sm font-semibold text-gray-900">Recent Alerts</h4>
                    <div className="space-y-2">
                      <div className="bg-yellow-50 border-l-4 border-yellow-400 p-3 rounded">
                        <div className="text-xs font-medium text-yellow-800">Insurance Expires Soon</div>
                        <div className="text-xs text-yellow-600">7 days remaining</div>
                      </div>
                      <div className="bg-blue-50 border-l-4 border-blue-400 p-3 rounded">
                        <div className="text-xs font-medium text-blue-800">Service Due</div>
                        <div className="text-xs text-blue-600">5,000 km milestone</div>
                      </div>
                    </div>
                  </div>

                  {/* Download CTA */}
                  <div className="bg-primary-50 rounded-lg p-4 text-center">
                    <Download className="h-6 w-6 text-primary-600 mx-auto mb-2" />
                    <div className="text-sm font-medium text-primary-800">Download Now</div>
                    <div className="text-xs text-primary-600">Get started in minutes</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Background Decoration */}
            <div className="absolute -top-4 -right-4 w-72 h-72 bg-white/10 rounded-full"></div>
            <div className="absolute -bottom-8 -left-8 w-96 h-96 bg-white/5 rounded-full"></div>
          </div>
        </div>

        {/* Bottom CTA */}
        <div className="mt-16 text-center">
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8">
            <h3 className="text-2xl font-bold mb-4">
              Ready to Transform Your Vehicle Management?
            </h3>
            <p className="text-xl opacity-90 mb-8 max-w-2xl mx-auto">
              Join thousands of satisfied users who trust DriveOn to keep their vehicles 
              in top condition and never miss important deadlines.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href="#"
                className="inline-flex items-center justify-center px-8 py-4 bg-white text-primary-600 font-semibold rounded-lg hover:bg-gray-100 transition-colors shadow-lg"
              >
                Download for iOS
                <ArrowRight className="ml-2 h-5 w-5" />
              </a>
              <a
                href="#"
                className="inline-flex items-center justify-center px-8 py-4 border-2 border-white text-white font-semibold rounded-lg hover:bg-white hover:text-primary-600 transition-colors"
              >
                Download for Android
                <ArrowRight className="ml-2 h-5 w-5" />
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default DownloadSection;
