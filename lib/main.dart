import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  // Refresh the scheduled-notification window every time the app opens.
  final storage = StorageService();
  final reminders = await storage.load();
  await NotificationService.rescheduleAll(reminders);

  runApp(const ChachiApp());
}

class ChachiApp extends StatelessWidget {
  const ChachiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'چاچی',
      debugShowCheckedModeBanner: false,
      theme: buildChachiTheme(),
      locale: const Locale('fa'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
