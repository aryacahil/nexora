import 'package:flutter/material.dart';
import '../../../../../services/uno_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UnoCardWidget
// ─────────────────────────────────────────────────────────────────────────────

class UnoCardWidget extends StatelessWidget {
  final UnoCard card;
  final bool isPlayable;
  final bool isSmall;
  final VoidCallback? onTap;

  const UnoCardWidget({
    super.key,
    required this.card,
    this.isPlayable = false,
    this.isSmall = false,
    this.onTap,
  });

  Color get _baseColor {
    switch (card.color) {
      case 'red':    return const Color(0xFFD32F2F);
      case 'green':  return const Color(0xFF2E7D32);
      case 'blue':   return const Color(0xFF1565C0);
      case 'yellow': return const Color(0xFFF9A825);
      case 'wild':   return const Color(0xFF1A1A2E);
      default:       return Colors.grey.shade800;
    }
  }

  Color get _textColor =>
      card.color == 'yellow' ? const Color(0xFF1A1A1A) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final w = isSmall ? 42.0 : 60.0;
    final h = isSmall ? 62.0 : 88.0;
    final centerFontSize = isSmall ? 13.0 : 20.0;
    final cornerFontSize = isSmall ? 7.0 : 9.5;

    return GestureDetector(
      onTap: isPlayable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        width: w,
        height: h,
        transform: isPlayable
            // ignore: deprecated_member_use
            ? (Matrix4.identity()..translate(0.0, -12.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _baseColor,
          borderRadius: BorderRadius.circular(isSmall ? 7 : 10),
          border: Border.all(
            color: isPlayable ? Colors.white : Colors.white.withValues(alpha: 0.15),
            width: isPlayable ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPlayable
                  ? _baseColor.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: isPlayable ? 14 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Wild: quadrant background
            if (card.isWild)
              ClipRRect(
                borderRadius: BorderRadius.circular(isSmall ? 7 : 10),
                child: CustomPaint(
                  size: Size(w, h),
                  painter: _WildQuadPainter(),
                ),
              ),

            // Center oval highlight (non-wild)
            if (!card.isWild)
              Center(
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    width: w * 0.7,
                    height: h * 0.55,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(w * 0.35),
                    ),
                  ),
                ),
              ),

            // Center value / icon
            Center(child: _buildCenterLabel(centerFontSize)),

            // Top-left corner
            Positioned(
              top: 4,
              left: 5,
              child: _buildCornerLabel(cornerFontSize),
            ),

            // Bottom-right corner (rotated 180)
            Positioned(
              bottom: 4,
              right: 5,
              child: Transform.rotate(
                angle: 3.14159,
                child: _buildCornerLabel(cornerFontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterLabel(double fontSize) {
    if (card.isWild) {
      return Container(
        width: fontSize * 2.2,
        height: fontSize * 2.2,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            card.value == 'wild4'
                ? Icons.add_circle_outline
                : Icons.color_lens_outlined,
            size: fontSize,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      );
    }

    final actionIcon = _actionIcon;
    if (actionIcon != null) {
      return Icon(
        actionIcon,
        size: fontSize * 1.4,
        color: _textColor,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
      );
    }

    return Text(
      card.displayValue,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: _textColor,
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 3)],
      ),
    );
  }

  Widget _buildCornerLabel(double fontSize) {
    if (card.isWild) {
      return Icon(
        card.value == 'wild4' ? Icons.add : Icons.circle,
        size: fontSize + 2,
        color: Colors.white70,
      );
    }
    final actionIcon = _actionIcon;
    if (actionIcon != null) {
      return Icon(
        actionIcon,
        size: fontSize + 1,
        color: _textColor.withValues(alpha: 0.85),
      );
    }
    return Text(
      card.displayValue,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: _textColor.withValues(alpha: 0.85),
      ),
    );
  }

  IconData? get _actionIcon {
    switch (card.value) {
      case 'skip':    return Icons.block;
      case 'reverse': return Icons.swap_horiz;
      default:        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Back
// ─────────────────────────────────────────────────────────────────────────────

class UnoCardBack extends StatelessWidget {
  final bool isSmall;
  const UnoCardBack({super.key, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final w = isSmall ? 36.0 : 50.0;
    final h = isSmall ? 54.0 : 74.0;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D0D1A), Color(0xFF1A1A35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmall ? 6 : 9),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: w * 0.6,
          height: h * 0.55,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade700, width: isSmall ? 1.5 : 2),
            borderRadius: BorderRadius.circular(isSmall ? 3 : 5),
          ),
          child: Center(
            child: Text(
              'UNO',
              style: TextStyle(
                fontSize: isSmall ? 7.5 : 10.5,
                fontWeight: FontWeight.w900,
                color: Colors.red.shade500,
                letterSpacing: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wild Quadrant Painter
// ─────────────────────────────────────────────────────────────────────────────

class _WildQuadPainter extends CustomPainter {
  static const _colors = [
    Color(0xFFD32F2F),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFF9A825),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const pi = 3.14159265358979;

    for (int i = 0; i < 4; i++) {
      final paint = Paint()..color = _colors[i];
      final startAngle = i * pi / 2 - pi / 4;
      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 2),
          startAngle,
          pi / 2,
          false,
        )
        ..close();
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WildQuadPainter _) => false;
}