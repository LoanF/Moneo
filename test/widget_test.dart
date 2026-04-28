import 'package:flutter_test/flutter_test.dart';
import 'package:moneo/data/models/models.dart';
import 'package:moneo/data/models/app_user_model.dart';

void main() {
  group('Transaction', () {
    test('fromJson parse les champs de base', () {
      final tx = Transaction.fromJson({
        'id': 'tx-1',
        'amount': 42.5,
        'type': 'expense',
        'date': '2024-01-15T00:00:00.000Z',
        'isChecked': false,
        'accountId': 'acc-1',
      });
      expect(tx.id, 'tx-1');
      expect(tx.amount, 42.5);
      expect(tx.type, 'expense');
      expect(tx.isChecked, false);
      expect(tx.isMonthly, false);
    });

    test('fromJson détecte isMonthly via le préfixe [Auto]', () {
      final tx = Transaction.fromJson({
        'id': 'tx-2',
        'amount': 100.0,
        'type': 'expense',
        'date': '2024-01-15T00:00:00.000Z',
        'note': '[Auto] Loyer',
        'accountId': 'acc-1',
      });
      expect(tx.isMonthly, true);
      expect(tx.note, '[Auto] Loyer');
    });

    test('fromJson accepte amount en int et en String', () {
      final fromInt = Transaction.fromJson({
        'id': 'tx-3',
        'amount': 50,
        'type': 'income',
        'date': '2024-01-15T00:00:00.000Z',
        'accountId': 'acc-1',
      });
      final fromString = Transaction.fromJson({
        'id': 'tx-4',
        'amount': '75.25',
        'type': 'income',
        'date': '2024-01-15T00:00:00.000Z',
        'accountId': 'acc-1',
      });
      expect(fromInt.amount, 50.0);
      expect(fromString.amount, 75.25);
    });
  });

  group('BankAccount', () {
    test('fromJson parse tous les champs', () {
      final account = BankAccount.fromJson({
        'id': 'acc-1',
        'name': 'Compte courant',
        'balance': 1500.0,
        'pointedBalance': 1200.0,
        'sortOrder': 1,
        'type': 'checking',
        'currency': 'EUR',
      });
      expect(account.id, 'acc-1');
      expect(account.balance, 1500.0);
      expect(account.pointedBalance, 1200.0);
      expect(account.sortOrder, 1);
    });

    test('pointedBalance vaut balance par défaut si absent', () {
      final account = BankAccount.fromJson({
        'id': 'acc-2',
        'name': 'Épargne',
        'balance': 5000.0,
      });
      expect(account.pointedBalance, 5000.0);
    });
  });

  group('Category', () {
    test('fromJson accepte colorValue en int ou en String', () {
      final fromInt = Category.fromJson({
        'id': 'cat-1',
        'name': 'Alimentation',
        'iconCode': 'e532',
        'colorValue': 4294901760,
        'userId': 'user-1',
      });
      final fromString = Category.fromJson({
        'id': 'cat-2',
        'name': 'Transport',
        'iconCode': 'e1d3',
        'colorValue': '4280391411',
        'userId': 'user-1',
      });
      expect(fromInt.colorValue, 4294901760);
      expect(fromString.colorValue, 4280391411);
    });
  });

  group('MonthlyPayment', () {
    test('fromJson accepte lastProcessed ou lastApplied', () {
      final withProcessed = MonthlyPayment.fromJson({
        'id': 'mp-1',
        'name': 'Netflix',
        'amount': 15.99,
        'type': 'expense',
        'dayOfMonth': 5,
        'accountId': 'acc-1',
        'lastProcessed': '2024-01-05T00:00:00.000Z',
      });
      final withApplied = MonthlyPayment.fromJson({
        'id': 'mp-2',
        'name': 'Loyer',
        'amount': 900.0,
        'type': 'expense',
        'dayOfMonth': 1,
        'accountId': 'acc-1',
        'lastApplied': '2024-01-01T00:00:00.000Z',
      });
      expect(withProcessed.lastApplied, isNotNull);
      expect(withApplied.lastApplied, isNotNull);
    });

    test('lastApplied est null si absent', () {
      final mp = MonthlyPayment.fromJson({
        'id': 'mp-3',
        'name': 'Abonnement',
        'amount': 9.99,
        'type': 'expense',
        'dayOfMonth': 15,
        'accountId': 'acc-1',
      });
      expect(mp.lastApplied, isNull);
    });
  });

  group('AppUser', () {
    test('fromJson lit uid depuis le champ id', () {
      final user = AppUser.fromJson({
        'id': 'user-123',
        'username': 'lfrancoi',
        'email': 'test@example.com',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
        'hasCompletedSetup': true,
        'emailVerified': true,
      });
      expect(user.uid, 'user-123');
      expect(user.hasCompletedSetup, true);
      expect(user.emailVerified, true);
    });

    test('notificationPrefs utilise les valeurs par défaut si absent', () {
      final user = AppUser.fromJson({
        'id': 'user-456',
        'username': 'test',
        'email': 'test@example.com',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      });
      expect(user.notificationPrefs['monthlyRecap'], true);
      expect(user.notificationPrefs['activityReminder'], true);
    });
  });
}
