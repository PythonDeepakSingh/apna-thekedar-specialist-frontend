// lib/main_nav_screen.dart (Specialist App ke liye)
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/home/screens/home_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/my_jobs_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/edit_profile_screen.dart'; // Hum profile ke liye edit screen ka istemaal karenge

class MainNavScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  // Neeche navigation bar ke liye screens ki list
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MyJobsScreen(),
    EditProfileScreen(), // Profile ke liye
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home_2),
            activeIcon: Icon(Iconsax.home_25),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.folder_open),
            activeIcon: Icon(Iconsax.folder_open),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.user),
            activeIcon: Icon(Iconsax.user_tick),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}