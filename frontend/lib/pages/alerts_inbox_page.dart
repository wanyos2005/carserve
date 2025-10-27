import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driveon_car_platform/services/alerts_service.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';

class AlertsInboxPage extends StatefulWidget {
  const AlertsInboxPage({super.key});

  @override
  State<AlertsInboxPage> createState() => _AlertsInboxPageState();
}

class _AlertsInboxPageState extends State<AlertsInboxPage> {
  final _controller = ScrollController();
  bool _loading = true;
  List<dynamic> _alerts = [];
  int _offset = 0;
  final int _limit = 50;
  String? _filterType; // 'insurance_expiry', 'service_due'
  String? _filterStatus; // 'delivered', 'pending'

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    final userIdStr = UserContextService.currentContext?.id;
    if (userIdStr == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final userId = int.tryParse(userIdStr);
    if (userId == null) return;

    setState(() => _loading = true);
    final items = await AlertsService.getAlerts(
      userId: userId,
      type: _filterType,
      status: _filterStatus,
      limit: _limit,
      offset: refresh ? 0 : _offset,
    );
    setState(() {
      if (refresh) {
        _alerts = items;
        _offset = items.length;
      } else {
        _alerts.addAll(items);
        _offset += items.length;
      }
      _loading = false;
    });
  }

  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200 && !_loading) {
      _load();
    }
  }

  Future<void> _markRead(dynamic alert) async {
    final id = alert['id'] as String?;
    if (id == null) return;
    final ok = await AlertsService.markRead(id);
    if (ok) {
      setState(() {
        alert['status'] = 'delivered';
      });
    }
  }

  void _openAction(dynamic alert) {
    final url = alert['action_url'] as String?;
    if (url == null || url.isEmpty) return;
    // For MVP: show snackbar; future: deep-link
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open action: $url')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) async {
              setState(() {
                switch (val) {
                  case 'all': _filterType = null; break;
                  case 'insurance': _filterType = 'insurance_expiry'; break;
                  case 'service': _filterType = 'service_due'; break;
                }
              });
              await _load(refresh: true);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'all', child: Text('All')),
              PopupMenuItem(value: 'insurance', child: Text('Insurance')),
              PopupMenuItem(value: 'service', child: Text('Service')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(refresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: _loading && _alerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                controller: _controller,
                itemCount: _alerts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) => _AlertTile(
                  alert: _alerts[i],
                  onMarkRead: () => _markRead(_alerts[i]),
                  onOpenAction: () => _openAction(_alerts[i]),
                ),
              ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final dynamic alert;
  final VoidCallback onMarkRead;
  final VoidCallback onOpenAction;

  const _AlertTile({required this.alert, required this.onMarkRead, required this.onOpenAction});

  @override
  Widget build(BuildContext context) {
    final type = (alert['type'] ?? '').toString();
    final title = (alert['title'] ?? '').toString();
    final message = (alert['message'] ?? '').toString();
    final status = (alert['status'] ?? '').toString();
    final createdAt = alert['created_at'];
    final created = createdAt != null ? DateTime.tryParse(createdAt.toString()) : null;
    final timeStr = created != null ? DateFormat.yMMMd().add_jm().format(created) : '';

    IconData icon;
    Color color;
    switch (type) {
      case 'insurance_expiry':
        icon = Icons.shield_moon;
        color = Colors.indigo;
        break;
      case 'service_due':
        icon = Icons.build_circle;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (timeStr.isNotEmpty) Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (status == 'pending' || status == 'sent')
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              tooltip: 'Mark as read',
              onPressed: onMarkRead,
            )
          else
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
      onTap: onOpenAction,
    );
  }
}
