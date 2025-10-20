import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/app_export.dart';

// lib/presentation/edit_profile_screen/widgets/profile_avatar_widget.dart

class ProfileAvatarWidget extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String?) onImageChanged;
  final bool isEditing;

  const ProfileAvatarWidget({
    super.key,
    this.currentImageUrl,
    required this.onImageChanged,
    this.isEditing = true,
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  String? _selectedImageUrl;
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImageUrl = widget.currentImageUrl;
  }

  void _showImagePicker() {
    final currentTheme = Theme.of(context);
    showModalBottomSheet(
        context: context,
        backgroundColor: currentTheme.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (BuildContext context) {
          return Container(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: currentTheme.colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2))),
                SizedBox(height: 2.h),
                Text('Change Profile Photo',
                    style: currentTheme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 3.h),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageOption(context, 'Camera', 'camera_alt',
                          () => _selectFromCamera()),
                      _buildImageOption(context, 'Gallery', 'photo_library',
                          () => _selectFromGallery()),
                      _buildImageOption(
                          context, 'Remove', 'delete', () => _removeImage()),
                    ]),
                SizedBox(height: 2.h),
              ]));
        });
  }

  Widget _buildImageOption(
      BuildContext context, String label, String iconName, VoidCallback onTap) {
    final currentTheme = Theme.of(context);
    return GestureDetector(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Column(children: [
          Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: currentTheme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(30)),
              child: CustomIconWidget(
                  iconName: iconName,
                  size: 28,
                  color: currentTheme.colorScheme.primary)),
          SizedBox(height: 1.h),
          Text(label,
              style: currentTheme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ]));
  }

  Future<void> _selectFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedImageUrl = null; // Clear URL since we have a file
        });
        widget.onImageChanged(image.path);
        _showSuccessMessage('Photo captured successfully');
      }
    } catch (e) {
      _showErrorMessage('Failed to capture photo: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedImageUrl = null; // Clear URL since we have a file
        });
        widget.onImageChanged(image.path);
        _showSuccessMessage('Photo selected successfully');
      }
    } catch (e) {
      _showErrorMessage('Failed to select photo: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageUrl = null;
    });
    widget.onImageChanged(null);
    _showSuccessMessage('Profile photo removed');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2)));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Center(
        child: Stack(children: [
      Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                  color: currentTheme.colorScheme.primary, width: 3)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(57),
              child: _selectedImageFile != null
                  ? Image.file(
                      _selectedImageFile!,
                      width: 114,
                      height: 114,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(currentTheme);
                      },
                    )
                  : _selectedImageUrl != null
                      ? CustomImageWidget(
                          imageUrl: _selectedImageUrl,
                          height: 114,
                          width: 114,
                          fit: BoxFit.cover)
                      : _buildDefaultAvatar(currentTheme))),
      if (widget.isEditing)
        Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
                onTap: _showImagePicker,
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: currentTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: currentTheme.colorScheme.surface, width: 2)),
                    child: CustomIconWidget(
                        iconName: 'camera_alt',
                        size: 20,
                        color: currentTheme.colorScheme.onPrimary)))),
    ]));
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withAlpha(26),
      child: CustomIconWidget(
        iconName: 'person',
        size: 60,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
