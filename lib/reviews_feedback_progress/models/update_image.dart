// lib/reviews_feedback_progress/models/update_image.dart
import 'dart:io';
import 'package:flutter/material.dart';

class UpdateImage {
  File imageFile;
  TextEditingController nameController;

  UpdateImage({required this.imageFile, required String initialName})
      : nameController = TextEditingController(text: initialName);
}