import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/services/lockdown_service.dart';

class AdminLockdownPage extends StatelessWidget {
  const AdminLockdownPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LockdownService lockdownService = Get.find<LockdownService>();

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: Text('Admin Controls', style: TextStyles.appBarTitle),
        backgroundColor: ColorConstants.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.security, size: 64, color: ColorConstants.primaryBlue),
                  const SizedBox(height: 16),
                  Text(
                    'System Status',
                    style: TextStyles.h4,
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    lockdownService.isLockdownActive.value ? 'LOCKED DOWN' : 'OPERATIONAL',
                    style: TextStyles.h3.copyWith(
                      color: lockdownService.isLockdownActive.value 
                          ? ColorConstants.negativeRed 
                          : ColorConstants.positiveGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Actions',
              style: TextStyles.h5,
            ),
            const SizedBox(height: 16),
            
            // LOCKDOWN BUTTON
            Obx(() => lockdownService.isLockdownActive.value 
              ? const SizedBox.shrink() 
              : ElevatedButton.icon(
                  onPressed: () => _confirmAction(
                    context, 
                    'Enable Lockdown', 
                    'This will log out ALL users immediately and prevent them from logging in. Only you will have access.',
                    () => lockdownService.enableLockdown(),
                    isDestructive: true,
                  ),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('LOCKDOWN APP (LOGOUT EVERYONE)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.negativeRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyles.buttonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
            ),

            // RESTORE BUTTON
            Obx(() => !lockdownService.isLockdownActive.value 
              ? const SizedBox.shrink() 
              : ElevatedButton.icon(
                  onPressed: () => _confirmAction(
                    context, 
                    'Restore Access', 
                    'This will allow users to log in again. Are you sure?',
                    () => lockdownService.disableLockdown(),
                    isDestructive: false,
                  ),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('RESTORE APP ACCESS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.positiveGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyles.buttonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(BuildContext context, String title, String message, Function onConfirm, {required bool isDestructive}) {
    Get.dialog(
      AlertDialog(
        title: Text(title, style: TextStyles.h4),
        content: Text(message, style: TextStyles.bodyMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyles.buttonTextSecondary),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onConfirm();
              Get.snackbar(
                'Success', 
                'Action completed successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: isDestructive ? ColorConstants.negativeRed : ColorConstants.positiveGreen,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? ColorConstants.negativeRed : ColorConstants.positiveGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
