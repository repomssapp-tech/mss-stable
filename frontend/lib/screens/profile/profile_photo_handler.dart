import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';

Future<void> changeProfilePicture(
  BuildContext context,
  AppProvider provider,
) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
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
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF2563EB),
              ),
              title: Text(
                context.l10n.chooseFromGallery,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
                color: Color(0xFF2563EB),
              ),
              title: Text(
                context.l10n.takePhoto,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
                  color: Color(0xFFEF4444),
                ),
                title: Text(
                  context.l10n.removePhoto,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
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
