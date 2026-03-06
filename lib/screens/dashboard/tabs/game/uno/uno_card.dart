import 'package:flutter/material.dart';
import '../../../../../services/uno_service.dart';

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

  Color get _cardColor {
    switch (card.color) {
      case 'red': return const Color(0xFFE53935);
      case 'green': return const Color(0xFF43A047);
      case 'blue': return const Color(0xFF1E88E5);
      case 'yellow': return const Color(0xFFFDD835);
      case 'wild': return const Color(0xFF212121);
      default: return Colors.grey;
    }
  }

  Color get _textColor {
    if (card.color == 'yellow') return Colors.black87;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final w = isSmall ? 44.0 : 62.0;
    final h = isSmall ? 64.0 : 90.0;
    final fontSize = isSmall ? 14.0 : 22.0;

    return GestureDetector(
      onTap: isPlayable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: w,
        height: h,
        transform: isPlayable
            ? (Matrix4.identity()..translate(0.0, -10.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(isSmall ? 6 : 10),
          border: Border.all(
            color: isPlayable
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: isPlayable ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPlayable
                  ? _cardColor.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: isPlayable ? 12 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Oval putih di tengah
            Center(
              child: Container(
                width: w * 0.65,
                height: h * 0.65,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: card.isWild ? 0.0 : 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Wild: warna-warni
            if (card.isWild)
              ClipRRect(
                borderRadius: BorderRadius.circular(isSmall ? 6 : 10),
                child: CustomPaint(
                  size: Size(w, h),
                  painter: _WildPainter(),
                ),
              ),

            // Nilai kartu tengah
            Center(
              child: Text(
                card.displayValue,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: card.isWild ? Colors.white : _textColor,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Sudut kiri atas
            Positioned(
              top: 3,
              left: 4,
              child: Text(
                card.displayValue,
                style: TextStyle(
                  fontSize: isSmall ? 7 : 10,
                  fontWeight: FontWeight.bold,
                  color: card.isWild ? Colors.white : _textColor,
                ),
              ),
            ),

            // Sudut kanan bawah (terbalik)
            Positioned(
              bottom: 3,
              right: 4,
              child: Transform.rotate(
                angle: 3.14159,
                child: Text(
                  card.displayValue,
                  style: TextStyle(
                    fontSize: isSmall ? 7 : 10,
                    fontWeight: FontWeight.bold,
                    color: card.isWild ? Colors.white : _textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kartu belakang (tangan lawan)
class UnoCardBack extends StatelessWidget {
  final bool isSmall;
  const UnoCardBack({super.key, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final w = isSmall ? 38.0 : 52.0;
    final h = isSmall ? 56.0 : 76.0;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmall ? 5 : 8),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'UNO',
          style: TextStyle(
            fontSize: isSmall ? 8 : 11,
            fontWeight: FontWeight.w900,
            color: Colors.red,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _WildPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFF43A047),
      const Color(0xFF1E88E5),
      const Color(0xFFFDD835),
    ];
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    for (int i = 0; i < 4; i++) {
      final paint = Paint()..color = colors[i];
      canvas.save();
      canvas.clipRect(rect);
      final path = Path();
      final cx = size.width / 2;
      final cy = size.height / 2;
      path.moveTo(cx, cy);
      final startAngle = i * (3.14159 / 2);
      path.lineTo(cx + size.width * 2 * cos(startAngle.toDouble()), cy + size.height * 2 * sin(startAngle.toDouble()));
      path.arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 2),
        startAngle,
        3.14159 / 2,
        false,
      );
      path.close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  double cos(double a) => dartCos(a);
  double sin(double a) => dartSin(a);

  static double dartCos(double a) {
    const vals = [1.0, 0.0, -1.0, 0.0];
    final idx = ((a / (3.14159 / 2)).round() % 4 + 4) % 4;
    return vals[idx];
  }

  static double dartSin(double a) {
    const vals = [0.0, 1.0, 0.0, -1.0];
    final idx = ((a / (3.14159 / 2)).round() % 4 + 4) % 4;
    return vals[idx];
  }

  @override
  bool shouldRepaint(_WildPainter _) => false;
}