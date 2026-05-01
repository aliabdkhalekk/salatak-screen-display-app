import 'package:flutter/material.dart';

class MosqueLogoBadge extends StatelessWidget {
  const MosqueLogoBadge({
    super.key,
    this.size = 84,
    this.showShadow = true,
  });

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.26;
    final domeColor = const Color(0xFF123A49);
    const gold = Color(0xFFD8BE74);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A1A23),
            Color(0xFF15485B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: gold,
            ),
          ),
          Positioned(
            bottom: size * 0.22,
            child: Container(
              width: size * 0.28,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: domeColor,
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.34,
            child: Container(
              width: size * 0.26,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: domeColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(size * 0.14, size * 0.14),
                ),
              ),
            ),
          ),
          Positioned(
            left: size * 0.24,
            bottom: size * 0.24,
            child: _Minaret(
              width: size * 0.08,
              height: size * 0.36,
              color: domeColor,
            ),
          ),
          Positioned(
            right: size * 0.24,
            bottom: size * 0.24,
            child: _Minaret(
              width: size * 0.08,
              height: size * 0.36,
              color: domeColor,
            ),
          ),
          Positioned(
            right: size * 0.2,
            top: size * 0.18,
            child: SizedBox(
              width: size * 0.16,
              height: size * 0.16,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: domeColor,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: size * 0.13,
                      height: size * 0.13,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Minaret extends StatelessWidget {
  const _Minaret({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width * 1.1,
          height: height * 0.12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(width),
          ),
        ),
        Container(
          width: width,
          height: height * 0.88,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(width),
          ),
        ),
      ],
    );
  }
}
