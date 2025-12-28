// lib/home/widgets/home_drawer.dart (UPDATED - Clean Version)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/edit_profile_screen.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart';
import 'package:apna_thekedar_specialist/profile/screens/notification_settings_screen.dart';
// MyEarningsScreen import hata diya gaya hai
import 'package:apna_thekedar_specialist/profile/screens/kyc_screen.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/select_services_screen.dart';
import 'dart:io'; 
import 'package:apna_thekedar_specialist/support/support_screen.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:provider/provider.dart';
import 'package:apna_thekedar_specialist/services/location_service.dart'; // LocationService import

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _hasError = false;
  
  bool _isAvailable = false;
  bool _isSwitchLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
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
            _isAvailable = profile.isAvailable;
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

  Future<void> _toggleAvailability(bool newValue) async {
    setState(() => _isSwitchLoading = true);
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);

    try {
      final response = await apiService.patch(
        '/specialist/profile/professional/update/', 
        {'is_available': newValue}
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _isAvailable = newValue;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(newValue ? 'You are now Online!' : 'You are now Offline.'),
            backgroundColor: newValue ? Colors.green : Colors.orange,
          ));
          
          if (newValue) {
            locationService.startLocationUpdates();
          } else {
            locationService.stopLocationUpdates();
          }

        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating status. Please try again.')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      if (mounted) setState(() => _isSwitchLoading = false);
    }
  }

  void _logout() async {
    // Logout se pehle "Offline" set karein
    if (_isAvailable) {
      await _toggleAvailability(false);
    }
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

   // === YEH FUNCTION AB ISTEMAAL NAHI HO RAHA ===
   /*
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
   */
   // ============================================

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF4B2E1E);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
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

          if (!_isLoading && !_hasError)
            SwitchListTile(
              title: Text(
                _isAvailable ? 'You are Online' : 'You are Offline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isAvailable ? Colors.green[700] : Colors.red[700],
                ),
              ),
              subtitle: Text(_isAvailable ? 'Ready for new jobs' : 'Not receiving new jobs'),
              value: _isAvailable,
              onChanged: _isSwitchLoading ? null : _toggleAvailability,
              secondary: _isSwitchLoading 
                ? const CircularProgressIndicator() 
                : Icon(_isAvailable ? Iconsax.status : Iconsax.danger, color: _isAvailable ? Colors.green : Colors.red),
            ),
          
          // === RATINGS YAHAN SE HATA DI GAYI HAIN ===
          const Divider(),
          // ==========================================

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
            title: const Text('My Profile'), // "Edit Profile" se "My Profile" kar diya
            onTap: () async {
              Navigator.pop(context);
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              _loadUserProfile(); // Wapas aane par profile reload karein (taaki switch sync rahe)
            },
          ),
          
          // === "MY EARNINGS" YAHAN SE HATA DIYA GAYA HAI ===
          
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
              Navigator.pop(context);
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