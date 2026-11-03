import 'dart:io';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

Future<void> changeProfilePicture(
  BuildContext context,
  AppProvider provider,
) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                context.l10n.profilePhotoTitle,
                style: context.text.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                context.l10n.chooseFromGallery,
                style: context.text.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (pickedFile != null) {
                  await savePickedImage(pickedFile.path, provider);
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                context.l10n.takePhoto,
                style: context.text.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (pickedFile != null) {
                  await savePickedImage(pickedFile.path, provider);
                }
              },
            ),
            if (provider.hasCustomPhoto)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.dangerStrong,
                ),
                title: Text(
                  context.l10n.removePhoto,
                  style: context.text.body.copyWith(
                    color: AppColors.dangerStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await provider.updateProfilePhoto('');
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    },
  );
}

Future<void> savePickedImage(String tempPath, AppProvider provider) async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final String extension = tempPath.split('.').last;
    final String newFileName =
        'profile_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final String newPath = '${appDir.path}/$newFileName';

    final File tempFile = File(tempPath);
    await tempFile.copy(newPath);
    await provider.updateProfilePhoto(newPath);
  } catch (e) {
    debugPrint('Error saving picked profile photo: $e');
  }
}
