import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          tileColor: transaction.isChecked ? AppColors.thirdBackground.withOpacity(0.5) : Colors.transparent,
          leading: CircleAvatar(
            backgroundColor: transaction.isChecked ? Colors.green.withOpacity(0.2) : AppColors.thirdBackground,
            child: Icon(
              transaction.isChecked ? Icons.check : (transaction.amount < 0 ? Icons.shopping_cart : Icons.add_chart),
              color: transaction.isChecked ? Colors.green : AppColors.mainColor,
            ),
          ),
          title: Text(
            transaction.title,
            style: const TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            "${transaction.date.day}/${transaction.date.month}/${transaction.date.year}",
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          trailing: Text(
            "${transaction.amount > 0 ? '+' : ''}${transaction.amount.toStringAsFixed(2)} €",
            style: TextStyle(
              color: transaction.amount < 0 ? Colors.redAccent : Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}