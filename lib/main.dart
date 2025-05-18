import 'package:divar_app/providers/admin_provider.dart';
import 'package:divar_app/providers/comment_provider.dart';
import 'package:divar_app/screens/ad_details_screen.dart';
import 'package:divar_app/screens/admin_dashboard_screen.dart';
import 'package:divar_app/screens/admin_login_screen.dart';
import 'package:divar_app/screens/location_screen.dart';
import 'package:divar_app/screens/myAds_screen.dart';
import 'package:divar_app/screens/post_ad_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/ad_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/bookmark_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Builder(
        builder: (context) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          return FutureBuilder(
            future: authProvider.initialize(),
            builder: (context, snapshot) {
              print('FutureBuilder snapshot: $snapshot');
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              }
              final isLoggedIn = authProvider.phoneNumber != null;
              print('isLoggedIn: $isLoggedIn');
              return MaterialApp(
                title: 'دیوار',
                theme: appTheme,
                debugShowCheckedModeBanner: false,
                supportedLocales: const [Locale('fa', 'IR')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                locale: const Locale('fa', 'IR'),
                home: Directionality(
                  textDirection: TextDirection.rtl,
                  child: isLoggedIn ? const HomeScreen() : const AuthScreen(),
                ),
                routes: {
                  '/auth': (context) => const AuthScreen(),
                  '/home': (context) => const HomeScreen(),
                  '/ad_details': (context) => const AdDetailsScreen(),
                  '/profile': (context) => const ProfileScreen(),
                  '/my_ads': (context) => Consumer<AuthProvider>(
                        builder: (context, authProvider, _) => MyAdsScreen(
                          phoneNumber: authProvider.phoneNumber ?? '',
                        ),
                      ),
                  '/location': (context) => const LocationScreen(),
                  '/post_ad': (context) => const PostAdScreen(),
                  '/admin_login': (context) => const AdminLoginScreen(),
                  '/admin_dashboard': (context) => const AdminDashboardScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
