import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/symptom_input_screen.dart';

void main() {
  runApp(const SmartHealthApp());
}

class SmartHealthApp extends StatefulWidget {
  const SmartHealthApp({super.key});

  @override
  State<SmartHealthApp> createState() => _SmartHealthAppState();
}

class _SmartHealthAppState extends State<SmartHealthApp> {
  // A single API client is shared across screens.
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Health',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: SymptomInputScreen(api: _api),
    );
  }
}
