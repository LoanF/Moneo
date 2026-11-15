import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:moneo/app.dart';
import 'package:moneo/state/providers.dart';
import 'package:moneo/ui/auth/auth_pages.dart';
import 'package:moneo/ui/home/home_page.dart';
import 'package:moneo/ui/widgets/common.dart';

import 'support.dart';

/// Les captures d'écran ne sont produites qu'à la demande (`--dart-define=SCREENSHOTS=true
/// --update-goldens`) : leur rendu dépend de la plateforme, elles ne servent pas de test.
const _screenshots = bool.fromEnvironment('SCREENSHOTS');

Future<void> _shot(WidgetTester tester, String name) async {
  if (_screenshots) await expectLater(find.byType(MoneoApp), matchesGoldenFile('screens/$name.png'));
}

TextField _field(WidgetTester tester, String label) => tester.widget<TextField>(find.widgetWithText(TextField, label));

void main() {
  setUpAll(prepareTests);

  group('connexion', () {
    testWidgets('les champs sont reconnus par les gestionnaires de mots de passe', (tester) async {
      await TestApp(signedIn: false).pump(tester);

      expect(find.byType(LoginPage), findsOneWidget);
      // Les deux champs partagent un même groupe : le gestionnaire les remplit et les enregistre ensemble.
      expect(find.ancestor(of: find.widgetWithText(TextField, 'Mot de passe'), matching: find.byType(AutofillGroup)), findsOneWidget);
      expect(find.ancestor(of: find.widgetWithText(TextField, 'Adresse email'), matching: find.byType(AutofillGroup)), findsOneWidget);

      final email = _field(tester, 'Adresse email');
      expect(email.autofillHints, containsAll([AutofillHints.username, AutofillHints.email]));
      expect(email.keyboardType, TextInputType.emailAddress);
      expect(email.autocorrect, isFalse);

      final password = _field(tester, 'Mot de passe');
      expect(password.autofillHints, [AutofillHints.password]);
      expect(password.obscureText, isTrue);
      await _shot(tester, 'login_dark');
    });

    testWidgets('l’inscription demande un nouvel identifiant et un nouveau mot de passe', (tester) async {
      await TestApp(signedIn: false).pump(tester);
      await tester.tap(find.text('Créer un compte'));
      await settle(tester);

      expect(_field(tester, 'Adresse email').autofillHints, containsAll([AutofillHints.newUsername, AutofillHints.email]));
      expect(_field(tester, 'Mot de passe').autofillHints, [AutofillHints.newPassword]);
      // Un seul champ de mot de passe : rien à retaper, le gestionnaire peut générer le sien.
      expect(find.byType(PasswordField), findsOneWidget);
    });

    testWidgets('valide les champs avant d’appeler le serveur', (tester) async {
      final app = TestApp(signedIn: false);
      await app.pump(tester);
      await tester.tap(find.text('Se connecter'));
      await settle(tester);

      expect(find.text('Saisissez votre adresse email'), findsOneWidget);
      expect(find.text('Saisissez votre mot de passe'), findsOneWidget);
      expect(app.server.count('POST', '/auth/login'), 0);
    });

    testWidgets('connecte, enregistre les jetons et affiche les comptes', (tester) async {
      final app = TestApp(signedIn: false);
      await app.pump(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Adresse email'), ' Loan@Moneo.test ');
      await tester.enterText(find.widgetWithText(TextField, 'Mot de passe'), 'correct horse battery');
      await tester.tap(find.text('Se connecter'));
      await settle(tester);

      expect(app.tokens.refresh, 'refresh-1');
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Compte courant'), findsOneWidget);
    });

    testWidgets('affiche le message du serveur en cas d’échec', (tester) async {
      final app = TestApp(
        signedIn: false,
        handler: (request, body) => request.path == '/auth/login' ? const FakeError(401, 'Email ou mot de passe incorrect') : defaultHandler(request, body),
      );
      await app.pump(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Adresse email'), 'loan@moneo.test');
      await tester.enterText(find.widgetWithText(TextField, 'Mot de passe'), 'mauvais');
      await tester.tap(find.text('Se connecter'));
      await settle(tester);

      expect(find.text('Email ou mot de passe incorrect'), findsOneWidget);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renvoie à la vérification de l’adresse puis au premier lancement', (tester) async {
      var verified = false;
      final app = TestApp(
        handler: (request, body) => switch ('${request.method} ${request.path}') {
          'GET /bootstrap' => bootstrapJson(verified: verified, setup: false),
          'POST /auth/verify-email' => userJson(verified: verified = true, setup: false),
          _ => defaultHandler(request, body),
        },
      );
      await app.pump(tester);
      expect(find.text('Vérifiez votre adresse'), findsOneWidget);
      expect(_field(tester, 'Code à 6 chiffres').autofillHints, [AutofillHints.oneTimeCode]);

      await tester.enterText(find.widgetWithText(TextField, 'Code à 6 chiffres'), '123456');
      await settle(tester);
      expect(find.textContaining('Bienvenue'), findsOneWidget);
      expect(find.text('Importer mon classeur'), findsOneWidget);
    });
  });

  group('accueil', () {
    testWidgets('montre les trois soldes et les opérations à pointer', (tester) async {
      final app = TestApp();
      await app.pump(tester, light: true);

      // Le grand chiffre est le solde du compte affiché, pas un total de tous les comptes.
      expect(find.text('1 036,46 €'), findsOneWidget);
      expect(find.text('928,60 €'), findsOneWidget);
      expect(find.text('À pointer · 3'), findsOneWidget);
      expect(find.text('TotalEnergies'), findsOneWidget);
      expect(find.text('Chèque n° 30'), findsOneWidget);
      // Une dépense porte toujours son signe : la couleur ne fait que le souligner.
      expect(find.text('−68,01 €'), findsOneWidget);
      // La vue par défaut ne demande que les opérations non pointées.
      expect(app.server.calls, contains('GET /transactions'));
      await _shot(tester, 'home_light');
    });

    testWidgets('s’affiche en thème sombre', (tester) async {
      final app = TestApp();
      app.container.read(devicePrefsProvider.notifier).update((p) => p.copyWith(themeMode: ThemeMode.dark));
      await app.pump(tester);
      expect(Theme.of(tester.element(find.byType(HomePage))).brightness, Brightness.dark);
      await _shot(tester, 'home_dark');
    });

    testWidgets('pointe une opération d’un appui sur son poinçon', (tester) async {
      Object? sent;
      final app = TestApp(
        handler: (request, body) {
          if (request.path == '/transactions/check') sent = body;
          return defaultHandler(request, body);
        },
      );
      await app.pump(tester);
      await tester.tap(find.byType(CheckBadge).first);
      await settle(tester);

      expect(sent, {
        'ids': ['c0000000-0000-4000-8000-000000000001'],
        'isChecked': true,
      });
    });

    testWidgets('masque les montants à la demande', (tester) async {
      await TestApp().pump(tester);
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await settle(tester);
      expect(find.text('928,60 €'), findsNothing);
      expect(find.text('•••• €'), findsWidgets);
    });

    testWidgets('revient à la connexion quand la session est révoquée', (tester) async {
      final app = TestApp(handler: (request, body) => const FakeError(401, 'Session expirée'));
      await app.pump(tester);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(app.tokens.access, isNull);
    });

    testWidgets('s’ouvre sur les dernières données connues quand le réseau manque', (tester) async {
      final app = TestApp(handler: (request, body) => throw const SocketException('hors ligne'));
      await app.store.write('bootstrap', bootstrapJson());
      await app.pump(tester);

      expect(find.text('Compte courant'), findsOneWidget);
      expect(find.text('928,60 €'), findsOneWidget);
      expect(find.textContaining('Hors ligne'), findsOneWidget);
    });
  });

  group('saisie', () {
    Future<void> openEditor(WidgetTester tester) async {
      await tester.tap(find.text('Dépense'));
      await settle(tester);
    }

    testWidgets('envoie une dépense avec sa catégorie par défaut et la date du jour', (tester) async {
      Map<String, dynamic>? created;
      final app = TestApp(
        handler: (request, body) {
          if (request.method == 'POST' && request.path == '/transactions') created = body as Map<String, dynamic>;
          return defaultHandler(request, body);
        },
      );
      await app.pump(tester);
      await openEditor(tester);

      await tester.enterText(find.byKey(const Key('amount')), '12,50');
      await tester.enterText(find.widgetWithText(TextField, 'Libellé (facultatif)'), 'Boulangerie');
      await tester.tap(find.text('Ajouter'));
      await settle(tester);

      expect(created, isNotNull);
      expect(created!['amount'], 12.5);
      expect(created!['type'], 'expense');
      expect(created!['note'], 'Boulangerie');
      expect(created!['id'], isA<String>(), reason: 'identifiant généré côté client pour un rejeu sans doublon');
      expect(find.text('Opération ajoutée'), findsOneWidget);
      await _shot(tester, 'home_after_add');
    });

    testWidgets('refuse un montant vide', (tester) async {
      final app = TestApp();
      await app.pump(tester);
      await openEditor(tester);
      await _shot(tester, 'editor_dark');
      await tester.tap(find.text('Ajouter'));
      await settle(tester);

      expect(find.text('Saisissez un montant supérieur à zéro'), findsOneWidget);
      expect(app.server.count('POST', '/transactions'), 0);
    });

    testWidgets('met l’opération en attente quand le réseau manque, puis l’envoie', (tester) async {
      var online = false;
      Object? replayed;
      final app = TestApp(
        handler: (request, body) {
          if (request.method == 'POST' && request.path == '/transactions' && !online) throw const SocketException('hors ligne');
          if (request.path == '/transactions/batch') {
            replayed = body;
            final items = (body! as Map)['transactions'] as List;
            return {
              'results': [for (final t in items) {'id': (t as Map)['id'], 'status': 'created'}],
            };
          }
          return defaultHandler(request, body);
        },
      );
      await app.pump(tester);
      await openEditor(tester);
      await tester.enterText(find.byKey(const Key('amount')), '9');
      await tester.tap(find.text('Ajouter'));
      await settle(tester);

      expect(app.container.read(outboxProvider), hasLength(1));
      expect(find.textContaining('en attente d’envoi'), findsWidgets);
      expect(await app.store.read('outbox'), hasLength(1), reason: 'la file survit à la fermeture de l’app');

      online = true;
      // Sous l'horloge simulée des tests, on déclenche le rafraîchissement puis on fait avancer le temps.
      unawaited(app.container.read(appDataProvider.notifier).refresh());
      await settle(tester);

      expect(replayed, isNotNull);
      expect(app.container.read(outboxProvider), isEmpty);
    });
  });

  group('navigation', () {
    testWidgets('parcourt les cinq sections sans erreur', (tester) async {
      final app = TestApp(
        handler: (request, body) => switch (request.path) {
          '/stats/summary' => {
              'income': 1500, 'expense': 430, 'net': 1070, 'savingsRate': 71.3, 'transactionCount': 5, 'averageDailyExpense': 14.3,
              'expensesByCategory': [
                {'categoryId': null, 'name': 'Restaurant', 'iconCode': 'restaurant', 'colorValue': 0xFFE91E63, 'total': 430, 'count': 4, 'percent': 100, 'subcategories': [{'id': 'x', 'name': 'Fast-food', 'total': 30, 'count': 1}]},
              ],
              'incomeByCategory': <Object>[], 'expensesByPaymentMethod': <Object>[],
            },
          '/stats/monthly' => [for (var m = 1; m <= 12; m++) {'period': '2026-${m.toString().padLeft(2, '0')}', 'income': 1500, 'expense': 900 + m * 20, 'net': 0}],
          '/stats/balance-history' => {'points': [for (var d = 1; d <= 30; d++) {'date': '2026-10-${d.toString().padLeft(2, '0')}', 'balance': 900 + d * 3.0}]},
          '/stats/forecast' => {
              'currentBalance': 928.6, 'projectedBalance': 520.1, 'lowest': {'date': '2026-12-05', 'balance': 410.2},
              'points': [for (var d = 0; d <= 30; d++) {'date': '2026-11-15', 'balance': 928.6 - d * 13}],
              'upcoming': [{'recurringPaymentId': 'x', 'name': 'Loyer', 'date': '2026-12-05', 'amount': -350, 'accountId': 'a'}],
            },
          _ => defaultHandler(request, body),
        },
      );
      app.container.read(devicePrefsProvider.notifier).update((p) => p.copyWith(themeMode: ThemeMode.dark));
      await app.pump(tester);

      await tester.tap(find.byIcon(Icons.insights_outlined));
      await settle(tester);
      expect(find.text('DÉPENSES PAR CATÉGORIE'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _shot(tester, 'insights_dark');

      await tester.tap(find.byIcon(Icons.event_repeat_outlined));
      await settle(tester);
      expect(find.text('Loyer'), findsOneWidget);
      expect(find.text('montant variable', findRichText: true), findsNothing);
      await _shot(tester, 'recurring_dark');

      await tester.tap(find.byIcon(Icons.savings_outlined));
      await settle(tester);
      expect(find.textContaining('Bientôt atteint'), findsOneWidget);
      await _shot(tester, 'budgets_dark');

      await tester.tap(find.byIcon(Icons.tune_outlined));
      await settle(tester);
      expect(find.text('Import et export'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _shot(tester, 'settings_dark');
    });
  });
}
