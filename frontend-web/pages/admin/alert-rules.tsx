import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { 
  Plus, 
  Edit, 
  Trash2, 
  Play, 
  Pause, 
  Bell, 
  AlertTriangle,
  CheckCircle,
  Clock,
  Settings,
  Filter,
  Search
} from 'lucide-react';
import { useApi } from '../../hooks/useApi';

interface AlertRule {
  id: string;
  name: string;
  description: string;
  isActive: boolean;
  triggerCount: number;
  lastTriggered: string;
  conditions: string;
  actions?: string[];
  createdAt: string;
  updatedAt: string;
}

interface CreateRuleData {
  name: string;
  description: string;
  alert_type: 'insurance_expiry' | 'service_due' | 'maintenance_reminder' | 'promotional' | string;
  trigger_conditions: any;
  message_template: string;
  title_template: string;
  channels: string[];
  priority: number;
  is_active: boolean;
  schedule_expression?: string | null;
  created_by?: string;
}

const AlertRulesPage: React.FC = () => {
  const router = useRouter();
  const [rules, setRules] = useState<AlertRule[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingRule, setEditingRule] = useState<AlertRule | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterActive, setFilterActive] = useState<'all' | 'active' | 'inactive'>('all');

  const { data: rulesData, loading: rulesLoading, refetch: refetchRules } = useApi<AlertRule[]>('/api/alerts/rules/');

  useEffect(() => {
    if (rulesData) {
      setRules(rulesData);
    }
  }, [rulesData]);

  useEffect(() => {
    setIsLoading(rulesLoading);
  }, [rulesLoading]);

  const filteredRules = rules.filter(rule => {
    const matchesSearch = rule.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         rule.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesFilter = filterActive === 'all' || 
                         (filterActive === 'active' && rule.isActive) ||
                         (filterActive === 'inactive' && !rule.isActive);
    return matchesSearch && matchesFilter;
  });

  const handleCreateRule = async (ruleData: CreateRuleData) => {
    try {
      const response = await fetch('/api/alerts/rules/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(ruleData),
      });

      if (response.ok) {
        setShowCreateModal(false);
        refetchRules();
      }
    } catch (error) {
      console.error('Error creating rule:', error);
    }
  };

  const handleToggleRule = async (ruleId: string, isActive: boolean) => {
    try {
      const response = await fetch(`/api/alert-service/rules/${ruleId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ isActive }),
      });

      if (response.ok) {
        refetchRules();
      }
    } catch (error) {
      console.error('Error toggling rule:', error);
    }
  };

  const handleDeleteRule = async (ruleId: string) => {
    if (confirm('Are you sure you want to delete this rule?')) {
      try {
        const response = await fetch(`/api/alert-service/rules/${ruleId}`, {
          method: 'DELETE',
        });

        if (response.ok) {
          refetchRules();
        }
      } catch (error) {
        console.error('Error deleting rule:', error);
      }
    }
  };

  const handleTestRule = async (ruleId: string) => {
    try {
      const response = await fetch(`/api/alert-service/rules/${ruleId}/test`, {
        method: 'POST',
      });

      if (response.ok) {
        alert('Rule test triggered successfully');
      }
    } catch (error) {
      console.error('Error testing rule:', error);
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
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Alert Rules</h1>
              <p className="text-gray-600 mt-1">Manage automated alert rules and triggers</p>
            </div>
            <div className="flex items-center space-x-4">
              <Link href="/dashboard">
                <button className="text-gray-600 hover:text-gray-900 px-4 py-2 rounded-lg border border-gray-300 hover:border-gray-400 transition-colors">
                  Back to Dashboard
                </button>
              </Link>
              <button
                onClick={() => setShowCreateModal(true)}
                className="bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 transition-colors flex items-center"
              >
                <Plus className="h-4 w-4 mr-2" />
                Create Rule
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Filters and Search */}
        <div className="bg-white rounded-xl shadow-sm p-6 mb-8">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search rules..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                />
              </div>
            </div>
            <div className="flex space-x-2">
              <button
                onClick={() => setFilterActive('all')}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  filterActive === 'all'
                    ? 'bg-primary-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                All Rules
              </button>
              <button
                onClick={() => setFilterActive('active')}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  filterActive === 'active'
                    ? 'bg-primary-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                Active
              </button>
              <button
                onClick={() => setFilterActive('inactive')}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  filterActive === 'inactive'
                    ? 'bg-primary-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                Inactive
              </button>
            </div>
          </div>
        </div>

        {/* Rules List */}
        <div className="bg-white rounded-xl shadow-sm">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">
              Alert Rules ({filteredRules.length})
            </h2>
          </div>
          <div className="divide-y divide-gray-200">
            {filteredRules.length === 0 ? (
              <div className="p-12 text-center">
                <Bell className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No rules found</h3>
                <p className="text-gray-600 mb-6">
                  {searchTerm || filterActive !== 'all'
                    ? 'Try adjusting your search or filter criteria'
                    : 'Get started by creating your first alert rule'}
                </p>
                {!searchTerm && filterActive === 'all' && (
                  <button
                    onClick={() => setShowCreateModal(true)}
                    className="bg-primary-600 text-white px-6 py-3 rounded-lg hover:bg-primary-700 transition-colors"
                  >
                    Create First Rule
                  </button>
                )}
              </div>
            ) : (
              filteredRules.map((rule) => (
                <div key={rule.id} className="p-6 hover:bg-gray-50 transition-colors">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <div className={`w-3 h-3 rounded-full ${rule.isActive ? 'bg-green-500' : 'bg-gray-300'}`}></div>
                        <h3 className="text-lg font-medium text-gray-900">{rule.name}</h3>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          rule.isActive 
                            ? 'bg-green-100 text-green-800' 
                            : 'bg-gray-100 text-gray-800'
                        }`}>
                          {rule.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                      <p className="text-gray-600 mb-4">{rule.description}</p>
                      
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                        <div>
                          <p className="text-sm font-medium text-gray-900">Trigger Count</p>
                          <p className="text-2xl font-bold text-primary-600">{rule.triggerCount}</p>
                        </div>
                        <div>
                          <p className="text-sm font-medium text-gray-900">Last Triggered</p>
                          <p className="text-sm text-gray-600">{rule.lastTriggered || 'Never'}</p>
                        </div>
                        <div>
                          <p className="text-sm font-medium text-gray-900">Created</p>
                          <p className="text-sm text-gray-600">{rule.createdAt}</p>
                        </div>
                      </div>

                      <div className="flex flex-wrap gap-2">
                        {(rule.actions || []).map((action, index) => (
                          <span key={index} className="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                            {action}
                          </span>
                        ))}
                      </div>
                    </div>

                    <div className="flex items-center space-x-2 ml-4">
                      <button
                        onClick={() => handleTestRule(rule.id)}
                        className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
                        title="Test Rule"
                      >
                        <Play className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => setEditingRule(rule)}
                        className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
                        title="Edit Rule"
                      >
                        <Edit className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => handleToggleRule(rule.id, !rule.isActive)}
                        className={`p-2 transition-colors ${
                          rule.isActive 
                            ? 'text-yellow-600 hover:text-yellow-700' 
                            : 'text-green-600 hover:text-green-700'
                        }`}
                        title={rule.isActive ? 'Deactivate Rule' : 'Activate Rule'}
                      >
                        {rule.isActive ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                      </button>
                      <button
                        onClick={() => handleDeleteRule(rule.id)}
                        className="p-2 text-red-400 hover:text-red-600 transition-colors"
                        title="Delete Rule"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Create Rule Modal */}
      {showCreateModal && (
        <CreateRuleModal
          onClose={() => setShowCreateModal(false)}
          onSubmit={handleCreateRule}
        />
      )}

      {/* Edit Rule Modal */}
      {editingRule && (
        <EditRuleModal
          rule={editingRule}
          onClose={() => setEditingRule(null)}
          onSubmit={(ruleData) => {
            // Handle edit logic
            setEditingRule(null);
          }}
        />
      )}
    </div>
  );
};

// Create Rule Modal Component
const CreateRuleModal: React.FC<{
  onClose: () => void;
  onSubmit: (data: CreateRuleData) => void;
}> = ({ onClose, onSubmit }) => {
  const [formData, setFormData] = useState<CreateRuleData>({
    name: '',
    description: '',
    alert_type: 'promotional',
    trigger_conditions: {},
    message_template: '',
    title_template: '',
    channels: ['in_app'],
    priority: 2,
    is_active: true,
    schedule_expression: null,
    created_by: 'system',
  });

  const [triggerConditionsText, setTriggerConditionsText] = useState<string>('{}');
  const [channelsState, setChannelsState] = useState<Record<string, boolean>>({
    in_app: true,
    email: false,
    sms: false,
    push: false,
    whatsapp: false,
  });
  const channelKeys = Object.keys(channelsState);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    let parsedConditions: any = {};
    try {
      parsedConditions = triggerConditionsText ? JSON.parse(triggerConditionsText) : {};
    } catch (err) {
      alert('Trigger Conditions must be valid JSON');
      return;
    }
    const selectedChannels = channelKeys.filter((k) => channelsState[k]);
    onSubmit({
      name: formData.name,
      description: formData.description,
      alert_type: formData.alert_type,
      trigger_conditions: parsedConditions,
      message_template: formData.message_template,
      title_template: formData.title_template,
      channels: selectedChannels,
      priority: Number(formData.priority) || 1,
      is_active: !!formData.is_active,
      schedule_expression: formData.schedule_expression || null,
      created_by: formData.created_by || 'system',
    });
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Create Alert Rule</h2>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Rule Name *
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              placeholder="e.g., Insurance Expiry Alert"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              rows={3}
              placeholder="Describe what this rule does..."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Trigger Conditions (JSON) *</label>
            <textarea
              required
              value={triggerConditionsText}
              onChange={(e) => setTriggerConditionsText(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 font-mono"
              rows={6}
              placeholder='{"type":"price_drop","min_drop_percent":5,"check_frequency":"hourly"}'
            />
            <p className="text-xs text-gray-500 mt-1">Provide valid JSON matching your rule logic.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Alert Type *</label>
              <select
                required
                value={formData.alert_type}
                onChange={(e) => setFormData({ ...formData, alert_type: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              >
                <option value="insurance_expiry">insurance_expiry</option>
                <option value="service_due">service_due</option>
                <option value="maintenance_reminder">maintenance_reminder</option>
                <option value="promotional">promotional</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Priority *</label>
              <input
                type="number"
                min={1}
                max={5}
                value={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: Number(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Title Template *</label>
              <input
                type="text"
                required
                value={formData.title_template}
                onChange={(e) => setFormData({ ...formData, title_template: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                placeholder="e.g., 🔥 Price Drop: {make} {model}"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Message Template *</label>
              <input
                type="text"
                required
                value={formData.message_template}
                onChange={(e) => setFormData({ ...formData, message_template: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                placeholder="e.g., Price drop! {make} {model} now at {new_price}"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Channels</label>
            <div className="flex flex-wrap gap-3">
              {channelKeys.map((ch) => (
                <label key={ch} className="inline-flex items-center space-x-2">
                  <input
                    type="checkbox"
                    checked={channelsState[ch]}
                    onChange={(e) => setChannelsState({ ...channelsState, [ch]: e.target.checked })}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  />
                  <span className="text-sm text-gray-700">{ch}</span>
                </label>
              ))}
            </div>
          </div>

          <div className="flex items-center">
            <input
              type="checkbox"
              id="is_active"
              checked={formData.is_active}
              onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
              className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
            />
            <label htmlFor="is_active" className="ml-2 text-sm text-gray-700">
              Activate rule immediately
            </label>
          </div>

          <div className="flex justify-end space-x-3 pt-6 border-t border-gray-200">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
            >
              Create Rule
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// Edit Rule Modal Component
const EditRuleModal: React.FC<{
  rule: AlertRule;
  onClose: () => void;
  onSubmit: (data: CreateRuleData) => void;
}> = ({ rule, onClose, onSubmit }) => {
  // Similar to CreateRuleModal but pre-populated with rule data
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full mx-4">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Edit Alert Rule</h2>
        </div>
        <div className="p-6">
          <p className="text-gray-600">Edit functionality coming soon...</p>
          <div className="flex justify-end space-x-3 pt-6">
            <button
              onClick={onClose}
              className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AlertRulesPage;
