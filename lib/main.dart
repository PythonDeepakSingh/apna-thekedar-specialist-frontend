// lib/main.dart (Updated with Global Internet Checker)
import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:apna_thekedar_specialist/services/location_service.dart'; // Naya import


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // === YEH NAYA CODE ADD KAREIN ===
  // Local Notifications Initialization
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Aapka app icon
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // iOS ke liye bhi settings add kar sakte hain agar zaroori ho
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // ==============================
  
  runApp(
    MultiProvider(
      providers: [
        // Global error providers hata diye gaye hain
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        Provider<GlobalKey<NavigatorState>>.value(value: navigatorKey),

        ChangeNotifierProvider<NotificationProvider>(
          create: (context) => NotificationProvider(context.read<ApiService>()),
        ),
        Provider<NotificationService>(
          create: (context) => NotificationService(
            context.read<GlobalKey<NavigatorState>>(),
            context.read<NotificationProvider>(),
          ),
        ),
        // Isse LocationService ko ApiService mil jaayegi
        Provider<LocationService>(
          create: (context) => LocationService(context.read<ApiService>()),
        ),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF4B2E1E);

    return MaterialApp(
      title: 'Apna Thekedar Specialist',
      navigatorKey: navigatorKey,
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
      // Builder se wrapper hata diya gaya hai
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: child!,
        );
      },
    );
  }
}