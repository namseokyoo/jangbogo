import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/shopping_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const JanbogoApp());
}

class JanbogoApp extends StatelessWidget {
  const JanbogoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ShoppingProvider()),
      ],
      child: MaterialApp(
        title: '잔보고',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
