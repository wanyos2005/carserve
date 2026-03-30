import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import {
  Plus, Send, XCircle, RefreshCw, Bell, AlertTriangle,
  Cloud, Shield, Route, Truck, Inbox, CheckCircle, Clock,
  MapPin, User
} from 'lucide-react';
import { apiRequest } from '../../lib/auth';
import { useAuth } from '../../lib/auth';

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

interface BroadcastAlert {
  id: string;
  title: string;
  message: string;
  type: string;
  priority: number;
  status: 'draft' | 'active' | 'expired' | 'cancelled';
  source?: string;
  action_url?: string;
  action_text?: string;
  expires_at?: string;
  created_by_admin?: string;
  created_at: string;
}

interface IncidentReport {
  id: string;
  user_id: number;
  incident_type: string;
  title: string;
  description: string;
  location_text?: string;
  status: 'submitted' | 'reviewing' | 'resolved' | 'dismissed';
  admin_notes?: string;
  created_at: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const TYPE_CONFIG: Record<string, { label: string; icon: React.ReactNode; color: string }> = {
  security:    { label: 'Security',    icon: <Shield   className="h-4 w-4" />, color: 'red'    },
  weather:     { label: 'Weather',     icon: <Cloud    className="h-4 w-4" />, color: 'blue'   },
  safety:      { label: 'Safety',      icon: <Bell     className="h-4 w-4" />, color: 'orange' },
  route_alert: { label: 'Route',       icon: <Route    className="h-4 w-4" />, color: 'purple' },
  fleet_alert: { label: 'Fleet',       icon: <Truck    className="h-4 w-4" />, color: 'teal'   },
};

const PRIORITY_LABELS: Record<number, { label: string; cls: string }> = {
  1: { label: 'Low',    cls: 'bg-gray-100 text-gray-600'   },
  2: { label: 'Medium', cls: 'bg-blue-100 text-blue-700'   },
  3: { label: 'High',   cls: 'bg-orange-100 text-orange-700' },
  4: { label: 'Urgent', cls: 'bg-red-100 text-red-700'     },
};

const STATUS_CLS: Record<string, string> = {
  draft:     'bg-gray-100 text-gray-600',
  active:    'bg-green-100 text-green-700',
  expired:   'bg-yellow-100 text-yellow-700',
  cancelled: 'bg-red-100 text-red-700',
};

const INCIDENT_STATUS_CLS: Record<string, string> = {
  submitted: 'bg-blue-100 text-blue-700',
  reviewing: 'bg-orange-100 text-orange-700',
  resolved:  'bg-green-100 text-green-700',
  dismissed: 'bg-gray-100 text-gray-500',
};

// ─────────────────────────────────────────────────────────────────────────────
// Main page
// ─────────────────────────────────────────────────────────────────────────────

const BroadcastAlertsPage: React.FC = () => {
  const router = useRouter();
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'broadcasts' | 'incidents'>('broadcasts');
  const [alerts, setAlerts] = useState<BroadcastAlert[]>([]);
  const [incidents, setIncidents] = useState<IncidentReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const getDashboardUrl = () =>
    user?.providerId ? `/provider/dashboard?providerId=${user.providerId}` : '/provider/dashboard';

  const fetchAlerts = async () => {
    setLoading(true);
    try {
      const params = statusFilter !== 'all' ? `?status=${statusFilter}` : '';
      const resp = await apiRequest(`/api/broadcast-alerts${params}`);
      if (resp?.ok) setAlerts(await resp.json());
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const fetchIncidents = async () => {
    setLoading(true);
    try {
      const resp = await apiRequest('/api/incidents');
      if (resp?.ok) setIncidents(await resp.json());
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  useEffect(() => {
    if (activeTab === 'broadcasts') fetchAlerts();
    else fetchIncidents();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, statusFilter]);

  const handlePublish = async (alertId: string) => {
    try {
      const resp = await apiRequest(`/api/broadcast-alerts/${alertId}/publish`, { method: 'POST' });
      if (resp?.ok) { fetchAlerts(); }
    } catch (e) { console.error(e); }
  };

  const handleCancel = async (alertId: string) => {
    if (!confirm('Cancel this alert?')) return;
    try {
      const resp = await apiRequest(`/api/broadcast-alerts/${alertId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'cancelled' }),
      });
      if (resp?.ok) fetchAlerts();
    } catch (e) { console.error(e); }
  };

  const handleIncidentUpdate = async (reportId: string, status: string) => {
    try {
      const resp = await apiRequest(`/api/incidents/${reportId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
      if (resp?.ok) fetchIncidents();
    } catch (e) { console.error(e); }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Drivon Alerts</h1>
              <p className="text-gray-600 mt-1">
                Broadcast safety alerts and manage user incident reports
              </p>
            </div>
            <div className="flex items-center space-x-3">
              <Link href={getDashboardUrl()}>
                <button className="text-gray-600 hover:text-gray-900 px-4 py-2 rounded-lg border border-gray-300 transition-colors">
                  Back to Dashboard
                </button>
              </Link>
              {activeTab === 'broadcasts' && (
                <button
                  onClick={() => setShowCreateModal(true)}
                  className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors flex items-center"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  New Alert
                </button>
              )}
            </div>
          </div>

          {/* Tabs */}
          <div className="flex space-x-1 border-b border-gray-200 -mb-px">
            {(['broadcasts', 'incidents'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-6 py-3 text-sm font-medium border-b-2 transition-colors capitalize ${
                  activeTab === tab
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                {tab === 'broadcasts' ? 'Broadcast Alerts' : 'Incident Reports'}
                {tab === 'incidents' && (
                  <span className="ml-2 bg-orange-100 text-orange-700 text-xs px-2 py-0.5 rounded-full">
                    {incidents.filter((i) => i.status === 'submitted').length}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

        {/* ── Broadcasts ── */}
        {activeTab === 'broadcasts' && (
          <>
            {/* Filter bar */}
            <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex items-center justify-between">
              <div className="flex space-x-2">
                {['all', 'draft', 'active', 'expired', 'cancelled'].map((s) => (
                  <button
                    key={s}
                    onClick={() => setStatusFilter(s)}
                    className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors capitalize ${
                      statusFilter === s
                        ? 'bg-indigo-600 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                  >
                    {s}
                  </button>
                ))}
              </div>
              <button
                onClick={fetchAlerts}
                className="text-gray-500 hover:text-gray-700 flex items-center text-sm"
              >
                <RefreshCw className="h-4 w-4 mr-1" />
                Refresh
              </button>
            </div>

            {loading ? (
              <div className="flex justify-center py-20">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600" />
              </div>
            ) : alerts.length === 0 ? (
              <div className="bg-white rounded-xl shadow-sm p-16 text-center">
                <Bell className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No alerts found</h3>
                <p className="text-gray-500 mb-6">Create your first broadcast alert for users</p>
                <button
                  onClick={() => setShowCreateModal(true)}
                  className="bg-indigo-600 text-white px-6 py-2 rounded-lg hover:bg-indigo-700"
                >
                  Create Alert
                </button>
              </div>
            ) : (
              <div className="space-y-4">
                {alerts.map((alert) => {
                  const cfg = TYPE_CONFIG[alert.type] ?? { label: alert.type, icon: <Bell className="h-4 w-4" />, color: 'gray' };
                  const pri = PRIORITY_LABELS[alert.priority] ?? PRIORITY_LABELS[2];
                  return (
                    <div key={alert.id} className="bg-white rounded-xl shadow-sm p-6">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center space-x-3 mb-2">
                            <span className={`text-${cfg.color}-600`}>{cfg.icon}</span>
                            <h3 className="text-lg font-semibold text-gray-900">{alert.title}</h3>
                            <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${STATUS_CLS[alert.status]}`}>
                              {alert.status}
                            </span>
                            <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${pri.cls}`}>
                              {pri.label}
                            </span>
                            <span className="px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-600">
                              {cfg.label}
                            </span>
                          </div>
                          <p className="text-gray-600 mb-2">{alert.message}</p>
                          {alert.source && (
                            <p className="text-xs text-gray-400">Source: {alert.source}</p>
                          )}
                          <p className="text-xs text-gray-400 mt-1">
                            Created {new Date(alert.created_at).toLocaleString()}
                            {alert.created_by_admin && ` by admin #${alert.created_by_admin}`}
                          </p>
                        </div>
                        <div className="flex items-center space-x-2 ml-4">
                          {alert.status === 'draft' && (
                            <button
                              onClick={() => handlePublish(alert.id)}
                              className="flex items-center px-3 py-1.5 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700 transition-colors"
                            >
                              <Send className="h-3.5 w-3.5 mr-1" />
                              Publish
                            </button>
                          )}
                          {alert.status === 'active' && (
                            <button
                              onClick={() => handleCancel(alert.id)}
                              className="flex items-center px-3 py-1.5 border border-red-300 text-red-600 text-sm rounded-lg hover:bg-red-50 transition-colors"
                            >
                              <XCircle className="h-3.5 w-3.5 mr-1" />
                              Cancel
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </>
        )}

        {/* ── Incidents ── */}
        {activeTab === 'incidents' && (
          <>
            <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex justify-end">
              <button
                onClick={fetchIncidents}
                className="text-gray-500 hover:text-gray-700 flex items-center text-sm"
              >
                <RefreshCw className="h-4 w-4 mr-1" />
                Refresh
              </button>
            </div>

            {loading ? (
              <div className="flex justify-center py-20">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600" />
              </div>
            ) : incidents.length === 0 ? (
              <div className="bg-white rounded-xl shadow-sm p-16 text-center">
                <Inbox className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900">No incident reports</h3>
                <p className="text-gray-500 mt-2">User-submitted reports will appear here</p>
              </div>
            ) : (
              <div className="space-y-4">
                {incidents.map((report) => (
                  <div key={report.id} className="bg-white rounded-xl shadow-sm p-6">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center space-x-3 mb-2">
                          <AlertTriangle className="h-4 w-4 text-orange-500" />
                          <h3 className="text-lg font-semibold text-gray-900">{report.title}</h3>
                          <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${INCIDENT_STATUS_CLS[report.status]}`}>
                            {report.status}
                          </span>
                          <span className="px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-600 capitalize">
                            {report.incident_type}
                          </span>
                        </div>
                        <p className="text-gray-600 mb-2">{report.description}</p>
                        <div className="flex items-center space-x-4 text-xs text-gray-400">
                          <span className="flex items-center">
                            <User className="h-3 w-3 mr-1" />
                            User #{report.user_id}
                          </span>
                          {report.location_text && (
                            <span className="flex items-center">
                              <MapPin className="h-3 w-3 mr-1" />
                              {report.location_text}
                            </span>
                          )}
                          <span className="flex items-center">
                            <Clock className="h-3 w-3 mr-1" />
                            {new Date(report.created_at).toLocaleString()}
                          </span>
                        </div>
                      </div>
                      {report.status === 'submitted' && (
                        <div className="flex items-center space-x-2 ml-4">
                          <button
                            onClick={() => handleIncidentUpdate(report.id, 'reviewing')}
                            className="px-3 py-1.5 bg-orange-600 text-white text-sm rounded-lg hover:bg-orange-700 transition-colors"
                          >
                            Review
                          </button>
                          <button
                            onClick={() => handleIncidentUpdate(report.id, 'resolved')}
                            className="flex items-center px-3 py-1.5 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700 transition-colors"
                          >
                            <CheckCircle className="h-3.5 w-3.5 mr-1" />
                            Resolve
                          </button>
                          <button
                            onClick={() => handleIncidentUpdate(report.id, 'dismissed')}
                            className="px-3 py-1.5 border border-gray-300 text-gray-600 text-sm rounded-lg hover:bg-gray-50 transition-colors"
                          >
                            Dismiss
                          </button>
                        </div>
                      )}
                      {report.status === 'reviewing' && (
                        <button
                          onClick={() => handleIncidentUpdate(report.id, 'resolved')}
                          className="flex items-center px-3 py-1.5 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700 ml-4"
                        >
                          <CheckCircle className="h-3.5 w-3.5 mr-1" />
                          Resolve
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}
      </div>

      {showCreateModal && (
        <CreateAlertModal
          onClose={() => setShowCreateModal(false)}
          onCreated={() => { setShowCreateModal(false); fetchAlerts(); }}
        />
      )}
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────────────
// Create alert modal
// ─────────────────────────────────────────────────────────────────────────────

interface CreateAlertModalProps {
  onClose: () => void;
  onCreated: () => void;
}

const CreateAlertModal: React.FC<CreateAlertModalProps> = ({ onClose, onCreated }) => {
  const [form, setForm] = useState({
    title: '',
    message: '',
    type: 'security',
    priority: 2,
    source: '',
    action_text: '',
    action_url: '',
    publish_now: false,
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');
    try {
      const body = {
        title: form.title,
        message: form.message,
        type: form.type,
        priority: form.priority,
        channels: ['in_app', 'push'],
        source: form.source || undefined,
        action_text: form.action_text || undefined,
        action_url: form.action_url || undefined,
      };
      const createResp = await apiRequest('/api/broadcast-alerts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      if (!createResp?.ok) throw new Error('Failed to create alert');
      const created = await createResp.json();

      if (form.publish_now) {
        await apiRequest(`/api/broadcast-alerts/${created.id}/publish`, { method: 'POST' });
      }
      onCreated();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl max-w-xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
          <h2 className="text-xl font-semibold text-gray-900">New Broadcast Alert</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">✕</button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-red-700 text-sm">
              {error}
            </div>
          )}

          {/* Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Alert Type *</label>
            <div className="flex flex-wrap gap-2">
              {Object.entries(TYPE_CONFIG).map(([key, cfg]) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => setForm({ ...form, type: key })}
                  className={`flex items-center px-3 py-1.5 rounded-lg text-sm border transition-colors ${
                    form.type === key
                      ? 'bg-indigo-600 text-white border-indigo-600'
                      : 'border-gray-300 text-gray-700 hover:border-indigo-400'
                  }`}
                >
                  <span className="mr-1.5">{cfg.icon}</span>
                  {cfg.label}
                </button>
              ))}
            </div>
          </div>

          {/* Priority */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Priority: <span className="font-bold">{PRIORITY_LABELS[form.priority]?.label}</span>
            </label>
            <input
              type="range" min={1} max={4} value={form.priority}
              onChange={(e) => setForm({ ...form, priority: Number(e.target.value) })}
              className="w-full"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Title *</label>
            <input
              required value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
              placeholder="e.g. Security alert: Westlands area"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Message *</label>
            <textarea
              required rows={4} value={form.message}
              onChange={(e) => setForm({ ...form, message: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
              placeholder="Describe the situation clearly..."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">OSINT Source</label>
            <input
              value={form.source}
              onChange={(e) => setForm({ ...form, source: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
              placeholder="e.g. Kenya Red Cross, KMD, NPS"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">CTA Button Text</label>
              <input
                value={form.action_text}
                onChange={(e) => setForm({ ...form, action_text: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
                placeholder="e.g. Stay Safe"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">CTA URL / Deep Link</label>
              <input
                value={form.action_url}
                onChange={(e) => setForm({ ...form, action_url: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
                placeholder="/safety-tips"
              />
            </div>
          </div>

          <label className="flex items-center space-x-3 cursor-pointer">
            <input
              type="checkbox" checked={form.publish_now}
              onChange={(e) => setForm({ ...form, publish_now: e.target.checked })}
              className="h-4 w-4 text-indigo-600 rounded"
            />
            <div>
              <p className="text-sm font-medium text-gray-700">Publish immediately</p>
              <p className="text-xs text-gray-500">Fan-out to all users starts right away</p>
            </div>
          </label>

          <div className="flex justify-end space-x-3 pt-2 border-t border-gray-200">
            <button
              type="button" onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
            >
              Cancel
            </button>
            <button
              type="submit" disabled={submitting}
              className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 flex items-center"
            >
              {submitting
                ? <><span className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />Saving…</>
                : form.publish_now ? 'Create & Publish' : 'Save as Draft'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default BroadcastAlertsPage;
