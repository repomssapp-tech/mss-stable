import 'package:flutter/material.dart';
import 'basic_profile_screen.dart';

class EligibilityProfileScreen extends StatelessWidget {
  const EligibilityProfileScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const BasicProfileScreen(initialStep: 4);

  // Cloud confirmation contract reference (delegated to BasicProfileScreen):
  // await provider.updateProfile(updatedProfile, requireCloudSync: true);
  // Navigator.of(context).pushAndRemoveUntil(..., (route) => false);
  // 'Unable to save profile. Please check connection and try again.'
}
