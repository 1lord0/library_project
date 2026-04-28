import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'constants/app_strings.dart';
import 'services/auth_service.dart';
import 'services/seed_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SeedService().seedInitialData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (!auth.isLoggedIn) return const LoginScreen();
            if (auth.isAdmin) return const AdminDashboardScreen();
            return const UserHomeScreen();
          },
        ),
      ),
    );
  }
}
