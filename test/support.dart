import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:moneo/app.dart';
import 'package:moneo/core/api_client.dart';
import 'package:moneo/core/local_store.dart';
import 'package:moneo/state/providers.dart';

typedef Handler = Object? Function(RequestOptions request, Object? body);

/// Faux serveur : chaque requête est confiée à `handler`, qui renvoie le JSON de réponse,
/// un [FakeError] pour un statut d'erreur, ou lève [SocketException] pour simuler une coupure.
class FakeServer implements HttpClientAdapter {
  FakeServer(this.handler);
  Handler handler;
  final calls = <String>[];

  int count(String method, String path) => calls.where((c) => c == '$method $path').length;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add('${options.method} ${options.path}');
    Object? body = options.data;
    if (body is String && body.isNotEmpty) body = jsonDecode(body);
    final result = handler(options, body);
    if (result is FakeError) {
      return ResponseBody.fromString(jsonEncode({'error': result.message, 'code': result.code}), result.status, headers: _json);
    }
    return ResponseBody.fromString(jsonEncode(result ?? {'success': true}), 200, headers: _json);
  }

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

class FakeError {
  const FakeError(this.status, this.message, [this.code]);
  final int status;
  final String message;
  final String? code;
}

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore({this.access, this.refresh});
  String? access;
  String? refresh;

  @override
  Future<({String? access, String? refresh})> read() async => (access: access, refresh: refresh);

  @override
  Future<void> write({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async => access = refresh = null;
}

// ── Jeu de données, calqué sur le classeur de référence ──────────────────────

const _courant = '11111111-1111-4111-8111-111111111111';
const _livret = '22222222-2222-4222-8222-222222222222';
const _restaurant = '33333333-3333-4333-8333-333333333333';
const _fastFood = '44444444-4444-4444-8444-444444444444';
const _voiture = '55555555-5555-4555-8555-555555555555';
const _carte = '66666666-6666-4666-8666-666666666666';
const _cheque = '77777777-7777-4777-8777-777777777777';

Map<String, dynamic> userJson({bool verified = true, bool setup = true}) => {
      'id': '99999999-9999-4999-8999-999999999999',
      'username': 'Loan',
      'email': 'loan@moneo.test',
      'photoUrl': null,
      'hasCompletedSetup': setup,
      'emailVerified': verified,
      'hasPassword': true,
      'settings': {'currency': 'EUR', 'monthStartDay': 1, 'recurringMode': 'month_start', 'skipNote': false},
      'notificationPrefs': <String, dynamic>{},
    };

Map<String, dynamic> accountJson(String id, String name, double balance, {double pointed = 0, int unchecked = 0, double uncheckedDebit = 0}) => {
      'id': id,
      'name': name,
      'type': 'checking',
      'initialBalance': 284.42,
      'sortOrder': 0,
      'includeInTotal': true,
      'archived': false,
      'balance': balance,
      'pointedBalance': pointed,
      'todayBalance': balance + 92.5,
      'uncheckedCredit': 0,
      'uncheckedDebit': uncheckedDebit,
      'uncheckedCount': unchecked,
      'transactionCount': 2383,
    };

Map<String, dynamic> bootstrapJson({bool verified = true, bool setup = true}) => {
      'user': userJson(verified: verified, setup: setup),
      'accounts': [
        accountJson(_courant, 'Compte courant', 928.60, pointed: 1036.46, unchecked: 3, uncheckedDebit: 440.01),
        accountJson(_livret, 'Livret A', 8245.41, pointed: 8245.41),
      ],
      'categories': [
        {'id': _restaurant, 'name': 'Restaurant', 'iconCode': 'restaurant', 'colorValue': 0xFFE91E63, 'parentId': null, 'sortOrder': 0},
        {'id': _fastFood, 'name': 'Fast-food', 'iconCode': 'restaurant', 'colorValue': 0xFFE91E63, 'parentId': _restaurant, 'sortOrder': 0},
        {'id': _voiture, 'name': 'Voiture', 'iconCode': 'directions_car', 'colorValue': 0xFF2196F3, 'parentId': null, 'sortOrder': 1},
      ],
      'paymentMethods': [
        {'id': _carte, 'name': 'Carte bancaire', 'kind': 'card', 'defaultDirection': 'expense', 'sortOrder': 0},
        {'id': _cheque, 'name': 'Chèque', 'kind': 'cheque', 'defaultDirection': 'expense', 'sortOrder': 1},
      ],
      'chequebooks': [
        {'id': '88888888-8888-4888-8888-888888888888', 'name': 'Chéquier', 'accountId': null, 'nextNumber': 31, 'isActive': true},
      ],
      'recurringPayments': [
        {'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'accountId': _courant, 'categoryId': null, 'paymentMethodId': null, 'name': 'Loyer', 'amount': 350, 'type': 'expense', 'dayOfMonth': 5, 'monthlyAmounts': {'12': 360.5}, 'isActive': true},
      ],
      'budgets': [
        {'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'categoryId': _restaurant, 'amount': 100, 'alertThreshold': 80, 'periodFrom': '2026-11-01', 'periodTo': '2026-11-30', 'spent': 86, 'remaining': 14, 'percent': 86, 'projected': 184.3},
      ],
      'unreadNotifications': 2,
      'pendingRecurring': 0,
    };

Map<String, dynamic> txJson(String id, double amount, String date, {String? note, String? categoryId, String? methodId, String? cheque, bool checked = false}) => {
      'id': id,
      'accountId': _courant,
      'categoryId': categoryId,
      'paymentMethodId': methodId,
      'chequeNumber': cheque,
      'amount': amount,
      'type': amount > 0 ? 'income' : 'expense',
      'date': date,
      'note': note,
      'isChecked': checked,
      'transferId': null,
      'counterparty': null,
      'recurringPaymentId': null,
      'deletedAt': null,
    };

Map<String, dynamic> transactionsJson() {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final items = [
    txJson('c0000000-0000-4000-8000-000000000001', -68.01, today, note: 'TotalEnergies', categoryId: _voiture, methodId: _carte),
    txJson('c0000000-0000-4000-8000-000000000002', -22, today, note: 'Coiffeur', methodId: _cheque, cheque: '30'),
    txJson('c0000000-0000-4000-8000-000000000003', -7.6, '2026-10-27', note: 'Mc-Do', categoryId: _fastFood, methodId: _carte),
    txJson('c0000000-0000-4000-8000-000000000004', 1500, '2026-10-28', note: 'Salaire'),
  ];
  return {'items': items, 'total': items.length, 'sumCredit': 1500, 'sumDebit': 97.61};
}

/// Réponses par défaut d'un serveur en bon état, pour un utilisateur déjà installé.
Object? defaultHandler(RequestOptions request, Object? body) => switch ('${request.method} ${request.path}') {
      'GET /bootstrap' => bootstrapJson(),
      'GET /transactions' => transactionsJson(),
      'GET /transactions/suggestions' => <Object>[],
      'GET /recurring-payments/pending' => <Object>[],
      'POST /auth/login' => {'accessToken': 'access-1', 'refreshToken': 'refresh-1', 'expiresIn': 900, 'user': userJson()},
      _ => {'success': true},
    };

class TestApp {
  TestApp({Handler? handler, bool signedIn = true})
      : server = FakeServer(handler ?? defaultHandler),
        tokens = MemoryTokenStore(access: signedIn ? 'access-0' : null, refresh: signedIn ? 'refresh-0' : null),
        store = MemoryLocalStore();

  final FakeServer server;
  final MemoryTokenStore tokens;
  final MemoryLocalStore store;

  late final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      tokenStoreProvider.overrideWithValue(tokens),
      localStoreProvider.overrideWithValue(store),
      realtimeEnabledProvider.overrideWithValue(false),
      apiClientProvider.overrideWith((ref) {
        final client = ApiClient(baseUrl: 'https://api.test', tokens: tokens, adapter: server);
        client.onSessionExpired = () => ref.read(sessionProvider.notifier).expire();
        return client;
      }),
    ],
  );

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 844), bool light = false}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(container.dispose);
    // Les captures se font en thème sombre, l'identité de l'app.
    if (const bool.fromEnvironment('SCREENSHOTS') && !light) {
      container.read(devicePrefsProvider.notifier).update((p) => p.copyWith(themeMode: ThemeMode.dark));
    }
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MoneoApp()));
    await settle(tester);
  }
}

/// Laisse passer les requêtes et les animations sans attendre les animations infinies (squelettes).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

bool _ready = false;

/// Charge les vraies polices (Roboto, icônes) pour que les captures soient lisibles.
Future<void> prepareTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_ready) return;
  _ready = true;
  Intl.defaultLocale = 'fr_FR';
  await initializeDateFormatting('fr_FR');

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final fonts = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  if (!fonts.existsSync()) return;
  Future<ByteData> bytes(String name) async => ByteData.view((await File('${fonts.path}/$name').readAsBytes()).buffer);
  final roboto = FontLoader('Roboto');
  for (final file in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
    roboto.addFont(bytes(file));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')..addFont(bytes('materialicons-regular.otf'));
  await icons.load();
}
