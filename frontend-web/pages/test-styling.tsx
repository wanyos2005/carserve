import React from 'react';

const TestStyling: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold text-primary-600 mb-8">Tailwind CSS Test</h1>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Card 1</h2>
            <p className="text-gray-600 mb-4">This is a test card to verify Tailwind CSS is working.</p>
            <button className="btn-primary">Primary Button</button>
          </div>
          
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Card 2</h2>
            <p className="text-gray-600 mb-4">Custom colors and components should be styled.</p>
            <button className="btn-secondary">Secondary Button</button>
          </div>
          
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Card 3</h2>
            <p className="text-gray-600 mb-4">Gradients and animations should work.</p>
            <div className="text-gradient text-2xl font-bold">Gradient Text</div>
          </div>
        </div>
        
        <div className="mt-8 bg-white rounded-xl shadow-lg p-6">
          <h2 className="text-2xl font-semibold text-gray-900 mb-4">Form Test</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Test Input</label>
              <input 
                type="text" 
                className="input-field" 
                placeholder="Type something here..."
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Test Textarea</label>
              <textarea 
                className="input-field" 
                rows={3}
                placeholder="Multi-line text here..."
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TestStyling;
