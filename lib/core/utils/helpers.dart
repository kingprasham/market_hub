import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/color_constants.dart';
import 'toast_helper.dart';

class Helpers {
  // Show Snackbar
  static void showSnackBar({
    required String message,
    bool isError = false,
  }) {
    if (isError) {
      ToastHelper.showError(message);
    } else {
      ToastHelper.showSuccess(message);
    }
  }

  // Show Success Snackbar
  static void showSuccess(String message) {
    ToastHelper.showSuccess(message);
  }

  // Show Error Snackbar
  static void showError(String message) {
    ToastHelper.showError(message);
  }

  // Show Loading Dialog
  static void showLoading({String? message}) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: ColorConstants.primaryColor,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Hide Loading Dialog
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // Show Confirmation Dialog
  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDanger = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? ColorConstants.errorColor : ColorConstants.primaryColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Convert File to Base64
  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  // Check if color is light or dark
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  // Hide keyboard
  static void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // Copy to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    showSuccess('Copied to clipboard');
  }

  // Check if email is valid
  static bool isValidEmail(String email) {
    return GetUtils.isEmail(email);
  }

  // Parse JSON safely
  static Map<String, dynamic>? parseJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Get device type
  static String getDeviceType() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isLinux) {
      return 'Linux';
    }
    return 'Unknown';
  }

  // Calculate percentage change
  static double calculatePercentChange(double oldValue, double newValue) {
    if (oldValue == 0) return 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  // Get color based on change
  static Color getChangeColor(double change) {
    if (change > 0) return ColorConstants.positiveGreen;
    if (change < 0) return ColorConstants.negativeRed;
    return ColorConstants.textSecondary;
  }

  // Get change icon
  static IconData getChangeIcon(double change) {
    if (change > 0) return Icons.arrow_upward;
    if (change < 0) return Icons.arrow_downward;
    return Icons.remove;
  }
}
