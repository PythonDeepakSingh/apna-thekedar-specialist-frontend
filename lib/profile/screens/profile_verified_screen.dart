import 'package:flutter/material.dart';

class ProfileVerifiedScreen extends StatelessWidget {
  const ProfileVerifiedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Verified"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, size: 100, color: Colors.green),
              SizedBox(height: 20),
              Text(
                "Congratulations!",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Your profile is now verified. You are eligible to receive new job requirements.",
                textAlign: TextAlign.center,
              ),
              // Yahan aap verification fields ki list dikha sakte hain future mein
            ],
          ),
        ),
      ),
    );
  }
}