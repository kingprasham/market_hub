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
        gradient: ColorConstants.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.show_chart,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}
