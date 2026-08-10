import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'symptom_input_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

/// The app's main scaffold: hosts the four tabs behind a premium bottom
/// navigation bar. An IndexedStack preserves each tab's state when switching.
class MainShell extends StatefulWidget {
  final ApiService api;
  final AuthService auth;
  const MainShell({super.key, required this.api, required this.auth});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onSelectTab: _select),
          SymptomInputScreen(api: widget.api),
          HistoryScreen(onSelectTab: _select),
          ProfileScreen(auth: widget.auth),
        ],
      ),
      bottomNavigationBar: AppBottomNav(index: _index, onTap: _select),
    );
  }
}
