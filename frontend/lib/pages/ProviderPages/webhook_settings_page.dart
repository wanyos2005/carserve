import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:driveon_car_platform/services/provider_service.dart';

class WebhookSettingsPage extends StatefulWidget {
  final String providerId;

  const WebhookSettingsPage({super.key, required this.providerId});

  @override
  State<WebhookSettingsPage> createState() => _WebhookSettingsPageState();
}

class _WebhookSettingsPageState extends State<WebhookSettingsPage> {
  List<dynamic> _webhooks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWebhooks();
  }

  Future<void> _loadWebhooks() async {
    setState(() => _loading = true);
    final data = await ProviderService.getProviderWebhookUrls(widget.providerId);
    setState(() {
      _webhooks = data;
      _loading = false;
    });
  }

  Future<void> _toggleActive(Map<String, dynamic> webhook) async {
    final updated = await ProviderService.updateProviderWebhookUrl(
      webhook['id'],
      {'is_active': !(webhook['is_active'] as bool)},
    );
    if (updated != null) _loadWebhooks();
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Webhook'),
        content: const Text(
            'This will stop all future deliveries to this URL. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ProviderService.deleteProviderWebhookUrl(id);
      _loadWebhooks();
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddWebhookSheet(
        providerId: widget.providerId,
        onSaved: _loadWebhooks,
      ),        
    );
  }

  void _showLogs(Map<String, dynamic> webhook) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _WebhookLogsPage(
          subscriptionId: webhook['id'],
          label: webhook['label'] ?? webhook['callback_url'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Webhooks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Add Webhook'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal[50]!, Colors.blue[50]!],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _webhooks.isEmpty
                ? _buildEmpty()
                : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.webhook, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'No webhooks configured',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Add a callback URL to receive M-Pesa payment\nnotifications in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _showAddSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add your first webhook'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildInfoBanner(),
        const SizedBox(height: 16),
        ...(_webhooks.map((w) => _WebhookCard(
              webhook: Map<String, dynamic>.from(w),
              onToggle: () => _toggleActive(Map<String, dynamic>.from(w)),
              onDelete: () => _delete(w['id']),
              onViewLogs: () => _showLogs(Map<String, dynamic>.from(w)),
            ))),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.teal[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Every M-Pesa payment you receive is POSTed to your registered URLs, '
              'signed with your secret (X-DriveOn-Signature header).',
              style: TextStyle(fontSize: 13, color: Colors.teal[800]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Webhook Card ─────────────────────────────────────────────────────────────

class _WebhookCard extends StatefulWidget {
  final Map<String, dynamic> webhook;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onViewLogs;

  const _WebhookCard({
    required this.webhook,
    required this.onToggle,
    required this.onDelete,
    required this.onViewLogs,
  });

  @override
  State<_WebhookCard> createState() => _WebhookCardState();
}

class _WebhookCardState extends State<_WebhookCard> {
  bool _secretVisible = false;

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$label copied'),
          duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.webhook;
    final isActive = w['is_active'] as bool? ?? true;
    final label = w['label'] as String? ?? '';
    final url = w['callback_url'] as String? ?? '';
    final secret = w['secret'] as String? ?? '';
    final createdAt = w['created_at'] as String? ?? '';
    final color = isActive ? Colors.teal : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.webhook, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label.isNotEmpty)
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      GestureDetector(
                        onTap: () => _copy(context, url, 'URL'),
                        child: Text(
                          url,
                          style: TextStyle(
                            fontSize: label.isEmpty ? 14 : 12,
                            color: label.isEmpty
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: label.isEmpty
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (_) => widget.onToggle(),
                  activeColor: Colors.teal,
                ),
              ],
            ),

            const Divider(height: 22),

            // Secret row
            Row(
              children: [
                Icon(Icons.vpn_key_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text('Secret: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                Expanded(
                  child: Text(
                    _secretVisible ? secret : '••••••••••••••••',
                    style: const TextStyle(
                        fontSize: 13, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _secretVisible = !_secretVisible),
                  child: Icon(
                    _secretVisible ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copy(context, secret, 'Secret'),
                  child:
                      Icon(Icons.copy, size: 18, color: Colors.grey[500]),
                ),
              ],
            ),

            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Added ${_formatDate(createdAt)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: widget.onViewLogs,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Logs'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.blue[700]),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Add Webhook Bottom Sheet ─────────────────────────────────────────────────

class _AddWebhookSheet extends StatefulWidget {
  final String providerId;
  final VoidCallback onSaved;

  const _AddWebhookSheet(
      {required this.providerId, required this.onSaved});

  @override
  State<_AddWebhookSheet> createState() => _AddWebhookSheetState();
}

class _AddWebhookSheetState extends State<_AddWebhookSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _labelController = TextEditingController();
  final _secretController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final result = await ProviderService.createProviderWebhookUrl({
      'provider_id': widget.providerId,
      'callback_url': _urlController.text.trim(),
      'label': _labelController.text.trim(),
      'secret': _secretController.text.trim(),
    });

    setState(() => _saving = false);

    if (result != null && mounted) {
      Navigator.pop(context);
      widget.onSaved();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to save. Check the URL and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                const Text('New Webhook',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            Text(
              'We will POST every M-Pesa payment to this URL.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _labelController,
              decoration: _input(
                label: 'Label (optional)',
                hint: 'e.g. FuelPro ERP, My POS System',
                icon: Icons.label_outline,
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: _input(
                label: 'Callback URL',
                hint: 'https://yourapp.com/mpesa-webhook',
                icon: Icons.link,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'URL is required';
                if (!v.trim().startsWith('http'))
                  return 'Must start with http:// or https://';
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _secretController,
              decoration: _input(
                label: 'Signing Secret',
                hint: 'Min 8 characters',
                icon: Icons.vpn_key_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Secret is required';
                if (v.trim().length < 8)
                  return 'Must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Your server uses this to verify the X-DriveOn-Signature header '
              'on every incoming webhook request.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Webhook',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  InputDecoration _input(
      {required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ─── Delivery Logs Page ───────────────────────────────────────────────────────

class _WebhookLogsPage extends StatefulWidget {
  final String subscriptionId;
  final String label;

  const _WebhookLogsPage(
      {required this.subscriptionId, required this.label});

  @override
  State<_WebhookLogsPage> createState() => _WebhookLogsPageState();
}

class _WebhookLogsPageState extends State<_WebhookLogsPage> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    final data =
        await ProviderService.getWebhookDeliveryLogs(widget.subscriptionId);
    setState(() {
      _logs = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No deliveries yet',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildLogItem(_logs[i]),
                ),
    );
  }

  Widget _buildLogItem(dynamic log) {
    final status = log['status'] as String? ?? 'unknown';
    final httpStatus = log['http_status'] as int?;
    final error = log['error'] as String?;
    final attemptedAt = log['attempted_at'] as String? ?? '';
    final attempt = log['attempt_number'] as int? ?? 1;
    final rawResponseBody = log['response_body'] as String?;
    final isSuccess = status == 'success';
    final color = isSuccess ? Colors.green : Colors.red;

    // Try to parse response_body as JSON for structured display
    Map<String, dynamic>? parsedResponse;
    if (rawResponseBody != null && rawResponseBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawResponseBody);
        if (decoded is Map<String, dynamic>) parsedResponse = decoded;
      } catch (_) {}
    }

    // Pull out recognisable payment fields (covers Kelly's schema and common M-Pesa patterns)
    final respStatus = _strField(parsedResponse, ['status', 'Status', 'result']);
    final respCode = _strField(parsedResponse, ['code', 'transaction_code', 'TransID', 'ref']);
    final respAmount = _strField(parsedResponse, ['amount', 'Amount', 'trans_amount']);
    final respName = _strField(parsedResponse, ['name', 'Name', 'BillRefNumber', 'customer']);
    final respTime = _strField(parsedResponse, ['trans_time', 'TransTime', 'timestamp', 'time', 'created_at']);
    final respMessage = _strField(parsedResponse, ['message', 'Message', 'ResultDesc', 'description']);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(status.toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                if (httpStatus != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('HTTP $httpStatus',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                  ),
                ],
                if (attempt > 1) ...[
                  const SizedBox(width: 6),
                  Text('attempt $attempt',
                      style: TextStyle(fontSize: 11, color: Colors.orange[700])),
                ],
                const Spacer(),
                Text(_formatDate(attemptedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),

          // ── Error text (failed/timeout deliveries) ───────────────────────
          if (error != null && error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(error,
                  style: TextStyle(fontSize: 12, color: Colors.red[400]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),

          // ── Parsed response fields ────────────────────────────────────────
          if (parsedResponse != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (respStatus != null) _chip('Status', respStatus),
                  if (respCode != null) _chip('Code', respCode),
                  if (respAmount != null) _chip('Amount', 'Ksh $respAmount'),
                  if (respName != null) _chip('Name', respName),
                  if (respTime != null) _chip('Time', respTime),
                ],
              ),
            ),
            if (respMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                child: Text(respMessage,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
          ],

          // ── Raw response collapsible ──────────────────────────────────────
          if (rawResponseBody != null && rawResponseBody.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text('Raw response',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SelectableText(
                      rawResponseBody,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Returns the first non-null string value found under any of [keys] in [map].
  String? _strField(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final k in keys) {
      final v = map[k];
      if (v != null) return v.toString();
    }
    return null;
  }

  Widget _chip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
