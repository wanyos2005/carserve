import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { 
  ArrowLeft, 
  Plus, 
  Trash2, 
  Edit, 
  Save,
  X,
  Check
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';

interface ServiceTemplate {
  id: string;
  name: string;
  items: Array<{
    service_id: string;
    service_name?: string;
  }>;
  created_at: string;
}

interface AttachedService {
  service_id: string;
  display_name?: string;
  service: {
    name: string;
    description?: string;
  };
}

const ManageTemplatesPage: React.FC = () => {
  const router = useRouter();
  const { providerId } = router.query;
  const [templates, setTemplates] = useState<ServiceTemplate[]>([]);
  const [attachedServices, setAttachedServices] = useState<AttachedService[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newTemplateName, setNewTemplateName] = useState('');
  const [selectedServiceIds, setSelectedServiceIds] = useState<Set<string>>(new Set());

  const { data: templatesData, loading: templatesLoading, refetch: refetchTemplates } = useApi<ServiceTemplate[]>(`/api/service-provider-service/providers/${providerId}/templates`);
  const { data: servicesData, loading: servicesLoading } = useApi<AttachedService[]>(`/api/service-provider-service/providers/${providerId}/services`);

  useEffect(() => {
    if (templatesData && Array.isArray(templatesData)) {
      setTemplates(templatesData);
    }
  }, [templatesData]);

  useEffect(() => {
    if (servicesData && Array.isArray(servicesData)) {
      setAttachedServices(servicesData);
    }
  }, [servicesData]);

  useEffect(() => {
    setIsLoading(templatesLoading || servicesLoading);
  }, [templatesLoading, servicesLoading]);

  const handleServiceToggle = (serviceId: string) => {
    const newSelection = new Set(selectedServiceIds);
    if (newSelection.has(serviceId)) {
      newSelection.delete(serviceId);
    } else {
      newSelection.add(serviceId);
    }
    setSelectedServiceIds(newSelection);
  };

  const handleCreateTemplate = async () => {
    if (!newTemplateName.trim() || selectedServiceIds.size === 0) {
      alert('Name and at least one service required');
      return;
    }

    try {
      const payload = {
        provider_id: providerId,
        name: newTemplateName.trim(),
        items: Array.from(selectedServiceIds).map(id => ({ service_id: id })),
      };

      const response = await fetch(`/api/service-provider-service/providers/${providerId}/templates`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        setNewTemplateName('');
        setSelectedServiceIds(new Set());
        setShowCreateForm(false);
        refetchTemplates();
        alert('Template created successfully');
      } else {
        alert('Failed to create template');
      }
    } catch (error) {
      console.error('Error creating template:', error);
      alert('Error creating template');
    }
  };

  const handleDeleteTemplate = async (templateId: string) => {
    if (confirm('Are you sure you want to delete this template?')) {
      try {
        const response = await fetch(`/api/service-provider-service/templates/${templateId}`, {
          method: 'DELETE',
        });

        if (response.ok) {
          refetchTemplates();
          alert('Template deleted successfully');
        } else {
          alert('Failed to delete template');
        }
      } catch (error) {
        console.error('Error deleting template:', error);
        alert('Error deleting template');
      }
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center space-x-4">
              <Link href="/provider/dashboard">
                <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
                  <ArrowLeft className="h-5 w-5" />
                </button>
              </Link>
              <div>
                <h1 className="text-3xl font-bold text-gray-900">Manage Templates</h1>
                <p className="text-gray-600 mt-1">Create and manage service templates</p>
              </div>
            </div>
            <button
              onClick={() => setShowCreateForm(true)}
              className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 transition-colors flex items-center"
            >
              <Plus className="h-4 w-4 mr-2" />
              Create Template
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Existing Templates */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Existing Templates</h2>
          {templates.length === 0 ? (
            <div className="bg-white rounded-xl shadow-sm p-8 text-center">
              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Plus className="h-8 w-8 text-gray-400" />
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No templates yet</h3>
              <p className="text-gray-600 mb-4">Create your first service template to get started</p>
              <button
                onClick={() => setShowCreateForm(true)}
                className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 transition-colors"
              >
                Create First Template
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {templates.map((template) => (
                <div key={template.id} className="bg-white rounded-xl shadow-sm p-6">
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900">{template.name}</h3>
                      <p className="text-sm text-gray-600">
                        Includes {template.items.length} service{template.items.length !== 1 ? 's' : ''}
                      </p>
                    </div>
                    <button
                      onClick={() => handleDeleteTemplate(template.id)}
                      className="p-2 text-red-400 hover:text-red-600 transition-colors"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                  
                  <div className="space-y-2">
                    {template.items.map((item, index) => {
                      const service = attachedServices.find(s => s.service_id === item.service_id);
                      return (
                        <div key={index} className="flex items-center space-x-2 text-sm text-gray-600">
                          <Check className="h-4 w-4 text-green-500" />
                          <span>{service?.display_name || service?.service.name || 'Unknown Service'}</span>
                        </div>
                      );
                    })}
                  </div>
                  
                  <div className="mt-4 pt-4 border-t border-gray-200">
                    <p className="text-xs text-gray-500">
                      Created {new Date(template.created_at).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Create New Template Form */}
        {showCreateForm && (
          <div className="bg-white rounded-xl shadow-sm p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-semibold text-gray-900">Create New Template</h2>
              <button
                onClick={() => setShowCreateForm(false)}
                className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Template Name *
                </label>
                <input
                  type="text"
                  value={newTemplateName}
                  onChange={(e) => setNewTemplateName(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                  placeholder="e.g., Basic Service Package"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Select Services *
                </label>
                <div className="space-y-3 max-h-64 overflow-y-auto">
                  {attachedServices.map((service) => (
                    <label key={service.service_id} className="flex items-center space-x-3 p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={selectedServiceIds.has(service.service_id)}
                        onChange={() => handleServiceToggle(service.service_id)}
                        className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      <div className="flex-1">
                        <div className="font-medium text-gray-900">
                          {service.display_name || service.service.name}
                        </div>
                        {service.display_name && (
                          <div className="text-sm text-gray-500">
                            Global: {service.service.name}
                          </div>
                        )}
                        {service.service.description && (
                          <div className="text-sm text-gray-600 mt-1">
                            {service.service.description}
                          </div>
                        )}
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => setShowCreateForm(false)}
                  className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCreateTemplate}
                  disabled={!newTemplateName.trim() || selectedServiceIds.size === 0}
                  className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center"
                >
                  <Save className="h-4 w-4 mr-2" />
                  Save Template
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ManageTemplatesPage;
