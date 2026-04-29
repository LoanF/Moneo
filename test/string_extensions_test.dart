import 'package:flutter_test/flutter_test.dart';
import 'package:moneo/core/extensions/string_extensions.dart';

void main() {
  group('StringExtension.capitalize', () {
    test('met en majuscule la première lettre', () {
      expect('hello'.capitalize(), 'Hello');
    });

    test('conserve le reste en minuscule', () {
      expect('hELLO'.capitalize(), 'HELLO');
    });

    test('ne touche pas une chaîne déjà capitalisée', () {
      expect('World'.capitalize(), 'World');
    });

    test('retourne la chaîne vide inchangée', () {
      expect(''.capitalize(), '');
    });

    test('fonctionne avec un seul caractère', () {
      expect('a'.capitalize(), 'A');
    });

    test('fonctionne avec un seul caractère majuscule', () {
      expect('Z'.capitalize(), 'Z');
    });

    test('fonctionne avec des chiffres', () {
      expect('42abc'.capitalize(), '42abc');
    });
  });
}
