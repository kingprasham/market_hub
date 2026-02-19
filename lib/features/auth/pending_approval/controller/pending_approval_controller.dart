import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/services/admin_api_service.dart';

class PendingApprovalController extends GetxController {
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check status periodically
    _startStatusCheck();
  }

  void _startStatusCheck() {
    // Check status every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (Get.currentRoute == AppRoutes.pendingApproval) {
        checkStatus();
        _startStatusCheck();
      }
    });
  }

  Future<void> checkStatus() async {
    isLoading.value = true;

    try {
      final user = LocalStorage.getUser();
      if (user == null) {
        Helpers.showError('User not found. Please register again.');
        Get.offAllNamed(AppRoutes.registration);
        return;
      }

      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.checkStatus(
        userId: int.parse(user.id),
        email: user.email,
      );

      if (response['success'] == true) {
        final status = response['status'];

        if (status == 'approved') {
          await LocalStorage.updateUser((u) => u.copyWith(isApproved: true));
          Helpers.showSuccess('Account approved! You can now login.');
          Get.offAllNamed(AppRoutes.login);
        } else if (status == 'rejected') {
          final reason = response['rejection_reason'] ?? 'Your account was not approved.';
          await LocalStorage.updateUser((u) => u.copyWith(
            isRejected: true,
            rejectionMessage: reason,
          ));
          _showRejectionDialog(reason);
        } else {
          Helpers.showSnackBar(message: 'Still pending approval');
        }
      }
    } catch (e) {
      Helpers.showSnackBar(message: 'Status check in progress...');
    } finally {
      isLoading.value = false;
    }
  }

  void _showRejectionDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Account Not Approved'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Allow re-upload of documents
            },
            child: const Text('Re-submit'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              contactSupport();
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void contactSupport() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.call, color: Colors.green),
              title: const Text('Call Support'),
              onTap: () async {
                Get.back();
                final Uri launchUri = Uri(scheme: 'tel', path: '+919876543210'); // Replace with actual number
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text('WhatsApp Support'),
              onTap: () async {
                Get.back();
                final Uri launchUri = Uri.parse('https://wa.me/919876543210'); // Replace with actual number
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email Support'),
              onTap: () async {
                Get.back();
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'support@markethubindia.com',
                  queryParameters: {'subject': 'Account Verification Query'},
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
