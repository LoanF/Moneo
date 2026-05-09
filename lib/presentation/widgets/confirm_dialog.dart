import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = "Supprimer",
  String cancelLabel = "Annuler",
  IconData icon = Icons.delete_forever_rounded,
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (confirmColor ?? AppColors.primaryRed).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: confirmColor ?? AppColors.primaryRed, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mainText,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(cancelLabel, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmColor ?? AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmLabel, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
