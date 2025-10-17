import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(
    MultiProvider(
      providers: [
        // Pehle independent providers
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        Provider<GlobalKey<NavigatorState>>.value(value: navigatorKey),

        // Ab dependent providers
        ChangeNotifierProvider<NotificationProvider>(
          create: (context) => NotificationProvider(context.read<ApiService>()),
        ),
        // NotificationService ab dusre providers ko theek se access kar payega
        Provider<NotificationService>(
          create: (context) => NotificationService(
            context.read<GlobalKey<NavigatorState>>(),
            context.read<NotificationProvider>(),
          ),
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