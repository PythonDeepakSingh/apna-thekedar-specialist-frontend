// lib/main.dart (FINAL & CORRECTED CODE)
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider ko import karein
import 'package:apna_thekedar_specialist/api/api_service.dart'; // ApiService ko import karein
import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';


// YEH HAI HAMARA NAYA "BACKGROUND WATCHMAN" FUNCTION
// Isse main() function ke bahar, sabse upar likhein
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background mein notification dikhane ke liye service ko call karein
  // YEH HAI CORRECTED FUNCTION NAME
  await NotificationService().showFirebaseNotification(message);
  print("Handling a background message: ${message.messageId}");
}

// Yeh Global key humein app ke bahar se navigation control karne mein madad karegi
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<ApiService>(
          create: (context) => ApiService(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (context) => NotificationProvider(context.read<ApiService>()),
        ),
        // ==================== YEH NAYI LINE ADD KAREIN ====================
        Provider<NotificationService>(
          create: (context) => NotificationService(navigatorKey, context.read<NotificationProvider>()),
        )
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Apna Thekedar Specialist',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(),
      ),
    );
  }
}
  


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF4B2E1E);

    return MaterialApp(
      title: 'Apna Thekedar Specialist',
      navigatorKey: navigatorKey, // Navigator key ko yahan set karein
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: darkColor,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: IconThemeData(color: darkColor),
          titleTextStyle: TextStyle(
              color: darkColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkColor, width: 2),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200)
          )
        )
      ),
      home: const SplashScreen(),
// ==================== YEH RAHA MASTER SOLUTION ====================
      // 'builder' property poore app ko wrap kar deta hai.
      builder: (context, child) {
        return GestureDetector(
          // Jab bhi keyboard ke bahar kahin bhi tap hoga...
          onTap: () {
              
            // ...toh keyboard ko band kar do.
            FocusScope.of(context).unfocus();
          },
          // 'child' ka matlab hai aapki current screen (koi bhi screen ho)
          child: child!,
        );
      },
      // ===============================================================
    );
  }
}