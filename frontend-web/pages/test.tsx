import React from 'react';
import Link from 'next/link';
import { ArrowLeft, CheckCircle, AlertTriangle, Star, Users, Building, Settings } from 'lucide-react';
import { useAuth } from '../lib/auth';

const TestPage: React.FC = () => {
  const { user } = useAuth();
  
  // Helper to get dashboard URL with providerId
  const getDashboardUrl = () => {
    if (user?.providerId) {
      return `/provider/dashboard?providerId=${user.providerId}`;
    }
    return '/provider/dashboard'; // Fallback if no providerId
  };
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-8">
        <div className="mb-6">
          <Link href="/" className="inline-flex items-center text-gray-600 hover:text-gray-900">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Home
          </Link>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-6">Styling Test Page</h1>
          
          {/* Test Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
            <div className="bg-blue-50 rounded-lg p-6">
              <div className="flex items-center space-x-3 mb-4">
                <CheckCircle className="h-8 w-8 text-blue-600" />
                <h3 className="text-lg font-semibold text-blue-900">Success</h3>
              </div>
              <p className="text-blue-800">This card shows success styling with blue colors.</p>
            </div>
            
            <div className="bg-green-50 rounded-lg p-6">
              <div className="flex items-center space-x-3 mb-4">
                <Star className="h-8 w-8 text-green-600" />
                <h3 className="text-lg font-semibold text-green-900">Rating</h3>
              </div>
              <p className="text-green-800">This card shows rating styling with green colors.</p>
            </div>
            
            <div className="bg-yellow-50 rounded-lg p-6">
              <div className="flex items-center space-x-3 mb-4">
                <AlertTriangle className="h-8 w-8 text-yellow-600" />
                <h3 className="text-lg font-semibold text-yellow-900">Warning</h3>
              </div>
              <p className="text-yellow-800">This card shows warning styling with yellow colors.</p>
            </div>
          </div>

          {/* Test Buttons */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Button Styles</h2>
            <div className="flex flex-wrap gap-4">
              <button className="btn-primary">Primary Button</button>
              <button className="btn-secondary">Secondary Button</button>
              <button className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors">
                Success Button
              </button>
              <button className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors">
                Danger Button
              </button>
            </div>
          </div>

          {/* Test Forms */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Form Elements</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Test Input</label>
                <input 
                  type="text" 
                  className="input-field" 
                  placeholder="Type something here..."
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Test Select</label>
                <select className="input-field">
                  <option>Option 1</option>
                  <option>Option 2</option>
                  <option>Option 3</option>
                </select>
              </div>
            </div>
          </div>

          {/* Test Navigation */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Navigation Links</h2>
            <div className="flex flex-wrap gap-4">
              <Link href="/demo-login" className="text-primary-600 hover:text-primary-700 font-medium">
                Demo Login
              </Link>
              <Link href="/login" className="text-primary-600 hover:text-primary-700 font-medium">
                Real Login
              </Link>
              <Link href={getDashboardUrl()} className="text-primary-600 hover:text-primary-700 font-medium">
                Dashboard
              </Link>
            </div>
          </div>

          {/* Test Icons */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Icons</h2>
            <div className="flex flex-wrap gap-4">
              <div className="flex items-center space-x-2">
                <Users className="h-5 w-5 text-blue-600" />
                <span>Users</span>
              </div>
              <div className="flex items-center space-x-2">
                <Building className="h-5 w-5 text-green-600" />
                <span>Building</span>
              </div>
              <div className="flex items-center space-x-2">
                <Settings className="h-5 w-5 text-gray-600" />
                <span>Settings</span>
              </div>
            </div>
          </div>

          {/* Test Gradients */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Gradients</h2>
            <div className="text-gradient text-3xl font-bold mb-4">
              Gradient Text Example
            </div>
            <div className="bg-gradient-to-r from-primary-500 to-primary-700 text-white p-6 rounded-lg">
              <h3 className="text-xl font-semibold mb-2">Gradient Background</h3>
              <p>This is a gradient background card.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TestPage;
