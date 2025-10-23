import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/profile/screens/kyc_screen.dart';
import 'package:apna_thekedar_specialist/main_nav_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Attractive Icon/Image
              Icon(
                Iconsax.award,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),

              // Welcome Message
              const Text(
                'Welcome to the\nApna Thekedar Family!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We are excited to have you onboard. Complete your profile to start receiving job opportunities in your area.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // KYC Button
              ElevatedButton.icon(
                icon: const Icon(Iconsax.document_upload),
                label: const Text('Complete Your KYC'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // KYC screen par navigate karein
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KycScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Skip Button
              TextButton(
                onPressed: () {
                  // Seedha dashboard par le jayein
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainNavScreen()),
                    (route) => false,
                  );
                },
                child: const Text('I\'ll do it later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}