// lib/home/widgets/home_drawer.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/edit_profile_screen.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart'; // Naya import
import 'package:apna_thekedar_specialist/profile/screens/notification_settings_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/my_earnings_screen.dart'; // Naya import 
import 'package:apna_thekedar_specialist/profile/screens/kyc_screen.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/select_services_screen.dart';


class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.loadFromApi();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  void _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

   Widget _buildRatingTile(String title, double rating) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(Iconsax.star_1, color: Colors.amber.shade700, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        rating.toStringAsFixed(1), // Ek decimal tak dikhayein
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF4B2E1E);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              _userProfile?.name ?? "Specialist",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              _userProfile?.phoneNumber ?? "",
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
                backgroundImage: (_userProfile?.profilePhotoUrl != null)
                    ? NetworkImage(_userProfile!.profilePhotoUrl!)
                    : null,
                backgroundColor: Colors.white,
                child: (_userProfile?.profilePhotoUrl == null)
                    ? const Icon(Iconsax.user, color: darkColor)
                    : null,
              ),


            decoration: const BoxDecoration(color: darkColor),
          ),

                    if (_userProfile != null) ...[
            _buildRatingTile("Work Rating", _userProfile!.workRating),
            _buildRatingTile("Behavior Rating", _userProfile!.behaviorRating),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Iconsax.document_upload),
            title: const Text('KYC and Documentation'),
            onTap: () {
              Navigator.pop(context); // Pehle drawer band karein
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KycScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.profile_circle),
            title: const Text('Edit Profile'),
            onTap: () async {
              Navigator.pop(context); // Pehle drawer band karein
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              _loadUserProfile(); // Wapas aane par profile refresh karein
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.wallet_2),
            title: const Text('My Earnings'),
            onTap: () {
              Navigator.pop(context); // Pehle drawer band karein
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyEarningsScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Iconsax.notification_bing),
            title: const Text('Notification Settings'),
            onTap: () {
              Navigator.pop(context); // Pehle drawer band karein
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.rulerpen),
            title: const Text('Skill Management'),
            onTap: () {
              Navigator.pop(context); // Pehle drawer band karein
              Navigator.push(
                context,
                // Hum yahan 'isUpdating' parameter bhej rahe hain
                MaterialPageRoute(builder: (context) => const SelectServicesScreen(isUpdating: true)),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Iconsax.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
