import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AttractiveErrorWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onRetry;

  const AttractiveErrorWidget({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cartoon Image
            Image.asset(
              imagePath,
              height: MediaQuery.of(context).size.height * 0.25,
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Retry Button
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF4B2E1E), // Aapke app ki theme ka color
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
