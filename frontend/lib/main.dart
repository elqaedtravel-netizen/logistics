import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/admin/admin_shell_screen.dart';
import 'presentation/driver/driver_home_screen.dart';
import 'presentation/storefront/storefront_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AntigravityLogisticsApp(),
    ),
  );
}

class AntigravityLogisticsApp extends ConsumerWidget {
  const AntigravityLogisticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'أنتيجرافيتي للشحن واللوجستيات',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar', 'EG'), // المصرية (Arabic Egypt)
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // تخطيط كامل من اليمين لليسار
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _resolveAppRoot(authState),
    );
  }

  Widget _resolveAppRoot(AuthState authState) {
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.isAuthenticated && authState.user != null) {
      final user = authState.user!;
      if (user.isAdmin || user.isDispatcher) {
        return const AdminShellScreen();
      } else if (user.isDriver) {
        return const DriverHomeScreen();
      }
    }

    // الواجهة الافتراضية للمتجر الإلكتروني وتتبع الشحنات للعملاء
    return const StorefrontHomeScreen();
  }
}
