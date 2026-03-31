// lib/pages/AdminPages/broadcast_alert_management_page.dart
// Admin interface for creating and managing Drivon Alerts broadcast alerts.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:driveon_car_platform/services/drivon_alerts_service.dart';

class BroadcastAlertManagementPage extends StatefulWidget {
  const BroadcastAlertManagementPage({super.key});

  @override
  State<BroadcastAlertManagementPage> createState() =>
      _BroadcastAlertManagementPageState();
}

class _BroadcastAlertManagementPageState
    extends State<BroadcastAlertManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BroadcastAlert> _alerts = [];
  List<IncidentReport> _incidents = [];
  bool _loadingAlerts = true;
  bool _loadingIncidents = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlerts();
    _loadIncidents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loadingAlerts = true);
    final alerts = await DrivonAlertsService.adminListAlerts();
    if (mounted) setState(() { _alerts = alerts; _loadingAlerts = false; });
  }

  Future<void> _loadIncidents() async {
    setState(() => _loadingIncidents = true);
    final incidents = await DrivonAlertsService.adminListIncidents();
    if (mounted) setState(() { _incidents = incidents; _loadingIncidents = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivon Alerts Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.campaign_outlined), text: 'Broadcast Alerts'),
            Tab(icon: Icon(Icons.report_problem_outlined), text: 'Incident Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BroadcastTab(
            alerts: _alerts,
            loading: _loadingAlerts,
            onRefresh: _loadAlerts,
            onCreated: _loadAlerts,
          ),
          _IncidentsTab(
            incidents: _incidents,
            loading: _loadingIncidents,
            onRefresh: _loadIncidents,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Broadcast alerts tab
// ─────────────────────────────────────────────────────────────────────────────

class _BroadcastTab extends StatelessWidget {
  final List<BroadcastAlert> alerts;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onCreated;

  const _BroadcastTab({
    required this.alerts,
    required this.loading,
    required this.onRefresh,
    required this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign_outlined,
                          size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No broadcast alerts yet'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Alert'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _AdminAlertCard(
                      alert: alerts[i],
                      onAction: onRefresh,
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Alert'),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateAlertSheet(onCreated: onCreated),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin alert card
// ─────────────────────────────────────────────────────────────────────────────

class _AdminAlertCard extends StatelessWidget {
  final BroadcastAlert alert;
  final VoidCallback onAction;
  const _AdminAlertCard({required this.alert, required this.onAction});

  static const _statusColors = <String, Color>{
    'draft':     Color(0xFF757575),
    'active':    Color(0xFF2E7D32),
    'expired':   Color(0xFF5D4037),
    'cancelled': Color(0xFFB71C1C),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[alert.status] ?? Colors.grey;
    final messenger = ScaffoldMessenger.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(alert.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    alert.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${alert.type.toUpperCase()} · Priority ${alert.priority}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(alert.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
            if (alert.source != null) ...[
              const SizedBox(height: 4),
              Text('Source: ${alert.source}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (alert.status == 'draft') ...[
                  FilledButton.icon(
                    onPressed: () async {
                      final result =
                          await DrivonAlertsService.adminPublishAlert(alert.id);
                      if (!context.mounted) return;
                      messenger.showSnackBar(SnackBar(
                        content: Text(result['success'] == true
                            ? 'Alert published and fan-out started!'
                            : 'Error: ${result['error']}'),
                        backgroundColor: result['success'] == true
                            ? Colors.green
                            : Colors.red,
                      ));
                      onAction();
                    },
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Publish'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700),
                  ),
                  const SizedBox(width: 8),
                ],
                if (alert.status == 'active')
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result =
                          await DrivonAlertsService.adminCancelAlert(alert.id);
                      if (!context.mounted) return;
                      messenger.showSnackBar(SnackBar(
                        content: Text(result['success'] == true
                            ? 'Alert cancelled'
                            : 'Error: ${result['error']}'),
                      ));
                      onAction();
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel'),
                    style:
                        OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create alert bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CreateAlertSheet extends StatefulWidget {
  final VoidCallback onCreated;
  final String? initialTitle;
  final String? initialMessage;
  final String? initialType;

  const _CreateAlertSheet({
    required this.onCreated,
    this.initialTitle,
    this.initialMessage,
    this.initialType,
  });

  @override
  State<_CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<_CreateAlertSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;
  final _sourceCtrl = TextEditingController();
  final _actionUrlCtrl = TextEditingController();
  final _actionTextCtrl = TextEditingController();
  late String _type;
  int _priority = 2;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _messageCtrl = TextEditingController(text: widget.initialMessage ?? '');
    _type = widget.initialType ?? 'security';
  }
  bool _publishNow = false;
  bool _submitting = false;
  final List<File> _pickedImages = [];
  bool _uploadingImages = false;

  static const _alertTypes = [
    ('security',    'Security'),
    ('weather',     'Weather'),
    ('safety',      'Safety'),
    ('route_alert', 'Route'),
    ('fleet_alert', 'Fleet'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _sourceCtrl.dispose();
    _actionUrlCtrl.dispose();
    _actionTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _pickedImages.add(File(picked.path)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // Upload any picked images first
    List<String> uploadedUrls = [];
    if (_pickedImages.isNotEmpty) {
      setState(() => _uploadingImages = true);
      for (final img in _pickedImages) {
        final url = await DrivonAlertsService.uploadAlertImage(img);
        if (url != null) uploadedUrls.add(url);
      }
      setState(() => _uploadingImages = false);
    }

    final createResult = await DrivonAlertsService.adminCreateAlert(
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      type: _type,
      priority: _priority,
      source: _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim(),
      actionUrl: _actionUrlCtrl.text.trim().isEmpty
          ? null
          : _actionUrlCtrl.text.trim(),
      actionText: _actionTextCtrl.text.trim().isEmpty
          ? null
          : _actionTextCtrl.text.trim(),
      mediaUrls: uploadedUrls,
    );

    if (!mounted) return;

    if (createResult['success'] != true) {
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(
          content: Text('Create failed: ${createResult['error']}')));
      return;
    }

    if (_publishNow) {
      final alertId = createResult['data']['id'] as String;
      await DrivonAlertsService.adminPublishAlert(alertId);
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    messenger.showSnackBar(SnackBar(
      content: Text(_publishNow
          ? 'Alert created and published!'
          : 'Alert saved as draft'),
      backgroundColor: Colors.green,
    ));
    nav.pop();
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Broadcast Alert',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Type chips
              const Text('Alert type',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: _alertTypes.map((t) => ChoiceChip(
                  label: Text(t.$2),
                  selected: _type == t.$1,
                  onSelected: (_) => setState(() => _type = t.$1),
                )).toList(),
              ),
              const SizedBox(height: 14),

              // Priority
              const Text('Priority',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _priority.toDouble(),
                min: 1, max: 4, divisions: 3,
                label: ['Low', 'Medium', 'High', 'Urgent'][_priority - 1],
                onChanged: (v) => setState(() => _priority = v.round()),
              ),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Message *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sourceCtrl,
                decoration: const InputDecoration(
                  labelText: 'OSINT source (optional)',
                  hintText: 'e.g. Kenya Red Cross, KMD',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Image attachments
              Row(
                children: [
                  const Text('Images',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickedImages.length >= 4 ? null : _pickImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (_pickedImages.isNotEmpty) ...[
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_pickedImages[i],
                              width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2, right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _pickedImages.removeAt(i)),
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _actionTextCtrl,
                      decoration: const InputDecoration(
                        labelText: 'CTA button text',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _actionUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'CTA URL / deep link',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SwitchListTile(
                value: _publishNow,
                onChanged: (v) => setState(() => _publishNow = v),
                title: const Text('Publish immediately'),
                subtitle: const Text(
                    'Turn off to save as draft and publish later'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text(_uploadingImages ? 'Uploading images…' : 'Saving…'),
                          ],
                        )
                      : Text(_publishNow ? 'Create & Publish' : 'Save as Draft'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incidents tab
// ─────────────────────────────────────────────────────────────────────────────

class _IncidentsTab extends StatelessWidget {
  final List<IncidentReport> incidents;
  final bool loading;
  final VoidCallback onRefresh;

  const _IncidentsTab({
    required this.incidents,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (incidents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No incident reports yet'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: incidents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) =>
            _IncidentCard(report: incidents[i], onAction: onRefresh),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentReport report;
  final VoidCallback onAction;
  const _IncidentCard({required this.report, required this.onAction});

  static const _statusColors = <String, Color>{
    'submitted': Color(0xFF1565C0),
    'reviewing': Color(0xFFE65100),
    'resolved':  Color(0xFF2E7D32),
    'dismissed': Color(0xFF757575),
  };

  static String _incidentTypeToAlertType(String incidentType) {
    const map = {
      'security': 'security',
      'road':     'route_alert',
      'weather':  'weather',
      'vehicle':  'safety',
      'other':    'safety',
    };
    return map[incidentType] ?? 'safety';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[report.status] ?? Colors.grey;
    final messenger = ScaffoldMessenger.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(report.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${report.incidentType.toUpperCase()} · User #${report.userId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(report.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
            if (report.locationText != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(report.locationText!,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
                    const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Primary: open broadcast creation pre-filled from this incident
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => _CreateAlertSheet(
                      onCreated: onAction,
                      initialTitle: report.title,
                      initialMessage: report.description,
                      initialType: _incidentTypeToAlertType(report.incidentType),
                    ),
                  ),
                  icon: const Icon(Icons.campaign, size: 16),
                  label: const Text('Create Alert'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700),
                ),
                const SizedBox(width: 4),
                // Secondary: internal status triage
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    await DrivonAlertsService.adminUpdateIncident(
                        report.id, status: value);
                    if (!context.mounted) return;
                    final label = value == 'reviewing'
                        ? 'Marked as reviewing'
                        : value == 'resolved'
                            ? 'Resolved'
                            : 'Dismissed';
                    messenger
                        .showSnackBar(SnackBar(content: Text(label)));
                    onAction();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'reviewing', child: Text('Mark reviewing')),
                    PopupMenuItem(
                        value: 'resolved', child: Text('Mark resolved')),
                    PopupMenuItem(
                        value: 'dismissed', child: Text('Dismiss')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
