import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../repositories/transaction_repository.dart';

class MonthlyProcessor {
  final AppDatabase _db;
  final TransactionRepository _transactionRepo;

  MonthlyProcessor(this._db, this._transactionRepo);

  Future<void> checkAndApply() async {
    final now = DateTime.now();

    final payments = await _db.select(_db.monthlyPayments).get();

    for (final payment in payments) {
      final bool alreadyProcessedThisMonth = payment.lastApplied != null &&
          payment.lastApplied!.month == now.month &&
          payment.lastApplied!.year == now.year;

      if (!alreadyProcessedThisMonth && now.day >= payment.dayOfMonth) {
        final transactionId = "monthly_${payment.id}_${now.month}-${now.year}";

        await _transactionRepo.addTransaction(TransactionsCompanion.insert(
          id: transactionId,
          amount: payment.amount,
          type: payment.type,
          accountId: payment.accountId,
          categoryId: Value(payment.categoryId),
          date: DateTime(now.year, now.month, payment.dayOfMonth),
          note: Value("[Auto] ${payment.name}"),
          isChecked: const Value(true),
        ));

        await (_db.update(_db.monthlyPayments)..where((t) => t.id.equals(payment.id)))
            .write(MonthlyPaymentsCompanion(lastApplied: Value(now)));
      }
    }
  }
}