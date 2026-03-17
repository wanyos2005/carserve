// lib/services/mpesa_sms_service.dart
//
// Listens for incoming M-Pesa SMS messages on the merchant device,
// parses the transaction details, and posts them to the backend API.
// Also scans the inbox on startup for any recent messages not yet synced.

import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'user_context_service.dart';

// Top-level handler required by telephony for background (app killed) SMS.
// Must be a top-level function, not a class method.
@pragma('vm:entry-point')
void backgroundSmsHandler(SmsMessage message) {
  if (!MpesaSmsService.isMpesaSms(message)) return;
  final body = message.body ?? '';
  if (body.isEmpty) return;

  // Always post raw_sms — backend deduplicates on transaction_code.
  // No SharedPreferences access in background isolate, so we rely on backend dedup.
  final parsed = MpesaSmsService.parseMpesaSms(body);
  final payload = <String, dynamic>{
    'raw_sms': body,
    'source': 'sms_reader',
    ...?parsed,
  };
  ApiService.post('/payment-service/mpesa/transactions', payload);
}

class MpesaSmsService {
  static final Telephony _telephony = Telephony.instance;

  // SharedPreferences key prefix for processed transaction codes
  static const String _processedKeyPrefix = 'mpesa_processed_';

  // How far back to scan the inbox on first run (in milliseconds)
  static const int _inboxScanDaysBack = 7;

  /// Call once from main.dart after user is authenticated.
  static Future<void> initialize() async {
    try {
      final granted = await _telephony.requestPhoneAndSmsPermissions;
      if (granted != true) {
        debugPrint('❌ MpesaSmsService: SMS permission denied');
        return;
      }

      // Scan existing inbox for unsynced M-Pesa messages
      await scanInbox();

      // Listen for new incoming SMS while app is foregrounded or backgrounded
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          debugPrint('📨 New SMS from: ${message.address}');
          await _processSms(message);
        },
        onBackgroundMessage: backgroundSmsHandler,
        listenInBackground: true,
      );

      debugPrint('✅ MpesaSmsService: initialized');
    } catch (e) {
      debugPrint('❌ MpesaSmsService init error: $e');
    }
  }

  /// Scans the device inbox for M-Pesa messages from the last [_inboxScanDaysBack] days
  /// and posts any that have not yet been synced.
  static Future<void> scanInbox() async {
    try {
      final cutoffMs = DateTime.now()
          .subtract(const Duration(days: _inboxScanDaysBack))
          .millisecondsSinceEpoch;

      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .equals('MPESA')
            .and(SmsColumn.DATE)
            .greaterThan(cutoffMs.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      debugPrint('📥 MpesaSmsService: found ${messages.length} M-Pesa messages in inbox');

      for (final msg in messages) {
        await _processSms(msg);
      }
    } catch (e) {
      debugPrint('❌ MpesaSmsService inbox scan error: $e');
    }
  }

  /// Processes a single SMS: parses it and posts to backend if not already synced.
  static Future<void> _processSms(SmsMessage message) async {
    if (!isMpesaSms(message)) return;

    final body = message.body ?? '';
    if (body.isEmpty) return;

    // Best-effort parse — may return null for non-payment messages (balance alerts, etc.)
    final parsed = parseMpesaSms(body);

    // Use transaction_code from parsed data, or fall back to SMS date for dedup key.
    // We always post — raw_sms is never dropped even if parsing failed.
    final dedupeKey = (parsed?['transaction_code'] as String?) ??
        'RAW_${message.date ?? body.hashCode}';

    // Deduplicate — skip if already posted
    if (await _isAlreadyProcessed(dedupeKey)) {
      debugPrint('⏭️ MpesaSmsService: already synced $dedupeKey');
      return;
    }

    // Build payload: always include raw_sms; merge parsed fields if available
    final payload = <String, dynamic>{
      'raw_sms': body,
      'source': 'sms_reader',
      ...?parsed,
    };

    // Attach timestamp from the SMS metadata if available
    if (message.date != null) {
      payload['received_at'] =
          DateTime.fromMillisecondsSinceEpoch(message.date!).toIso8601String();
    }

    // Attach the logged-in provider's ID so the backend can route webhooks correctly
    final providerId = UserContextService.currentContext?.providerId;
    if (providerId != null) {
      payload['provider_id'] = providerId;
    }

    final result =
        await ApiService.post('/payment-service/mpesa/transactions', payload);
    if (result != null) {
      await _markAsProcessed(dedupeKey);
      debugPrint('✅ MpesaSmsService: synced $dedupeKey');
    } else {
      debugPrint('❌ MpesaSmsService: failed to post $dedupeKey — will retry next scan');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers (public so backgroundSmsHandler can call them)
  // ---------------------------------------------------------------------------

  /// Returns true if the message is from M-Pesa.
  static bool isMpesaSms(SmsMessage message) {
    final address = (message.address ?? '').toUpperCase();
    return address == 'MPESA' || address.contains('MPESA');
  }

  /// Parses a raw M-Pesa SMS body into a structured map.
  /// Returns null if the message is not a recognised payment confirmation.
  ///
  /// Handles the two most common formats:
  ///   1. Received money: "RXXXXXXXX Confirmed. You have received Ksh..."
  ///   2. Customer paid to till/paybill: "RXXXXXXXX Confirmed. Ksh... paid to..."
  static Map<String, dynamic>? parseMpesaSms(String body) {
    if (body.isEmpty) return null;

    // Transaction code — always the first token (10 alphanumeric chars)
    final codeMatch = RegExp(r'^([A-Z0-9]{10})\s').firstMatch(body);
    if (codeMatch == null) return null;
    final transactionCode = codeMatch.group(1)!;
     debugPrint('⚠️ MpesaSmsServiceError: mpesa code: $codeMatch');
    // Amount — "Ksh1,000.00" or "Ksh500.00"
    final amountMatch = RegExp(r'Ksh([\d,]+\.?\d*)').firstMatch(body);
    if (amountMatch == null) return null;
    final amount = double.tryParse(
      amountMatch.group(1)!.replaceAll(',', ''),
    );
    if (amount == null) return null;

    // Balance — last Ksh occurrence in the message
    double? balance;
    final allAmounts = RegExp(r'Ksh([\d,]+\.?\d*)').allMatches(body).toList();
    if (allAmounts.length >= 2) {
      balance = double.tryParse(
        allAmounts.last.group(1)!.replaceAll(',', ''),
      );
    }

    // Determine transaction type and extract sender details
    String transactionType = 'unknown';
    String? senderName;
    String? senderPhone;

    // Format 1: you received money from someone
    final receivedMatch = RegExp(
      r'received Ksh[\d,\.]+\s+from\s+([A-Z ]+?)\s+(\d{10,12})',
      caseSensitive: false,
    ).firstMatch(body);

    // Format 2: customer paid to your till/paybill
    final paidToMatch = RegExp(
      r'([A-Z0-9]{10}) Confirmed\.\s*Ksh[\d,\.]+\s+paid to',
      caseSensitive: false,
    ).firstMatch(body);

    if (receivedMatch != null) {
      transactionType = 'received';
      senderName = receivedMatch.group(1)?.trim();
      senderPhone = receivedMatch.group(2)?.trim();
    } else if (paidToMatch != null) {
      transactionType = 'paybill_payment';
      // Sender name/phone may appear as "from JOHN DOE 254712345678"
      final fromMatch = RegExp(
        r'from\s+([A-Z ]+?)\s+(\d{10,12})',
        caseSensitive: false,
      ).firstMatch(body);
      senderName = fromMatch?.group(1)?.trim();
      senderPhone = fromMatch?.group(2)?.trim();
    } else {
      // Not a payment-received message — ignore withdrawals, transfers, etc.
      return null;
    }

    return {
      'raw_sms': body,
      'transaction_code': transactionCode,
      'amount': amount,
      'balance': balance,
      'transaction_type': transactionType,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'received_at': DateTime.now().toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Deduplication via SharedPreferences
  // ---------------------------------------------------------------------------

  static Future<bool> _isAlreadyProcessed(String transactionCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_processedKeyPrefix$transactionCode');
  }

  static Future<void> _markAsProcessed(String transactionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      '$_processedKeyPrefix$transactionCode',
      true,
    );
  }
}
