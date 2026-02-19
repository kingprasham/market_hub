import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Navigation is handled by SplashController, not here
  // to avoid duplicate navigation causing GlobalKey conflicts

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: ColorConstants.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.show_chart,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'Market Hub',
              style: TextStyles.h2.copyWith(
                color: ColorConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time Market Data',
              style: TextStyles.bodyMedium.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorConstants.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
