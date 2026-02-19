import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/color_constants.dart';

class ToastHelper {
  static void showSuccess(String message, {String title = 'Success', int? duration}) {
    _showToast(
      title: title,
      message: message,
      backgroundColor: ColorConstants.successColor,
      icon: Icons.check_circle_outline,
      duration: duration ?? 2,
    );
  }

  static void showError(String message, {String title = 'Error'}) {
    _showToast(
      title: title,
      message: message,
      backgroundColor: ColorConstants.errorColor,
      icon: Icons.error_outline,
      duration: 3,
    );
  }

  static void showInfo(String message, {String title = 'Info'}) {
    _showToast(
      title: title,
      message: message,
      backgroundColor: ColorConstants.infoColor,
      icon: Icons.info_outline,
    );
  }

  static void _showToast({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    int duration = 2,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor.withOpacity(0.95),
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white, size: 28),
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeIn,
      snackStyle: SnackStyle.FLOATING,
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) {
            Get.closeCurrentSnackbar();
          }
        },
        child: const Text(
          'CLOSE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
