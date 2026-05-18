import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// Lightweight 2D Vector Helper
class CyberVector2D {
  final double x;
  final double y;

  const CyberVector2D(this.x, this.y);

  CyberVector2D operator +(CyberVector2D other) => CyberVector2D(x + other.x, y + other.y);
  CyberVector2D operator *(double scalar) => CyberVector2D(x * scalar, y * scalar);

  double magnitude() => math.sqrt(x * x + y * y);
  
  CyberVector2D normalize() {
    final mag = magnitude();
    return mag == 0 ? const CyberVector2D(0, 0) : CyberVector2D(x / mag, y / mag);
  }
}

// Reusable AABB Bounding Box Collision Engine
class CyberCollision {
  static bool checkRectCollision(Rect rectA, Rect rectB) {
    return rectA.left < rectB.right &&
        rectA.right > rectB.left &&
        rectA.top < rectB.bottom &&
        rectA.bottom > rectB.top;
  }

  static bool checkCircleCollision(Offset centerA, double radiusA, Offset centerB, double radiusB) {
    final distance = (centerA - centerB).distance;
    return distance < (radiusA + radiusB);
  }
}

// Reusable Futuristic Touch Joystick Widget
class CyberJoystick extends StatefulWidget {
  final Function(CyberVector2D direction) onDirectionChanged;

  const CyberJoystick({
    super.key,
    required this.onDirectionChanged,
  });

  @override
  State<CyberJoystick> createState() => _CyberJoystickState();
}

class _CyberJoystickState extends State<CyberJoystick> {
  Offset _dragPosition = Offset.zero;
  final double _joystickRadius = 50.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final localPosition = details.localPosition - Offset(_joystickRadius, _joystickRadius);
          final distance = localPosition.distance;
          if (distance <= _joystickRadius) {
            _dragPosition = localPosition;
          } else {
            _dragPosition = Offset.fromDirection(localPosition.direction, _joystickRadius);
          }
          final vector = CyberVector2D(_dragPosition.dx / _joystickRadius, _dragPosition.dy / _joystickRadius);
          widget.onDirectionChanged(vector);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _dragPosition = Offset.zero;
          widget.onDirectionChanged(const CyberVector2D(0, 0));
        });
      },
      child: Container(
        width: _joystickRadius * 2,
        height: _joystickRadius * 2,
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.cyanBlue, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cyanBlue.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: _joystickRadius - 20 + _dragPosition.dx,
              top: _joystickRadius - 20 + _dragPosition.dy,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.neonPurple, AppTheme.electricPink],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricPink.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.gamepad,
                    size: 18,
                    color: Colors.white,
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
