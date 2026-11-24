// lib/services/moon_phase_service.dart
import 'dart:math' as math;

enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent;

  String get displayName => switch (this) {
        MoonPhase.newMoon => 'New Moon',
        MoonPhase.waxingCrescent => 'Waxing Crescent',
        MoonPhase.firstQuarter => 'First Quarter',
        MoonPhase.waxingGibbous => 'Waxing Gibbous',
        MoonPhase.fullMoon => 'Full Moon',
        MoonPhase.waningGibbous => 'Waning Gibbous',
        MoonPhase.lastQuarter => 'Last Quarter',
        MoonPhase.waningCrescent => 'Waning Crescent',
      };
}

class MoonPhaseInfo {
  const MoonPhaseInfo({
    required this.age,
    required this.illumination,
    required this.isWaxing,
    required this.phase,
    required this.nextNewMoon,
    required this.nextFullMoon,
  });

  /// Moon's age in days within the synodic month (0 <= age < 29.530588853).
  final double age;

  /// Fraction of the lunar surface illuminated as seen from Earth (0.0 to 1.0).
  final double illumination;

  /// True when the moon is waxing (between new and full), false when waning.
  final bool isWaxing;

  /// The 8-phase astronomical classification.
  final MoonPhase phase;

  /// Display name of the current moon phase.
  String get phaseName => phase.displayName;

  /// Estimated calendar date of the next new moon.
  final DateTime nextNewMoon;

  /// Estimated calendar date of the next full moon.
  final DateTime nextFullMoon;
}

/// Offline moon phase calculations using standard mean-lunation astronomy.
class MoonPhaseService {
  MoonPhaseService._();
  static final MoonPhaseService instance = MoonPhaseService._();

  /// Reference new moon: January 6, 2000 at 18:14 UTC.
  static final DateTime referenceNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

  /// Mean synodic month in days.
  static const double synodicMonth = 29.530588853;

  /// Computes the moon phase for the given local calendar date evaluated at local noon.
  MoonPhaseInfo compute(DateTime date) {
    final localNoon = DateTime(date.year, date.month, date.day, 12, 0, 0);
    final msSinceRef =
        localNoon.toUtc().difference(referenceNewMoon).inMilliseconds;
    final totalDays = msSinceRef / 86400000.0;

    var age = totalDays % synodicMonth;
    if (age < 0) {
      age += synodicMonth;
    }

    // Illumination fraction (0..1) using cosine of phase angle.
    final theta = 2.0 * math.pi * (age / synodicMonth);
    final illumination = ((1.0 - math.cos(theta)) / 2.0).clamp(0.0, 1.0);

    // Waxing is true between new moon and full moon.
    final halfMonth = synodicMonth / 2.0;
    final isWaxing = age < halfMonth;

    // 8 phase sectors centered on 0, 45, 90, 135, 180, 225, 270, 315 degrees.
    // Each slice is synodicMonth / 8, so half-slice is synodicMonth / 16.
    final halfSlice = synodicMonth / 16.0;
    final MoonPhase phase;
    if (age < halfSlice || age >= synodicMonth - halfSlice) {
      phase = MoonPhase.newMoon;
    } else if (age < 3.0 * halfSlice) {
      phase = MoonPhase.waxingCrescent;
    } else if (age < 5.0 * halfSlice) {
      phase = MoonPhase.firstQuarter;
    } else if (age < 7.0 * halfSlice) {
      phase = MoonPhase.waxingGibbous;
    } else if (age < 9.0 * halfSlice) {
      phase = MoonPhase.fullMoon;
    } else if (age < 11.0 * halfSlice) {
      phase = MoonPhase.waningGibbous;
    } else if (age < 13.0 * halfSlice) {
      phase = MoonPhase.lastQuarter;
    } else {
      phase = MoonPhase.waningCrescent;
    }

    // Calculate next new moon date (target age = synodicMonth)
    var daysToNextNew = synodicMonth - age;
    while (daysToNextNew <= 0.5) {
      daysToNextNew += synodicMonth;
    }
    final nextNewDate = _addDays(date, daysToNextNew);

    // Calculate next full moon date (target age = halfMonth)
    var daysToNextFull = halfMonth - age;
    while (daysToNextFull <= 0.5) {
      daysToNextFull += synodicMonth;
    }
    final nextFullDate = _addDays(date, daysToNextFull);

    return MoonPhaseInfo(
      age: age,
      illumination: illumination,
      isWaxing: isWaxing,
      phase: phase,
      nextNewMoon: nextNewDate,
      nextFullMoon: nextFullDate,
    );
  }

  DateTime _addDays(DateTime base, double days) {
    final d = DateTime(base.year, base.month, base.day);
    return d.add(Duration(days: days.round()));
  }
}
