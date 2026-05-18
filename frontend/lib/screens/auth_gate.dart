import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../utils/web_theme_color.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  String _colorToHex(Color color) {
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  SystemUiOverlayStyle _overlayStyleFor(Color backgroundColor) {
    final isDark =
        ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;

    return (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(
      statusBarColor: backgroundColor,
      systemNavigationBarColor: backgroundColor,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  void _applySystemUi(Color backgroundColor) {
    final style = _overlayStyleFor(backgroundColor);
    final hex = _colorToHex(backgroundColor);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(style);
      setWebThemeColor(hex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final Color systemBarColor = authController.isLoggedIn
            ? Theme.of(context).colorScheme.surface
            : Colors.white;

        _applySystemUi(systemBarColor);

        Widget child;

        if (authController.isInitializing) {
          child = Scaffold(
            backgroundColor: systemBarColor,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_customize,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Life Custom',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    '起動中...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        } else if (authController.isLoggedIn) {
          child = const HomePage();
        } else {
          child = const LoginPage();
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _overlayStyleFor(systemBarColor),
          child: child,
        );
      },
    );
  }
}