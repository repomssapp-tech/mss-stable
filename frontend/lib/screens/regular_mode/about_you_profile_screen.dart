import 'package:flutter/material.dart';
import 'basic_profile_screen.dart';

class AboutYouProfileScreen extends StatelessWidget {
  const AboutYouProfileScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const BasicProfileScreen(initialStep: 3);
}
