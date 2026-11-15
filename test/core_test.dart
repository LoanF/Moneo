import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneo/core/api_client.dart';
import 'package:moneo/core/format.dart';
import 'package:moneo/data/models.dart';

import 'support.dart';

void main() {
  setUpAll(prepareTests);

  group('mise en forme', () {
    test('écrit les montants à la française, avec un vrai signe moins', () {
      expect(Fmt.money(-68.01), '−68,01 €');
      expect(Fmt.money(1500), '1 500,00 €');
      expect(Fmt.signed(1500), '+1 500,00 €');
      expect(Fmt.signed(-7.6), '−7,60 €');
      expect(Fmt.plain(68.01), '68,01');
    });

    test('lit un montant saisi avec virgule, point ou espaces', () {
      expect(Fmt.parseAmount('68,01'), 68.01);
      expect(Fmt.parseAmount('1 234.5'), 1234.5);
      expect(Fmt.parseAmount('12 €'), 12);
      expect(Fmt.parseAmount(''), isNull);
      expect(Fmt.parseAmount('abc'), isNull);
    });

    test('complète une date saisie rapidement, comme dans le classeur', () {
      final now = DateTime(2026, 11, 15);
      expect(Fmt.parseQuickDate('14', now: now), DateTime(2026, 11, 14));
      expect(Fmt.parseQuickDate('3/2', now: now), DateTime(2026, 2, 3));
      expect(Fmt.parseQuickDate('31/12/25', now: now), DateTime(2025, 12, 31));
      expect(Fmt.parseQuickDate('05.01.2024', now: now), DateTime(2024, 1, 5));
    });

    test('refuse une date qui n’existe pas', () {
      final now = DateTime(2026, 6, 10);
      expect(Fmt.parseQuickDate('31', now: now), isNull, reason: 'pas de 31 juin');
      expect(Fmt.parseQuickDate('30/2', now: now), isNull);
      expect(Fmt.parseQuickDate('demain', now: now), isNull);
    });

    test('nomme les jours proches', () {
      expect(Fmt.dayLabel(Fmt.today()), 'Aujourd’hui');
      expect(Fmt.dayLabel(Fmt.iso(DateTime.now().subtract(const Duration(days: 1)))), 'Hier');
      expect(Fmt.month('2026-11'), 'Novembre 2026');
    });
  });

  group('modèles', () {
    final data = Bootstrap.fromJson(bootstrapJson());

    test('lit l’état de démarrage et distingue les trois soldes', () {
      final account = data.accounts.first;
      expect(account.balance, 928.60);
      expect(account.pointedBalance, 1036.46);
      expect(account.uncheckedCount, 3);
      expect(data.user.settings.recurringMode, RecurringMode.monthStart);
      expect(data.unreadNotifications, 2);
    });

    test('compose le libellé « catégorie · sous-catégorie »', () {
      final sub = data.categories.firstWhere((c) => c.parentId != null);
      expect(data.categoryLabel(sub.id), 'Restaurant · Fast-food');
      expect(data.categoryLabel(sub.parentId), 'Restaurant');
      expect(data.categoryLabel(null), 'Sans catégorie');
      expect(data.rootCategories, hasLength(2));
    });

    test('applique le montant propre à un mois pour une mensualité', () {
      final rent = data.recurring.single;
      expect(rent.amountForMonth(3), 350);
      expect(rent.amountForMonth(12), 360.5);
      expect(rent.yearlyTotal, 350 * 11 + 360.5);
    });

    test('qualifie un budget proche du plafond', () {
      final budget = data.budgets.single;
      expect(budget.isNear, isTrue);
      expect(budget.isOver, isFalse);
    });

    test('traduit les filtres en paramètres de requête', () {
      const filter = TxFilter(accountId: 'a', isChecked: false, query: '  kebab ', minAmount: 5);
      expect(filter.toQuery(), {'accountId': 'a', 'isChecked': 'false', 'q': 'kebab', 'minAmount': 5});
      expect(filter.activeCount, 1);
      expect(filter.copyWith(isChecked: null).toQuery().containsKey('isChecked'), isFalse);
      expect(filter, const TxFilter(accountId: 'a', isChecked: false, query: '  kebab ', minAmount: 5));
    });

    test('envoie un transfert au bon format', () {
      const draft = TxDraft(accountId: 'a', type: TxType.transfer, amount: -50, date: '2026-11-15', toAccountId: 'b');
      expect(draft.toTransferJson(), containsPair('fromAccountId', 'a'));
      expect(draft.toTransferJson(), containsPair('toAccountId', 'b'));
      expect(draft.toTransferJson()['amount'], 50);
      expect(draft.toTransferJson().containsKey('counterparty'), isFalse);
    });
  });

  group('client API', () {
    test('ne renouvelle la session qu’une fois quand plusieurs requêtes expirent ensemble', () async {
      final tokens = MemoryTokenStore(access: 'vieux', refresh: 'refresh-0');
      final server = FakeServer((request, body) {
        if (request.path == '/auth/refresh') return {'accessToken': 'neuf', 'refreshToken': 'refresh-1', 'expiresIn': 900};
        return request.headers['Authorization'] == 'Bearer neuf' ? {'ok': true} : const FakeError(401, 'Session expirée', 'token_expired');
      });
      final client = ApiClient(baseUrl: 'https://api.test', tokens: tokens, adapter: server);

      final results = await Future.wait([client.getJson('/a'), client.getJson('/b'), client.getJson('/c')]);

      expect(results, everyElement({'ok': true}));
      expect(server.count('POST', '/auth/refresh'), 1);
      expect(tokens.refresh, 'refresh-1');
    });

    test('ferme la session quand le serveur refuse le renouvellement', () async {
      final tokens = MemoryTokenStore(access: 'vieux', refresh: 'révoqué');
      var expired = 0;
      final server = FakeServer((request, body) => const FakeError(401, 'Session expirée'));
      final client = ApiClient(baseUrl: 'https://api.test', tokens: tokens, adapter: server, onSessionExpired: () => expired++);

      await expectLater(client.getJson('/a'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
      expect(expired, 1);
      expect(tokens.refresh, isNull);
      // Le renouvellement lui-même n'est jamais rejoué en boucle.
      expect(server.count('POST', '/auth/refresh'), 1);
    });

    test('garde la session quand le réseau tombe pendant le renouvellement', () async {
      final tokens = MemoryTokenStore(access: 'vieux', refresh: 'refresh-0');
      final server = FakeServer((request, body) {
        if (request.path == '/auth/refresh') throw const SocketException('hors ligne');
        return const FakeError(401, 'Session expirée');
      });
      final client = ApiClient(baseUrl: 'https://api.test', tokens: tokens, adapter: server);

      await expectLater(client.getJson('/a'), throwsA(isA<ApiException>()));
      expect(tokens.refresh, 'refresh-0');
    });

    test('n’envoie pas de jeton sur les routes publiques', () async {
      String? header;
      final server = FakeServer((request, body) {
        header = request.headers['Authorization'] as String?;
        return {'accessToken': 'a', 'refreshToken': 'r', 'user': userJson()};
      });
      final client = ApiClient(baseUrl: 'https://api.test', tokens: MemoryTokenStore(access: 'vieux', refresh: 'x'), adapter: server);
      await client.post('/auth/login', {'email': 'a@b.fr', 'password': 'x'});
      expect(header, isNull);
    });

    test('traduit les erreurs en messages présentables', () {
      final offline = ApiException.from(DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError));
      expect(offline.offline, isTrue);
      expect(offline.message, contains('réseau'));

      final server = ApiException.from(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: 409, data: {'error': 'Un compte existe déjà avec cet email', 'code': 'conflict'}),
        ),
      );
      expect(server.message, 'Un compte existe déjà avec cet email');
      expect(server.status, 409);
    });
  });
}
