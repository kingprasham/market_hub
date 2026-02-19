import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../buttons/primary_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    String? subtitle,
    String? description, // alias for subtitle
    String? buttonText,
    String? actionText, // alias for buttonText
    VoidCallback? onButtonPressed,
    VoidCallback? onAction, // alias for onButtonPressed
  })  : subtitle = subtitle ?? description,
        buttonText = buttonText ?? actionText,
        onButtonPressed = onButtonPressed ?? onAction;



  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: ColorConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyles.h4,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ColorConstants.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: ColorConstants.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyles.h4,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Try Again',
                onPressed: onRetry,
                width: 160,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoConnectionState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoConnectionState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ColorConstants.textSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off,
                size: 48,
                color: ColorConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Internet Connection',
              style: TextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your network and try again',
              style: TextStyles.bodyMedium.copyWith(
                color: ColorConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Retry',
                onPressed: onRetry,
                width: 160,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
