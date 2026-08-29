import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_brand_icon.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBrandIcon(
              size: 88,
              iconSize: 52,
              shadowOffset: 4,
            ),
            const SizedBox(height: 18),
            Text(
              'SERVISO',
              style: AppTypography.chakra(
                fontSize: 36,
                color: AppColors.primary,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
