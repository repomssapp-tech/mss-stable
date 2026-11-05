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
// Let the artwork provide contrast so Android does not put a light scrim
// behind the light buttons on these routes.
final appBlueFooterSystemUiStyle = appSystemUiStyle.copyWith(
  systemNavigationBarColor: AppColors.primary,
  systemNavigationBarDividerColor: AppColors.primary,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);
