// lib/home/widgets/home_drawer.dart (Updated with Error Handling)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/edit_profile_screen.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart';
import 'package:apna_thekedar_specialist/profile/screens/notification_settings_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/my_earnings_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/kyc_screen.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/select_services_screen.dart';
import 'dart:io'; // Naya import
import 'package:apna_thekedar_specialist/support/support_screen.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  UserProfile? _userProfile;
  bool _isLoading = true; // Naya variable
  bool _hasError = false; // Naya variable

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // === Is function ko update kiya gaya hai ===
  Future<void> _loadUserProfile() async {
    // Shuru me error false set karein
    if(mounted) setState(() { _isLoading = true; _hasError = false; });
    
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'no_internet';
      }
      
      final profile = await UserProfile.loadFromApi();
      if (mounted) {
        if (profile != null) {
          setState(() {
            _userProfile = profile;
          });
        } else {
          throw 'server_error';
        }
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        rating.toStringAsFixed(1),
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
          // === UserAccountsDrawerHeader ko update kiya gaya hai ===
          UserAccountsDrawerHeader(
            accountName: _isLoading
                ? const Text("Loading...")
                : _hasError
                    ? const Text("Could not load name", style: TextStyle(color: Colors.white70))
                    : Text(
                        _userProfile?.name ?? "Specialist",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
            accountEmail: _hasError
                ? InkWell(onTap: _loadUserProfile, child: const Text("Tap to retry", style: TextStyle(color: Colors.orange)))
                : Text(
                    _userProfile?.phoneNumber ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),
            currentAccountPicture: CircleAvatar(
                backgroundImage: (_userProfile?.profilePhotoUrl != null)
                    ? NetworkImage(_userProfile!.profilePhotoUrl!)
                    : null,
                backgroundColor: Colors.white,
                child: (_userProfile?.profilePhotoUrl == null)
                    ? (_isLoading 
                        ? const CircularProgressIndicator(strokeWidth: 2) 
                        : const Icon(Iconsax.user, color: darkColor)
                      )
                    : null,
              ),
            decoration: const BoxDecoration(color: darkColor),
          ),

          // Baaki ka UI
          if (!_isLoading && !_hasError && _userProfile != null) ...[
            _buildRatingTile("Work Rating", _userProfile!.workRating),
            _buildRatingTile("Behavior Rating", _userProfile!.behaviorRating),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Iconsax.document_upload),
            title: const Text('KYC and Documentation'),
            onTap: () {
              Navigator.pop(context);
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
              Navigator.pop(context);
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              _loadUserProfile();
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.wallet_2),
            title: const Text('My Earnings'),
            onTap: () {
              Navigator.pop(context);
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
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.rulerpen),
            title: const Text('Skill Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SelectServicesScreen(isUpdating: true)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.message_question),
            title: const Text('Support'),
            onTap: () {
              Navigator.pop(context); // Pehle drawer band karein
              // Hum yeh nayi screen agle step mein banayenge
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportScreen()),
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