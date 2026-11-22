import 'package:flutter/material.dart';

import '../../../utils/app_spacing.dart';

class ProfileOptionGrid extends StatelessWidget {
  const ProfileOptionGrid({super.key, required this.options});

  final List<Widget> options;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 250) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: options,
          );
        }
        return Column(
          spacing: AppSpacing.sm,
          children: [
            for (var index = 0; index < options.length; index += 2)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(child: options[index]),
                    if (index + 1 < options.length)
                      Expanded(child: options[index + 1])
                    else
                      const Spacer(),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
