import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class MarketHubApp extends StatelessWidget {
  const MarketHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Market Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
