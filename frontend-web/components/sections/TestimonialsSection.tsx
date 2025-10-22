import React from 'react';
import { Star, Quote } from 'lucide-react';

const TestimonialsSection: React.FC = () => {
  const testimonials = [
    {
      name: 'Sarah Mwangi',
      role: 'Business Owner',
      location: 'Nairobi',
      image: '/testimonials/sarah.jpg',
      content: 'DriveOn has been a game-changer for me. I used to forget about my car insurance renewal, but now I get timely reminders. It saved me from driving without insurance!',
      rating: 5,
    },
    {
      name: 'John Kimani',
      role: 'Software Engineer',
      location: 'Mombasa',
      image: '/testimonials/john.jpg',
      content: 'The service alerts are incredibly accurate. It tells me exactly when my car needs service based on mileage. No more guessing or over-servicing.',
      rating: 5,
    },
    {
      name: 'Grace Wanjiku',
      role: 'Teacher',
      location: 'Kisumu',
      image: '/testimonials/grace.jpg',
      content: 'I love how easy it is to book services through the app. The provider network is excellent, and I always get quality service at fair prices.',
      rating: 5,
    },
    {
      name: 'David Ochieng',
      role: 'Sales Manager',
      location: 'Nakuru',
      image: '/testimonials/david.jpg',
      content: 'The maintenance tracking feature is fantastic. I can see all my service history and costs in one place. It helps me budget better for car expenses.',
      rating: 5,
    },
    {
      name: 'Mary Akinyi',
      role: 'Nurse',
      location: 'Eldoret',
      image: '/testimonials/mary.jpg',
      content: 'As a busy professional, I don\'t have time to remember car maintenance schedules. DriveOn does it all for me. Highly recommended!',
      rating: 5,
    },
    {
      name: 'Peter Mutua',
      role: 'Entrepreneur',
      location: 'Thika',
      image: '/testimonials/peter.jpg',
      content: 'The insurance reminders are spot on. I got notified 30 days before my policy expired, giving me plenty of time to renew. Great service!',
      rating: 5,
    },
  ];

  return (
    <section className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            What Our Users Say
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Join thousands of satisfied users who trust DriveOn to keep their vehicles 
            in top condition and never miss important deadlines.
          </p>
        </div>

        {/* Testimonials Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {testimonials.map((testimonial, index) => (
            <div
              key={index}
              className="bg-gray-50 rounded-xl p-6 hover:shadow-lg transition-shadow duration-300"
            >
              {/* Quote Icon */}
              <div className="flex justify-center mb-4">
                <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center">
                  <Quote className="h-6 w-6 text-primary-600" />
                </div>
              </div>

              {/* Rating */}
              <div className="flex justify-center mb-4">
                {[...Array(testimonial.rating)].map((_, i) => (
                  <Star key={i} className="h-5 w-5 text-yellow-400 fill-current" />
                ))}
              </div>

              {/* Content */}
              <p className="text-gray-700 text-center mb-6 leading-relaxed">
                "{testimonial.content}"
              </p>

              {/* Author */}
              <div className="text-center">
                <div className="w-12 h-12 bg-primary-200 rounded-full flex items-center justify-center mx-auto mb-3">
                  <span className="text-primary-600 font-semibold text-lg">
                    {testimonial.name.split(' ').map(n => n[0]).join('')}
                  </span>
                </div>
                <div className="font-semibold text-gray-900">{testimonial.name}</div>
                <div className="text-sm text-gray-600">{testimonial.role}</div>
                <div className="text-sm text-primary-600">{testimonial.location}</div>
              </div>
            </div>
          ))}
        </div>

        {/* Stats Section */}
        <div className="mt-16 bg-gradient-to-r from-primary-50 to-primary-100 rounded-2xl p-8 lg:p-12">
          <div className="text-center mb-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-4">
              Trusted by Thousands of Kenyan Drivers
            </h3>
            <p className="text-gray-600">
              Our users have sent thousands of alerts and saved millions in potential costs
            </p>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            <div className="text-center">
              <div className="text-3xl lg:text-4xl font-bold text-primary-600 mb-2">10,000+</div>
              <div className="text-gray-600">Active Users</div>
            </div>
            <div className="text-center">
              <div className="text-3xl lg:text-4xl font-bold text-primary-600 mb-2">50,000+</div>
              <div className="text-gray-600">Alerts Sent</div>
            </div>
            <div className="text-center">
              <div className="text-3xl lg:text-4xl font-bold text-primary-600 mb-2">95%</div>
              <div className="text-gray-600">Satisfaction Rate</div>
            </div>
            <div className="text-center">
              <div className="text-3xl lg:text-4xl font-bold text-primary-600 mb-2">500+</div>
              <div className="text-gray-600">Service Providers</div>
            </div>
          </div>
        </div>

        {/* CTA Section */}
        <div className="mt-16 text-center">
          <h3 className="text-2xl font-bold text-gray-900 mb-4">
            Ready to Join Our Community?
          </h3>
          <p className="text-gray-600 mb-8 max-w-2xl mx-auto">
            Download DriveOn today and experience the peace of mind that comes with 
            never missing important vehicle maintenance or insurance deadlines.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a
              href="/download"
              className="inline-flex items-center justify-center px-8 py-4 bg-primary-600 text-white font-semibold rounded-lg hover:bg-primary-700 transition-colors shadow-lg hover:shadow-xl"
            >
              Download App
            </a>
            <a
              href="/#contact"
              className="inline-flex items-center justify-center px-8 py-4 border-2 border-primary-600 text-primary-600 font-semibold rounded-lg hover:bg-primary-50 transition-colors"
            >
              Contact Us
            </a>
          </div>
        </div>
      </div>
    </section>
  );
};

export default TestimonialsSection;
