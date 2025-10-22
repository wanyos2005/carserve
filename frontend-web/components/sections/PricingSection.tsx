import React from 'react';
import { Check, Star, Shield, Wrench, Bell, Smartphone } from 'lucide-react';

const PricingSection: React.FC = () => {
  const plans = [
    {
      name: 'Free',
      price: '0',
      period: 'forever',
      description: 'Perfect for getting started with basic vehicle management',
      features: [
        'Insurance expiry reminders',
        'Basic service alerts',
        'Mobile app access',
        'Email notifications',
        '1 vehicle',
        'Community support',
      ],
      cta: 'Get Started Free',
      popular: false,
      color: 'text-gray-600',
      bgColor: 'bg-gray-50',
      borderColor: 'border-gray-200',
    },
    {
      name: 'Pro',
      price: '500',
      period: 'month',
      description: 'Advanced features for serious vehicle owners',
      features: [
        'Everything in Free',
        'SMS notifications',
        'Push notifications',
        'Advanced analytics',
        'Up to 3 vehicles',
        'Priority support',
        'Service booking',
        'Maintenance tracking',
      ],
      cta: 'Start Free Trial',
      popular: true,
      color: 'text-primary-600',
      bgColor: 'bg-primary-50',
      borderColor: 'border-primary-300',
    },
    {
      name: 'Family',
      price: '1,200',
      period: 'month',
      description: 'Complete solution for families with multiple vehicles',
      features: [
        'Everything in Pro',
        'Unlimited vehicles',
        'Family management',
        'Driver profiles',
        'Expense tracking',
        'Insurance comparison',
        '24/7 phone support',
        'Custom alerts',
      ],
      cta: 'Start Free Trial',
      popular: false,
      color: 'text-purple-600',
      bgColor: 'bg-purple-50',
      borderColor: 'border-purple-200',
    },
  ];

  const features = [
    {
      icon: Shield,
      title: 'Insurance Reminders',
      description: 'Never miss renewal deadlines',
    },
    {
      icon: Wrench,
      title: 'Service Alerts',
      description: 'Smart maintenance scheduling',
    },
    {
      icon: Bell,
      title: 'Multi-channel Notifications',
      description: 'SMS, email, push, and in-app',
    },
    {
      icon: Smartphone,
      title: 'Mobile App',
      description: 'Access anywhere, anytime',
    },
  ];

  return (
    <section id="pricing" className="py-20 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Simple, Transparent Pricing
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Choose the plan that fits your needs. All plans include our core features 
            with no hidden fees or long-term contracts.
          </p>
        </div>

        {/* Pricing Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16">
          {plans.map((plan, index) => (
            <div
              key={index}
              className={`relative rounded-2xl p-8 ${
                plan.popular
                  ? 'bg-white shadow-xl border-2 border-primary-300 transform scale-105'
                  : 'bg-white shadow-lg border border-gray-200'
              }`}
            >
              {/* Popular Badge */}
              {plan.popular && (
                <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                  <div className="bg-primary-600 text-white px-4 py-1 rounded-full text-sm font-semibold flex items-center">
                    <Star className="h-4 w-4 mr-1" />
                    Most Popular
                  </div>
                </div>
              )}

              {/* Plan Header */}
              <div className="text-center mb-8">
                <h3 className="text-2xl font-bold text-gray-900 mb-2">{plan.name}</h3>
                <p className="text-gray-600 mb-4">{plan.description}</p>
                <div className="mb-4">
                  <span className="text-4xl font-bold text-gray-900">KSh {plan.price}</span>
                  <span className="text-gray-600">/{plan.period}</span>
                </div>
              </div>

              {/* Features */}
              <div className="space-y-4 mb-8">
                {plan.features.map((feature, featureIndex) => (
                  <div key={featureIndex} className="flex items-start space-x-3">
                    <Check className="h-5 w-5 text-green-500 mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700">{feature}</span>
                  </div>
                ))}
              </div>

              {/* CTA Button */}
              <button
                className={`w-full py-3 px-6 rounded-lg font-semibold transition-colors ${
                  plan.popular
                    ? 'bg-primary-600 text-white hover:bg-primary-700'
                    : 'bg-gray-100 text-gray-900 hover:bg-gray-200'
                }`}
              >
                {plan.cta}
              </button>
            </div>
          ))}
        </div>

        {/* Feature Comparison */}
        <div className="bg-white rounded-2xl shadow-lg p-8 lg:p-12">
          <div className="text-center mb-12">
            <h3 className="text-2xl font-bold text-gray-900 mb-4">
              What's Included in Every Plan
            </h3>
            <p className="text-gray-600">
              Core features that help you manage your vehicle effectively
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <div key={index} className="text-center">
                <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <feature.icon className="h-8 w-8 text-primary-600" />
                </div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">
                  {feature.title}
                </h4>
                <p className="text-gray-600 text-sm">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* FAQ Section */}
        <div className="mt-16">
          <div className="text-center mb-12">
            <h3 className="text-2xl font-bold text-gray-900 mb-4">
              Frequently Asked Questions
            </h3>
            <p className="text-gray-600">
              Everything you need to know about our pricing and plans
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-6">
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">
                  Can I change plans anytime?
                </h4>
                <p className="text-gray-600">
                  Yes, you can upgrade or downgrade your plan at any time. Changes take effect immediately.
                </p>
              </div>
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">
                  Is there a free trial?
                </h4>
                <p className="text-gray-600">
                  Yes, all paid plans come with a 14-day free trial. No credit card required to start.
                </p>
              </div>
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">
                  What payment methods do you accept?
                </h4>
                <p className="text-gray-600">
                  We accept M-Pesa, Airtel Money, bank transfers, and major credit cards.
                </p>
              </div>
            </div>
            <div className="space-y-6">
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">
                  Can I cancel anytime?
                </h4>
                <p className="text-gray-600">
                  Yes, you can cancel your subscription at any time. No cancellation fees or penalties.
                </p>
              </div>
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">
                  Do you offer discounts?
                </h4>
                <p className="text-gray-600">
                  Yes, we offer 20% off for annual subscriptions and special discounts for students and seniors.
                </p>
              </div>
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">
                  Is my data secure?
                </h4>
                <p className="text-gray-600">
                  Absolutely. We use bank-level encryption and never share your personal information with third parties.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* CTA Section */}
        <div className="mt-16 text-center">
          <div className="bg-gradient-to-r from-primary-600 to-primary-700 rounded-2xl p-8 lg:p-12 text-white">
            <h3 className="text-2xl lg:text-3xl font-bold mb-4">
              Ready to Get Started?
            </h3>
            <p className="text-xl mb-8 opacity-90">
              Join thousands of satisfied users and never miss important vehicle deadlines again.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href="/download"
                className="inline-flex items-center justify-center px-8 py-4 bg-white text-primary-600 font-semibold rounded-lg hover:bg-gray-100 transition-colors shadow-lg"
              >
                Download App
              </a>
              <a
                href="/#contact"
                className="inline-flex items-center justify-center px-8 py-4 border-2 border-white text-white font-semibold rounded-lg hover:bg-white hover:text-primary-600 transition-colors"
              >
                Contact Sales
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default PricingSection;
