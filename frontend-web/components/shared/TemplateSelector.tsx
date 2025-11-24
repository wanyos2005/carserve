import React from 'react';
import { DynamicForm } from 'lucide-react';

interface Template {
  id: string;
  name: string;
  items?: Array<{ service_id: string }>;
}

interface TemplateSelectorProps {
  templates: Template[];
  selectedTemplate: Template | null;
  onTemplateChange: (template: Template | null) => void;
  loading?: boolean;
}

export const TemplateSelector: React.FC<TemplateSelectorProps> = ({
  templates,
  selectedTemplate,
  onTemplateChange,
  loading = false,
}) => {
  return (
    <div className="bg-white rounded-xl shadow-sm p-4 sm:p-6">
      <div className="flex items-center gap-2 mb-4">
        <DynamicForm className="w-5 h-5 text-blue-700" />
        <h2 className="text-base sm:text-lg font-bold text-blue-700">
          Service Template
        </h2>
      </div>
      
      {loading ? (
        <div className="text-center py-4">
          <div className="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-blue-700"></div>
        </div>
      ) : templates.length === 0 ? (
        <div className="bg-orange-50 border border-orange-200 rounded-lg p-3">
          <div className="flex items-center gap-2">
            <span className="text-orange-700 text-xs">⚠️</span>
            <span className="text-xs text-orange-700">No templates available</span>
          </div>
        </div>
      ) : (
        <select
          value={selectedTemplate?.id || ''}
          onChange={(e) => {
            const template = templates.find(t => t.id === e.target.value) || null;
            onTemplateChange(template);
          }}
          className="
            w-full px-3 py-2 border border-gray-300 rounded-lg
            focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
            text-sm sm:text-base bg-white
          "
        >
          <option value="">Select Template</option>
          {templates.map((template) => (
            <option key={template.id} value={template.id}>
              {template.name} ({(template.items || []).length} services)
            </option>
          ))}
        </select>
      )}
    </div>
  );
};

