import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 32,
    this.iconSize = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/images/logo.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
