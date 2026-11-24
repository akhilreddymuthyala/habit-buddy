// lib/widgets/moon_phase_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/moon_phase_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

class MoonPhaseWidget extends StatelessWidget {
  const MoonPhaseWidget({
    super.key,
    required this.date,
    this.size = 64,
  });

  final DateTime date;
  final double size;

  void _showDetails(BuildContext context, MoonPhaseInfo info) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        final pct = (info.illumination * 100).round();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CustomPaint(
                    painter: MoonPainter(
                      illumination: info.illumination,
                      isWaxing: info.isWaxing,
                      isDark: theme.brightness == Brightness.dark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  info.phaseName,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '$pct% illuminated \u00b7 ${info.isWaxing ? "Waxing" : "Waning"}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        _detailRow(ctx, 'Moon age',
                            '${info.age.toStringAsFixed(1)} days'),
                        const Divider(height: 16),
                        _detailRow(ctx, 'Next full moon',
                            formatShortDate(info.nextFullMoon)),
                        const Divider(height: 16),
                        _detailRow(ctx, 'Next new moon',
                            formatShortDate(info.nextNewMoon)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = MoonPhaseService.instance.compute(date);
    final theme = Theme.of(context);
    final pct = (info.illumination * 100).round();
    final semantics = 'Moon phase: ${info.phaseName}, $pct% lit';

    return Semantics(
      label: semantics,
      button: true,
      child: InkWell(
        onTap: () => _showDetails(context, info),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size * 0.72,
                height: size * 0.72,
                child: CustomPaint(
                  painter: MoonPainter(
                    illumination: info.illumination,
                    isWaxing: info.isWaxing,
                    isDark: theme.brightness == Brightness.dark,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                info.phaseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoonPainter extends CustomPainter {
  const MoonPainter({
    required this.illumination,
    required this.isWaxing,
    required this.isDark,
  });

  final double illumination;
  final bool isWaxing;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 1.5;
    if (r <= 0) return;

    // Dark unlit disc
    final darkColor = isDark ? const Color(0xFF28251D) : const Color(0xFF38352D);
    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, darkPaint);

    // Lit portion
    final litColor = isDark ? const Color(0xFFFFECAC) : const Color(0xFFFFF0B8);
    final litPaint = Paint()
      ..color = litColor
      ..style = PaintingStyle.fill;

    if (illumination >= 0.999) {
      canvas.drawCircle(Offset(cx, cy), r, litPaint);
    } else if (illumination > 0.001) {
      final path = Path();
      final k = 2.0 * illumination - 1.0; // -1 to 1
      final rx = (r * k.abs()).clamp(0.001, r);

      if (isWaxing) {
        // Lit on the right (Northern hemisphere)
        path.moveTo(cx, cy - r);
        // Outer right semicircle: top -> bottom
        path.arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -math.pi / 2,
          math.pi,
          false,
        );
        // Terminator from bottom back to top
        final sweep = (k >= 0) ? math.pi : -math.pi;
        path.arcTo(
          Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: r * 2),
          math.pi / 2,
          sweep,
          false,
        );
      } else {
        // Lit on the left (waning)
        path.moveTo(cx, cy - r);
        // Outer left semicircle: top -> bottom
        path.arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -math.pi / 2,
          -math.pi,
          false,
        );
        // Terminator from bottom back to top
        final sweep = (k >= 0) ? -math.pi : math.pi;
        path.arcTo(
          Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: r * 2),
          math.pi / 2,
          sweep,
          false,
        );
      }
      path.close();
      canvas.drawPath(path, litPaint);
    }

    // Subtle outline
    final outlinePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(cx, cy), r, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant MoonPainter oldDelegate) {
    return oldDelegate.illumination != illumination ||
        oldDelegate.isWaxing != isWaxing ||
        oldDelegate.isDark != isDark;
  }
}
