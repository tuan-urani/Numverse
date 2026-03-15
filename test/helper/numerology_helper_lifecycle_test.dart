import 'package:flutter_test/flutter_test.dart';
import 'package:test/src/helper/numerology_helper.dart';

void main() {
  group('NumerologyHelper lifecycle formulas', () {
    test('calculateChallenges uses reduced day/month values', () {
      final DateTime birthDate = DateTime(1998, 12, 29);
      final List<int> numbers = NumerologyHelper.calculateChallenges(
        birthDate,
        30,
      ).map((cycle) => cycle.number).toList(growable: false);

      expect(numbers, <int>[1, 7, 6, 6]);
      expect(numbers.every((value) => value >= 0 && value <= 8), true);
    });

    test('calculateChallenges supports challenge number 0', () {
      final DateTime birthDate = DateTime(2000, 11, 11);
      final List<int> numbers = NumerologyHelper.calculateChallenges(
        birthDate,
        25,
      ).map((cycle) => cycle.number).toList(growable: false);

      expect(numbers, <int>[0, 0, 0, 0]);
    });
  });
}
