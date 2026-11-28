import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'services/permission_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation for standard camera HUD layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ThemeService.instance.init();

  final permissionResult = await PermissionService.checkPermissions();

  runApp(GpsCameraApp(hasPermissions: permissionResult.isGranted));
}

class GpsCameraApp extends StatelessWidget {
  final bool hasPermissions;

  const GpsCameraApp({super.key, required this.hasPermissions});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'GPS Camera',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeService.instance.themeMode,
          theme: ThemeData(
            fontFamily: "GoogleSans",
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.white,
              titleSpacing: 0,
              foregroundColor: Color(0xFF0F172A),
              elevation: 0,
            ),
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              secondary: Colors.cyan,
              surface: Colors.white,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            fontFamily: "GoogleSans",
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            appBarTheme: const AppBarTheme(
              surfaceTintColor: Colors.transparent,
              titleSpacing: 0,
              backgroundColor: Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              secondary: Colors.cyanAccent,
              surface: Color(0xFF1E293B),
            ),
            useMaterial3: true,
          ),
          home: hasPermissions ? const HomeScreen() : const PermissionScreen(),
        );
      },
    );
  }
}
