import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Text(
          'SERVISO',
          style: AppTypography.chakra(
            fontSize: 40,
            color: AppColors.primary,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
