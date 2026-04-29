import 'package:flutter_test/flutter_test.dart';
import 'package:moneo/data/models/models.dart';
import 'package:moneo/data/models/app_user_model.dart';

void main() {
  // ─── Transaction ─────────────────────────────────────────────────────────────

  group('Transaction.copyWith', () {
    final base = Transaction(
      id: 'tx-1',
      amount: 50.0,
      type: 'expense',
      date: DateTime(2024, 1, 15),
      note: 'Café',
      isChecked: false,
      accountId: 'acc-1',
      categoryId: 'cat-1',
      paymentMethodId: 'pm-1',
      chequeNumber: null,
    );

    test('met à jour les champs scalaires', () {
      final updated = base.copyWith(amount: 99.0, isChecked: true);
      expect(updated.amount, 99.0);
      expect(updated.isChecked, true);
      expect(updated.id, 'tx-1');
      expect(updated.accountId, 'acc-1');
    });

    test('peut effacer note en passant null explicitement', () {
      final updated = base.copyWith(note: null);
      expect(updated.note, isNull);
    });

    test('conserve note si non passée', () {
      final updated = base.copyWith(amount: 10.0);
      expect(updated.note, 'Café');
    });

    test('peut effacer categoryId', () {
      final updated = base.copyWith(categoryId: null);
      expect(updated.categoryId, isNull);
    });

    test('conserve categoryId si non passé', () {
      final updated = base.copyWith(amount: 10.0);
      expect(updated.categoryId, 'cat-1');
    });

    test('peut effacer paymentMethodId', () {
      final updated = base.copyWith(paymentMethodId: null);
      expect(updated.paymentMethodId, isNull);
    });
  });

  group('Transaction.fromJson champs optionnels', () {
    test('parse categoryId, paymentMethodId, chequeNumber', () {
      final tx = Transaction.fromJson({
        'id': 'tx-5',
        'amount': 30.0,
        'type': 'expense',
        'date': '2024-03-10T00:00:00.000Z',
        'accountId': 'acc-1',
        'categoryId': 'cat-2',
        'paymentMethodId': 'pm-3',
        'chequeNumber': 'CHQ-0042',
        'isChecked': true,
      });
      expect(tx.categoryId, 'cat-2');
      expect(tx.paymentMethodId, 'pm-3');
      expect(tx.chequeNumber, 'CHQ-0042');
      expect(tx.isChecked, true);
    });

    test('null pour les champs absents', () {
      final tx = Transaction.fromJson({
        'id': 'tx-6',
        'amount': 10.0,
        'type': 'income',
        'date': '2024-03-10T00:00:00.000Z',
        'accountId': 'acc-1',
      });
      expect(tx.categoryId, isNull);
      expect(tx.paymentMethodId, isNull);
      expect(tx.chequeNumber, isNull);
      expect(tx.note, isNull);
    });

    test('_parseDouble retourne 0.0 pour null', () {
      final tx = Transaction.fromJson({
        'id': 'tx-7',
        'amount': null,
        'type': 'expense',
        'date': '2024-03-10T00:00:00.000Z',
        'accountId': 'acc-1',
      });
      expect(tx.amount, 0.0);
    });
  });

  // ─── BankAccount ─────────────────────────────────────────────────────────────

  group('BankAccount.fromJson valeurs par défaut', () {
    test('type et currency ont des valeurs par défaut', () {
      final account = BankAccount.fromJson({
        'id': 'acc-3',
        'name': 'Livret',
        'balance': 2000.0,
      });
      expect(account.type, 'checking');
      expect(account.currency, 'EUR');
      expect(account.sortOrder, 0);
    });

    test('respecte les valeurs explicites', () {
      final account = BankAccount.fromJson({
        'id': 'acc-4',
        'name': 'Compte USD',
        'balance': 1000.0,
        'type': 'savings',
        'currency': 'USD',
        'sortOrder': 3,
      });
      expect(account.type, 'savings');
      expect(account.currency, 'USD');
      expect(account.sortOrder, 3);
    });
  });

  // ─── Category ────────────────────────────────────────────────────────────────

  group('Category.fromJson', () {
    test('parse parentId si présent', () {
      final cat = Category.fromJson({
        'id': 'cat-3',
        'name': 'Restaurants',
        'iconCode': 'e56c',
        'colorValue': 4280391411,
        'userId': 'user-1',
        'parentId': 'cat-parent',
      });
      expect(cat.parentId, 'cat-parent');
    });

    test('parentId null si absent', () {
      final cat = Category.fromJson({
        'id': 'cat-4',
        'name': 'Alimentation',
        'iconCode': 'e532',
        'colorValue': 4294901760,
        'userId': 'user-1',
      });
      expect(cat.parentId, isNull);
    });

    test('userId vide si absent', () {
      final cat = Category.fromJson({
        'id': 'cat-5',
        'name': 'Divers',
        'iconCode': 'e3af',
        'colorValue': 4280391411,
      });
      expect(cat.userId, '');
    });
  });

  // ─── MonthlyPayment ──────────────────────────────────────────────────────────

  group('MonthlyPayment.fromJson', () {
    test('parse categoryId si présent', () {
      final mp = MonthlyPayment.fromJson({
        'id': 'mp-4',
        'name': 'Assurance',
        'amount': 45.0,
        'type': 'expense',
        'dayOfMonth': 10,
        'accountId': 'acc-1',
        'categoryId': 'cat-insurance',
      });
      expect(mp.categoryId, 'cat-insurance');
    });

    test('dayOfMonth parsé depuis num', () {
      final mp = MonthlyPayment.fromJson({
        'id': 'mp-5',
        'name': 'Loyer',
        'amount': 850.0,
        'type': 'expense',
        'dayOfMonth': 1,
        'accountId': 'acc-1',
      });
      expect(mp.dayOfMonth, 1);
    });
  });

  // ─── PaymentMethod ───────────────────────────────────────────────────────────

  group('PaymentMethod', () {
    test('fromJson parse tous les champs', () {
      final pm = PaymentMethod.fromJson({
        'id': 'pm-1',
        'name': 'Visa',
        'type': 'credit',
      });
      expect(pm.id, 'pm-1');
      expect(pm.name, 'Visa');
      expect(pm.type, 'credit');
    });

    test('type vaut debit par défaut si absent', () {
      final pm = PaymentMethod.fromJson({
        'id': 'pm-2',
        'name': 'Carte bancaire',
      });
      expect(pm.type, 'debit');
    });

    test('constructeur direct fonctionne', () {
      const pm = PaymentMethod(id: 'pm-3', name: 'Chèque', type: 'cheque');
      expect(pm.id, 'pm-3');
      expect(pm.type, 'cheque');
    });
  });

  // ─── AppUser ─────────────────────────────────────────────────────────────────

  group('AppUser.fromJson cas supplémentaires', () {
    test('lit uid depuis le champ uid en priorité', () {
      final user = AppUser.fromJson({
        'uid': 'uid-direct',
        'id': 'id-fallback',
        'username': 'alice',
        'email': 'alice@example.com',
        'createdAt': '2024-06-01T00:00:00.000Z',
        'updatedAt': '2024-06-01T00:00:00.000Z',
      });
      expect(user.uid, 'uid-direct');
    });

    test('parse payment_methods (snake_case)', () {
      final user = AppUser.fromJson({
        'id': 'user-1',
        'username': 'bob',
        'email': 'bob@example.com',
        'createdAt': '2024-06-01T00:00:00.000Z',
        'updatedAt': '2024-06-01T00:00:00.000Z',
        'payment_methods': [
          {'id': 'pm-1', 'name': 'CB'},
        ],
      });
      expect(user.paymentMethods.length, 1);
      expect(user.paymentMethods.first['name'], 'CB');
    });

    test('parse paymentMethods (camelCase)', () {
      final user = AppUser.fromJson({
        'id': 'user-2',
        'username': 'carol',
        'email': 'carol@example.com',
        'createdAt': '2024-06-01T00:00:00.000Z',
        'updatedAt': '2024-06-01T00:00:00.000Z',
        'paymentMethods': [
          {'id': 'pm-2', 'name': 'Visa'},
          {'id': 'pm-3', 'name': 'Mastercard'},
        ],
      });
      expect(user.paymentMethods.length, 2);
    });

    test('les 4 prefs de notification par défaut sont présentes', () {
      final user = AppUser.fromJson({
        'id': 'user-3',
        'username': 'dave',
        'email': 'dave@example.com',
        'createdAt': '2024-06-01T00:00:00.000Z',
        'updatedAt': '2024-06-01T00:00:00.000Z',
      });
      expect(user.notificationPrefs['paymentApplied'], true);
      expect(user.notificationPrefs['lowBalance'], true);
      expect(user.notificationPrefs['monthlyRecap'], true);
      expect(user.notificationPrefs['activityReminder'], true);
    });

    test('notificationPrefs lit les valeurs du JSON', () {
      final user = AppUser.fromJson({
        'id': 'user-4',
        'username': 'eve',
        'email': 'eve@example.com',
        'createdAt': '2024-06-01T00:00:00.000Z',
        'updatedAt': '2024-06-01T00:00:00.000Z',
        'notificationPrefs': {
          'paymentApplied': false,
          'lowBalance': true,
          'monthlyRecap': false,
          'activityReminder': true,
        },
      });
      expect(user.notificationPrefs['paymentApplied'], false);
      expect(user.notificationPrefs['monthlyRecap'], false);
      expect(user.notificationPrefs['lowBalance'], true);
    });

    test('parse photoUrl et fcmToken', () {
      final user = AppUser.fromJson({
        'id': 'user-5',
        'username': 'frank',
        'email': 'frank@example.com',
        'createdAt': '2024-06-01T00:00:00.000Z',
        'updatedAt': '2024-06-01T00:00:00.000Z',
        'photoUrl': 'https://example.com/photo.jpg',
        'fcmToken': 'token-xyz',
      });
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.fcmToken, 'token-xyz');
    });
  });

  group('AppUser.copyWith', () {
    final base = AppUser(
      uid: 'user-1',
      username: 'alice',
      email: 'alice@example.com',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('met à jour username', () {
      final updated = base.copyWith(username: 'bob');
      expect(updated.username, 'bob');
      expect(updated.uid, 'user-1');
      expect(updated.email, 'alice@example.com');
    });

    test('met à jour hasCompletedSetup', () {
      final updated = base.copyWith(hasCompletedSetup: true);
      expect(updated.hasCompletedSetup, true);
    });

    test('met à jour notificationPrefs', () {
      final updated = base.copyWith(
        notificationPrefs: {'monthlyRecap': false},
      );
      expect(updated.notificationPrefs['monthlyRecap'], false);
    });

    test('met à jour paymentMethods', () {
      final updated = base.copyWith(paymentMethods: [
        {'id': 'pm-1', 'name': 'Visa'},
      ]);
      expect(updated.paymentMethods.length, 1);
    });
  });

  group('AppUser.toJson', () {
    test('inclut uniquement username, hasCompletedSetup et les champs non-null', () {
      final user = AppUser(
        uid: 'user-1',
        username: 'alice',
        email: 'alice@example.com',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        hasCompletedSetup: true,
        photoUrl: 'https://example.com/photo.jpg',
        fcmToken: 'token-abc',
      );
      final json = user.toJson();
      expect(json['username'], 'alice');
      expect(json['hasCompletedSetup'], true);
      expect(json['photoUrl'], 'https://example.com/photo.jpg');
      expect(json['fcmToken'], 'token-abc');
      expect(json.containsKey('email'), false);
      expect(json.containsKey('uid'), false);
    });

    test("n'inclut pas photoUrl ni fcmToken si null", () {
      final user = AppUser(
        uid: 'user-2',
        username: 'bob',
        email: 'bob@example.com',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final json = user.toJson();
      expect(json.containsKey('photoUrl'), false);
      expect(json.containsKey('fcmToken'), false);
    });
  });
}
