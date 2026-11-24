// test/moon_phase_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_buddy/services/moon_phase_service.dart';

void main() {
  final service = MoonPhaseService.instance;

  test('age is always within 0..29.530588853 and illumination within 0..1', () {
    // Check across a full year and a leap year
    var d = DateTime(2024, 1, 1);
    for (var i = 0; i < 730; i++) {
      final info = service.compute(d);
      expect(info.age, greaterThanOrEqualTo(0.0));
      expect(info.age, lessThan(MoonPhaseService.synodicMonth));
      expect(info.illumination, greaterThanOrEqualTo(0.0));
      expect(info.illumination, lessThanOrEqualTo(1.0));
      d = d.add(const Duration(days: 1));
    }
  });

  test('2024-01-11 is New Moon and 2024-01-25 is Full Moon', () {
    final newMoonInfo = service.compute(DateTime(2024, 1, 11));
    expect(newMoonInfo.phase, MoonPhase.newMoon);
    expect(newMoonInfo.phaseName, 'New Moon');
    expect(newMoonInfo.illumination, lessThan(0.1));

    final fullMoonInfo = service.compute(DateTime(2024, 1, 25));
    expect(fullMoonInfo.phase, MoonPhase.fullMoon);
    expect(fullMoonInfo.phaseName, 'Full Moon');
    expect(fullMoonInfo.illumination, greaterThan(0.9));
  });

  test('waxing is true between new and full, false after', () {
    // Test right after new moon
    final waxingCrescent = service.compute(DateTime(2024, 1, 15));
    expect(waxingCrescent.isWaxing, isTrue);

    // Test first quarter
    final firstQuarter = service.compute(DateTime(2024, 1, 18));
    expect(firstQuarter.isWaxing, isTrue);

    // Test after full moon
    final waningGibbous = service.compute(DateTime(2024, 1, 28));
    expect(waningGibbous.isWaxing, isFalse);

    // Test last quarter
    final lastQuarter = service.compute(DateTime(2024, 2, 2));
    expect(lastQuarter.isWaxing, isFalse);
  });

  test('next full and new moon dates are in the future and consistent with cycle', () {
    final dates = [
      DateTime(2024, 1, 11),
      DateTime(2024, 1, 25),
      DateTime(2024, 6, 15),
      DateTime(2024, 12, 31),
    ];

    for (final testDate in dates) {
      final info = service.compute(testDate);
      expect(info.nextNewMoon.isAfter(testDate), isTrue,
          reason: 'Next new moon from $testDate should be in the future');
      expect(info.nextFullMoon.isAfter(testDate), isTrue,
          reason: 'Next full moon from $testDate should be in the future');

      // The cycle difference between consecutive same events is ~29-30 days
      final daysToNew = info.nextNewMoon.difference(testDate).inDays;
      expect(daysToNew, greaterThanOrEqualTo(1));
      expect(daysToNew, lessThanOrEqualTo(32));

      final daysToFull = info.nextFullMoon.difference(testDate).inDays;
      expect(daysToFull, greaterThanOrEqualTo(1));
      expect(daysToFull, lessThanOrEqualTo(32));
    }
  });

  test('stable across month/year boundaries and a leap day', () {
    // Transition over leap day: 2024-02-28, 2024-02-29, 2024-03-01
    final feb28 = service.compute(DateTime(2024, 2, 28));
    final feb29 = service.compute(DateTime(2024, 2, 29));
    final mar01 = service.compute(DateTime(2024, 3, 1));

    // Age increases by ~1 day per day
    expect((feb29.age - feb28.age - 1.0).abs(), lessThan(0.05));
    expect((mar01.age - feb29.age - 1.0).abs(), lessThan(0.05));

    // Year boundary: 2024-12-31 to 2025-01-01
    final dec31 = service.compute(DateTime(2024, 12, 31));
    final jan01 = service.compute(DateTime(2025, 1, 1));
    final dayDelta = (jan01.age - dec31.age);
    final normalizedDelta = dayDelta < 0 ? dayDelta + MoonPhaseService.synodicMonth : dayDelta;
    expect((normalizedDelta - 1.0).abs(), lessThan(0.05));
  });
}
