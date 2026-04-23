import 'package:flutter/material.dart';

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message,
      {SnackBarAction? action}) {
    _show(
      context,
      message,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade600,
      action: action,
    );
  }

  static void showError(BuildContext context, String message,
      {SnackBarAction? action}) {
    _show(
      context,
      message,
      icon: Icons.error_outline,
      backgroundColor: Theme.of(context).colorScheme.error,
      action: action,
    );
  }

  static void showInfo(BuildContext context, String message,
      {SnackBarAction? action}) {
    _show(
      context,
      message,
      icon: Icons.info_outline,
      backgroundColor: Theme.of(context).colorScheme.primary,
      action: action,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: action == null
            ? const EdgeInsets.symmetric(horizontal: 40, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        duration: const Duration(seconds: 2),
        action: action,
      ),
    );
  }
}
