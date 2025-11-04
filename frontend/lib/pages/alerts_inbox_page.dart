import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driveon_car_platform/services/alerts_service.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/components/rating_dialog.dart';

class AlertsInboxPage extends StatefulWidget {
  const AlertsInboxPage({super.key});

  @override
  State<AlertsInboxPage> createState() => _AlertsInboxPageState();
}

class _AlertsInboxPageState extends State<AlertsInboxPage> {
  final _controller = ScrollController();
  bool _loading = true;
  List<Alert> _alerts = [];
  int _offset = 0;
  final int _limit = 50;
  String? _filterType; // 'insurance_expiry', 'service_due'
  String? _filterStatus; // 'delivered', 'pending' - NOTE: null means all statuses

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
    print('🔍 AlertsInbox: Current user ID from context: $userIdStr'); // Debug
    if (userIdStr == null) {
      print('⚠️ AlertsInbox: No user ID in context'); // Debug
      setState(() {
        _loading = false;
      });
      return;
    }
    final userId = int.tryParse(userIdStr);
    if (userId == null) {
      print('⚠️ AlertsInbox: Failed to parse user ID: $userIdStr'); // Debug
      return;
    }
    print('🔍 AlertsInbox: Fetching alerts for user_id=$userId'); // Debug

    setState(() => _loading = true);
    final items = await AlertsService.getAlerts(
      userId: userId,
      alertType: _filterType,
      status: _filterStatus,
      limit: _limit,
      offset: refresh ? 0 : _offset,
    );
    print('🔍 AlertsInbox: Received ${items.length} alerts'); // Debug
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

  Future<void> _markRead(Alert alert) async {
    final ok = await AlertsService.markAsRead(alert.id);
    if (ok) {
      setState(() {
        // Update the alert status locally
        final index = _alerts.indexWhere((a) => a.id == alert.id);
        if (index != -1) {
          _alerts[index] = Alert(
            id: alert.id,
            userId: alert.userId,
            type: alert.type,
            title: alert.title,
            message: alert.message,
            priority: alert.priority,
            vehicleId: alert.vehicleId,
            policyId: alert.policyId,
            bookingId: alert.bookingId,
            providerId: alert.providerId,
            channels: alert.channels,
            scheduledAt: alert.scheduledAt,
            actionUrl: alert.actionUrl,
            actionText: alert.actionText,
            alertMetadata: alert.alertMetadata,
            status: 'delivered',
            sentAt: alert.sentAt,
            deliveredAt: DateTime.now().toIso8601String(),
            errorMessage: alert.errorMessage,
            retryCount: alert.retryCount,
            createdAt: alert.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
      });
    }
  }

  void _openAction(Alert alert) async {
    if (alert.actionUrl == null || alert.actionUrl!.isEmpty) return;
    
    // Check if this is a rating request
    final ratingParams = parseRatingActionUrl(alert.actionUrl!);
    if (ratingParams != null) {
      final userIdStr = UserContextService.currentContext?.id;
      if (userIdStr != null) {
        final userId = int.tryParse(userIdStr);
        if (userId != null) {
          await showRatingDialog(
            context: context,
            userId: userId,
            providerId: ratingParams['provider_id']!,
            bookingId: ratingParams['booking_id'],
            logId: ratingParams['log_id'],
          );
          return;
        }
      }
    }
    
    // For other action URLs, show snackbar for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open action: ${alert.actionUrl}')),
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
  final Alert alert;
  final VoidCallback onMarkRead;
  final VoidCallback onOpenAction;

  const _AlertTile({required this.alert, required this.onMarkRead, required this.onOpenAction});

  @override
  Widget build(BuildContext context) {
    final created = DateTime.tryParse(alert.createdAt);
    final timeStr = created != null ? DateFormat.yMMMd().add_jm().format(created) : '';

    IconData icon;
    Color color;
    switch (alert.type) {
      case 'insurance_expiry':
        icon = Icons.shield_moon;
        color = Colors.indigo;
        break;
      case 'service_due':
        icon = Icons.build_circle;
        color = Colors.blue;
        break;
      case 'rating_request':
        icon = Icons.star;
        color = Colors.amber;
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
      title: Text(alert.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.message, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (timeStr.isNotEmpty) Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (alert.isUnread)
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
