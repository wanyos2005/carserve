import 'package:flutter/material.dart';

/// A reusable modal bottom sheet component that provides consistent styling
/// and behavior across the app. Eliminates code duplication in modal implementations.
class ModalBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? footer;
  final double heightPercentage;
  final String? subtitle;
  final bool showHandleBar;

  const ModalBottomSheet({
    super.key,
    required this.title,
    required this.content,
    this.footer,
    this.heightPercentage = 0.8,
    this.subtitle,
    this.showHandleBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightPercentage,
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar (optional)
          if (showHandleBar) _buildHandleBar(),
          
          // Header
          _buildHeader(context),
          
          // Content
          Expanded(child: content),
          
          // Footer (optional)
          if (footer != null) footer!,
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A helper function to show a modal bottom sheet with consistent styling
Future<T?> showCustomModalBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => child,
  );
}
