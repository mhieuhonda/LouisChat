import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/app_store.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LouisChatApp());
}

class LouisChatApp extends StatelessWidget {
  const LouisChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStore(),
      child: MaterialApp(
        title: 'LouisChat',
        debugShowCheckedModeBanner: false,
        theme: buildMessengerTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
