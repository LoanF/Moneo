import 'package:dio/dio.dart';

String handleError(Object e) {
  if (e is DioException) return _fromDio(e);
  final msg = e.toString();
  if (msg.startsWith('Exception: ')) return msg.substring(11);
  return msg;
}

String _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
      return 'Connexion trop lente. Vérifiez votre réseau.';
    case DioExceptionType.receiveTimeout:
      return 'Le serveur met trop de temps à répondre.';
    case DioExceptionType.connectionError:
      return 'Impossible de contacter le serveur. Vérifiez votre connexion.';
    case DioExceptionType.cancel:
      return 'Requête annulée.';
    case DioExceptionType.badResponse:
      return _fromBadResponse(e);
    default:
      return 'Une erreur inattendue est survenue.';
  }
}

String _fromBadResponse(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final msg = data['error'] ?? data['message'];
    if (msg is String && msg.isNotEmpty) return msg;
  }
  switch (e.response?.statusCode) {
    case 400: return 'Données invalides.';
    case 401: return 'Session expirée. Reconnectez-vous.';
    case 403: return 'Accès refusé.';
    case 404: return 'Ressource introuvable.';
    case 409: return 'Un conflit est survenu.';
    case 422: return 'Données incorrectes.';
    case 429: return 'Trop de tentatives. Réessayez dans quelques minutes.';
    case 500:
    case 502:
    case 503: return 'Erreur serveur. Réessayez plus tard.';
    default: return 'Erreur réseau (${e.response?.statusCode}).';
  }
}
