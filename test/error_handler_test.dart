import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneo/core/utils/error_handler.dart';

void main() {
  group('handleError', () {
    test('supprime le préfixe "Exception: "', () {
      final result = handleError(Exception('Données invalides'));
      expect(result, 'Données invalides');
    });

    test('retourne le message brut si pas de préfixe Exception', () {
      final result = handleError(StateError('état inattendu'));
      expect(result, contains('état inattendu'));
    });

    test('gère un DioException de type connectionTimeout', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(handleError(ex), 'Connexion trop lente. Vérifiez votre réseau.');
    });

    test('gère un DioException de type sendTimeout', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );
      expect(handleError(ex), 'Connexion trop lente. Vérifiez votre réseau.');
    });

    test('gère un DioException de type receiveTimeout', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );
      expect(handleError(ex), 'Le serveur met trop de temps à répondre.');
    });

    test('gère un DioException de type connectionError', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      expect(handleError(ex), 'Impossible de contacter le serveur. Vérifiez votre connexion.');
    });

    test('gère un DioException de type cancel', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );
      expect(handleError(ex), 'Requête annulée.');
    });

    test('gère un DioException de type unknown', () {
      final ex = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.unknown,
      );
      expect(handleError(ex), 'Une erreur inattendue est survenue.');
    });
  });

  group('handleError – badResponse', () {
    Response<dynamic> _response(int statusCode, {Map<String, dynamic>? data}) {
      return Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: statusCode,
        data: data,
      );
    }

    DioException _badResponse(int statusCode, {Map<String, dynamic>? data}) {
      return DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: _response(statusCode, data: data),
      );
    }

    test('400 → Données invalides', () {
      expect(handleError(_badResponse(400)), 'Données invalides.');
    });

    test('401 → Session expirée', () {
      expect(handleError(_badResponse(401)), 'Session expirée. Reconnectez-vous.');
    });

    test('403 → Accès refusé', () {
      expect(handleError(_badResponse(403)), 'Accès refusé.');
    });

    test('404 → Ressource introuvable', () {
      expect(handleError(_badResponse(404)), 'Ressource introuvable.');
    });

    test('409 → Un conflit est survenu', () {
      expect(handleError(_badResponse(409)), 'Un conflit est survenu.');
    });

    test('422 → Données incorrectes', () {
      expect(handleError(_badResponse(422)), 'Données incorrectes.');
    });

    test('429 → Trop de tentatives', () {
      expect(handleError(_badResponse(429)), 'Trop de tentatives. Réessayez dans quelques minutes.');
    });

    test('500 → Erreur serveur', () {
      expect(handleError(_badResponse(500)), 'Erreur serveur. Réessayez plus tard.');
    });

    test('502 → Erreur serveur', () {
      expect(handleError(_badResponse(502)), 'Erreur serveur. Réessayez plus tard.');
    });

    test('503 → Erreur serveur', () {
      expect(handleError(_badResponse(503)), 'Erreur serveur. Réessayez plus tard.');
    });

    test('code inconnu affiche le code HTTP', () {
      final result = handleError(_badResponse(418));
      expect(result, 'Erreur réseau (418).');
    });

    test('message "error" dans le body est retourné directement', () {
      final result = handleError(_badResponse(400, data: {'error': 'Email déjà utilisé'}));
      expect(result, 'Email déjà utilisé');
    });

    test('message "message" dans le body est retourné directement', () {
      final result = handleError(_badResponse(422, data: {'message': 'Champ requis manquant'}));
      expect(result, 'Champ requis manquant');
    });

    test('body vide tombe sur le code HTTP', () {
      final result = handleError(_badResponse(400, data: {}));
      expect(result, 'Données invalides.');
    });
  });
}
