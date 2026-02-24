import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import 'app_logo.dart';

class CommonAppBarTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const CommonAppBarTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyles.h4.copyWith(
                color: ColorConstants.textPrimary,
                fontSize: 18,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyles.caption.copyWith(
                  color: ColorConstants.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
