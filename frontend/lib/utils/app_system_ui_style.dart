import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

const appSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarColor: AppColors.surface,
  systemNavigationBarDividerColor: AppColors.border,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: true,
);

// Splash and sign-in share the same blue artwork behind the navigation bar.
final appBlueFooterSystemUiStyle = appSystemUiStyle.copyWith(
  systemNavigationBarColor: AppColors.primary,
  systemNavigationBarDividerColor: AppColors.primary,
  systemNavigationBarIconBrightness: Brightness.light,
);
