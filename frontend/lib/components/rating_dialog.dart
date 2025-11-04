// frontend/lib/components/rating_dialog.dart
import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/provider_service.dart';

/// Show a rating dialog for a provider
/// This is a shared component that can be used from anywhere in the app
Future<void> showRatingDialog({
  required BuildContext context,
  required int userId,
  required String providerId,
  String? bookingId,
  String? logId,
}) async {
  int selected = 5;
  final commentCtrl = TextEditingController();
  
  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Rate Provider"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      icon: Icon(
                        idx <= selected ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          selected = idx;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(
                    labelText: "Comment (optional)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Skip"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ProviderService.rateProvider(
                      providerId: providerId,
                      rating: selected,
                      comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                      userId: userId,
                      bookingId: bookingId,
                      logId: logId,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text("✅ Rating submitted successfully")),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text("Failed to submit rating: $e")),
                      );
                    }
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Parse action URL to extract rating parameters
/// Handles URLs like: /rate?provider_id=xxx&log_id=yyy or /rate?provider_id=xxx&booking_id=zzz
Map<String, String?>? parseRatingActionUrl(String actionUrl) {
  try {
    if (!actionUrl.startsWith('/rate')) {
      return null;
    }
    
    final uri = Uri.parse(actionUrl);
    final providerId = uri.queryParameters['provider_id'];
    
    if (providerId == null) {
      return null;
    }
    
    return {
      'provider_id': providerId,
      'log_id': uri.queryParameters['log_id'],
      'booking_id': uri.queryParameters['booking_id'],
    };
  } catch (e) {
    return null;
  }
}

