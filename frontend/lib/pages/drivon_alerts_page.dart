// lib/pages/drivon_alerts_page.dart
// Drivon Alerts – safety, security, weather and route alerts for users.
// Separate concern from Drivon Connect (providers / bookings).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driveon_car_platform/services/drivon_alerts_service.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';

const _kAdminPhone = '0795510924'; // hardcoded until configurable

class DrivonAlertsPage extends StatefulWidget {
  const DrivonAlertsPage({super.key});

  @override
  State<DrivonAlertsPage> createState() => _DrivonAlertsPageState();
}

class _DrivonAlertsPageState extends State<DrivonAlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    ('All', null),
    ('Security', 'security'),
    ('Weather', 'weather'),
    ('Safety', 'safety'),
    ('Route', 'route_alert'),
  ];

  int _selectedTab = 0;
  List<BroadcastAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
        _loadAlerts();
      }
    });
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final typeFilter = _tabs[_selectedTab].$2;
    final alerts = await DrivonAlertsService.getActiveAlerts(alertType: typeFilter);
    if (mounted) setState(() { _alerts = alerts; _loading = false; });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivon Alerts'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      body: Column(
        children: [
          const _PhonePromptBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _alerts.isEmpty
                    ? _EmptyState(onRefresh: _loadAlerts)
                    : RefreshIndicator(
                        onRefresh: _loadAlerts,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _alerts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) =>
                              _BroadcastAlertCard(alert: _alerts[index]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openIncidentReport,
        icon: const Icon(Icons.report_problem_outlined),
        label: const Text('Report Incident'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _openIncidentReport() {
    final userIdStr = UserContextService.currentContext?.id;
    if (userIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to report an incident')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentReportPage(userId: int.parse(userIdStr)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert card
// ─────────────────────────────────────────────────────────────────────────────

class _BroadcastAlertCard extends StatelessWidget {
  final BroadcastAlert alert;
  const _BroadcastAlertCard({required this.alert});

  static const _typeConfig = <String, (IconData, Color)>{
    'security':    (Icons.security,          Color(0xFFD32F2F)),
    'weather':     (Icons.cloud,             Color(0xFF1565C0)),
    'safety':      (Icons.health_and_safety, Color(0xFFE65100)),
    'route_alert': (Icons.alt_route,         Color(0xFF6A1B9A)),
    'fleet_alert': (Icons.local_shipping,    Color(0xFF00695C)),
  };

  Color _priorityColor() {
    switch (alert.priority) {
      case 4: return const Color(0xFFB71C1C);
      case 3: return const Color(0xFFE65100);
      case 2: return const Color(0xFF1565C0);
      default: return const Color(0xFF757575);
    }
  }

  String _priorityLabel() {
    switch (alert.priority) {
      case 4: return 'URGENT';
      case 3: return 'HIGH';
      case 2: return 'MEDIUM';
      default: return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig[alert.type] ??
        (Icons.notifications, const Color(0xFF546E7A));
    final icon = cfg.$1;
    final color = cfg.$2;
    final priorityColor = _priorityColor();

    return Card(
      elevation: alert.priority >= 3 ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: alert.priority >= 3
            ? BorderSide(color: priorityColor, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _priorityLabel(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(alert.message, style: const TextStyle(fontSize: 14)),
            if (alert.source != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Source: ${alert.source}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (alert.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: alert.mediaUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      alert.mediaUrls[i],
                      width: 200,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 200, height: 140,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (alert.actionUrl != null && alert.actionUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(alert.actionText ?? 'Opening...')),
                    );
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: color),
                  child: Text(alert.actionText ?? 'Learn More'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone prompt banner (dismissible, shows until dismissed or phone added)
// ─────────────────────────────────────────────────────────────────────────────

class _PhonePromptBanner extends StatefulWidget {
  const _PhonePromptBanner();

  @override
  State<_PhonePromptBanner> createState() => _PhonePromptBannerState();
}

class _PhonePromptBannerState extends State<_PhonePromptBanner> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    final phone = UserContextService.currentContext?.rawData?['phone'];
    if (phone != null && phone.toString().isNotEmpty) {
      _visible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sms_outlined, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get SMS alerts when you\'re offline',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Add your phone number to receive critical safety alerts via SMS.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showPhoneDialog(context),
            child: const Text('Add'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _visible = false),
          ),
        ],
      ),
    );
  }

  void _showPhoneDialog(BuildContext context) {
    final controller = TextEditingController();
    // Capture messenger before any async gaps
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Receive critical Drivon Alerts via SMS even when you\'re offline.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '0712345678',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = controller.text.trim();
              if (phone.isEmpty) return;
              Navigator.pop(ctx);
              final result = await DrivonAlertsService.updatePhone(phone);
              if (!mounted) return;
              if (result['success'] == true) {
                setState(() => _visible = false);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Phone number saved!')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed: ${result['error']}')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text('All clear',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('No active alerts in your area.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incident report page (defined here to avoid a circular import; extracted
// to its own file once the widget grows larger)
// ─────────────────────────────────────────────────────────────────────────────

class IncidentReportPage extends StatefulWidget {
  final int userId;
  const IncidentReportPage({super.key, required this.userId});

  @override
  State<IncidentReportPage> createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _incidentType = 'security';
  bool _submitting = false;

  static const _types = [
    ('security', 'Security threat', Icons.security),
    ('road', 'Road / traffic', Icons.alt_route),
    ('weather', 'Weather hazard', Icons.cloud),
    ('vehicle', 'Vehicle incident', Icons.directions_car),
    ('other', 'Other', Icons.more_horiz),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final result = await DrivonAlertsService.submitIncident(
      userId: widget.userId,
      incidentType: _incidentType,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      locationText: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result['success'] == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Incident reported. Thank you for keeping the community safe!'),
          backgroundColor: Colors.green,
        ),
      );
      // Prompt admin notification before leaving the page
      await _showNotifyAdminSheet(
        title: _titleController.text.trim(),
        incidentType: _incidentType,
        location: _locationController.text.trim(),
      );
      if (!mounted) return;
      nav.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to submit: ${result['error']}')),
      );
    }
  }

  Future<void> _showNotifyAdminSheet({
    required String title,
    required String incidentType,
    required String location,
  }) async {
    if (!mounted) return;
    final msg = '[INCIDENT REPORT]\n'
        'Type: $incidentType\n'
        'Title: $title'
        '${location.isNotEmpty ? '\nLocation: $location' : ''}\n\n'
        'Please review on the Drivon admin panel.';
    final waPhone = _kAdminPhone.startsWith('0')
        ? '254${_kAdminPhone.substring(1)}'
        : _kAdminPhone;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notify the Drivon team directly',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Speed up the response — tap to open your messaging app with a pre-filled message.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final url = 'https://wa.me/$waPhone?text=${Uri.encodeComponent(msg)}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final url = 'sms:$_kAdminPhone?body=${Uri.encodeComponent(msg)}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.sms, size: 18),
                      label: const Text('SMS'),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.report_problem, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your report goes directly to Drivon\'s safety team. '
                        'We review every submission.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Incident type chips
              const Text('Incident type',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _types.map((t) {
                  final selected = _incidentType == t.$1;
                  return ChoiceChip(
                    label: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.$3, size: 14,
                          color: selected ? Colors.white : null),
                      const SizedBox(width: 4),
                      Text(t.$2),
                    ]),
                    selected: selected,
                    onSelected: (_) => setState(() => _incidentType = t.$1),
                    selectedColor: Colors.red.shade700,
                    labelStyle:
                        TextStyle(color: selected ? Colors.white : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Brief title *',
                  hintText: 'e.g. Armed robbery on Thika Road',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe what happened, time, number of people involved…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'e.g. Near Westgate, Westlands',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Submitting…' : 'Submit Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
