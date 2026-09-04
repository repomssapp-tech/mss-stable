import 'package:flutter/material.dart';
import 'basic_profile_screen.dart';

class LocationProfileScreen extends StatelessWidget {
  const LocationProfileScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const BasicProfileScreen(initialStep: 2);
}
