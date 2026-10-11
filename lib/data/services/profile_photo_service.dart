import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePhotoService {
  static final ImagePicker _picker = ImagePicker();
  static const _photoDirectoryName = 'jembergo_profile_photos';

  static Future<File?> getPhoto(String userId) async {
    final photo = await _photoFile(userId);
    return await photo.exists() ? photo : null;
  }

  static Future<File?> pickPhoto(String userId) async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (selected == null) return null;

    final destination = await _photoFile(userId);
    await selected.saveTo(destination.path);
    final savedPhoto = destination;
    if (!await savedPhoto.exists() || await savedPhoto.length() == 0) {
      throw FileSystemException(
        'Selected profile photo was not saved.',
        destination.path,
      );
    }
    return savedPhoto;
  }

  static Future<void> removePhoto(String userId) async {
    final photo = await _photoFile(userId);
    if (await photo.exists()) await photo.delete();
  }

  static Future<File> _photoFile(String userId) async {
    final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File(
        '${directory.path}${Platform.pathSeparator}profile_$safeUserId.image',
      );
    } on Exception catch (error, stackTrace) {
      debugPrint(
        'Could not access app documents directory for profile photo: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      final directory = Directory(
        '${Directory.systemTemp.path}'
        '${Platform.pathSeparator}$_photoDirectoryName',
      );
      await directory.create(recursive: true);
      return File(
        '${directory.path}${Platform.pathSeparator}profile_$safeUserId.image',
      );
    }
  }
}
