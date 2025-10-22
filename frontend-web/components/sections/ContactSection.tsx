import React, { useState } from 'react';
import { Phone, Mail, MapPin, Clock, Send, CheckCircle } from 'lucide-react';

const ContactSection: React.FC = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    subject: '',
    message: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    // Simulate form submission
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    setIsSubmitting(false);
    setIsSubmitted(true);
    
    // Reset form after 3 seconds
    setTimeout(() => {
      setIsSubmitted(false);
      setFormData({
        name: '',
        email: '',
        phone: '',
        subject: '',
        message: '',
      });
    }, 3000);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const contactInfo = [
    {
      icon: Phone,
      title: 'Phone',
      details: '+254 700 000 000',
      description: 'Call us during business hours',
    },
    {
      icon: Mail,
      title: 'Email',
      details: 'info@driveon.co.ke',
      description: 'We respond within 24 hours',
    },
    {
      icon: MapPin,
      title: 'Address',
      details: 'Nairobi, Kenya',
      description: 'Serving all of Kenya',
    },
    {
      icon: Clock,
      title: 'Business Hours',
      details: 'Mon - Fri: 8AM - 6PM',
      description: 'Sat: 9AM - 4PM',
    },
  ];

  const subjects = [
    'General Inquiry',
    'Technical Support',
    'Billing Question',
    'Feature Request',
    'Partnership Inquiry',
    'Other',
  ];

  return (
    <section id="contact" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Get in Touch
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Have questions about DriveOn? We're here to help. Send us a message 
            and we'll get back to you as soon as possible.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Contact Form */}
          <div className="bg-gray-50 rounded-2xl p-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-6">Send us a Message</h3>
            
            {isSubmitted ? (
              <div className="text-center py-8">
                <CheckCircle className="h-16 w-16 text-green-500 mx-auto mb-4" />
                <h4 className="text-xl font-semibold text-gray-900 mb-2">Message Sent!</h4>
                <p className="text-gray-600">Thank you for your message. We'll get back to you soon.</p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                      Full Name *
                    </label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      required
                      value={formData.name}
                      onChange={handleChange}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors"
                      placeholder="Your full name"
                    />
                  </div>
                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                      Email Address *
                    </label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      required
                      value={formData.email}
                      onChange={handleChange}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors"
                      placeholder="your@email.com"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-2">
                      Phone Number
                    </label>
                    <input
                      type="tel"
                      id="phone"
                      name="phone"
                      value={formData.phone}
                      onChange={handleChange}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors"
                      placeholder="+254 700 000 000"
                    />
                  </div>
                  <div>
                    <label htmlFor="subject" className="block text-sm font-medium text-gray-700 mb-2">
                      Subject *
                    </label>
                    <select
                      id="subject"
                      name="subject"
                      required
                      value={formData.subject}
                      onChange={handleChange}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors"
                    >
                      <option value="">Select a subject</option>
                      {subjects.map((subject) => (
                        <option key={subject} value={subject}>
                          {subject}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-2">
                    Message *
                  </label>
                  <textarea
                    id="message"
                    name="message"
                    required
                    rows={6}
                    value={formData.message}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-colors resize-none"
                    placeholder="Tell us how we can help you..."
                  />
                </div>

                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full bg-primary-600 text-white py-3 px-6 rounded-lg font-semibold hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center"
                >
                  {isSubmitting ? (
                    <>
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                      Sending...
                    </>
                  ) : (
                    <>
                      <Send className="h-5 w-5 mr-2" />
                      Send Message
                    </>
                  )}
                </button>
              </form>
            )}
          </div>

          {/* Contact Information */}
          <div className="space-y-8">
            <div>
              <h3 className="text-2xl font-bold text-gray-900 mb-6">Contact Information</h3>
              <p className="text-gray-600 mb-8">
                We're here to help you with any questions about DriveOn. 
                Reach out to us through any of the channels below.
              </p>
            </div>

            <div className="space-y-6">
              {contactInfo.map((info, index) => (
                <div key={index} className="flex items-start space-x-4">
                  <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <info.icon className="h-6 w-6 text-primary-600" />
                  </div>
                  <div>
                    <h4 className="text-lg font-semibold text-gray-900 mb-1">
                      {info.title}
                    </h4>
                    <p className="text-gray-900 font-medium mb-1">{info.details}</p>
                    <p className="text-gray-600 text-sm">{info.description}</p>
                  </div>
                </div>
              ))}
            </div>

            {/* Additional Info */}
            <div className="bg-primary-50 rounded-xl p-6">
              <h4 className="text-lg font-semibold text-gray-900 mb-3">
                Need Immediate Help?
              </h4>
              <p className="text-gray-600 mb-4">
                For urgent technical issues or account problems, call our support line 
                during business hours for immediate assistance.
              </p>
              <div className="flex items-center space-x-2">
                <Phone className="h-4 w-4 text-primary-600" />
                <span className="text-primary-600 font-medium">+254 700 000 000</span>
              </div>
            </div>

            {/* Social Media */}
            <div>
              <h4 className="text-lg font-semibold text-gray-900 mb-3">
                Follow Us
              </h4>
              <p className="text-gray-600 mb-4">
                Stay updated with the latest news and features.
              </p>
              <div className="flex space-x-4">
                <a href="#" className="text-gray-400 hover:text-primary-600 transition-colors">
                  <span className="sr-only">Facebook</span>
                  <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                    <span className="text-sm font-semibold">f</span>
                  </div>
                </a>
                <a href="#" className="text-gray-400 hover:text-primary-600 transition-colors">
                  <span className="sr-only">Twitter</span>
                  <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                    <span className="text-sm font-semibold">t</span>
                  </div>
                </a>
                <a href="#" className="text-gray-400 hover:text-primary-600 transition-colors">
                  <span className="sr-only">Instagram</span>
                  <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                    <span className="text-sm font-semibold">i</span>
                  </div>
                </a>
                <a href="#" className="text-gray-400 hover:text-primary-600 transition-colors">
                  <span className="sr-only">LinkedIn</span>
                  <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                    <span className="text-sm font-semibold">in</span>
                  </div>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default ContactSection;
