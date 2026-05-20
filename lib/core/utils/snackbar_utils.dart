import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Themed snackbar utilities
class SnackbarUtils {
  SnackbarUtils._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error_rounded);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppColors.warning, Icons.warning_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.accent, Icons.info_rounded);
  }

  /// Show a snackbar with an undo action
  static void showUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.accent,
          onPressed: onUndo,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
