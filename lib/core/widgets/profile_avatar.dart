// lib/core/widgets/profile_avatar.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final VoidCallback onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.imageFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? backgroundImage;
    if (imageFile != null) {
      backgroundImage = FileImage(imageFile!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(imageUrl!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: backgroundImage,
            child: backgroundImage == null
                ? const Icon(Iconsax.user, size: 60, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.camera, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
