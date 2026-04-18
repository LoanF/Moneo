import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../../core/helpers/icon_helper.dart';
import '../../core/themes/app_colors.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String? categoryIcon;
  final int? categoryColor;

  const TransactionTile({super.key, required this.transaction, this.categoryIcon, this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final bool hasValidColor = categoryColor != null && categoryColor != 0;
    final Color iconColor = hasValidColor
        ? Color(categoryColor!)
        : (transaction.amount < 0 ? AppColors.mainColor : AppColors.primaryGreen);

    return Container(
      decoration: BoxDecoration(
        color: transaction.isChecked ? AppColors.thirdBackground.withValues(alpha: 0.3) : AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: transaction.isChecked ? AppColors.primaryGreen.withValues(alpha: 0.1) : iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            transaction.isChecked
                ? Icons.check_circle_rounded
                : IconHelper.getIcon(categoryIcon ?? ""),
            color: transaction.isChecked ? AppColors.primaryGreen : iconColor,
            size: 24,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                transaction.note ?? "",
                style: TextStyle(
                  color: AppColors.mainText.withValues(alpha: transaction.isChecked ? 0.5 : 1.0),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  decoration: transaction.isChecked ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (transaction.isMonthly) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 10, color: AppColors.mainColor),
                    const SizedBox(width: 4),
                    const Text(
                      "MENSUEL",
                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          DateFormat.yMMMMd().format(transaction.date),
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${transaction.amount > 0 ? '+' : ''}${transaction.amount.toStringAsFixed(2)} €",
              style: TextStyle(
                color: transaction.isChecked ? AppColors.grey1 : (transaction.amount < 0 ? AppColors.primaryRed : AppColors.primaryGreen),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            if (transaction.isChecked)
              const Text(
                "Pointé",
                style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}